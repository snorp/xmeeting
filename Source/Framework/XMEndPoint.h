/*
 * $Id: XMEndPoint.h,v 1.8 2006/04/17 17:51:22 hfriederich Exp $
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
	
	// Setup Methods
	void SetEnableVideo(BOOL enableVideo);
	
	// Overriding OpalEndPoint methods
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
	
	// InCall Methods
	BOOL SendUserInputTone(PString & callID, const char tone);
	BOOL SendUserInputString(PString & callID, const PString & string);
	BOOL StartCameraEvent(PString & callID, XMCameraEvent cameraEvent);	
	void StopCameraEvent(PString & callID);

private:
		
	OpalH281Handler * GetH281Handler(PString & callID);
	
	BOOL isIncomingCall;
	BOOL enableVideo;
};

#endif // __XM_END_POINT_H__