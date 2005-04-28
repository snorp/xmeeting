/*
 * $Id: XMPCSSEndPoint.cpp,v 1.2 2005/04/28 20:26:27 hfriederich Exp $
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
	//cout << "XMPCSSEndPoint::OnGetDestination" << endl;
	return "destination";
}

void XMPCSSEndPoint::OnShowIncoming(const OpalPCSSConnection & connection)
{
	//cout << "XMPCSSEndPoint::Incoming connection " << connection << endl;
	
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
	
	/*cout << connection.GetRemotePartyName() << "a" <<
		connection.GetRemotePartyNumber() << "b" <<
		connection.GetRemotePartyAddress() << "c" <<
		connection.GetRemoteApplication() << endl;*/
	OpalPCSSEndPoint::OnConnected(connection);
}

void XMPCSSEndPoint::AcceptIncomingConnection(const PString & token)
{
	PSafePtr<OpalPCSSConnection> connection = GetPCSSConnectionWithLock(token, PSafeReadOnly);
	
	if(connection != NULL)
	{
		connection->AcceptIncoming();
	}
}

void XMPCSSEndPoint::RefuseIncomingConnection(PString & token)
{
	PSafePtr<OpalPCSSConnection> connection = GetPCSSConnectionWithLock(token, PSafeReadOnly);
	
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

void XMPCSSEndPoint::GetCallInformation(PString & remoteName, 
										PString & remoteNumber,
										PString & remoteAddress,
										PString & remoteApplication)
{
	PSafePtr<OpalPCSSConnection> connection = GetPCSSConnectionWithLock(incomingConnectionToken, PSafeReadOnly);
	
	//cout << "trying with " << incomingConnectionToken << endl;
	if(connection != NULL)
	{
		remoteName = connection->GetRemotePartyName();
		remoteNumber = connection->GetRemotePartyNumber();
		remoteAddress = connection->GetRemotePartyAddress();
		remoteApplication = connection->GetRemoteApplication();
		
		//cout << "fetching " << remoteName << " " << remoteNumber << " "
			//<< remoteAddress << " " << remoteApplication << endl;
	}
	else{
		//cout << "failed fetching infos" << endl;
	}
}