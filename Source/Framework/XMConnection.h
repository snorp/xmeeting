/*
 * $Id: XMConnection.h,v 1.22 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CONNECTION_H__
#define __XM_CONNECTION_H__

#include <ptlib.h>
#include <opal/localep.h>
#include "XMBridge.h"

class XMEndPoint;
class OpalH224Handler;
class OpalH281Handler;

class XMConnection : public OpalLocalConnection
{
  PCLASSINFO(XMConnection, OpalLocalConnection);
	
public:
  XMConnection(OpalCall & call, XMEndPoint & endPoint);
  ~XMConnection();
	
  // Overrides from OpalLocalConnection
  virtual void Release(OpalConnection::CallEndReason callEndReason);
  
  virtual OpalMediaFormatList GetMediaFormats() const;
	
  virtual OpalMediaStream * CreateMediaStream(const OpalMediaFormat & mediaFormat,
                                              unsigned sessionID,
                                              bool isSource);
  virtual void OnPatchMediaStream(bool isSource, OpalMediaPatch & patch);
  
  // bandwidth management
  virtual bool SetBandwidthAvailable(unsigned newBandwidth, bool force = false);
  virtual unsigned GetBandwidthUsed() const { return 0; }
  virtual bool SetBandwidthUsed(unsigned releasedBandwidth, unsigned requiredBandwidth) { return true; }
  
  OpalH281Handler * GetH281Handler();
	
private:
		
  PSoundChannel * CreateSoundChannel(bool isSource);
  OpalH224Handler * GetH224Handler();
  
  bool enableVideo;
	
  XMEndPoint & endpoint;
  OpalH224Handler *h224Handler;
  OpalH281Handler *h281Handler;
    
  OpalMediaFormat h261VideoFormat;
  OpalMediaFormat h263VideoFormat;
  OpalMediaFormat h263PlusVideoFormat;
  OpalMediaFormat h264VideoFormat;
};

#endif // __XM_CONNECTION_H__

