/*
 * $Id: XMEndPoint.h,v 1.16 2007/03/28 07:25:18 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_END_POINT_H__
#define __XM_END_POINT_H__

#include <ptlib.h>
#include <opal/endpoint.h>

#include "XMTypes.h"
#include "XMBridge.h"

class XMOpalManager;
class XMConnection;
class OpalH281Handler;

class XMEndPoint : public OpalEndPoint
{
	PCLASSINFO(XMEndPoint, OpalEndPoint);

public:
	XMEndPoint(XMOpalManager & manager);
	~XMEndPoint();
	
	// Setup Methods
	BOOL GetEnableSilenceSuppression() const { return enableSilenceSuppression; }
    void SetEnableSilenceSuppression(BOOL _enableSilenceSuppression) { enableSilenceSuppression = _enableSilenceSuppression; }
    
	BOOL GetEnableEchoCancellation() { return enableEchoCancellation; }
    void SetEnableEchoCancellation(BOOL _enableEchoCancellation) { enableEchoCancellation = _enableEchoCancellation; }
    
    BOOL GetEnableVideo() const { return enableVideo; }
	void SetEnableVideo(BOOL _enableVideo) { enableVideo = _enableVideo; }
	
	// Overriding OpalEndPoint methods
    virtual OpalMediaFormatList GetMediaFormats() const { return OpalMediaFormatList(); }
    
	virtual BOOL MakeConnection(OpalCall & call,
								const PString & party,
								void *userData = NULL,
								unsigned int options = 0,
                                OpalConnection::StringOptions * stringOptions = NULL);
    virtual BOOL OnIncomingConnection(OpalConnection & connection,
                                      unsigned options,
                                      OpalConnection::StringOptions * stringOptions);
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