/*
 * $Id: XMEndPoint.cpp,v 1.1 2005/10/11 09:03:10 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#include "XMEndPoint.h"
#include "XMConnection.h"
#include "XMMediaFormats.h"
#include "XMSoundChannel.h"

XM_REGISTER_FORMATS();

#pragma mark Constructor & Destructor

XMEndPoint::XMEndPoint(OpalManager & manager,
					   const char *prefix)
: OpalEndPoint(manager, prefix, CanTerminateCall)
{
	cout << "XMEndPoint created" << endl;
}

XMEndPoint::~XMEndPoint()
{
	cout << "~XMEndPoint called" << endl;
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
	mediaFormats += XM_VIDEO_FORMAT_H261;
	
	//AddVideoMediaFormats(mediaFormats);
	
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

void XMEndPoint::SetAcceptIncomingCall(BOOL acceptCall)
{
	if(acceptCall)
	{
		cout << "Accepting the call" << endl;
	}
	else
	{
		cout << "Refusing incoming call" << endl;
	}
}

void XMEndPoint::ClearCall(const PString & token)
{
	PSafePtr<OpalCall> call = GetManager().FindCallWithLock(token);
	if(call != NULL)
	{
		call->Clear();
	}
	else
	{
		cout << "Clearing the Call failed (Call not found)" << endl;
	}
}

void XMEndPoint::SetCallProtocol(XMCallProtocol protocol)
{
	cout << "SetCallProtocol: " << protocol << endl;
}