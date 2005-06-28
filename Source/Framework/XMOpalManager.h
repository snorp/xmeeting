/*
 * $Id: XMOpalManager.h,v 1.5 2005/06/28 20:41:06 hfriederich Exp $
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
	
	/* Getting access to the endpoints */
	XMH323EndPoint * H323EndPoint();
	XMPCSSEndPoint * PCSSEndPoint();
	
	/* overriding some callbacks */
	BOOL OnIncomingConnection(OpalConnection & connection);
	void OnEstablishedCall(OpalCall & call);
	void OnClearedCall(OpalCall & call);
	void OnEstablished(OpalConnection & connection);
	void OnConnected(OpalConnection & connection);
	void OnReleased(OpalConnection & connection);
	BOOL OnOpenMediaStream(OpalConnection & connection, OpalMediaStream & stream);
	void OnClosedMediaStream(OpalMediaStream & stream);

	/* Network setup functions */
	void SetBandwidthLimit(unsigned limit);
	
	/* video functions */
	void SetVideoFunctionality(BOOL receiveVideo, BOOL enableVideoTransmit);
	
private:
	XMPCSSEndPoint *pcssEP;
	XMH323EndPoint *h323EP;
};

#endif // __XM_OPAL_MANAGER_H__
