/*
 * $Id: XMOpalManager.h,v 1.6 2005/10/11 09:03:10 hfriederich Exp $
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
#include "XMEndPoint.h"
#include "XMH323EndPoint.h"

class XMEndPoint;

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
	XMEndPoint * CallEndPoint();
	
	/* overriding some methods */
	virtual BOOL OnIncomingConnection(OpalConnection & connection);
	virtual void OnEstablishedCall(OpalCall & call);
	virtual void OnClearedCall(OpalCall & call);
	virtual void OnEstablished(OpalConnection & connection);
	virtual void OnConnected(OpalConnection & connection);
	virtual void OnReleased(OpalConnection & connection);
	virtual BOOL OnOpenMediaStream(OpalConnection & connection, OpalMediaStream & stream);
	virtual void OnClosedMediaStream(OpalMediaStream & stream);
	virtual OpalMediaPatch * CreateMediaPatch(OpalMediaStream & source);

	/* Network setup functions */
	void SetBandwidthLimit(unsigned limit);
	
	/* video functions */
	void SetVideoFunctionality(BOOL receiveVideo, BOOL enableVideoTransmit);
	
private:
	BOOL IsOutgoingMedia(OpalMediaStream & stream);
	
	XMEndPoint *callEndPoint;
	XMH323EndPoint *h323EndPoint;
};

#endif // __XM_OPAL_MANAGER_H__
