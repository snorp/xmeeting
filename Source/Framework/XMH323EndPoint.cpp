/*
 * $Id: XMH323EndPoint.cpp,v 1.3 2005/06/28 20:41:06 hfriederich Exp $
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
	
	remoteName = "";
	remoteNumber = "";
	remoteAddress = "";
	remoteApplication = "";
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

#pragma mark Getting call information

void XMH323EndPoint::GetCallInformation(PString & theRemoteName,
										PString & theRemoteNumber,
										PString & theRemoteAddress,
										PString & theRemoteApplication)
{
	theRemoteName = remoteName;
	theRemoteNumber = remoteNumber;
	theRemoteAddress = remoteAddress;
	theRemoteApplication = remoteApplication;
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

void XMH323EndPoint::OnEstablished(OpalConnection & connection)
{
	cout << "XMH323EndPoint::OnEstablished()" << endl;
	remoteName = connection.GetRemotePartyName();
	remoteNumber = connection.GetRemotePartyNumber();
	remoteAddress = connection.GetRemotePartyAddress();
	remoteApplication = connection.GetRemoteApplication();
	
	H323EndPoint::OnEstablished(connection);
}

void XMH323EndPoint::OnReleased(OpalConnection & connection)
{
	cout << "XMH323EndPoint::OnReleased()" << endl;
	
	remoteName = "";
	remoteNumber = "";
	remoteAddress = "";
	remoteApplication = "";
	
	H323EndPoint::OnReleased(connection);
	
	unsigned callID = connection.GetCall().GetToken().AsUnsigned();
	XMCallEndReason endReason = (XMCallEndReason)connection.GetCall().GetCallEndReason();
	noteCallCleared(callID, endReason);
}