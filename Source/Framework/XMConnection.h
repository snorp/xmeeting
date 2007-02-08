/*
 * $Id: XMConnection.h,v 1.9 2007/02/08 08:43:34 hfriederich Exp $
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
	virtual BOOL OnOpenMediaStream(OpalMediaStream & stream);
	
	void AcceptIncoming();
	PSoundChannel * CreateSoundChannel(BOOL isSource);
	
	virtual BOOL IsMediaBypassPossible(const OpalMediaType & mediaType) const;
	
	virtual OpalMediaStream * CreateMediaStream(const OpalMediaFormat & mediaFormat,
												BOOL isSource);
	virtual void OnPatchMediaStream(BOOL isSource, OpalMediaPatch & patch);
	
	BOOL SendUserInputString(const PString & value);
	virtual BOOL GetMediaInformation(const OpalMediaType & mediaType,  MediaInformation & info) const;
	
	OpalH281Handler * GetH281Handler();
	
private:
		
	OpalH224Handler * GetH224Handler();
	
	XMEndPoint & endpoint;
	OpalH224Handler *h224Handler;
	OpalH281Handler *h281Handler;
};

#endif // __XM_CONNECTION_H__

