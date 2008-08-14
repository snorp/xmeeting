/*
 * $Id: XMEndPoint.h,v 1.17 2008/08/14 19:57:05 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_END_POINT_H__
#define __XM_END_POINT_H__

#include <ptlib.h>
#include <opal/localep.h>

#include "XMTypes.h"
#include "XMBridge.h"

class XMOpalManager;
class XMConnection;
class OpalH281Handler;

class XMEndPoint : public OpalLocalEndPoint
{
	PCLASSINFO(XMEndPoint, OpalLocalEndPoint);

public:
	XMEndPoint(XMOpalManager & manager);
	~XMEndPoint();
	
	// Setup Methods
	bool GetEnableSilenceSuppression() const { return enableSilenceSuppression; }
    void SetEnableSilenceSuppression(bool _enableSilenceSuppression) { enableSilenceSuppression = _enableSilenceSuppression; }
    
	bool GetEnableEchoCancellation() { return enableEchoCancellation; }
    void SetEnableEchoCancellation(bool _enableEchoCancellation) { enableEchoCancellation = _enableEchoCancellation; }
    
    bool GetEnableVideo() const { return enableVideo; }
	void SetEnableVideo(bool _enableVideo) { enableVideo = _enableVideo; }
	
	// Overriding OpalEndPoint methods
    virtual OpalMediaFormatList GetMediaFormats() const { return OpalMediaFormatList(); }
    
	virtual bool MakeConnection(OpalCall & call,
								const PString & party,
								void *userData = NULL,
								unsigned int options = 0,
                                OpalConnection::StringOptions * stringOptions = NULL);
    virtual bool OnIncomingConnection(OpalConnection & connection,
                                      unsigned options,
                                      OpalConnection::StringOptions * stringOptions);
	virtual OpalLocalConnection * CreateConnection(OpalCall & call, void * userData);
	virtual PSoundChannel * CreateSoundChannel(const XMConnection & connection, bool isSource);
	PSafePtr<XMConnection> GetXMConnectionWithLock(const PString & token,
												   PSafetyMode mode = PSafeReadWrite);
	
	// Call Management & Information
	bool StartCall(XMCallProtocol protocol, const PString & remoteParty, PString & token);
	void OnShowOutgoing(const XMConnection & connection);
	void OnShowIncoming(XMConnection & connection);
	void AcceptIncomingCall();
	void RejectIncomingCall();
	
	virtual void OnEstablished(OpalConnection & connection);
	
	// InCall Methods
	virtual void SetSendUserInputMode(OpalConnection::SendUserInputModes mode);
	bool SendUserInputTone(PString & callID, const char tone);
	bool SendUserInputString(PString & callID, const PString & string);
	bool StartCameraEvent(PString & callID, XMCameraEvent cameraEvent);	
	void StopCameraEvent(PString & callID);
	
	// helper functions
	static OpalConnection::CallEndReason GetCallRejectionReasonForCallProtocol(XMCallProtocol callProtocol);
	static XMCallProtocol GetCallProtocolForCall(XMConnection & connection);
	

private:
        
	OpalH281Handler * GetH281Handler(PString & callID);
	
	bool isIncomingCall;
	
	bool enableSilenceSuppression;
	bool enableEchoCancellation;
	bool enableVideo;
};

#endif // __XM_END_POINT_H__