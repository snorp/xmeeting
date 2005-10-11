/*
 * $Id: XMEndPoint.h,v 1.1 2005/10/11 09:03:10 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_END_POINT_H__
#define __XM_END_POINT_H__

#include <ptlib.h>
#include <opal/endpoint.h>

#include "XMOpalManager.h"
#include "XMTypes.h"
#include "XMBridge.h"

class XMConnection;

class XMEndPoint : public OpalEndPoint
{
	PCLASSINFO(XMEndPoint, OpalEndPoint);

public:
	XMEndPoint(OpalManager & manager,
			   const char *prefix = "xm");
	~XMEndPoint();
	
	// Overriding EndPoint methods
	virtual BOOL MakeConnection(OpalCall & call,
								const PString & party,
								void *userData = NULL);
	virtual OpalMediaFormatList GetMediaFormats() const;
	virtual XMConnection * CreateConnection(OpalCall & call, PString & token);
	virtual PSoundChannel * CreateSoundChannel(const XMConnection & connection, BOOL isSource);
	PSafePtr<XMConnection> GetXMConnectionWithLock(const PString & token,
												   PSafetyMode mode = PSafeReadWrite);
	void OnShowIncoming(const XMConnection & connection);
	BOOL OnShowOutgoing(const XMConnection & connection);
	void AcceptIncomingConnection(const PString & connectionToken);
	BOOL OnShowUserInput(const XMConnection & connection, const PString & indication);
	
	// Call Management & Information
	BOOL StartCall(XMCallProtocol protocol, const PString & remoteParty, PString & token);
	void SetAcceptIncomingCall(BOOL acceptCall);
	void ClearCall(const PString & callToken);
	void SetCallProtocol(XMCallProtocol protocol);
											
};

#endif // __XM_END_POINT_H__