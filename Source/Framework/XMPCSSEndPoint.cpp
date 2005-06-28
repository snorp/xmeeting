/*
 * $Id: XMPCSSEndPoint.cpp,v 1.4 2005/06/28 20:41:06 hfriederich Exp $
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
	
	cout << connection.GetRemotePartyName() << "*r*" << connection.GetRemoteApplication() << endl;
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