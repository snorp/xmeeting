/*
 * $Id: XMH323EndPoint.cpp,v 1.2 2005/06/23 12:35:56 hfriederich Exp $
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

#pragma mark Init & Deallocation
XMH323EndPoint::XMH323EndPoint(OpalManager & manager)
: H323EndPoint(manager)
{
	isListening = FALSE;
}

XMH323EndPoint::~XMH323EndPoint()
{
}

#pragma mark Endpoint Setup

BOOL XMH323EndPoint::EnableListeners(BOOL flag)
{
	if(flag == TRUE)
	{
		BOOL result = TRUE;
		
		if(isListening == FALSE)
		{
			cout << GetDefaultListeners() << endl;
			result = StartListeners(GetDefaultListeners());
			if(result == TRUE)
			{
				isListening = TRUE;
				return TRUE;
			}
			else
			{
				return FALSE;
			}
		}
		else
		{
			return TRUE;
		}
	}
	else
	{
		if(isListening == TRUE)
		{
			RemoveListener(NULL);
			isListening = FALSE;
		}
		return TRUE;
	}
}

BOOL XMH323EndPoint::IsListening()
{
	return isListening;
}

BOOL XMH323EndPoint::SetGatekeeper(const PString & address,
								   const PString & identifier,
								   const PString & username,
								   const PString & phoneNumber)
{	
	// By setting the user name , we clear all previously used aliases
	SetLocalUserName(GetManager().GetDefaultUserName());
	
	if(identifier != NULL || address != NULL)
	{
		if(username != NULL)
		{
			AddAliasName(username);
		}
		if(phoneNumber != NULL)
		{
			AddAliasName(phoneNumber);
		}
		
		// if didRegisterAtGatekeeper is yes after the
		// call to UseGatekeeper, we have a new registration
		// and notify the XMeeting framework
		didRegisterAtGatekeeper = FALSE;
		BOOL result = UseGatekeeper(address, identifier);
		if(result == TRUE && didRegisterAtGatekeeper == TRUE)
		{
			PString gatekeeperName = GetGatekeeper()->GetName();
			noteGatekeeperRegistration(gatekeeperName);
		}
		else if (result == FALSE)
		{
			noteGatekeeperRegistrationFailure();
		}
		return result;
	}
	else
	{
		BOOL doesUnregister = FALSE;
		
		if(GetGatekeeper() != NULL)
		{
			doesUnregister = TRUE;
		}
		return RemoveGatekeeper();
		
		// if we unregistered, we have to inform the obj-C world
		if(doesUnregister)
		{
			noteGatekeeperUnregistration();
		}
	}
}

void XMH323EndPoint::CheckGatekeeperRegistration()
{
	if(IsRegisteredWithGatekeeper() == FALSE)
	{
		noteGatekeeperUnregistration();
	}
}

#pragma mark Overriding Callbacks

void XMH323EndPoint::OnRegistrationConfirm()
{
	didRegisterAtGatekeeper = TRUE;
}

void XMH323EndPoint::OnRegistrationReject()
{
	cout << "OnRegistrationReject()" << endl;
}