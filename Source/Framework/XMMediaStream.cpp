/*
 * $Id: XMMediaStream.cpp,v 1.7 2007/02/08 23:09:13 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#include "XMMediaStream.h"
#include "XMOpalManager.h"
#include "XMCallbackBridge.h"

#include <codec/vidcodec.h>

static XMMediaStream *videoTransmitterStream = NULL;

XMMediaStream::XMMediaStream(const OpalMediaFormat & mediaFormat,
										   BOOL isSource)
: OpalMediaStream(mediaFormat, isSource),
  dataFrame((isSource ? 3000 : 0))
{
      isTerminated = FALSE;
}

XMMediaStream::~XMMediaStream()
{
}

void XMMediaStream::OnPatchStart()
{
    if (isSource == TRUE) {
        unsigned maxFramesPerSecond = UINT_MAX;
        unsigned maxBitrate = XMOpalManager::GetVideoBandwidthLimit();
        
        RTP_DataFrame::PayloadTypes payloadType = mediaFormat.GetPayloadType();
        
        unsigned frameTime = mediaFormat.GetFrameTime();
        unsigned framesPerSecond = (unsigned)round(90000.0 / (double)frameTime);
        unsigned bitrate = mediaFormat.GetBandwidth()*100;
        unsigned flags = 0;
        
        XMCodecIdentifier codecIdentifier = _XMGetMediaFormatCodec(mediaFormat);
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
        
        // adjusting the payload type afterwards, now that the packetization scheme has
        // been determined
        
        //FIXME
        /*OpalTranscoder * transcoder = sinks[0].primaryCodec;
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
        }*/
        
        videoTransmitterStream = this;
        
        dataFrame.SetPayloadSize(0);
        dataFrame.SetPayloadType(payloadType);
        
        unsigned keyframeInterval = XMOpalManager::GetManager()->GetKeyFrameIntervalForCurrentCall(codecIdentifier);
        _XMStartMediaTransmit(2, codecIdentifier, videoSize, maxFramesPerSecond, maxBitrate, keyframeInterval, flags);
    }
}

BOOL XMMediaStream::Close()
{	
    if (IsSource())
    {
        _XMStopMediaTransmit(2);
        
        // Wait until the video system terminated
        while(isTerminated == FALSE) {
            PThread::Sleep(10);
        }
    }
    
    return OpalMediaStream::Close();
}

BOOL XMMediaStream::ReadPacket(RTP_DataFrame & packet)
{	
	return FALSE;
}

BOOL XMMediaStream::WritePacket(RTP_DataFrame & packet)
{
	return FALSE;
}

void XMMediaStream::SetTimeStamp(unsigned mediaID, unsigned timeStamp)
{
    if (videoTransmitterStream == NULL) {
        FALSE;
    }
    
    RTP_DataFrame & dataFrame = videoTransmitterStream->dataFrame;
    dataFrame.SetTimestamp(timeStamp);
}

void XMMediaStream::AppendData(unsigned mediaID, void *data, unsigned length)
{
    if (videoTransmitterStream == NULL) {
        return;
    }
    
    RTP_DataFrame & dataFrame = videoTransmitterStream->dataFrame;

    BYTE *dataPtr = dataFrame.GetPayloadPtr();
    PINDEX dataSize = dataFrame.GetPayloadSize();
    
    dataPtr += dataSize;
    dataSize += length;
    
    memcpy(dataPtr, data, length);
    
    dataFrame.SetPayloadSize(dataSize);
}

void XMMediaStream::SendPacket(unsigned mediaID, BOOL setMarker)
{
    if (videoTransmitterStream == NULL) {
        return;
    }
    
    RTP_DataFrame & dataFrame = videoTransmitterStream->dataFrame;
    
    dataFrame.SetMarker(setMarker);
    
    videoTransmitterStream->PushPacket(dataFrame);
    
    dataFrame.SetPayloadSize(0);
}

void XMMediaStream::HandleDidStopTransmitting(unsigned mediaID)
{
    if (videoTransmitterStream == NULL) {
        return;
    }
    
    videoTransmitterStream->isTerminated = TRUE;
    videoTransmitterStream = NULL;
}
