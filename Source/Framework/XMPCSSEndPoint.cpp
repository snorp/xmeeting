/*
 * $Id: XMPCSSEndPoint.cpp,v 1.3 2005/06/23 12:35:56 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#include "XMPCSSEndPoint.h"
#include "XMCallbackBridge.h"

#pragma mark Init & Deallocation

XMPCSSEndPoint::XMPCSSEndPoint(XMOpalManager & mgr)
: OpalPCSSEndPoint(mgr)
{
}

#pragma mark Call Management & Information

BOOL XMPCSSEndPoint::StartCall(const PString & remoteParty, PString & token)
{
	PString partyA = "pc:*";
	
	return GetManager().SetUpCall(partyA, remoteParty, token);
}

void XMPCSSEndPoint::SetAcceptIncomingCall(BOOL acceptConnection)
{
	if(acceptConnection)
	{
		AcceptIncomingConnection(incomingConnectionToken);
	}
	else
	{
		RefuseIncomingConnection(incomingConnectionToken);
	}
}

void XMPCSSEndPoint::ClearCall(PString & callToken)
{
	PSafePtr<OpalCall> call = GetManager().FindCallWithLock(callToken);
	if(call != NULL)
	{
		call->Clear();
	}
	else
	{
		cout << "Didn't find call, clearing the call failed!" << endl;
	}
}

void XMPCSSEndPoint::SetCallProtocol(XMCallProtocol theProtocol)
{
	protocol = theProtocol;
}

void XMPCSSEndPoint::GetCallInformation(PString & callToken,
										PString & remoteName, 
										PString & remoteNumber,
										PString & remoteAddress,
										PString & remoteApplication)
{
	PSafePtr<OpalPCSSConnection> connection = GetPCSSConnectionWithLock(incomingConnectionToken, PSafeReadOnly);
	
	if(connection != NULL)
	{
		remoteName = connection->GetRemotePartyName();
		remoteNumber = connection->GetRemotePartyNumber();
		remoteAddress = connection->GetRemotePartyAddress();
		remoteApplication = connection->GetRemoteApplication();
		
	}
}

#pragma mark Overriding Callbacks

PString XMPCSSEndPoint::OnGetDestination(const OpalPCSSConnection & connection)
{
	cout << "XMPCSSEndPoint::OnGetDestination" << endl;
	return "destination";
}

void XMPCSSEndPoint::OnShowIncoming(const OpalPCSSConnection & connection)
{	
	incomingConnectionToken = connection.GetToken();
	
	// obtaining the call ID
	unsigned callID = connection.GetCall().GetToken().AsUnsigned();
		
	// using the callback to notify the Cocoa/Objective-C world
	noteIncomingCall(callID, 
					 protocol, 
					 connection.GetRemotePartyName(), 
					 connection.GetRemotePartyNumber(), 
					 connection.GetRemotePartyAddress(),
					 connection.GetRemoteApplication());
}

BOOL XMPCSSEndPoint::OnShowOutgoing(const OpalPCSSConnection & connection)
{
	cout << "XMPCSSEndPOint::OnShowOutgoing" << endl;
	return TRUE;
}

void XMPCSSEndPoint::OnEstablished(OpalConnection & connection)
{
	cout << "XMPCSSEndPoint::OnEstablished" << endl;
	OpalPCSSEndPoint::OnEstablished(connection);
}

void XMPCSSEndPoint::OnConnected(OpalConnection & connection)
{
	cout << "XMPCSSEndPoint::OnConnected" << endl;
	OpalPCSSEndPoint::OnConnected(connection);
}

void XMPCSSEndPoint::RefuseIncomingConnection(const PString & token)
{
	PSafePtr<OpalPCSSConnection> connection = GetPCSSConnectionWithLock(token, PSafeReadOnly);
	
	if(connection != NULL)
	{
		connection->ClearCall(OpalConnection::EndedByRefusal);
	}
}