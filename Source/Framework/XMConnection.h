/*
 * $Id: XMConnection.h,v 1.6 2006/10/21 11:52:11 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CONNECTION_H__
#define __XM_CONNECTION_H__

#include <ptlib.h>
#include <opal/connection.h>
#include "XMBridge.h"

class XMEndPoint;

class XMConnection : public OpalConnection
{
	PCLASSINFO(XMConnection, OpalConnection);
	
public:
	XMConnection(OpalCall & call,
				 XMEndPoint & endPoint,
				 const PString & token);
	~XMConnection();
	
	virtual BOOL SetUpConnection();
	virtual BOOL SetAlerting(const PString & calleeName,
							 BOOL withMedia);
	virtual BOOL SetConnected();
	virtual OpalMediaFormatList GetMediaFormats() const;
	virtual BOOL OnOpenMediaStream(OpalMediaStream & stream);
	
	void AcceptIncoming();
	PSoundChannel * CreateSoundChannel(BOOL isSource);
	
	virtual BOOL IsMediaBypassPossible(unsigned sessionID) const;
	
	virtual OpalMediaStream * CreateMediaStream(const OpalMediaFormat & mediaFormat,
												unsigned sessionID,
												BOOL isSource);
	virtual void OnPatchMediaStream(BOOL isSource, OpalMediaPatch & patch);
	
private:
	XMEndPoint & endpoint;
};

#endif // __XM_CONNECTION_H__

