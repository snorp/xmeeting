/*
 * $Id: XMEndPoint.h,v 1.7 2006/03/14 23:05:57 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
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
	XMEndPoint(OpalManager & manager);
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
	
	// Call Management & Information
	BOOL StartCall(XMCallProtocol protocol, const PString & remoteParty, PString & token);
	void OnShowOutgoing(const XMConnection & connection);
	void OnShowIncoming(XMConnection & connection);
	void AcceptIncomingCall();
	void RejectIncomingCall();
	
	virtual void OnReleased(OpalConnection & connection);
	virtual void OnEstablished(OpalConnection & connection);

	void SetEnableVideo(BOOL enableVideo);

private:
	BOOL BeginAcceptIncomingCall();
	BOOL CompleteAcceptIncomingCall();
	PString incomingConnectionToken;
	
	BOOL enableVideo;
};

#endif // __XM_END_POINT_H__