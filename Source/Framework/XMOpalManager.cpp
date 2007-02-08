/*
 * $Id: XMOpalManager.cpp,v 1.47 2007/02/08 23:09:14 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#include "XMOpalManager.h"

#include "XMTypes.h"
#include "XMCallbackBridge.h"
#include "XMMediaFormats.h"
#include "XMMediaStream.h"
#include "XMSoundChannel.h"
#include "XMReceiverMediaPatch.h"
#include "XMProcess.h"
#include "XMConnection.h"

#include <ptlib.h>

#define XM_MAX_BANDWIDTH 1100000

using namespace std;

#pragma mark Init & Deallocation

static XMProcess *theProcess = NULL;
static XMOpalManager * managerInstance = NULL;
static XMEndPoint *callEndPointInstance = NULL;
static XMH323EndPoint *h323EndPointInstance = NULL;
static XMSIPEndPoint *sipEndPointInstance = NULL;

void XMOpalManager::InitOpal(const PString & pTracePath)
{	
	if(theProcess == NULL)
	{
		PProcess::PreInitialise(0, 0, 0);
		theProcess = new XMProcess;
		
		if(pTracePath != NULL)
		{
			PTrace::Initialise(5, pTracePath, PTrace::Timestamp|PTrace::Thread|PTrace::FileAndLine);
		}
        
        managerInstance = new XMOpalManager();
        callEndPointInstance = new XMEndPoint(*managerInstance);
        h323EndPointInstance = new XMH323EndPoint(*managerInstance);
        sipEndPointInstance = new XMSIPEndPoint(*managerInstance);
        
        XMSoundChannel::Init();
	}
}

void XMOpalManager::CloseOpal()
{
    delete managerInstance;
    managerInstance = NULL;
    // The endpoints are deleted when the manager is deleted
    callEndPointInstance = NULL;
    h323EndPointInstance = NULL;
    sipEndPointInstance = NULL;
    delete theProcess;
    theProcess = NULL;
    
    XMSoundChannel::DoClose();
}

XMOpalManager::XMOpalManager()
{	
	defaultAudioPacketTime = 0;
	currentAudioPacketTime = 0;
	
	connectionToken = "";
	remoteName = "";
	remoteNumber = "";
	remoteAddress = "";
	remoteApplication = "";
	
	OpalEchoCanceler::Params params(OpalEchoCanceler::Cancelation);
	SetEchoCancelParams(params);
    
    SetAutoStartTransmitVideo(TRUE);
    SetAutoStartReceiveVideo(TRUE);
    
    AddRouteEntry("xm:.*   = h323:<da>");
	AddRouteEntry("h323:.* = xm:<da>");
	AddRouteEntry("xm:.*   = sip:<da>");
	AddRouteEntry("sip:.*  = xm:<da>");
}

XMOpalManager::~XMOpalManager()
{
}

#pragma mark -
#pragma mark Accessing the manager and endpoints

XMOpalManager * XMOpalManager::GetManager()
{
	return managerInstance;
}

XMEndPoint * XMOpalManager::GetCallEndPoint()
{
    return callEndPointInstance;
}

XMH323EndPoint * XMOpalManager::GetH323EndPoint()
{
    return h323EndPointInstance;
}

XMSIPEndPoint * XMOpalManager::GetSIPEndPoint()
{
    return sipEndPointInstance;
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
	
	if(connectionToken == "") // current connection token is empty
	{
		connectionToken = theConnectionToken;
		callProtocol = theCallProtocol;
		isValid = TRUE;
	}
	else if(connectionToken == theConnectionToken) // same connection token
	{
		isValid = TRUE;
	}
	
	if(isValid == TRUE) // if valid, update information
	{
		remoteName = theRemoteName;
		remoteNumber = theRemoteNumber;
		remoteAddress = theRemoteAddress;
		remoteApplication = theRemoteApplication;
		
		if(remoteName == "" &&
		   remoteNumber == "" &&
		   remoteAddress == "" &&
		   remoteApplication == "") // empty information, clear connection token / call protocol
		{
			connectionToken = "";
			callProtocol = XMCallProtocol_UnknownProtocol;
		}
	}
}

#pragma mark Getting Call Statistics

void XMOpalManager::GetCallStatistics(XMCallStatisticsRecord *callStatistics)
{
    // The endpoints (either H.323 or SIP) contain the RTP statistics.
    // Find out which endpoint to ask
	switch(callProtocol)
	{
		case XMCallProtocol_H323:
			GetH323EndPoint()->GetCallStatistics(callStatistics);
			return;
		case XMCallProtocol_SIP:
			GetSIPEndPoint()->GetCallStatistics(callStatistics);
			return;
		default: // should not happen actually
			return;
	}
}

#pragma mark overriding some callbacks

void XMOpalManager::OnEstablishedCall(OpalCall & call)
{
	unsigned callID = call.GetToken().AsUnsigned();
	
    // Determine if we were originating the call or not, by looking at
    // the class of the endpoint associated with the first connection
    // in the call dictionary.
	BOOL isIncomingCall = TRUE;
	OpalEndPoint & endPoint = call.GetConnection(0, PSafeReadOnly)->GetEndPoint();
	if(PIsDescendant(&endPoint, XMEndPoint))
	{
		isIncomingCall = FALSE;
	}
	
	// Determine the IP address this call is running on.
    // We need to have the other connection as the local XMConnection instance
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
	
	// reset any packet time information
	currentAudioPacketTime = 0;
}

void XMOpalManager::OnReleased(OpalConnection & connection)
{
    // XMOpalManager::OnClearedCall() gets only called if the call was actually
    // established. This callback gets also called if the connection is released
    // before the call is established.
	if(!PIsDescendant(&connection, XMConnection))
	{
		PIPSocket::Address address(0);
		OpalTransport *transport = &(connection.GetTransport());
		if(transport != NULL) {
			OpalTransportAddress transportAddress = transport->GetLocalAddress();
			transportAddress.GetIpAddress(address);
		}
		
        unsigned callID = connection.GetCall().GetToken().AsUnsigned();
		if(address.IsValid())
		{
			_XMHandleCallReleased(callID, address.AsString());
		}
        else
        {
            _XMHandleCallReleased(callID, "");
        }
	}
    
	OpalManager::OnReleased(connection);
	
	// reset any packet time information
	currentAudioPacketTime = 0;
}

OpalMediaPatch * XMOpalManager::CreateMediaPatch(OpalMediaStream & source, BOOL requiresPatchThread)
{
    // Incoming video streams are treated using a special patch instance.
    // The other streams have the default OpalMediaPatch / OpalPassiveMediaPatch instance
    if (requiresPatchThread == TRUE && source.GetMediaFormat().GetMediaType() == OpalDefaultVideoMediaType) {
        return new XMReceiverMediaPatch(source);
    }
    
    return OpalManager::CreateMediaPatch(source, requiresPatchThread);
}

void XMOpalManager::OnOpenRTPMediaStream(const OpalConnection & connection, const OpalMediaStream & stream)
{
    // Called when an RTP stream is opened.
    // The main purpose of this callback is to forward this information to the Obj-C world
    
    unsigned callID = connection.GetCall().GetToken().AsUnsigned();
    OpalMediaFormat mediaFormat = stream.GetMediaFormat();
    const OpalMediaType & mediaType = mediaFormat.GetMediaType();
    if(mediaType == OpalDefaultVideoMediaType)
    {
        // The incoming video stream (source for OPAL) is treated as being open as soon the
        // first data is decoded and the exact parameters of the stream are
        // known.
        if(stream.IsSink())
        {
            XMVideoSize videoSize = _XMGetMediaFormatSize(mediaFormat);
            const char *mediaFormatName = _XMGetMediaFormatName(mediaFormat);
            
            _XMHandleVideoStreamOpened(callID, mediaFormatName, videoSize, false, 0, 0);
        }
    }
    else if(mediaType == OpalDefaultAudioMediaType)
    {
        _XMHandleAudioStreamOpened(callID, mediaFormat, stream.IsSource());
    }
}

void XMOpalManager::OnClosedRTPMediaStream(const OpalConnection & connection, const OpalMediaStream & stream)
{
    // Called when an RTP stream is closed.
    // The main purpose of this callback is to forward this information to the Obj-C world
    
    unsigned callID = connection.GetCall().GetToken().AsUnsigned();
    OpalMediaFormat mediaFormat = stream.GetMediaFormat();
    const OpalMediaType & mediaType = mediaFormat.GetMediaType();
    if(mediaType == OpalDefaultVideoMediaType) 
    {
        _XMHandleVideoStreamClosed(callID, stream.IsSource());
    }
    else if(mediaType == OpalDefaultAudioMediaType)
    {
        _XMHandleAudioStreamClosed(callID, stream.IsSource());
    }
}

#pragma mark General Setup Methods

void XMOpalManager::SetUserName(const PString & username)
{
    // Forwards this information to the endpoints.
    
	OpalManager::SetDefaultUserName(username);
	GetH323EndPoint()->SetDefaultDisplayName(username);
	GetSIPEndPoint()->SetDefaultDisplayName(username);
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
			case PSTUNClient::OpenNat:
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
#pragma mark Audio Setup Methods

void XMOpalManager::SetAudioPacketTime(unsigned audioPacketTime)
{
	defaultAudioPacketTime = audioPacketTime;
}

void XMOpalManager::SetCurrentAudioPacketTime(unsigned audioPacketTime)
{
	currentAudioPacketTime = audioPacketTime;
}

unsigned XMOpalManager::GetCurrentAudioPacketTime()
{
	if(currentAudioPacketTime != 0) // remote party signaled special value
	{
		return currentAudioPacketTime;
	}
	if(defaultAudioPacketTime != 0) // user defined special value
	{
		return defaultAudioPacketTime;
	}
	return 0; // use default value
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
#pragma mark UserInput methods

BOOL XMOpalManager::SetUserInputMode(XMUserInputMode userInputMode)
{
	OpalConnection::SendUserInputModes mode;
	
	switch(userInputMode) {
		case XMUserInputMode_ProtocolDefault:
			mode = OpalConnection::SendUserInputAsProtocolDefault;
			break;
		case XMUserInputMode_StringTone:
			mode = OpalConnection::SendUserInputAsTone;
			break;
		case XMUserInputMode_RFC2833:
			mode = OpalConnection::SendUserInputAsInlineRFC2833;
			break;
		case XMUserInputMode_InBand:
			// Separate RFC 2833 is not implemented and is therefore used
			// to signal InBand DTMF. HACK HACK
			mode = OpalConnection::SendUserInputAsSeparateRFC2833;
			break;
		default:
			return FALSE;
	}
	
	GetH323EndPoint()->SetSendUserInputMode(mode);
	GetSIPEndPoint()->SetSendUserInputMode(mode);
	GetCallEndPoint()->SetSendUserInputMode(mode);
	
	return TRUE;
}

#pragma mark -
#pragma mark Debug Log Information

void XMOpalManager::LogMessage(const PString & message)
{
    // Logs the message using the default PTRACE facility.
    
	PTRACE(1, message);
}

	