/*
 * $Id: XMTransmitterMediaPatch.cpp,v 1.25 2007/02/08 08:43:34 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#include "XMTransmitterMediaPatch.h"

#include <math.h>
#include <opal/mediastrm.h>

#include "XMOpalManager.h"
#include "XMBridge.h"
#include "XMMediaFormats.h"
#include "XMMediaStream.h"
#include "XMCallbackBridge.h"

#include "XMAudioTester.h"

static XMTransmitterMediaPatch *videoTransmitterPatch = NULL;

XMTransmitterMediaPatch::XMTransmitterMediaPatch(OpalMediaStream & src)
: OpalMediaPatch(src)
{
	doesRunOwnThread = TRUE;
	isTerminated = FALSE;
	dataFrame = NULL;
	codecIdentifier = XMCodecIdentifier_UnknownCodec;
}

XMTransmitterMediaPatch::~XMTransmitterMediaPatch()
{
}

void XMTransmitterMediaPatch::Start()
{
	XMAudioTester::Stop();
	
	if(PIsDescendant(&source, XMMediaStream))
	{
		// If Resume has already been called, don't start the process again
		if(doesRunOwnThread == FALSE)
		{
			return;
		}

		// we don't spawn a new thread but instead
		// tell the MediaTransmitter to start transmitting
		// the desired media
		doesRunOwnThread = FALSE;
		videoTransmitterPatch = this;
		
		PINDEX i = sinks.GetSize();
		if(i > 0)
		{
			unsigned maxFramesPerSecond = UINT_MAX;
			unsigned maxBitrate = XMOpalManager::GetVideoBandwidthLimit();
			
			OpalMediaFormat mediaFormat = sinks[0].stream->GetMediaFormat();
			payloadType = mediaFormat.GetPayloadType();
			
			unsigned frameTime = mediaFormat.GetFrameTime();
			unsigned framesPerSecond = (unsigned)round(90000.0 / (double)frameTime);
			unsigned bitrate = mediaFormat.GetBandwidth()*100;
			unsigned flags = 0;
						
			codecIdentifier = _XMGetMediaFormatCodec(mediaFormat);
			XMVideoSize videoSize = _XMGetMediaFormatSize(mediaFormat);

			if(codecIdentifier == XMCodecIdentifier_H263)
			{
				// If we're  sending H.263, we need to know which
				// format to send. The payload code is submitted in the
				// flags parameter
				flags = payloadType;
				
				if(payloadType == RTP_DataFrame::H263)
				{
					cout << "Sending RFC2190" << endl;
				}
				else
				{
					cout << "Sending RFC2429" << endl;
				}
			}
			else if(codecIdentifier == XMCodecIdentifier_H264)
			{
				if(_XMGetH264PacketizationMode() == XM_H264_PACKETIZATION_MODE_SINGLE_NAL)
				{
					// We send only at a limited bitrate to avoid too many
					// NAL units which are TOO big to fit
					if(bitrate > 320000)
					{
						bitrate = 320000;
					}
				}
				
				flags = (_XMGetH264PacketizationMode() << 8) + (_XMGetH264Profile() << 4) + _XMGetH264Level();
			}
			
			// adjusting the maxFramesPerSecond / maxBitrate parameters
			if(framesPerSecond < maxFramesPerSecond)
			{
				maxFramesPerSecond = framesPerSecond;
			}
			
			if(bitrate < maxBitrate)
			{
				maxBitrate = bitrate;
			}
			
			if(codecIdentifier == XMCodecIdentifier_UnknownCodec ||
			   videoSize == XMVideoSize_NoVideo)
			{
				return;
			}
			
			unsigned keyframeInterval = XMOpalManager::GetManagerInstance()->GetKeyFrameIntervalForCurrentCall(codecIdentifier);
			_XMStartMediaTransmit(2, codecIdentifier, videoSize, maxFramesPerSecond, maxBitrate, keyframeInterval, flags);
			
			// adjusting the payload type afterwards, now that the packetization scheme has
			// been determined
			OpalTranscoder * transcoder = sinks[0].primaryCodec;
			if(PIsDescendant(transcoder, XMVideoTranscoder))
			{
				XMVideoTranscoder *t = (XMVideoTranscoder *)transcoder;
				RTP_DataFrame::PayloadMapType map = t->GetPayloadMap();
				
				if(map.size() != 0)
				{
					RTP_DataFrame::PayloadMapType::iterator r = map.find(mediaFormat.GetPayloadType());
					if(r != map.end())
					{
						payloadType = r->second;
					}
				}
			}
		}
	}
	else
	{
		// Adjust the number of samples per packet if needed
		inUse.Wait();
		
		if(sinks.GetSize() == 0)
		{
			return; // should not happen!
		}
		BOOL isStreamedTranscoder = FALSE;
		Sink & sink = sinks[0];
		if(PIsDescendant(sink.primaryCodec, OpalStreamedTranscoder))
		{
			isStreamedTranscoder = TRUE;
		}
		if(isStreamedTranscoder == TRUE)
		{
			unsigned packetTime = XMOpalManager::GetManagerInstance()->GetCurrentAudioPacketTime();
			if(packetTime != 0)
			{
				OpalMediaFormat mediaFormat = source.GetMediaFormat();
				PINDEX size = mediaFormat.GetTimeUnits() * packetTime;
				source.SetDataSize(2*size); // implicitely assuming PCM-16
				mediaFormat = sink.stream->GetMediaFormat();
				size = mediaFormat.GetTimeUnits() * packetTime;
				sink.stream->SetDataSize(size); // implicitely assuming PCMA / PCMU
			}
		}
		inUse.Signal();
			
		// behave as normally
		OpalMediaPatch::Start();
	}
}

void XMTransmitterMediaPatch::Close()
{
	if(doesRunOwnThread == FALSE)
	{
		_XMStopMediaTransmit(2);
	}
	
	OpalMediaPatch::Close();
	
	// Waiting until the MediaTransmitter suspended the
	// transmission of media
	while(doesRunOwnThread == FALSE && isTerminated == FALSE)
	{
		PThread::Sleep(10);
	}
}

BOOL XMTransmitterMediaPatch::ExecuteCommand(const OpalMediaCommand & command,
											 BOOL fromSink)
{
	if(fromSink)
	{
		if(PIsDescendant(&command, OpalVideoUpdatePicture))
		{
			_XMUpdatePicture();
			return TRUE;
		}
		else if(PIsDescendant(&command, OpalTemporalSpatialTradeOff))
		{
			return TRUE;
		}
		else if(PIsDescendant(&command, OpalVideoFreezePicture))
		{
			return TRUE;
		}
	}
	
	return OpalMediaPatch::ExecuteCommand(command, fromSink);
}

void XMTransmitterMediaPatch::SetTimeStamp(unsigned sessionID, unsigned timeStamp)
{
	if(videoTransmitterPatch == NULL)
	{
		return;
	}
	
	RTP_DataFrame *frame = videoTransmitterPatch->dataFrame;
	
	if(frame == NULL)
	{
		frame = new RTP_DataFrame(3000);
		videoTransmitterPatch->dataFrame = frame;
		frame->SetPayloadSize(0);
		
		frame->SetPayloadType(videoTransmitterPatch->payloadType);
	}
	
	frame->SetTimestamp(timeStamp);
}

void XMTransmitterMediaPatch::AppendData(unsigned sessionID,
										 void *data,
										 unsigned length)
{
	if(videoTransmitterPatch == NULL)
	{
		return;
	}
	
	RTP_DataFrame *frame = videoTransmitterPatch->dataFrame;
	
	if(frame == NULL)
	{
		return;
	}
	
	BYTE *dataPtr = frame->GetPayloadPtr();
	PINDEX dataSize = frame->GetPayloadSize();
	
	dataPtr += dataSize;
	dataSize += length;
	
	memcpy(dataPtr, data, length);
	
	frame->SetPayloadSize(dataSize);
}

void XMTransmitterMediaPatch::SendPacket(unsigned sessionID, BOOL setMarker)
{	
	if(videoTransmitterPatch == NULL)
	{
		return;
	}
		
	RTP_DataFrame *frame = videoTransmitterPatch->dataFrame;
	
	frame->SetMarker(setMarker);
	
	videoTransmitterPatch->inUse.Wait();
	
	PINDEX i;
	PINDEX size = videoTransmitterPatch->sinks.GetSize();
	for(i = 0; i < size; i++)
	{
		BOOL result = videoTransmitterPatch->sinks[i].stream->WritePacket(*frame);
		if(result == FALSE)
		{
			cout << "ERROR when writing frame to sink!" << endl;
		}
	}
	
	videoTransmitterPatch->inUse.Signal();
	
	videoTransmitterPatch->dataFrame->SetPayloadSize(0);
}

void XMTransmitterMediaPatch::HandleDidStopTransmitting(unsigned sessionID)
{
	if(videoTransmitterPatch == NULL)
	{
		return;
	}
	
	videoTransmitterPatch->isTerminated = TRUE;
	videoTransmitterPatch = NULL;
}