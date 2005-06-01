/*
 * $Id: XMH323EndPoint.cpp,v 1.1 2005/06/01 21:20:21 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#include <ptclib/random.h>
#include <opal/call.h>
#include <h323/h323pdu.h>
#include <h323/gkclient.h>
#include <ptclib/url.h>
#include <ptclib/pils.h>

#include "XMCallbackBridge.h"

#include "XMH323EndPoint.h"

XMH323EndPoint::XMH323EndPoint(OpalManager & manager)
: H323EndPoint(manager)
{
}

XMH323EndPoint::~XMH323EndPoint()
{
}

BOOL XMH323EndPoint::UseGatekeeper(const PString & address,
				   const PString & identifier,
				   const PString & localAddress)
{
	didRegisterAtGatekeeper = FALSE;
	BOOL result = H323EndPoint::UseGatekeeper(address,
											  identifier,
											  localAddress);
	if(didRegisterAtGatekeeper == TRUE)
	{
		PString gatekeeperName = this->GetGatekeeper()->GetName();
		noteRegisteredAtGatekeeper(gatekeeperName);
	}
	return result;
}

void XMH323EndPoint::OnRegistrationConfirm()
{
	didRegisterAtGatekeeper = TRUE;
}

void XMH323EndPoint::OnRegistrationReject()
{
	cout << "OnRegistrationReject()" << endl;
}