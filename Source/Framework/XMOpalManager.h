/*
 * $Id: XMOpalManager.h,v 1.7 2005/10/17 12:57:53 hfriederich Exp $
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
	
	/* overriding some callbacks */
	virtual void OnEstablishedCall(OpalCall & call);
	virtual void OnClearedCall(OpalCall & call);
	virtual BOOL OnOpenMediaStream(OpalConnection & connection, OpalMediaStream & stream);
	virtual void OnClosedMediaStream(const OpalMediaStream & stream);
	virtual OpalMediaPatch * CreateMediaPatch(OpalMediaStream & source);

	/* Network setup functions */
	void SetBandwidthLimit(unsigned limit);
	
	/* video functions */
	void SetVideoFunctionality(BOOL receiveVideo, BOOL enableVideoTransmit);
	
private:
	BOOL IsOutgoingMedia(OpalMediaStream & stream);
	
	unsigned callID;
	
	XMEndPoint *callEndPoint;
	XMH323EndPoint *h323EndPoint;
};

#endif // __XM_OPAL_MANAGER_H__
