/*
 * $Id: XMOpalManager.cpp,v 1.1 2005/02/11 12:58:44 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#include "XMTypes.h"
#include "XMOpalManager.h"
#include "XMCallbackBridge.h"

using namespace std;

XMOpalManager::XMOpalManager()
{
	pcssEP = NULL;
	h323EP = NULL;
}

XMOpalManager::~XMOpalManager()
{
	delete pcssEP;
	delete h323EP;
}

void XMOpalManager::Initialise()
{
	pcssEP = new XMPCSSEndPoint(*this);
	h323EP = new H323EndPoint(*this);
	
	AddRouteEntry("pc:.*   = h323:<da>");
	AddRouteEntry("h323:.* = pc:<da>");
}

XMPCSSEndPoint *XMOpalManager::CurrentPCSSEndPoint()
{
	return pcssEP;
}

H323EndPoint *XMOpalManager::CurrentH323EndPoint()
{
	return h323EP;
}

BOOL XMOpalManager::OnIncomingConnection(OpalConnection & connection)
{
	//cout << "XMOpalManager::OnIncomingConnection"  << endl;
	
	XMCallProtocol protocol;
	
	PString prefix = connection.GetEndPoint().GetPrefixName();
	if(prefix == "h323")
	{
		protocol = XMCallProtocol_H323;
	}
	else
	{
		protocol = XMCallProtocol_Unknown;
	}
	
	pcssEP->SetCallProtocol(protocol);
	
	return OpalManager::OnIncomingConnection(connection);
}

void XMOpalManager::OnEstablishedCall(OpalCall & call)
{	
	unsigned callID = call.GetToken().AsUnsigned();
	noteCallEstablished(callID);
	OpalManager::OnEstablishedCall(call);
}

void XMOpalManager::OnClearedCall(OpalCall & call)
{
	unsigned callID = call.GetToken().AsUnsigned();
	noteCallCleared(callID, (XMCallEndReason)call.GetCallEndReason());
	OpalManager::OnClearedCall(call);
}

void XMOpalManager::OnEstablished(OpalConnection & connection)
{
	//cout << "XMOpalManager::OnEstablished" << endl;
	OpalManager::OnEstablished(connection);
}

void XMOpalManager::OnConnected(OpalConnection & connection)
{
	//cout << "XMOpalManager::OnConnected" << endl;
	OpalManager::OnConnected(connection);
}

void XMOpalManager::OnReleased(OpalConnection & connection)
{
	//cout << "XMOpalManager::OnReleased" << endl;
	OpalManager::OnReleased(connection);
}

BOOL XMOpalManager::OnOpenMediaStream(OpalConnection & connection, OpalMediaStream & stream)
{
	//cout << "XMOpalManager::OnOpenMediaStream:" << stream.GetMediaFormat() << endl;
	
	return OpalManager::OnOpenMediaStream(connection, stream);
}

