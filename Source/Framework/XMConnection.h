/*
 * $Id: XMConnection.h,v 1.10 2007/02/13 11:56:08 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CONNECTION_H__
#define __XM_CONNECTION_H__

#include <ptlib.h>
#include <opal/connection.h>
#include "XMBridge.h"

class XMEndPoint;
class OpalH224Handler;
class OpalH281Handler;

class XMConnection : public OpalConnection
{
	PCLASSINFO(XMConnection, OpalConnection);
	
public:
	XMConnection(OpalCall & call,
				 XMEndPoint & endPoint,
				 const PString & token);
	~XMConnection();
	
    virtual BOOL OnIncomingConnection(unsigned int options, OpalConnection::StringOptions * stringOptions);
	virtual BOOL SetUpConnection();
	virtual BOOL SetAlerting(const PString & calleeName,
							 BOOL withMedia);
	virtual BOOL SetConnected();
	virtual OpalMediaFormatList GetMediaFormats() const;
    virtual void AdjustMediaFormatOptions(OpalMediaFormat & mediaFormat) const;
    
    virtual BOOL SetBandwidthAvailable(unsigned newBandwidth, BOOL force = FALSE);
	
	void AcceptIncoming();
	
	virtual BOOL IsMediaBypassPossible(const OpalMediaType & mediaType) const { return FALSE; }
	
	virtual OpalMediaStream * CreateMediaStream(const OpalMediaFormat & mediaFormat,
												BOOL isSource);
    virtual BOOL OnOpenMediaStream(OpalMediaStream & stream);
	virtual void OnPatchMediaStream(BOOL isSource, OpalMediaPatch & patch);
    PSoundChannel * CreateSoundChannel(BOOL isSource);
	
	BOOL SendUserInputString(const PString & value);
	virtual BOOL GetMediaInformation(const OpalMediaType & mediaType,  MediaInformation & info) const;
	
	OpalH281Handler * GetH281Handler();
	
private:
		
	OpalH224Handler * GetH224Handler();
    
    BOOL enableVideo;
	
	XMEndPoint & endpoint;
	OpalH224Handler *h224Handler;
	OpalH281Handler *h281Handler;
    
    OpalVideoFormat h261VideoFormat;
    OpalVideoFormat h263VideoFormat;
    OpalVideoFormat h263PlusVideoFormat;
    OpalVideoFormat h264VideoFormat;
};

#endif // __XM_CONNECTION_H__

