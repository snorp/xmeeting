/*
 * $Id: XMConnection.h,v 1.16 2008/10/08 23:55:32 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
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
  //virtual void AdjustMediaFormatOptions(OpalMediaFormat & mediaFormat) const;
    
  //virtual bool SetBandwidthAvailable(unsigned newBandwidth, bool force = false);
	
  virtual bool IsMediaBypassPossible(const OpalMediaType & mediaType) const { return false; }
	
  virtual OpalMediaStream * CreateMediaStream(const OpalMediaFormat & mediaFormat,
                                              unsigned sessionID,
                                              bool isSource);
  virtual void OnPatchMediaStream(bool isSource, OpalMediaPatch & patch);
  PSoundChannel * CreateSoundChannel(bool isSource);
	
  OpalH281Handler * GetH281Handler();
	
private:
		
  OpalH224Handler * GetH224Handler();
  
  bool enableVideo;
	
  XMEndPoint & endpoint;
  OpalH224Handler *h224Handler;
  OpalH281Handler *h281Handler;
    
  //OpalVideoFormat h261VideoFormat;
  //OpalVideoFormat h263VideoFormat;
  //OpalVideoFormat h263PlusVideoFormat;
  //OpalVideoFormat h264VideoFormat;
};

#endif // __XM_CONNECTION_H__

