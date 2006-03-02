/*
 * $Id: XMSIPEndPoint.cpp,v 1.1 2006/03/02 22:35:54 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#include "XMSIPEndPoint.h"

#include "XMOpalManager.h"

XMSIPEndPoint::XMSIPEndPoint(OpalManager & manager)
: SIPEndPoint(manager)
{
	isListening = FALSE;
	
	connectionToken = "";
	
	SetInitialBandwidth(UINT_MAX);
}

XMSIPEndPoint::~XMSIPEndPoint()
{
}

BOOL XMSIPEndPoint::EnableListeners(BOOL enable)
{
	BOOL result = TRUE;
	
	if(enable == TRUE && isListening == FALSE)
	{
		result = StartListeners(GetDefaultListeners());
		if(result == TRUE)
		{
			isListening = TRUE;
		}
	}
	else
	{
		if(isListening == TRUE)
		{
			RemoveListener(NULL);
			isListening = FALSE;
		}
	}
	
	return result;
}

BOOL XMSIPEndPoint::IsListening()
{
	return isListening;
}

void XMSIPEndPoint::OnEstablished(OpalConnection & connection)
{
	XMOpalManager *manager = (XMOpalManager *)(&GetManager());
	
	connectionToken = connection.GetToken();
	
	manager->SetCallInformation(connectionToken,
								connection.GetRemotePartyName(),
								connection.GetRemotePartyNumber(),
								connection.GetRemotePartyAddress(),
								connection.GetRemoteApplication());
	
	SIPEndPoint::OnEstablished(connection);
}

void XMSIPEndPoint::OnReleased(OpalConnection & connection)
{
	XMOpalManager *manager = (XMOpalManager *)(&GetManager());
	PString empty = "";
	
	manager->SetCallInformation(connectionToken,
								empty,
								empty,
								empty,
								empty);
	
	connectionToken = "";
	
	SIPEndPoint::OnReleased(connection);
}
		