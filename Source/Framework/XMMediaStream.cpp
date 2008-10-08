/*
 * $Id: XMMediaStream.cpp,v 1.16 2008/10/08 21:20:50 hfriederich Exp $
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
                             unsigned sessionID,
                             bool isSource)
: OpalMediaStream(conn, mediaFormat, sessionID, isSource),
  dataFrame((isSource ? 3000 : 0)),
  hasStarted(false),
  isTerminated(false)
{
}

XMMediaStream::~XMMediaStream()
{
}

void XMMediaStream::OnPatchStart()
{
  if (IsSource()) {
        
    PSafeLockReadWrite safeLock(*this);
    if (!safeLock.IsLocked()) {
      return;
    }
      
    // Ensure the code below runs just once.
    // Also avoid possible race conditions
    if(hasStarted == true || isTerminated == true) {
      return;
    }
        
    // Adjust the local media format
    mediaFormat = mediaPatch->GetSource().GetMediaFormat();
      
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
        
    if(codecIdentifier == XMCodecIdentifier_H263) {
      // If we're  sending H.263, we need to know which
      // format to send. The payload code is submitted in the
      // flags parameter
      flags = payloadType;
            
      if(payloadType == RTP_DataFrame::H263) {
        cout << "Sending RFC2190" << endl;
      } else {
        cout << "Sending RFC2429" << endl;
      }
    } else if(codecIdentifier == XMCodecIdentifier_H264) {
      if(_XMGetH264PacketizationMode(mediaFormat) == XM_H264_PACKETIZATION_MODE_SINGLE_NAL) {
        // We send only at a limited bitrate to avoid too many
        // NAL units which are TOO big to fit
        if(bitrate > 320000) {
          bitrate = 320000;
        }
      }
        
      flags = (_XMGetH264PacketizationMode(mediaFormat) << 8) + (_XMGetH264Profile(mediaFormat) << 4) + _XMGetH264Level(mediaFormat);
    }
        
    videoTransmitterStream = this;
    hasStarted = true;
        
    dataFrame.SetPayloadSize(0);
    dataFrame.SetPayloadType(payloadType);
        
    unsigned keyframeInterval = XMOpalManager::GetManager()->GetKeyFrameIntervalForCurrentCall(codecIdentifier);
    _XMStartMediaTransmit(2, codecIdentifier, videoSize, framesPerSecond, bitrate, keyframeInterval, flags);
  }
}

bool XMMediaStream::Close()
{	
  if (IsSource()) {
    if (!LockReadWrite()) {
      return false;
    }
    if (hasStarted == true) {
      _XMStopMediaTransmit(2);
    } else {
      isTerminated = true;
    }
    UnlockReadWrite();
        
    // Wait until the video system terminated
    while(isTerminated == false) {
      PThread::Sleep(10);
    }
  }
    
  return OpalMediaStream::Close();
}

bool XMMediaStream::ReadPacket(RTP_DataFrame & packet)
{	
  return false;
}

bool XMMediaStream::WritePacket(RTP_DataFrame & packet)
{
  return false;
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
  
  // SetPayloadSize must be called BEFORE copying the data, or some data will get lost.
  // (Don't know why!!!!!)
  dataFrame.SetPayloadSize(dataSize);
    
  memcpy(dataPtr, data, length);
}

void XMMediaStream::SendPacket(unsigned mediaID, bool setMarker)
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
      
  videoTransmitterStream->isTerminated = true;
  videoTransmitterStream = NULL;
}

/*bool XMMediaStream::ExecuteCommand(const OpalMediaCommand & command,
                                   bool isEndOfChain)
{
    if(isEndOfChain == true) {
        if(PIsDescendant(&command, OpalVideoUpdatePicture)) {
            _XMUpdatePicture();
        }
        return true;
    }
    return OpalMediaStream::ExecuteCommand(command/*, isEndOfChain);
}*/
