/*
 * $Id: XMMediaStream.cpp,v 1.22 2008/10/16 22:04:44 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#include <ptclib/random.h>

#include <codec/vidcodec.h>
#include <opal/patch.h>

#include "XMMediaStream.h"
#include "XMOpalManager.h"
#include "XMCallbackBridge.h"
#include "XMConnection.h"
#include "XMEndPoint.h"

#define XM_MAX_FPS 30

static XMMediaStream *videoTransmitterStream = NULL;

XMMediaStream::XMMediaStream(XMConnection & _connection,
                             const OpalMediaFormat & mediaFormat,
                             unsigned sessionID,
                             bool isSource)
: OpalMediaStream(_connection, mediaFormat, sessionID, isSource),
  connection(_connection),
  dataFrame((isSource ? 3000 : 0)),
  hasStarted(false),
  isTerminated(false),
  timeStampBase(PRandom::Number())
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
      
    RTP_DataFrame::PayloadTypes payloadType = mediaFormat.GetPayloadType();
        
    unsigned frameTime = mediaFormat.GetFrameTime();
    unsigned framesPerSecond = (unsigned)round((double)OpalMediaFormat::VideoClockRate / (double)frameTime);
    framesPerSecond = std::min((unsigned)XM_MAX_FPS, framesPerSecond);
    framesPerSecond = std::max(framesPerSecond, (unsigned)1);
        
    unsigned bitrate = mediaFormat.GetBandwidth();
    bitrate = std::min(bitrate, XMOpalManager::GetManager()->GetVideoBandwidthLimit(mediaFormat));
        
    unsigned flags = 0;
        
    XMCodecIdentifier codecIdentifier = _XMGetMediaFormatCodec(mediaFormat);
    XMVideoSize videoSize = _XMGetMediaFormatSize(mediaFormat);
        
    if(codecIdentifier == XMCodecIdentifier_UnknownCodec ||
       videoSize == XMVideoSize_NoVideo || videoSize == XMVideoSize_Custom) {
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
      //if(_XMGetH264PacketizationMode(mediaFormat) == XM_H264_PACKETIZATION_MODE_SINGLE_NAL) {
        // We send only at a limited bitrate to avoid too many
        // NAL units which are TOO big to fit
        if(bitrate > 320000) {
          bitrate = 320000;
        }
      //}
      // TODO: FIXME
      flags = (XM_H264_PACKETIZATION_MODE_SINGLE_NAL << 8) + (_XMGetH264Profile(mediaFormat) << 4) + _XMGetH264Level(mediaFormat);
    }
        
    videoTransmitterStream = this;
    hasStarted = true;
        
    dataFrame.SetPayloadSize(0);
    dataFrame.SetPayloadType(payloadType);
        
    unsigned keyFrameInterval = GetKeyFrameInterval(codecIdentifier);
    _XMStartMediaTransmit(2, codecIdentifier, videoSize, framesPerSecond, bitrate, keyFrameInterval, flags);
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

bool XMMediaStream::ExecuteCommand(const OpalMediaCommand & command)
{
  if(PIsDescendant(&command, OpalVideoUpdatePicture)) {
    _XMUpdatePicture();
   // return true;
  }
  return OpalMediaStream::ExecuteCommand(command);
}

void XMMediaStream::SetTimeStamp(unsigned mediaID, unsigned timeStamp)
{
  if (videoTransmitterStream == NULL) {
    return;
  }
    
  RTP_DataFrame & dataFrame = videoTransmitterStream->dataFrame;
  dataFrame.SetTimestamp(videoTransmitterStream->timeStampBase + timeStamp);
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

unsigned XMMediaStream::GetKeyFrameInterval(XMCodecIdentifier codecIdentifier)
{
  XMCallProtocol callProtocol = XMEndPoint::GetCallProtocolForCall(connection);
  PString remoteApplicationString = XMOpalManager::GetRemoteApplicationString(connection.GetRemoteProductInfo());
  
  // Polycom MGC (Accord MGC) has problems decoding QuickTime H.263. If at all, only I-frames should be sent.
  if (codecIdentifier == XMCodecIdentifier_H263 && remoteApplicationString.Find("ACCORD MGC") != P_MAX_INDEX) {
    // zero key frame interval means sending only I-frames
    return 0;
  }
  
  switch (callProtocol) {
    case XMCallProtocol_H323:
      return 200;
    case XMCallProtocol_SIP:
      return 60;
    default:
      return 0;
  }
}
                                           
