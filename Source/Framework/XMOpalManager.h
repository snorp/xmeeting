/*
 * $Id: XMOpalManager.h,v 1.2 2005/04/28 20:26:27 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_OPAL_MANAGER_H__
#define __XM_OPAL_MANAGER_H__

#include <ptlib.h>
#include <opal/manager.h>
#include <h323/h323ep.h>

#include "XMTypes.h"
#include "XMPCSSEndPoint.h"
#include "XMH323EndPoint.h"

class XMPCSSEndPoint;

class XMOpalManager : public OpalManager
{
	PCLASSINFO(XMOpalManager, OpalManager);
	
public:
	XMOpalManager();
	~XMOpalManager();
	
	void Initialise();
	
	XMPCSSEndPoint *CurrentPCSSEndPoint();
	H323EndPoint *CurrentH323EndPoint();
	
	BOOL StartH323Listeners(unsigned listenerPort);
	void StopH323Listeners();
	BOOL IsH323Listening();
	
	virtual BOOL TranslateIPAddress(PIPSocket::Address & localAddress,
									const PIPSocket::Address & remoteAddress);
	BOOL TranslateAddress(PString & address);
	
	void SetVideoFunctionality(BOOL receiveVideo, BOOL sendVideo);
	
	/* General call  functions */
	BOOL StartCall(const PString & remoteName, PString & token);
	void SetAcceptIncomingCall(BOOL acceptFlag);
	void ClearCall(PString & callToken);
	
	void GetCallInformation(PString & callToken,
							PString & remoteName, 
							PString & remoteNumber,
							PString & remoteAddress,
							PString & remoteApplication);
	
	/* overriding some callbacks */
	BOOL OnIncomingConnection(OpalConnection & connection);
	void OnEstablishedCall(OpalCall & call);
	void OnClearedCall(OpalCall & call);
	void OnEstablished(OpalConnection & connection);
	void OnConnected(OpalConnection & connection);
	void OnReleased(OpalConnection & connection);
	BOOL OnOpenMediaStream(OpalConnection & connection, OpalMediaStream & stream);
	void OnClosedMediaStream(OpalMediaStream & stream);
	
	/* dealing with h.323 functionality */
	void SetH323Functionality(BOOL enableFastStart, BOOL enableH245Tunnel);
	BOOL SetGatekeeper(const PString & address, const PString & identifier,
					   const PString & username, const PString & phoneNumber);
	
private:
	
	XMPCSSEndPoint *pcssEP;
	XMH323EndPoint *h323EP;
};

#endif // __XM_OPAL_MANAGER_H__
