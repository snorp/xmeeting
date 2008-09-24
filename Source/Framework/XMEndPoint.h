/*
 * $Id: XMEndPoint.h,v 1.20 2008/09/24 06:52:41 hfriederich Exp $
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

#define XM_LOCAL_ENDPOINT_PREFIX "xm"

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
    
  bool GetEnableEchoCancellation() const { return enableEchoCancellation; }
  void SetEnableEchoCancellation(bool _enableEchoCancellation) { enableEchoCancellation = _enableEchoCancellation; }
    
  bool GetEnableVideo() const { return enableVideo; }
  void SetEnableVideo(bool _enableVideo) { enableVideo = _enableVideo; }
	
  // Overriding OpalEndPoint methods
  virtual OpalLocalConnection * CreateConnection(OpalCall & call, void * userData);
  virtual bool OnOutgoingCall(const OpalLocalConnection & connection);
  virtual bool OnIncomingCall(OpalLocalConnection & connection);
  
  // Call Management & Information
  void DoAcceptIncomingCall(const PString & callToken);
	void DoRejectIncomingCall(const PString & callToken, bool isBusy);
  
  virtual OpalMediaFormatList GetMediaFormats() const { return OpalMediaFormatList(); }
	virtual PSoundChannel * CreateSoundChannel(const XMConnection & connection, bool isSource);
	
	// InCall Methods
	bool SendUserInputTone(PString & callID, const char tone);
	bool SendUserInputString(PString & callID, const PString & string);
	bool StartCameraEvent(PString & callID, XMCameraEvent cameraEvent);	
	void StopCameraEvent(PString & callID);
	
	// helper functions
	static OpalConnection::CallEndReason GetCallRejectionReasonForCallProtocol(XMCallProtocol callProtocol);
	static XMCallProtocol GetCallProtocolForCall(OpalLocalConnection & connection);
	

private:
        
	OpalH281Handler * GetH281Handler(PString & callID);
	
	bool enableSilenceSuppression;
	bool enableEchoCancellation;
	bool enableVideo;
};

#endif // __XM_END_POINT_H__