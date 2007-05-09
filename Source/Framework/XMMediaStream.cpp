/*
 * $Id: XMMediaStream.cpp,v 1.13 2007/05/09 14:58:21 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#include "XMMediaStream.h"
#include "XMOpalManager.h"
#include "XMCallbackBridge.h"
#include "XMConnection.h"

#include <codec/vidcodec.h>
#include <opal/patch.h>

#define XM_MAX_FPS 30

static XMMediaStream *videoTransmitterStream = NULL;

XMMediaStream::XMMediaStream(XMConnection & conn,
                             const OpalMediaFormat & mediaFormat,
                             BOOL isSource)
: OpalMediaStream(conn, mediaFormat, isSource),
  dataFrame((isSource ? 3000 : 0))
{
    hasStarted = FALSE;
    isTerminated = FALSE;
}

XMMediaStream::~XMMediaStream()
{
}

void XMMediaStream::OnPatchStart()
{
    if (IsSource()) {
        
        PWaitAndSignal m(patchMutex);
        
        // Ensure the code below runs just once.
        // Also avoid possible race conditions
        if(hasStarted == TRUE || isTerminated == TRUE) {
            return;
        }
        
        // Adjust the local media format
        mediaFormat = mediaPatch->GetSinkFormat();
        
        RTP_DataFrame::PayloadTypes payloadType = mediaFormat.GetPayloadType();
        
        unsigned frameTime = mediaFormat.GetFrameTime();
        unsigned framesPerSecond = (unsigned)round((double)OpalMediaFormat::VideoClockRate / (double)frameTime);
        framesPerSecond = std::min((unsigned)XM_MAX_FPS, framesPerSecond);
        
        unsigned bitrate = mediaFormat.GetBandwidth();
        bitrate = std::min(bitrate, XMOpalManager::GetManager()->GetVideoBandwidthLimit());
        
        unsigned flags = 0;
        
        XMCodecIdentifier codecIdentifier = _XMGetMediaFormatCodec(mediaFormat);
        XMVideoSize videoSize = _XMGetMediaFormatSize(mediaFormat);
        
        if(codecIdentifier == XMCodecIdentifier_UnknownCodec ||
           videoSize == XMVideoSize_NoVideo) 
        {
            // Shouldn't actually happen
            return;
        }
        
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
            if(_XMGetH264PacketizationMode(mediaFormat) == XM_H264_PACKETIZATION_MODE_SINGLE_NAL)
            {
                // We send only at a limited bitrate to avoid too many
                // NAL units which are TOO big to fit
                if(bitrate > 320000)
                {
                    bitrate = 320000;
                }
            }
            
            flags = (_XMGetH264PacketizationMode(mediaFormat) << 8) + (_XMGetH264Profile(mediaFormat) << 4) + _XMGetH264Level(mediaFormat);
        }
        
        videoTransmitterStream = this;
        hasStarted = TRUE;
        
        dataFrame.SetPayloadSize(0);
        dataFrame.SetPayloadType(payloadType);
        
        unsigned keyframeInterval = XMOpalManager::GetManager()->GetKeyFrameIntervalForCurrentCall(codecIdentifier);
        _XMStartMediaTransmit(2, codecIdentifier, videoSize, framesPerSecond, bitrate, keyframeInterval, flags);
    }
}

BOOL XMMediaStream::Close()
{	
    if (IsSource())
    {
        patchMutex.Wait();
        if (hasStarted == TRUE) {
            _XMStopMediaTransmit(2);
        } else {
            isTerminated = TRUE;
        }
        patchMutex.Signal();
        
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
        return;
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

BOOL XMMediaStream::ExecuteCommand(const OpalMediaCommand & command,
                                   BOOL isEndOfChain)
{
    if(isEndOfChain == TRUE) {
        if(PIsDescendant(&command, OpalVideoUpdatePicture)) {
            _XMUpdatePicture();
        }
        return TRUE;
    }
    return OpalMediaStream::ExecuteCommand(command, isEndOfChain);
}
