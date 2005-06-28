/*
 * $Id: XMPCSSEndPoint.h,v 1.4 2005/06/28 20:41:06 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_PCSS_END_POINT_H__
#define __XM_PCSS_END_POINT_H__

#include <ptlib.h>
#include <opal/manager.h>
#include <opal/pcss.h>

#include "XMOpalManager.h"
#include "XMTypes.h"

class XMOpalManager;

/**
 * XMPCSSEndPoint represents the "real" endpoint in an OPAL call
 * The functionality of OpalPCSSEndPoint is extended so that this
 * instance is completely responsible for the call management
 * (at least for the outside)
 **/
class XMPCSSEndPoint : public OpalPCSSEndPoint
{
	PCLASSINFO(XMPCSSEndPoint, OpalPCSSEndPoint);
	
public:
	XMPCSSEndPoint(XMOpalManager  & manager);
	
	// Call Management & Information
	BOOL StartCall(const PString & remoteParty, PString & token);
	void SetAcceptIncomingCall(BOOL acceptFlag);
	void ClearCall(PString & callToken);
	void SetCallProtocol(XMCallProtocol protocol);
	
	// Overriding some callbacks
	virtual PString OnGetDestination(const OpalPCSSConnection & connection);
	virtual void OnShowIncoming(const OpalPCSSConnection & connection);
	virtual BOOL OnShowOutgoing(const OpalPCSSConnection & connection);
	virtual void OnEstablished(OpalConnection & connection);
	virtual void OnConnected(OpalConnection & connection);
	virtual void RefuseIncomingConnection(const PString & connectionToken);
	
private:
	PString incomingConnectionToken;
	XMCallProtocol protocol;
};

#endif // __XM_PCSS_END_POINT_H__

