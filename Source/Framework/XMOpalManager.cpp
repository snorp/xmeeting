/*
 * $Id: XMOpalManager.cpp,v 1.2 2005/04/28 20:26:27 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#include "XMTypes.h"
#include "XMOpalManager.h"
#include "XMCallbackBridge.h"
#include "XMVideoDevices.h"

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
	h323EP = new XMH323EndPoint(*this);
	AddRouteEntry("pc:.*   = h323:<da>");
	AddRouteEntry("h323:.* = pc:<da>");
	
	/*
	PString codecsToRemove = "G.723\nG.728\nG.729\nH.261";
	SetMediaFormatMask(codecsToRemove.Lines());
	
	PString codecOrder = "G.711-uLaw\nG.711-ALaw\nH.261";
	SetMediaFormatOrder(codecOrder.Lines());
	 */
}

XMPCSSEndPoint *XMOpalManager::CurrentPCSSEndPoint()
{
	return pcssEP;
}

H323EndPoint *XMOpalManager::CurrentH323EndPoint()
{
	return h323EP;
}

BOOL XMOpalManager::StartH323Listeners(unsigned listenerPort)
{
	BOOL result = h323EP->StartListeners(psprintf("tcp$*:%u", listenerPort));
	//cout << "listening on interface: " << h323EP->GetInterfaceAddresses() << endl;
	return result;
}

void XMOpalManager::StopH323Listeners()
{
	h323EP->RemoveListener(NULL);
}

BOOL XMOpalManager::IsH323Listening()
{
	PStringArray array = h323EP->GetDefaultListeners();
	if(array.GetSize() == 0)
	{
		return FALSE;
	}
	else
	{
		return TRUE;
	}
}

BOOL XMOpalManager::TranslateIPAddress(PIPSocket::Address & localAddress,
									   const PIPSocket::Address & remoteAddress)
{
	return OpalManager::TranslateIPAddress(localAddress, remoteAddress);
}

BOOL XMOpalManager::TranslateAddress(PString & address)
{
	
	return FALSE;
}

void XMOpalManager::SetVideoFunctionality(BOOL receiveVideo, BOOL transmitVideo)
{	
	if(receiveVideo)
	{
		autoStartReceiveVideo = TRUE;
		PVideoDevice::OpenArgs video = GetVideoOutputDevice();
		video.deviceName = "XMVideo";
		SetVideoOutputDevice(video);
	}
	else
	{
		autoStartReceiveVideo = FALSE;
	}
	
	if(transmitVideo)
	{
		autoStartTransmitVideo = TRUE;
		PVideoDevice::OpenArgs video = GetVideoInputDevice();
		video.deviceName = "XMVideo";
		SetVideoInputDevice(video);
	}
	else
	{
		autoStartTransmitVideo = FALSE;
	}
}

BOOL XMOpalManager::StartCall(const PString & remoteParty, PString & token)
{
	PString partyA = "pc:*";
	
	return SetUpCall(partyA, remoteParty, token);
}

void XMOpalManager::SetAcceptIncomingCall(BOOL acceptFlag)
{
	pcssEP->SetAcceptIncomingCall(acceptFlag);
}

void XMOpalManager::ClearCall(PString & callToken)
{
	PSafePtr<OpalCall> call = FindCallWithLock(callToken);
	if(call != NULL)
	{
		call->Clear();
	}
	else
	{
		cout << "Didn't find call, clearing the call failed!" << endl;
	}
}

void XMOpalManager::GetCallInformation(PString & callToken,
									   PString & remoteName, 
									   PString & remoteNumber,
									   PString & remoteAddress,
									   PString & remoteApplication)
{
	//pcssEP->GetCallInformation(remoteName, remoteNumber, remoteAddress, remoteApplication);
	PSafePtr<OpalCall> call = FindCallWithLock(callToken, PSafeReadOnly);
	
	if(call == NULL)
	{
		return;
	}
	
	PSafePtr<OpalConnection> connection = call->GetConnection(0);
	
	if(connection == NULL)
	{
		return;
	}
	
	remoteName = connection->GetRemotePartyName();
	remoteNumber = connection->GetRemotePartyNumber();
	remoteAddress = connection->GetRemotePartyAddress();
	remoteApplication = connection->GetRemoteApplication();
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
	// first, we want to find out whether we are interested in this media stream or not
	// We are only interested in the external codecs and not the internal PCM-16
	// and Linear-16-Mono formats.
	PString format = stream.GetMediaFormat();
	if(!(format == OpalPCM16 
		 || format == "RGB24" 
		 || format == "YUV420P"))
	{
		unsigned callID = connection.GetCall().GetToken().AsUnsigned();
		noteMediaStreamOpened(callID, stream.IsSource(), format);
	}
	
	return OpalManager::OnOpenMediaStream(connection, stream);
}

void XMOpalManager::OnClosedMediaStream(OpalMediaStream & stream)
{
	//noteMediaStreamClosed(0, stream.IsSource(), stream.GetMediaFormat());
	cout << "media stream closed: " << stream.GetMediaFormat() << endl;
	OpalManager::OnClosedMediaStream(stream);
}

void XMOpalManager::SetH323Functionality(BOOL enableFastStart, BOOL enableH245Tunnel)
{
	h323EP->DisableFastStart(!enableFastStart);
	h323EP->DisableH245Tunneling(!enableH245Tunnel);
}

BOOL XMOpalManager::SetGatekeeper(const PString & address, const PString & identifier,
								  const PString & username, const PString & phoneNumber)
{
	// By setting the user name of the h323 endpoint, we clear all previously
	// used aliases
	h323EP->SetLocalUserName(GetDefaultUserName());
	
	if(identifier != NULL || address != NULL)
	{
		if(username != NULL)
		{
			h323EP->AddAliasName(username);
		}
		if(phoneNumber != NULL)
		{
			h323EP->AddAliasName(phoneNumber);
		}
		if(h323EP->UseGatekeeper(address, identifier))
		{
			//H323Gatekeeper *gk = h323EP->GetGatekeeper();
			return TRUE;
		}
		else
		{
			return FALSE;
		}
	}
	else
	{
		return h323EP->RemoveGatekeeper();
	}
}

