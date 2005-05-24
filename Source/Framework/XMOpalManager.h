/*
 * $Id: XMOpalManager.h,v 1.3 2005/05/24 15:21:01 hfriederich Exp $
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
	static void InitOpal();
	
	XMOpalManager();
	~XMOpalManager();
	
	void Initialise();
	
	/* overriding some callbacks */
	BOOL OnIncomingConnection(OpalConnection & connection);
	void OnEstablishedCall(OpalCall & call);
	void OnClearedCall(OpalCall & call);
	void OnEstablished(OpalConnection & connection);
	void OnConnected(OpalConnection & connection);
	void OnReleased(OpalConnection & connection);
	BOOL OnOpenMediaStream(OpalConnection & connection, OpalMediaStream & stream);
	void OnClosedMediaStream(OpalMediaStream & stream);
	
	/* Call Management functions */
	BOOL StartCall(const PString & remoteName, PString & token);
	void SetAcceptIncomingCall(BOOL acceptFlag);
	void ClearCall(PString & callToken);
	void GetCallInformation(PString & callToken,
							PString & remoteName, 
							PString & remoteNumber,
							PString & remoteAddress,
							PString & remoteApplication);

	/* Network setup functions */
	void SetBandwidthLimit(unsigned limit);
	
	/* audio functions */
	const PString & GetSoundChannelPlayDevice();
	BOOL SetSoundChannelPlayDevice(const PString & name);
	const PString & GetSoundChannelRecordDevice();
	BOOL SetSoundChannelRecordDevice(const PString & name);
	unsigned GetSoundChannelBufferDepth();
	void SetSoundChannelBufferDepth(unsigned depth);
	
	/* video functions */
	void SetVideoFunctionality(BOOL receiveVideo, BOOL sendVideo);
	
	/* dealing with h.323 functionality */
	BOOL EnableH323Listeners(BOOL flag);
	BOOL IsH323Listening();
	void SetH323Functionality(BOOL enableFastStart, BOOL enableH245Tunnel);
	BOOL SetGatekeeper(const PString & address, const PString & identifier,
					   const PString & username, const PString & phoneNumber);
	
	/* dealing with SIP functionality */
	// currently none
	
private:
	XMPCSSEndPoint *pcssEP;
	XMH323EndPoint *h323EP;
	BOOL isH323Listening;
};

#endif // __XM_OPAL_MANAGER_H__
