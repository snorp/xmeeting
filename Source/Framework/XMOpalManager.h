/*
 * $Id: XMOpalManager.h,v 1.1 2005/02/11 12:58:44 hfriederich Exp $
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

#include "XMPCSSEndPoint.h"

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
	
	/* overriding the callbacks */
	BOOL OnIncomingConnection(OpalConnection & connection);
	void OnEstablishedCall(OpalCall & call);
	void OnClearedCall(OpalCall & call);
	void OnEstablished(OpalConnection & connection);
	void OnConnected(OpalConnection & connection);
	void OnReleased(OpalConnection & connection);
	BOOL OnOpenMediaStream(OpalConnection & connection, OpalMediaStream & stream);
	
private:
	PString currentCallToken;
	
	XMPCSSEndPoint *pcssEP;
	H323EndPoint *h323EP;
};

#endif // __XM_OPAL_MANAGER_H__
