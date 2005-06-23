/*
 * $Id: XMH323EndPoint.h,v 1.2 2005/06/23 12:35:56 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_H323_END_POINT_H__
#define __XM_H323_END_POINT_H__

#include <ptlib.h>
#include <h323/h323ep.h>

class XMGatekeeper;

class XMH323EndPoint : public H323EndPoint
{
	PCLASSINFO(XMH323EndPoint, H323EndPoint);

public:
	XMH323EndPoint(OpalManager & manager);
	virtual ~XMH323EndPoint();
	
	// Setup methods
	BOOL EnableListeners(BOOL flag);
	BOOL IsListening();
	BOOL SetGatekeeper(const PString & address, const PString & identifier,
					   const PString & username, const PString & phoneNumber);
	void CheckGatekeeperRegistration();
	
	// overriding some callbacks
	virtual void OnRegistrationConfirm();
	virtual void OnRegistrationReject();
private:
	BOOL isListening;
	BOOL didRegisterAtGatekeeper;
};

#endif // __XM_H323_END_POINT_H__