/*
 * $Id: XMPCSSEndPoint.cpp,v 1.1 2005/02/11 12:58:44 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#include "XMPCSSEndPoint.h"
#include "XMCallbackBridge.h"

XMPCSSEndPoint::XMPCSSEndPoint(XMOpalManager & mgr)
: OpalPCSSEndPoint(mgr)
{
}

PString XMPCSSEndPoint::OnGetDestination(const OpalPCSSConnection & connection)
{
	cout << "XMPCSSEndPoint::OnGetDestination" << endl;
	return "destination";
}

void XMPCSSEndPoint::OnShowIncoming(const OpalPCSSConnection & connection)
{
	cout << "XMPCSSEndPoint::Incoming connection " << connection << endl;
	
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
	//cout << "XMPCSSEndPOint::OnShowOutgoing" << endl;
	return TRUE;
}

void XMPCSSEndPoint::OnEstablished(OpalConnection & connection)
{
	//cout << "XMPCSSEndPoint::OnEstablished" << endl;
	OpalPCSSEndPoint::OnEstablished(connection);
}

void XMPCSSEndPoint::OnConnected(OpalConnection & connection)
{
	//cout << "XMPCSSEndPoint::OnConnected" << endl;
	OpalPCSSEndPoint::OnConnected(connection);
}

void XMPCSSEndPoint::RefuseIncomingConnection(PString & token)
{
	PSafePtr<OpalPCSSConnection> connection = GetPCSSConnectionWithLock(token);
	
	if(connection != NULL)
	{
		connection->ClearCall(OpalConnection::EndedByRefusal);
	}
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

void XMPCSSEndPoint::SetCallProtocol(XMCallProtocol theProtocol)
{
	protocol = theProtocol;
}