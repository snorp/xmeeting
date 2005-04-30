/*
 * $Id: XMPCSSEndPoint.h,v 1.2 2005/04/28 20:26:27 hfriederich Exp $
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

class XMPCSSEndPoint : public OpalPCSSEndPoint
{
	PCLASSINFO(XMPCSSEndPoint, OpalPCSSEndPoint);
	
public:
	XMPCSSEndPoint(XMOpalManager  & manager);
	
	virtual PString OnGetDestination(const OpalPCSSConnection & connection);
	virtual void OnShowIncoming(const OpalPCSSConnection & connection);
	virtual BOOL OnShowOutgoing(const OpalPCSSConnection & connection);
	virtual void OnEstablished(OpalConnection & connection);
	virtual void OnConnected(OpalConnection & connection);
	
	virtual void AcceptIncomingConnection(const PString & connectionToken);
	virtual void RefuseIncomingConnection(PString & connectionToken);
	
	void SetAcceptIncomingCall(BOOL acceptConnection);
	void SetCallProtocol(XMCallProtocol protocol);
	
	void GetCallInformation(PString & remoteName, 
							PString & remoteNumber,
							PString & remoteAddress,
							PString & remoteApplication);
	
private:
	PString incomingConnectionToken;
	XMCallProtocol protocol;
};

#endif // __XM_PCSS_END_POINT_H__
