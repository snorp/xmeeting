/*
 * $Id: XMMediaStream.h,v 1.14 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_MEDIA_STREAM_H__
#define __XM_MEDIA_STREAM_H__

#include <ptlib.h>
#include <opal/mediastrm.h>
#include <rtp/rtp.h>

#include "XMTypes.h"

class XMConnection;

/**
 * OpalMediaStream wrapper for QuickTime codecs (sending)
 * The packetizers directly assemble the RTP data frame through the
 * API presented here
 **/
class XMMediaStream : public OpalMediaStream
{
  PCLASSINFO(XMMediaStream, OpalMediaStream);
	
public:
  XMMediaStream(XMConnection & connection,
                const OpalMediaFormat & mediaFormat,
                unsigned sessionID,
                bool isSource);
  ~XMMediaStream();
	
  virtual void OnPatchStart();
  virtual bool Close();
  virtual bool ReadPacket(RTP_DataFrame & packet);
  virtual bool WritePacket(RTP_DataFrame & packet);
  virtual bool IsSynchronous() const { return false; }
  virtual bool RequiresPatchThread() const { return false; }
  
  virtual bool ExecuteCommand(const OpalMediaCommand & command);
    
  // packetizer methods
  static void SetTimeStamp(unsigned mediaID, unsigned timeStamp);
  static void AppendData(unsigned mediaID, void *data, unsigned lenght);
  static void SendPacket(unsigned mediaID, bool setMarker);
  static void HandleDidStopTransmitting(unsigned mediaID);
    
private:
    
  unsigned GetKeyFrameInterval(XMCodecIdentifier identifier);
  
  XMConnection & connection;
  RTP_DataFrame dataFrame;
  unsigned timeStampBase;
  bool hasStarted;
  bool isTerminated;
};

#endif // __XM_MEDIA_STREAM_H__
