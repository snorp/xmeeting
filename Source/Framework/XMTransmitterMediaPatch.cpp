/*
 * $Id: XMTransmitterMediaPatch.cpp,v 1.7 2006/01/09 22:22:57 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#include "XMTransmitterMediaPatch.h"

#include <math.h>
#include <opal/mediastrm.h>

#include "XMBridge.h"
#include "XMMediaFormats.h"
#include "XMMediaStream.h"
#include "XMCallbackBridge.h"

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

BOOL XMTransmitterMediaPatch::IsTerminated() const
{
	if(doesRunOwnThread == TRUE)
	{
		return OpalMediaPatch::IsTerminated();
	}
	else
	{
		// since we don't run our own thread, the IsSuspended()
		// method must return whether the MediaTransmitter is still
		// transmitting media or not. This is required so that
		// WaitForTermination() does behave correctly
		return isTerminated;
	}
}

void XMTransmitterMediaPatch::Resume()
{
	if(PIsDescendant(&source, XMMediaStream))
	{
		// we don't spawn a new thread but instead
		// tell the MediaTransmitter to start transmitting
		// the desired media
		doesRunOwnThread = FALSE;
		isTerminated = FALSE;
		videoTransmitterPatch = this;
		
		PINDEX i = sinks.GetSize();
		if(i > 0)
		{
			unsigned maxFramesPerSecond = UINT_MAX;
			unsigned maxBitrate = _XMGetVideoBandwidthLimit();
			
			OpalMediaFormat mediaFormat = sinks[0].stream->GetMediaFormat();
			
			unsigned frameTime = mediaFormat.GetFrameTime();
			unsigned framesPerSecond = (unsigned)round(90000.0 / (double)frameTime);
			unsigned bitrate = mediaFormat.GetBandwidth();
			unsigned payloadCode = (unsigned)mediaFormat.GetPayloadType();
			if(mediaFormat == XM_MEDIA_FORMAT_H263)
			{
				payloadCode = mediaFormat.GetFrameTime();
			}
			
			codecIdentifier = _XMGetMediaFormatCodec(mediaFormat);
			XMVideoSize videoSize = _XMGetMediaFormatSize(mediaFormat);
			
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
				cout << "Trying to open unknown codec for transmission" << endl;
				return;
			}
			
			_XMStartMediaTransmit(2, codecIdentifier, videoSize, maxFramesPerSecond, maxBitrate, payloadCode);
		}
	}
	else
	{
		// behave as normally
		OpalMediaPatch::Resume();
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
	while(!IsTerminated())
	{
		Sleep(10);
	}
}

BOOL XMTransmitterMediaPatch::ExecuteCommand(const OpalMediaCommand & command,
											 BOOL fromSink)
{
	if(fromSink && PIsDescendant(&command, OpalVideoUpdatePicture))
	{
		_XMUpdatePicture();
		return TRUE;
	}
	return OpalMediaPatch::ExecuteCommand(command, fromSink);
}

void XMTransmitterMediaPatch::SetTimeStamp(unsigned sessionID, unsigned timeStamp)
{
	if(videoTransmitterPatch == NULL)
	{
		cout << "No VideoTransmitterPatch found!" << endl;
		return;
	}
	
	RTP_DataFrame *frame = videoTransmitterPatch->dataFrame;
	
	if(frame == NULL)
	{
		frame = new RTP_DataFrame(20000);
		videoTransmitterPatch->dataFrame = frame;
		frame->SetPayloadSize(0);
		
		XMCodecIdentifier theCodec = videoTransmitterPatch->codecIdentifier;
		
		if(theCodec == XMCodecIdentifier_H261)
		{
			frame->SetPayloadType(RTP_DataFrame::H261);
		}
		else if(theCodec == XMCodecIdentifier_H263)
		{
			OpalMediaFormat mediaFormat = videoTransmitterPatch->sinks[0].stream->GetMediaFormat();
			RTP_DataFrame::PayloadTypes payloadCode = (RTP_DataFrame::PayloadTypes)mediaFormat.GetFrameTime();
			frame->SetPayloadType(payloadCode);
		}
		else if(theCodec == XMCodecIdentifier_H264)
		{
			frame->SetPayloadType(RTP_DataFrame::DynamicBase);
		}
	}
	
	frame->SetTimestamp(timeStamp);
}

void XMTransmitterMediaPatch::AppendData(unsigned sessionID,
										 void *data,
										 unsigned length)
{
	if(videoTransmitterPatch == NULL)
	{
		cout << "No VideoTransmitterPatch found (3)" << endl;
		return;
	}
	
	RTP_DataFrame *frame = videoTransmitterPatch->dataFrame;
	
	if(frame == NULL)
	{
		cout << "FRAME IS NULL" << endl;
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
		cout << "No VideoTransmitterPatch found (4)" << endl;
		return;
	}
		
	RTP_DataFrame *frame = videoTransmitterPatch->dataFrame;
	
	frame->SetMarker(setMarker);
	
	videoTransmitterPatch->inUse.Wait();
	
	videoTransmitterPatch->FilterFrame(*frame, videoTransmitterPatch->source.GetMediaFormat());
	
	PINDEX i;
	for(i = 0; i < videoTransmitterPatch->sinks.GetSize(); i++)
	{
		BOOL result = videoTransmitterPatch->sinks[i].stream->WritePacket(*frame);
		if(result == FALSE)
		{
			cout << "ERROR Writing frame to sink!" << endl;
		}
	}
	
	videoTransmitterPatch->inUse.Signal();
	
	videoTransmitterPatch->dataFrame->SetPayloadSize(0);
}

void XMTransmitterMediaPatch::HandleDidStopTransmitting(unsigned sessionID)
{
	if(videoTransmitterPatch == NULL)
	{
		cout << "ERROR: NO TRANSMITTER PATCH FOUND" << endl;
		return;
	}
	
	videoTransmitterPatch->isTerminated = TRUE;
	videoTransmitterPatch = NULL;
}