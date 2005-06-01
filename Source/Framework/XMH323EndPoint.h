/*
 * $Id: XMH323EndPoint.h,v 1.1 2005/06/01 21:20:21 hfriederich Exp $
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
	
	BOOL UseGatekeeper(const PString & address = PString::Empty(),
					   const PString & identifier = PString::Empty(),
					   const PString & localAddress = PString::Empty());
	virtual void OnRegistrationConfirm();
	virtual void OnRegistrationReject();
protected:
	BOOL didRegisterAtGatekeeper;
};

#endif // __XM_H323_END_POINT_H__