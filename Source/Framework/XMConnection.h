/*
 * $Id: XMConnection.h,v 1.12 2008/08/14 19:57:05 hfriederich Exp $
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
	PCLASSINFO(XMConnection, OpalConnection);
	
public:
	XMConnection(OpalCall & call,
				 XMEndPoint & endPoint);
	~XMConnection();
	
  virtual bool OnIncomingConnection(unsigned int options, OpalConnection::StringOptions * stringOptions);
  virtual bool SetUpConnection();
  virtual bool SetAlerting(const PString & calleeName,
                           bool withMedia);
	virtual bool SetConnected();
	virtual OpalMediaFormatList GetMediaFormats() const;
    virtual void AdjustMediaFormatOptions(OpalMediaFormat & mediaFormat) const;
    
    virtual bool SetBandwidthAvailable(unsigned newBandwidth, bool force = false);
	
	void AcceptIncoming();
	
	virtual bool IsMediaBypassPossible(const OpalMediaType & mediaType) const { return false; }
	
	virtual OpalMediaStream * CreateMediaStream(const OpalMediaFormat & mediaFormat,
                                              unsigned sessionID,
                                              bool isSource);
    virtual bool OnOpenMediaStream(OpalMediaStream & stream);
	virtual void OnPatchMediaStream(bool isSource, OpalMediaPatch & patch);
    virtual void OnClosedMediaStream(const OpalMediaStream & stream);
    PSoundChannel * CreateSoundChannel(bool isSource);
	
	bool SendUserInputString(const PString & value);
	
	OpalH281Handler * GetH281Handler();
	
private:
		
	OpalH224Handler * GetH224Handler();
    
    bool enableVideo;
	
	XMEndPoint & endpoint;
	OpalH224Handler *h224Handler;
	OpalH281Handler *h281Handler;
    
    OpalVideoFormat h261VideoFormat;
    OpalVideoFormat h263VideoFormat;
    OpalVideoFormat h263PlusVideoFormat;
    OpalVideoFormat h264VideoFormat;
};

#endif // __XM_CONNECTION_H__

