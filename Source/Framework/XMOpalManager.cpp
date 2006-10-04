/*
 * $Id: XMOpalManager.cpp,v 1.40 2006/10/04 21:44:48 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#include "XMOpalManager.h"

#include "XMTypes.h"
#include "XMCallbackBridge.h"
#include "XMMediaFormats.h"
#include "XMSoundChannel.h"
#include "XMTransmitterMediaPatch.h"
#include "XMReceiverMediaPatch.h"
#include "XMProcess.h"
#include "XMConnection.h"

#include <ptlib.h>

#define XM_MAX_BANDWIDTH 1100000

using namespace std;

#pragma mark Init & Deallocation

static XMOpalManager * managerInstance = NULL;

void XMOpalManager::InitOpal(const PString & pTracePath)
{
	static XMProcess *theProcess = NULL;
	
	if(theProcess == NULL)
	{
		PProcess::PreInitialise(0, 0, 0);
		theProcess = new XMProcess;
		
		if(pTracePath != NULL)
		{
			PTrace::Initialise(5, pTracePath, PTrace::Timestamp|PTrace::Thread|PTrace::FileAndLine);
		}
	}
}

void XMOpalManager::CloseOpal()
{
}

XMOpalManager::XMOpalManager()
{
	managerInstance = this;
	
	callEndPoint = NULL;
	h323EndPoint = NULL;
	sipEndPoint = NULL;
	
	connectionToken = "";
	remoteName = "";
	remoteNumber = "";
	remoteAddress = "";
	remoteApplication = "";
}

XMOpalManager::~XMOpalManager()
{
	delete callEndPoint;
	delete h323EndPoint;
	delete sipEndPoint;
}

void XMOpalManager::Initialise()
{
	callEndPoint = new XMEndPoint(*this);
	h323EndPoint = new XMH323EndPoint(*this);
	sipEndPoint = new XMSIPEndPoint(*this);
	AddRouteEntry("xm:.*   = h323:<da>");
	AddRouteEntry("h323:.* = xm:<da>");
	AddRouteEntry("xm:.*   = sip:<da>");
	AddRouteEntry("sip:.*  = xm:<da>");
	
	SetAutoStartTransmitVideo(TRUE);
	SetAutoStartReceiveVideo(TRUE);
}

#pragma mark -
#pragma mark Accessing the manager

XMOpalManager * XMOpalManager::GetManagerInstance()
{
	return managerInstance;
}

#pragma mark Access to Endpoints

XMEndPoint * XMOpalManager::CallEndPoint()
{
	return callEndPoint;
}

XMH323EndPoint * XMOpalManager::H323EndPoint()
{
	return h323EndPoint;
}

XMSIPEndPoint * XMOpalManager::SIPEndPoint()
{
	return sipEndPoint;
}

#pragma mark Getting / Setting Call Information

void XMOpalManager::GetCallInformation(PString & theRemoteName,
									   PString & theRemoteNumber,
									   PString & theRemoteAddress,
									   PString & theRemoteApplication) const
{
	theRemoteName = remoteName;
	theRemoteNumber = remoteNumber;
	theRemoteAddress = remoteAddress;
	theRemoteApplication = remoteApplication;
}

void XMOpalManager::SetCallInformation(const PString & theConnectionToken,
									   const PString & theRemoteName,
									   const PString & theRemoteNumber,
									   const PString & theRemoteAddress,
									   const PString & theRemoteApplication,
									   XMCallProtocol theCallProtocol)
{
	BOOL isValid = FALSE;
	
	if(connectionToken == "")
	{
		connectionToken = theConnectionToken;
		callProtocol = theCallProtocol;
		isValid = TRUE;
	}
	else if(connectionToken == theConnectionToken)
	{
		isValid = TRUE;
	}
	
	if(isValid == TRUE)
	{
		remoteName = theRemoteName;
		remoteNumber = theRemoteNumber;
		remoteAddress = theRemoteAddress;
		remoteApplication = theRemoteApplication;
		
		if(remoteName == "" &&
		   remoteNumber == "" &&
		   remoteAddress == "" &&
		   remoteApplication == "")
		{
			connectionToken = "";
			callProtocol = XMCallProtocol_UnknownProtocol;
		}
	}
}

#pragma mark Getting Call Statistics

void XMOpalManager::GetCallStatistics(XMCallStatisticsRecord *callStatistics)
{
	switch(callProtocol)
	{
		case XMCallProtocol_H323:
			h323EndPoint->GetCallStatistics(callStatistics);
			return;
		case XMCallProtocol_SIP:
			sipEndPoint->GetCallStatistics(callStatistics);
			return;
		default:
			return;
	}
}

#pragma mark overriding some callbacks

BOOL XMOpalManager::OnIncomingConnection(OpalConnection & connection)
{
	// Make sure that one connection is accepted only once.
	// This is especially important in case there are several INVITEs arriving,
	// probably sent over different interfaces by the remote client
	return OpalManager::OnIncomingConnection(connection);
}

void XMOpalManager::OnEstablishedCall(OpalCall & call)
{
	unsigned callID = call.GetToken().AsUnsigned();
	
	// determine the direction of the call by the fact which endpoint is
	// connected with the first connection
	// Is there a better way to determine this?
	BOOL isIncomingCall = TRUE;
	OpalEndPoint & endPoint = call.GetConnection(0, PSafeReadOnly)->GetEndPoint();
	if(PIsDescendant(&endPoint, XMEndPoint))
	{
		isIncomingCall = FALSE;
	}
	
	// Determine the IP address this call is running on
	PSafePtr<OpalConnection> connection;
	if(isIncomingCall)
	{
		connection = call.GetConnection(0);
	}
	else
	{
		connection = call.GetConnection(1);
	}
	PIPSocket::Address address(0);
	connection->GetTransport().GetLocalAddress().GetIpAddress(address);
	
	if(address.IsValid())
	{
		_XMHandleCallEstablished(callID, isIncomingCall, address.AsString());
	}
	else
	{
		_XMHandleCallEstablished(callID, isIncomingCall, "");
	}
	OpalManager::OnEstablishedCall(call);
}

void XMOpalManager::OnClearedCall(OpalCall & call)
{	
	unsigned callID = call.GetToken().AsUnsigned();
	_XMHandleCallCleared(callID, (XMCallEndReason)call.GetCallEndReason());
	OpalManager::OnClearedCall(call);
}

void XMOpalManager::OnReleased(OpalConnection & connection)
{
	if(!PIsDescendant(&connection, XMConnection))
	{
		PIPSocket::Address address(0);
		OpalTransport *transport = &(connection.GetTransport());
		if(transport != NULL) {
			OpalTransportAddress transportAddress = transport->GetLocalAddress();
			transportAddress.GetIpAddress(address);
		}
		
		if(address.IsValid())
		{
			unsigned callID = connection.GetCall().GetToken().AsUnsigned();
			_XMHandleCallReleased(callID, address.AsString());
		}
	}
	OpalManager::OnReleased(connection);
}

BOOL XMOpalManager::OnOpenMediaStream(OpalConnection & connection, OpalMediaStream & stream)
{	
	BOOL result = OpalManager::OnOpenMediaStream(connection, stream);
	
	if(result == TRUE)
	{
		// first, we want to find out whether we are interested in this media stream or not
		// We are only interested in the external codecs and not the internal PCM-16 format
		// and XM_MEDIA_FORMAT_VIDEO
		OpalMediaFormat mediaFormat = stream.GetMediaFormat();
		if(!(mediaFormat == OpalPCM16 ||
			 mediaFormat == XM_MEDIA_FORMAT_VIDEO))
		{
			callID = connection.GetCall().GetToken().AsUnsigned();
			
			if(_XMIsVideoMediaFormat(mediaFormat))
			{
				if(!stream.IsSource())
				{
					XMVideoSize videoSize = _XMGetMediaFormatSize(mediaFormat);
					const char *mediaFormatName = _XMGetMediaFormatName(mediaFormat);
					
					_XMHandleVideoStreamOpened(callID, mediaFormatName, videoSize, false, 0, 0);
				}
			}
			else
			{
				_XMHandleAudioStreamOpened(callID, mediaFormat, stream.IsSource());
			}
		}
	}
	
	return result;
}

void XMOpalManager::OnClosedMediaStream(const OpalMediaStream & stream)
{
	// first, we want to find out whether we are interested in this media stream or not
	// We are only interested in the external codecs and not the internal PCM-16 format
	// and XM_MEDIA_FORMAT_VIDEO
	OpalMediaFormat mediaFormat = stream.GetMediaFormat();
	if(!(mediaFormat == OpalPCM16 ||
		 mediaFormat == XM_MEDIA_FORMAT_VIDEO))
	{
		
		if(_XMIsVideoMediaFormat(mediaFormat))
		{
			_XMHandleVideoStreamClosed(callID, stream.IsSource());
		}
		else
		{
			_XMHandleAudioStreamClosed(callID, stream.IsSource());
		}
	}
	
	OpalManager::OnClosedMediaStream(stream);
}

OpalMediaPatch * XMOpalManager::CreateMediaPatch(OpalMediaStream & source)
{
	if(IsOutgoingMedia(source))
	{
		return new XMTransmitterMediaPatch(source);
	}
	else
	{
		return new XMReceiverMediaPatch(source);
	}
}

OpalH281Handler * XMOpalManager::CreateH281ProtocolHandler(OpalH224Handler & handler) const
{
	_XMHandleFECCChannelOpened();
	return OpalManager::CreateH281ProtocolHandler(handler);
}

#pragma mark General Setup Methods

void XMOpalManager::SetUserName(const PString & username)
{
	OpalManager::SetDefaultUserName(username);
	h323EndPoint->SetDefaultDisplayName(username);
	sipEndPoint->SetDefaultDisplayName(username);
}

#pragma mark Network Setup Methods

static unsigned bandwidthLimit = XM_MAX_BANDWIDTH;
static unsigned availableBandwidth = XM_MAX_BANDWIDTH;

void XMOpalManager::SetBandwidthLimit(unsigned limit)
{
	if(limit == 0 || limit > XM_MAX_BANDWIDTH)
	{
		limit = XM_MAX_BANDWIDTH;
	}
	
	bandwidthLimit = limit;
}

unsigned XMOpalManager::GetBandwidthLimit()
{
	return bandwidthLimit;
}

unsigned XMOpalManager::GetVideoBandwidthLimit()
{
	// taking away 64kbit/s for audio
	return XMOpalManager::GetAvailableBandwidth() - 64000;
}

unsigned XMOpalManager::GetAvailableBandwidth()
{
	return availableBandwidth;
}

void XMOpalManager::SetAvailableBandwidth(unsigned bandwidth)
{
	if(availableBandwidth > bandwidth)
	{
		availableBandwidth = bandwidth;
	}
}

void XMOpalManager::ResetAvailableBandwidth()
{
	availableBandwidth = XM_MAX_BANDWIDTH;
}

void XMOpalManager::SetNATInformation(const PString & stunServer,
									  const PString & theTranslationAddress)
{
	//
	// In case STUN works as expected, use it. In case of failures,
	// SymmetricNAT, SymmetricFirewall, PartialBlockedNAT, dont' use
	// STUN but rather rely on the translationAddress feature only.
	// This has the advantage that in case of STUN problems, connections
	// may still work...
	//
	if(stun != NULL) {
		delete stun;
		stun = NULL;
	}
	
	if(stunServer.IsEmpty())
	{
		SetTranslationAddress(theTranslationAddress);
		_XMHandleSTUNInformation(XMNATType_UnknownNAT, "");
	}
	else
	{
		stun = new PSTUNClient(stunServer, GetUDPPortBase(), GetUDPPortMax(),
								GetRtpIpPortBase(), GetRtpIpPortMax());
		PSTUNClient::NatTypes natType = stun->GetNatType();
		
		switch(natType) {
		
			case PSTUNClient::UnknownNat:
			case PSTUNClient::BlockedNat:
				delete stun;
				stun = NULL;
				SetTranslationAddress(theTranslationAddress);
				_XMHandleSTUNInformation(XMNATType_Error, "");
				break;
			case PSTUNClient::OpenNat:
			case PSTUNClient::ConeNat:
			case PSTUNClient::RestrictedNat:
			case PSTUNClient::PortRestrictedNat:
				stun->GetExternalAddress(translationAddress);
				if(GetTranslationAddress().IsValid()) {
					_XMHandleSTUNInformation((XMNATType)natType, GetTranslationAddress().AsString());
				}
				else
				{
					delete stun;
					stun = NULL;
					SetTranslationAddress(theTranslationAddress);
					_XMHandleSTUNInformation(XMNATType_Error, "");
				}
				break;
			case PSTUNClient::SymmetricNat:
			case PSTUNClient::SymmetricFirewall:
			case PSTUNClient::PartialBlockedNat:
			default:
				PIPSocket::Address stunExternalAddress;
				stun->GetExternalAddress(stunExternalAddress);
				delete stun;
				stun = NULL;
				SetTranslationAddress(theTranslationAddress);
				_XMHandleSTUNInformation((XMNATType)natType, stunExternalAddress.AsString());
				break;
		}
	}
}

#pragma mark -
#pragma mark Video Setup Methods

void XMOpalManager::SetVideoFunctionality(BOOL newEnableVideoTransmit, BOOL newEnableVideoReceive)
{
	enableVideoTransmit = newEnableVideoTransmit;
	enableVideoReceive = newEnableVideoReceive;
}

#pragma mark -
#pragma mark Information about current Calls

unsigned XMOpalManager::GetKeyFrameIntervalForCurrentCall(XMCodecIdentifier codecIdentifier)
{
	switch (callProtocol)
	{
		case XMCallProtocol_H323:
			return GetH323KeyFrameInterval(codecIdentifier);
		case XMCallProtocol_SIP:
			return 60;
		default:
			return 0;
	}
}

BOOL XMOpalManager::IsValidCapabilityForSending(const XMH323VideoCapability & capability)
{
	if(PIsDescendant(&capability, XM_H323_H263_Capability))
	{
		if(remoteApplication.Find("ACCORD MGC") != P_MAX_INDEX)
		{
			return FALSE;
		}
	}
	return TRUE;
}

unsigned XMOpalManager::GetH323KeyFrameInterval(XMCodecIdentifier codecIdentifier)
{
	// Hack to enable certain endpoints to successfully decode XM H.263 streams
	// If keyFrameInterval is zero, only I-frames are sent.
	if(remoteApplication.Find("ACCORD MGC") != P_MAX_INDEX &&
	   codecIdentifier == XMCodecIdentifier_H263)
	{
		return 0;
	}
	
	return 200;
}

#pragma mark -
#pragma mark Debug Log Information

void XMOpalManager::LogMessage(const PString & message)
{
	PTRACE(1, message);
}

#pragma mark -
#pragma mark Private Methods

BOOL XMOpalManager::IsOutgoingMedia(OpalMediaStream & stream)
{
	OpalMediaFormat mediaFormat = stream.GetMediaFormat();
	OpalMediaFormatList outgoingMediaFormats = callEndPoint->GetMediaFormats();
	
	if(outgoingMediaFormats.FindFormat(mediaFormat) != P_MAX_INDEX)
	{
		return TRUE;
	}
	
	return FALSE;
}
	