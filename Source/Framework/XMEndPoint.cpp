/*
 * $Id: XMEndPoint.cpp,v 1.28 2007/03/21 13:18:17 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#include "XMEndPoint.h"

#include <h323/h323ep.h>
#include <sip/sipep.h>
#include <h224/h224mediafmt.h>
#include <h224/h281.h>
#include <h224/h224handler.h>
#include <h224/h281handler.h>

#include "XMOpalManager.h"
#include "XMCallbackBridge.h"
#include "XMH323EndPoint.h"
#include "XMSIPEndPoint.h"
#include "XMConnection.h"
#include "XMMediaFormats.h"
#include "XMSoundChannel.h"

XM_REGISTER_FORMATS();

#pragma mark Constructor & Destructor

XMEndPoint::XMEndPoint(XMOpalManager & manager)
: OpalEndPoint(manager, "xm", CanTerminateCall)
{
	isIncomingCall = FALSE;
	enableSilenceSuppression = FALSE;
	enableEchoCancellation = FALSE;
	enableVideo = FALSE;
}

XMEndPoint::~XMEndPoint()
{
}

#pragma mark -
#pragma mark Overriding OpalEndPoint Methods

BOOL XMEndPoint::MakeConnection(OpalCall & call,
                                const PString & remoteParty,
                                void *userData,
                                unsigned int options,
                                OpalConnection::StringOptions * stringOptions)
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
	
	return TRUE;
}

BOOL XMEndPoint::OnIncomingConnection(OpalConnection & connection,
                                      unsigned options,
                                      OpalConnection::StringOptions * stringOptions)
{
    return manager.OnIncomingConnection(connection, options, stringOptions);
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
	PString deviceName;
	
	if(isSource)
	{
		deviceName = XMInputSoundChannelDevice;
	}
	else
	{
		deviceName = XMSoundChannelDevice;
	}
	
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
	
	XMOpalManager::GetManager()->SetCallProtocol(protocol);
	
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
	XMCallProtocol callProtocol = GetCallProtocolForCall(connection);
	
	if(callProtocol == XMCallProtocol_UnknownProtocol)
	{
		RejectIncomingCall();
		return;
	}
	
	isIncomingCall = TRUE;
	
	// determine the IP address this connection runs on
	PIPSocket::Address address(0);
	connection.GetCall().GetOtherPartyConnection(connection)->GetTransport().GetLocalAddress().GetIpAddress(address);
	PString localAddress = address.AsString();
	if(!address.IsValid())
	{
		localAddress = "";
	}
	
	_XMHandleIncomingCall(callID,
						  callProtocol,
						  connection.GetRemotePartyName(),
						  connection.GetRemotePartyNumber(),
						  connection.GetRemotePartyAddress(),
						  connection.GetRemoteApplication(),
						  localAddress);
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
		XMCallProtocol callProtocol = GetCallProtocolForCall(*connection);
		OpalConnection::CallEndReason callEndReason = GetCallRejectionReasonForCallProtocol(callProtocol);
		connection->ClearCall(callEndReason);
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

void XMEndPoint::SetSendUserInputMode(OpalConnection::SendUserInputModes mode)
{
	PSafePtr<XMConnection> connection = GetXMConnectionWithLock("XMeeting");
	if(connection == NULL)
	{
		return;
	}
	
	PSafePtr<OpalConnection> otherConnection = connection->GetCall().GetOtherPartyConnection(*connection);
	if(otherConnection != NULL)
	{
		otherConnection->SetSendUserInputMode(mode);
	}
}

BOOL XMEndPoint::SendUserInputTone(PString & callID, const char tone)
{	
	OpalConnection *otherConnection;
	// Send the user input tone while the connection isn't locked
	// to prevent deadlock/timeout problems when using the SIP INFO method
	{
		PSafePtr<XMConnection> connection = GetXMConnectionWithLock("XMeeting");
		if(connection == NULL)
		{
			return FALSE;
		}
		
		PSafePtr<OpalConnection> theConnection = connection->GetCall().GetOtherPartyConnection(*connection);
		if(theConnection == NULL)
		{
			return FALSE;
		}
		otherConnection = theConnection;
	}
	
	return otherConnection->SendUserInputTone(tone, 240);
}

BOOL XMEndPoint::SendUserInputString(PString & callID, const PString & string)
{
	OpalConnection *otherConnection;
	// Send the user input string while the connection isn't locked
	// to prevent deadlock/timeout problems when using the SIP INFO method
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
	
	return connection->GetH281Handler();
}

#pragma mark -
#pragma mark Static Helper Functions

OpalConnection::CallEndReason XMEndPoint::GetCallRejectionReasonForCallProtocol(XMCallProtocol callProtocol)
{
	switch(callProtocol)
	{
		case XMCallProtocol_SIP:
			return OpalConnection::EndedByLocalBusy;
		default:
			return OpalConnection::EndedByNoAccept;
	}
}

XMCallProtocol XMEndPoint::GetCallProtocolForCall(XMConnection & connection)
{
	XMCallProtocol theCallProtocol = XMCallProtocol_UnknownProtocol;
	
	OpalEndPoint & endPoint = connection.GetCall().GetOtherPartyConnection(connection)->GetEndPoint();
	
	if(PIsDescendant(&endPoint, H323EndPoint))
	{
		theCallProtocol = XMCallProtocol_H323;
	}
	else if(PIsDescendant(&endPoint, SIPEndPoint))
	{
		theCallProtocol = XMCallProtocol_SIP;
	}
	
	return theCallProtocol;
}