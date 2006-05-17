/*
 * $Id: XMEndPoint.cpp,v 1.14 2006/05/17 11:48:38 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#include "XMEndPoint.h"

#include <h323/h323ep.h>
#include <sip/sipep.h>
#include <h224/h281.h>
#include <h224/h224handler.h>
#include <h224/h281handler.h>

#include "XMCallbackBridge.h"
#include "XMConnection.h"
#include "XMMediaFormats.h"
#include "XMSoundChannel.h"

XM_REGISTER_FORMATS();

#pragma mark Constructor & Destructor

XMEndPoint::XMEndPoint(OpalManager & manager)
: OpalEndPoint(manager, "xm", CanTerminateCall)
{
	isIncomingCall = FALSE;
}

XMEndPoint::~XMEndPoint()
{
}

#pragma mark -
#pragma mark SetupMethods

void XMEndPoint::SetEnableVideo(BOOL flag)
{
	enableVideo = flag;
}

#pragma mark -
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
	
	// only ever one active connection
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

#pragma mark -
#pragma mark Call Management Methods

BOOL XMEndPoint::StartCall(XMCallProtocol protocol, const PString & remoteParty, PString & token)
{
	PString partyB;
	
	switch(protocol)
	{
		case XMCallProtocol_H323:
			partyB = "h323:";
			break;
		case XMCallProtocol_SIP:
			partyB = "sip:";
			break;
		default:
			return FALSE;
			break;
	}
	
	PString partyA = "xm:*";
	
	partyB += remoteParty;
	
	XMOpalManager::GetManagerInstance()->SetCallProtocol(protocol);
	
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
	else if(PIsDescendant(&endPoint, SIPEndPoint))
	{
		callProtocol = XMCallProtocol_SIP;
	}
	
	if(callProtocol == XMCallProtocol_UnknownProtocol)
	{
		RejectIncomingCall();
		return;
	}
	
	isIncomingCall = TRUE;
	
	_XMHandleIncomingCall(callID,
						  callProtocol,
						  connection.GetRemotePartyName(),
						  connection.GetRemotePartyNumber(),
						  connection.GetRemotePartyAddress(),
						  connection.GetRemoteApplication());
}

void XMEndPoint::AcceptIncomingCall()
{
	if(isIncomingCall == FALSE)
	{
		return;
	}
	PSafePtr<XMConnection> connection = GetXMConnectionWithLock("XMeeting", PSafeReadOnly);
	if(connection != NULL)
	{
		connection->AcceptIncoming();
	}
}

void XMEndPoint::RejectIncomingCall()
{
	if(isIncomingCall == FALSE)
	{
		return;
	}
	
	PSafePtr<XMConnection> connection = GetXMConnectionWithLock("XMeeting", PSafeReadOnly);
	if(connection != NULL)
	{
		connection->ClearCall(OpalConnection::EndedByNoAccept);
	}
}

void XMEndPoint::OnReleased(OpalConnection & connection)
{
	OpalEndPoint::OnReleased(connection);
}

void XMEndPoint::OnEstablished(OpalConnection & connection)
{
	isIncomingCall = FALSE;
	OpalEndPoint::OnEstablished(connection);
}

#pragma mark -
#pragma mark InCall Methods

BOOL XMEndPoint::SendUserInputTone(PString & callID, const char tone)
{
	PSafePtr<XMConnection> connection = GetXMConnectionWithLock("XMeeting");
	if(connection == NULL)
	{
		return FALSE;
	}
	
	PSafePtr<OpalConnection> otherConnection = connection->GetCall().GetOtherPartyConnection(*connection);
	if(otherConnection == NULL)
	{
		return FALSE;
	}
	
	return otherConnection->SendUserInputTone(tone);
}

BOOL XMEndPoint::SendUserInputString(PString & callID, const PString & string)
{
	PSafePtr<XMConnection> connection = GetXMConnectionWithLock("XMeeting");
	if(connection == NULL)
	{
		return FALSE;
	}
	
	PSafePtr<OpalConnection> otherConnection = connection->GetCall().GetOtherPartyConnection(*connection);
	if(otherConnection == NULL)
	{
		return FALSE;
	}
	
	return otherConnection->SendUserInputString(string);
}

BOOL XMEndPoint::StartCameraEvent(PString & callID, XMCameraEvent cameraEvent)
{	
	OpalH281Handler *h281Handler = GetH281Handler(callID);
	
	if(h281Handler == NULL)
	{
		return FALSE;
	}
	
	H281_Frame::PanDirection panDirection = H281_Frame::NoPan;
	H281_Frame::TiltDirection tiltDirection = H281_Frame::NoTilt;
	H281_Frame::ZoomDirection zoomDirection = H281_Frame::NoZoom;
	H281_Frame::FocusDirection focusDirection = H281_Frame::NoFocus;
	
	switch(cameraEvent)
	{
		case XMCameraEvent_NoEvent:
			return FALSE;
		case XMCameraEvent_PanLeft:
			panDirection = H281_Frame::PanLeft;
			break;
		case XMCameraEvent_PanRight:
			panDirection = H281_Frame::PanRight;
			break;
		case XMCameraEvent_TiltUp:
			tiltDirection = H281_Frame::TiltUp;
			break;
		case XMCameraEvent_TiltDown:
			tiltDirection = H281_Frame::TiltDown;
			break;
		case XMCameraEvent_ZoomIn:
			zoomDirection = H281_Frame::ZoomIn;
			break;
		case XMCameraEvent_ZoomOut:
			zoomDirection = H281_Frame::ZoomOut;
			break;
		case XMCameraEvent_FocusIn:
			focusDirection = H281_Frame::FocusIn;
			break;
		case XMCameraEvent_FocusOut:
			focusDirection = H281_Frame::FocusOut;
			break;
	}
	
	h281Handler->StartAction(panDirection, tiltDirection, zoomDirection, focusDirection);
	
	return TRUE;
}

void XMEndPoint::StopCameraEvent(PString & callID)
{	
	OpalH281Handler *h281Handler = GetH281Handler(callID);
	
	if(h281Handler == NULL)
	{
		return;
	}
	
	h281Handler->StopAction();
}

OpalH281Handler * XMEndPoint::GetH281Handler(PString & callID)
{
	PSafePtr<XMConnection> connection = GetXMConnectionWithLock("XMeeting");
	if(connection == NULL)
	{
		return NULL;
	}
	
	PSafePtr<OpalConnection> otherConnection = connection->GetCall().GetOtherPartyConnection(*connection);
	if(otherConnection == NULL)
	{
		return NULL;
	}
	
	OpalH224Handler * h224Handler = otherConnection->GetH224Handler();
	
	if(h224Handler == NULL)
	{
		return NULL;
	}
	
	OpalH281Handler *h281Handler = h224Handler->GetH281Handler();
	
	if(h281Handler == NULL)
	{
		return NULL;
	}
	
	return h281Handler;
}