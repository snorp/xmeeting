/*
 * $Id: XMEndPoint.cpp,v 1.34 2008/09/22 22:56:47 hfriederich Exp $
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
: OpalLocalEndPoint(manager, XM_LOCAL_ENDPOINT_PREFIX),
  enableSilenceSuppression(false),
  enableEchoCancellation(false),
  enableVideo(false)
{
}

XMEndPoint::~XMEndPoint()
{
}

#pragma mark -
#pragma mark Overriding OpalEndPoint Methods

OpalLocalConnection * XMEndPoint::CreateConnection(OpalCall & call, void *userData)
{
	return new XMConnection(call, *this);
}

bool XMEndPoint::OnOutgoingCall(const OpalLocalConnection & connection)
{
  _XMHandleCallIsAlerting(connection.GetCall().GetToken());
  return OpalLocalEndPoint::OnOutgoingCall(connection);
}

bool XMEndPoint::OnIncomingCall(OpalLocalConnection & connection)
{
  const PString & callToken = connection.GetCall().GetToken();
  
  // sanity check, should not happen
  XMCallProtocol callProtocol = GetCallProtocolForCall(connection);
  if (callProtocol == XMCallProtocol_UnknownProtocol) {
    connection.Release(OpalConnection::EndedByNoAccept);
    return false;
  }
    
  // determine the IP address this connection runs on
  PIPSocket::Address address(0);
  connection.GetCall().GetOtherPartyConnection(connection)->GetTransport().GetLocalAddress().GetIpAddress(address);
  PString localAddress = "";
  if (address.IsValid()) {
    localAddress = address.AsString();
  }
    
  _XMHandleIncomingCall(callToken,
                        callProtocol,
                        connection.GetRemotePartyName(),
                        connection.GetRemotePartyNumber(),
                        connection.GetRemotePartyAddress(),
                        XMOpalManager::GetRemoteApplicationString(connection.GetRemoteProductInfo()),
                        localAddress);
  
  return true;
}

PSoundChannel * XMEndPoint::CreateSoundChannel(const XMConnection & connection,
                                               bool isSource)
{
  PString deviceName = isSource ? XMInputSoundChannelDevice : XMSoundChannelDevice;
  PSoundChannel * soundChannel = new PSoundChannel();
	
  if (soundChannel->Open(deviceName, isSource ? PSoundChannel::Recorder : PSoundChannel::Player, 1, 8000, 16)) {
    return soundChannel;
  }
	
  delete soundChannel;
  return NULL;
}

#pragma mark -
#pragma mark Call Management Methods

void XMEndPoint::DoAcceptIncomingCall(const PString & callToken)
{
  PSafePtr<OpalLocalConnection> connection = GetLocalConnectionWithLock(callToken, PSafeReadOnly);
  if (connection != NULL) {
    if (connection->GetCall().GetConnection(0) != connection) { // ensure it really is an incoming call
      connection->AcceptIncoming();
    }
  } else {
    PTRACE(1, "XMEndPoint\tCould not find active connection");
  }
}

void XMEndPoint::DoRejectIncomingCall(const PString & callToken, bool isBusy)
{
	PSafePtr<OpalLocalConnection> connection = GetLocalConnectionWithLock(callToken, PSafeReadOnly);
	if (connection != NULL) {
    if (connection->GetCall().GetConnection(0) != connection) { // ensure it really is an incoming call
		  XMCallProtocol callProtocol = GetCallProtocolForCall(*connection);
      OpalConnection::CallEndReason callEndReason = OpalConnection::EndedByNoAccept;
      if (!isBusy) {
        callEndReason = GetCallRejectionReasonForCallProtocol(callProtocol);
      }
		  connection->Release(callEndReason);
    }
	} else {
    PTRACE(1, "XMEndPoint\tCould not find active connection");
  }
}

#pragma mark -
#pragma mark InCall Methods

void XMEndPoint::SetSendUserInputMode(OpalConnection::SendUserInputModes mode)
{
	/*PSafePtr<XMConnection> connection = GetXMConnectionWithLock("XMeeting");
	if (connection == NULL)
	{
		return;
	}
	
	PSafePtr<OpalConnection> otherConnection = connection->GetCall().GetOtherPartyConnection(*connection);
	if (otherConnection != NULL)
	{
		otherConnection->SetSendUserInputMode(mode);
	}*/
}

bool XMEndPoint::SendUserInputTone(PString & callID, const char tone)
{	
	OpalConnection *otherConnection;
	// Send the user input tone while the connection isn't locked
	// to prevent deadlock/timeout problems when using the SIP INFO method
	{
		/*PSafePtr<XMConnection> connection = GetXMConnectionWithLock("XMeeting");
		if (connection == NULL)
		{
			return false;
		}
		
		PSafePtr<OpalConnection> theConnection = connection->GetCall().GetOtherPartyConnection(*connection);
		if (theConnection == NULL)
		{
			return false;
		}*/
		//otherConnection = theConnection;
	}
	
	//return otherConnection->SendUserInputTone(tone, 240);
  return false;
}

bool XMEndPoint::SendUserInputString(PString & callID, const PString & string)
{
	OpalConnection *otherConnection;
	// Send the user input string while the connection isn't locked
	// to prevent deadlock/timeout problems when using the SIP INFO method
	{
		/*PSafePtr<XMConnection> connection = GetXMConnectionWithLock("XMeeting");
		if (connection == NULL)
		{
			return false;
		}
	
		PSafePtr<OpalConnection> otherConnection = connection->GetCall().GetOtherPartyConnection(*connection);
		if (otherConnection == NULL)
		{
			return false;
		}*/
	}
	
	return otherConnection->SendUserInputString(string);
}

bool XMEndPoint::StartCameraEvent(PString & callID, XMCameraEvent cameraEvent)
{	
	OpalH281Handler *h281Handler = GetH281Handler(callID);
	
	if (h281Handler == NULL)
	{
		return false;
	}
	
	H281_Frame::PanDirection panDirection = H281_Frame::NoPan;
	H281_Frame::TiltDirection tiltDirection = H281_Frame::NoTilt;
	H281_Frame::ZoomDirection zoomDirection = H281_Frame::NoZoom;
	H281_Frame::FocusDirection focusDirection = H281_Frame::NoFocus;
	
	switch(cameraEvent)
	{
		case XMCameraEvent_NoEvent:
			return false;
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
	
	return true;
}

void XMEndPoint::StopCameraEvent(PString & callID)
{	
	OpalH281Handler *h281Handler = GetH281Handler(callID);
	
	if (h281Handler == NULL)
	{
		return;
	}
	
	h281Handler->StopAction();
}

OpalH281Handler * XMEndPoint::GetH281Handler(PString & callID)
{
	/*PSafePtr<XMConnection> connection = GetXMConnectionWithLock("XMeeting");
	if (connection == NULL)
	{
		return NULL;
	}
	
	return connection->GetH281Handler();*/
  return NULL;
}

#pragma mark -
#pragma mark Static Helper Functions

OpalConnection::CallEndReason XMEndPoint::GetCallRejectionReasonForCallProtocol(XMCallProtocol callProtocol)
{
  // Return a different reject reason in case of SIP, to generate the correct response message
	switch (callProtocol) {
		case XMCallProtocol_SIP:
			return OpalConnection::EndedByLocalBusy;
		default:
			return OpalConnection::EndedByAnswerDenied;
	}
}

XMCallProtocol XMEndPoint::GetCallProtocolForCall(OpalLocalConnection & connection)
{
	XMCallProtocol callProtocol = XMCallProtocol_UnknownProtocol;
	
	OpalEndPoint & endPoint = connection.GetCall().GetOtherPartyConnection(connection)->GetEndPoint();
	
	if (PIsDescendant(&endPoint, H323EndPoint)) {
		callProtocol = XMCallProtocol_H323;
	} else if (PIsDescendant(&endPoint, SIPEndPoint)) {
		callProtocol = XMCallProtocol_SIP;
	}
	
	return callProtocol;
}