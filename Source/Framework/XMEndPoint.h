/*
 * $Id: XMEndPoint.h,v 1.13 2007/02/08 08:43:34 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_END_POINT_H__
#define __XM_END_POINT_H__

#include <ptlib.h>
#include <opal/endpoint.h>

#include "XMOpalManager.h"
#include "XMTypes.h"
#include "XMBridge.h"

class XMConnection;
class OpalH281Handler;

class XMEndPoint : public OpalEndPoint
{
	PCLASSINFO(XMEndPoint, OpalEndPoint);

public:
	XMEndPoint(OpalManager & manager);
	~XMEndPoint();
	
	// Setup Methods
	void SetAudioFunctionality(BOOL enableSilenceSuppression, BOOL enableEchoCancellation);
	void SetEnableVideo(BOOL enableVideo);
	
	// Data
	BOOL EnableSilenceSuppression();
	BOOL EnableEchoCancellation();
	
	// Overriding OpalEndPoint methods
	virtual BOOL MakeConnection(OpalCall & call,
								const PString & party,
								void *userData = NULL,
								unsigned int options = 0);
    virtual BOOL OnIncomingConnection(OpalConnection & connection,
                                      unsigned options,
                                      OpalConnection::StringOptions * stringOptions);
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
	virtual void SetSendUserInputMode(OpalConnection::SendUserInputModes mode);
	BOOL SendUserInputTone(PString & callID, const char tone);
	BOOL SendUserInputString(PString & callID, const PString & string);
	BOOL StartCameraEvent(PString & callID, XMCameraEvent cameraEvent);	
	void StopCameraEvent(PString & callID);
	
	// helper functions
	static OpalConnection::CallEndReason GetCallRejectionReasonForCallProtocol(XMCallProtocol callProtocol);
	static XMCallProtocol GetCallProtocolForCall(XMConnection & connection);
	

private:
		
	OpalH281Handler * GetH281Handler(PString & callID);
	
	BOOL isIncomingCall;
	
	BOOL enableSilenceSuppression;
	BOOL enableEchoCancellation;
	
	BOOL enableVideo;
};

#endif // __XM_END_POINT_H__