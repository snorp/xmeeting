/*
 * $Id: XMEndPoint.cpp,v 1.6 2005/10/28 06:59:57 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#include "XMEndPoint.h"

#include <h323/h323ep.h>

#include "XMCallbackBridge.h"
#include "XMConnection.h"
#include "XMMediaFormats.h"
#include "XMSoundChannel.h"

XM_REGISTER_FORMATS();

#pragma mark Constructor & Destructor

XMEndPoint::XMEndPoint(OpalManager & manager,
					   const char *prefix)
: OpalEndPoint(manager, prefix, CanTerminateCall)
{
}

XMEndPoint::~XMEndPoint()
{
}

#pragma mark Overriding OpalEndPoint Methods

BOOL XMEndPoint::MakeConnection(OpalCall & call,
							const PString & remoteParty,
							void *userData)
{
	PString token = "XMeeting";
	PSafePtr<XMConnection> connection = GetXMConnectionWithLock(token);
	if(connection != NULL)
	{
		return FALSE;
	}
	
	connection = CreateConnection(call, token);
	if(connection == NULL)
	{
		return FALSE;
	}
	
	connectionsActive.SetAt(connection->GetToken(), connection);
	
	if(call.GetConnection(0) == connection)
	{
		connection->InitiateCall();
	}
	
	return TRUE;
}

OpalMediaFormatList XMEndPoint::GetMediaFormats() const
{
	OpalMediaFormatList mediaFormats;
	
	mediaFormats += OpalPCM16;
	
	if(enableVideo == TRUE)
	{
		mediaFormats += XM_MEDIA_FORMAT_VIDEO;
	}
	
	return mediaFormats;
}

PSafePtr<XMConnection> XMEndPoint::GetXMConnectionWithLock(const PString & token,
														   PSafetyMode mode)
{
	return PSafePtrCast<OpalConnection, XMConnection>(GetConnectionWithLock(token, mode));
}

XMConnection * XMEndPoint::CreateConnection(OpalCall & call, PString & token)
{
	return new XMConnection(call, *this, token);
}

PSoundChannel * XMEndPoint::CreateSoundChannel(const XMConnection & connection,
											   BOOL isSource)
{
	PString deviceName = XMSoundChannelDevice;
	
	PSoundChannel * soundChannel = new PSoundChannel();
	
	if(soundChannel->Open(deviceName,
						  isSource ? PSoundChannel::Recorder : PSoundChannel::Player,
						  1, 8000, 16))
	{
		return soundChannel;
	}
	
	delete soundChannel;
	return NULL;
}

#pragma mark CallManagement Methods

BOOL XMEndPoint::StartCall(XMCallProtocol protocol, const PString & remoteParty, PString & token)
{
	PString partyB;
	
	switch(protocol)
	{
		case XMCallProtocol_H323:
			partyB = "h323:";
			break;
		case XMCallProtocol_SIP:
			return FALSE;
			break;
		default:
			return FALSE;
			break;
	}
	
	PString partyA = "xm:*";
	
	partyB += remoteParty;
	
	return GetManager().SetUpCall(partyA, partyB, token);
}

void XMEndPoint::OnShowOutgoing(const XMConnection & connection)
{
	unsigned callID = connection.GetCall().GetToken().AsUnsigned();
	
	_XMHandleCallIsAlerting(callID);
}

void XMEndPoint::OnShowIncoming(XMConnection & connection)
{
	unsigned callID = connection.GetCall().GetToken().AsUnsigned();
	XMCallProtocol callProtocol = XMCallProtocol_UnknownProtocol;
		
	OpalEndPoint & endPoint = connection.GetCall().GetOtherPartyConnection(connection)->GetEndPoint();
	
	if(PIsDescendant(&endPoint, H323EndPoint))
	{
		callProtocol = XMCallProtocol_H323;
	}
	
	if(callProtocol == XMCallProtocol_UnknownProtocol)
	{
		cout << "No Valid call protocol" << endl;
		RejectIncomingCall();
		return;
	}
	
	incomingConnectionToken = connection.GetToken();
	
	_XMHandleIncomingCall(callID,
						  callProtocol,
						  connection.GetRemotePartyName(),
						  connection.GetRemotePartyNumber(),
						  connection.GetRemotePartyAddress(),
						  connection.GetRemoteApplication());
}

void XMEndPoint::AcceptIncomingCall()
{
	if(incomingConnectionToken.IsEmpty())
	{
		return;
	}
	PSafePtr<XMConnection> connection = GetXMConnectionWithLock(incomingConnectionToken, PSafeReadOnly);
	if(connection != NULL)
	{
		connection->AcceptIncoming();
	}
}

void XMEndPoint::RejectIncomingCall()
{
	PSafePtr<XMConnection> connection = GetXMConnectionWithLock(incomingConnectionToken, PSafeReadOnly);
	if(connection != NULL)
	{
		connection->ClearCall(OpalConnection::EndedByRefusal);
	}
}

void XMEndPoint::ClearCall(const PString & token)
{
	PSafePtr<OpalCall> call = GetManager().FindCallWithLock(token, PSafeReadOnly);
	if(call != NULL)
	{
		call->Clear();
	}
	else
	{
		cout << "Clearing the Call failed (Call not found)" << endl;
	}
}

void XMEndPoint::SetEnableVideo(BOOL flag)
{
	enableVideo = flag;
}