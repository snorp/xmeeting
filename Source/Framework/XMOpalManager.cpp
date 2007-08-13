/*
 * $Id: XMOpalManager.cpp,v 1.57 2007/08/13 00:36:34 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#include <ptlib.h>

#include "XMOpalManager.h"

#include "XMTypes.h"
#include "XMCallbackBridge.h"
#include "XMMediaFormats.h"
#include "XMMediaStream.h"
#include "XMSoundChannel.h"
#include "XMReceiverMediaPatch.h"
#include "XMProcess.h"
#include "XMEndPoint.h"
#include "XMConnection.h"
#include "XMH323EndPoint.h"
#include "XMSIPEndPoint.h"

#define XM_MAX_BANDWIDTH 1100000

using namespace std;

#pragma mark -
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
  bandwidthLimit = XM_MAX_BANDWIDTH;
  
  defaultAudioPacketTime = 0;
  currentAudioPacketTime = 0;
  
  connectionToken = "";
  remoteName = "";
  remoteNumber = "";
  remoteAddress = "";
  remoteApplication = "";
  origRemoteAddress = "";
  
  callEndReason = NULL;
  
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
  h323EndPointInstance->CleanUp();
  sipEndPointInstance->CleanUp();
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

#pragma mark -
#pragma mark Initiating a call

unsigned XMOpalManager::InitiateCall(XMCallProtocol protocol, 
                                     const char * remoteParty, 
                                     const char * origAddressString,
                                     XMCallEndReason * _callEndReason)
{
  PString token;
  unsigned callID = 0;
  
  callEndReason = _callEndReason;
  BOOL returnValue = GetCallEndPoint()->StartCall(protocol, remoteParty, token);
  callEndReason = NULL;
  
  if (returnValue == TRUE)
  {
	callID = token.AsUnsigned();
	
	origRemoteAddress = origAddressString;
  }
  
  return callID;
}

void XMOpalManager::HandleCallInitiationFailed(XMCallEndReason endReason)
{
  if (callEndReason != NULL) {
	*callEndReason = endReason;
  }
}

#pragma mark -
#pragma mark Getting / Setting Call Information

void XMOpalManager::LockCallInformation()
{
  callInformationMutex.Wait();
}

void XMOpalManager::UnlockCallInformation()
{
  callInformationMutex.Signal();
}

void XMOpalManager::GetCallInformation(PString & theRemoteName,
									   PString & theRemoteNumber,
									   PString & theRemoteAddress,
									   PString & theRemoteApplication) const
{
  theRemoteName = remoteName;
  theRemoteNumber = remoteNumber;
  if (origRemoteAddress != "") {
	theRemoteAddress = origRemoteAddress;
  } else {
	theRemoteAddress = remoteAddress;
  }
  theRemoteApplication = remoteApplication;
}

void XMOpalManager::SetCallInformation(const PString & theConnectionToken,
									   const PString & theRemoteName,
									   const PString & theRemoteNumber,
									   const PString & theRemoteAddress,
									   const PString & theRemoteApplication,
									   XMCallProtocol theCallProtocol)
{
  PWaitAndSignal m(callInformationMutex);
  
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
	  origRemoteAddress = "";
	  callProtocol = XMCallProtocol_UnknownProtocol;
	}
  }
}

#pragma mark -
#pragma mark Getting Call Statistics

void XMOpalManager::GetCallStatistics(XMCallStatisticsRecord *callStatistics)
{
  // The endpoints (either H.323 or SIP) contain the RTP statistics.
  // Find out which endpoint to ask
  switch(callProtocol)
  {
	case XMCallProtocol_H323:
	  GetH323EndPoint()->GetCallStatistics(callStatistics);
	  break;
	case XMCallProtocol_SIP:
	  GetSIPEndPoint()->GetCallStatistics(callStatistics);
	  break;
	default: // should not happen actually
	  return;
  }
  
  PTRACE(3, "XMeeting Call Statistics:" <<
		 "\nroundTripDelay:          " << callStatistics->roundTripDelay <<
		 "\naudioPacketsSent:        " << callStatistics->audioPacketsSent <<
		 "\naudioBytesSent:          " << callStatistics->audioBytesSent <<
		 "\naudioMininumSendTime:    " << callStatistics->audioMinimumSendTime <<
		 "\naudioAverageSendTime:    " << callStatistics->audioAverageSendTime <<
		 "\naudioMaximumSendTime:    " << callStatistics->audioMaximumSendTime <<
		 "\naudioPacketsReceived:    " << callStatistics->audioPacketsReceived <<
		 "\naudioBytesReceived:      " << callStatistics->audioBytesReceived <<
		 "\naudioMinimumReceiveTime: " << callStatistics->audioMinimumReceiveTime <<
		 "\naudioAverageReceiveTime: " << callStatistics->audioAverageReceiveTime <<
		 "\naudioMaximumReceiveTime: " << callStatistics->audioMaximumReceiveTime <<
		 "\naudioPacketsLost:        " << callStatistics->audioPacketsLost <<
		 "\naudioPacketsOutOfOrder:  " << callStatistics->audioPacketsOutOfOrder <<
		 "\naudioPaketsTooLate:      " << callStatistics->audioPacketsTooLate <<
		 "\naudioAverageJitterTime:  " << callStatistics->audioAverageJitterTime <<
		 "\naudioMaximumJitterTime:  " << callStatistics->audioMaximumJitterTime <<
		 "\naudioJitterBufferSize:   " << callStatistics->audioJitterBufferSize <<
		 "\nvideoPacketsSent:        " << callStatistics->videoPacketsSent <<
		 "\nvideoBytesSent:          " << callStatistics->videoBytesSent <<
		 "\nvideoMininumSendTime:    " << callStatistics->videoMinimumSendTime <<
		 "\nvideoAverageSendTime:    " << callStatistics->videoAverageSendTime <<
		 "\nvideoMaximumSendTime:    " << callStatistics->videoMaximumSendTime <<
		 "\nvideoPacketsReceived:    " << callStatistics->videoPacketsReceived <<
		 "\nvideoBytesReceived:      " << callStatistics->videoBytesReceived <<
		 "\nvideoMinimumReceiveTime: " << callStatistics->videoMinimumReceiveTime <<
		 "\nvideoAverageReceiveTime: " << callStatistics->videoAverageReceiveTime <<
		 "\nvideoMaximumReceiveTime: " << callStatistics->videoMaximumReceiveTime <<
		 "\nvideoPacketsLost:        " << callStatistics->videoPacketsLost <<
		 "\nvideoPacketsOutOfOrder:  " << callStatistics->videoPacketsOutOfOrder <<
		 "\nvideoPaketsTooLate:      " << callStatistics->videoPacketsTooLate <<
		 "\nvideoAverageJitterTime:  " << callStatistics->videoAverageJitterTime <<
		 "\nvideoMaximumJitterTime:  " << callStatistics->videoMaximumJitterTime);
}

void XMOpalManager::ExtractCallStatistics(const OpalConnection & connection,
                                          XMCallStatisticsRecord *callStatistics)
{
  RTP_Session *session = connection.GetSession(OpalDefaultAudioMediaType);
  if (session != NULL)
  {
	callStatistics->audioPacketsSent = session->GetPacketsSent();
	callStatistics->audioBytesSent = session->GetOctetsSent();
	callStatistics->audioMinimumSendTime = session->GetMinimumSendTime();
	callStatistics->audioAverageSendTime = session->GetAverageSendTime();
	callStatistics->audioMaximumSendTime = session->GetMaximumSendTime();
	
	callStatistics->audioPacketsReceived = session->GetPacketsReceived();
	callStatistics->audioBytesReceived = session->GetOctetsReceived();
	callStatistics->audioMinimumReceiveTime = session->GetMinimumReceiveTime();
	callStatistics->audioAverageReceiveTime = session->GetAverageReceiveTime();
	callStatistics->audioMaximumReceiveTime = session->GetMaximumReceiveTime();
	
	callStatistics->audioPacketsLost = session->GetPacketsLost();
	callStatistics->audioPacketsOutOfOrder = session->GetPacketsOutOfOrder();
	callStatistics->audioPacketsTooLate = session->GetPacketsTooLate();
	
	callStatistics->audioAverageJitterTime = session->GetAvgJitterTime();
	callStatistics->audioMaximumJitterTime = session->GetMaxJitterTime();
	callStatistics->audioJitterBufferSize = session->GetJitterBufferSize();
  } 
  else 
  {
	callStatistics->audioPacketsSent = UINT_MAX;
	callStatistics->audioBytesSent = UINT_MAX;
	callStatistics->audioMinimumSendTime = UINT_MAX;
	callStatistics->audioAverageSendTime = UINT_MAX;
	callStatistics->audioMaximumSendTime = UINT_MAX;
	
	callStatistics->audioPacketsReceived = UINT_MAX;
	callStatistics->audioBytesReceived = UINT_MAX;
	callStatistics->audioMinimumReceiveTime = UINT_MAX;
	callStatistics->audioAverageReceiveTime = UINT_MAX;
	callStatistics->audioMaximumReceiveTime = UINT_MAX;
	
	callStatistics->audioPacketsLost = UINT_MAX;
	callStatistics->audioPacketsOutOfOrder = UINT_MAX;
	callStatistics->audioPacketsTooLate = UINT_MAX;
	
	callStatistics->audioAverageJitterTime = UINT_MAX;
	callStatistics->audioMaximumJitterTime = UINT_MAX;
	callStatistics->audioJitterBufferSize = UINT_MAX;
  }
  
  session = connection.GetSession(OpalDefaultVideoMediaType);
  if(session != NULL)
  {
	callStatistics->videoPacketsSent = session->GetPacketsSent();
	callStatistics->videoBytesSent = session->GetOctetsSent();
	callStatistics->videoMinimumSendTime = session->GetMinimumSendTime();
	callStatistics->videoAverageSendTime = session->GetAverageSendTime();
	callStatistics->videoMaximumSendTime = session->GetMaximumSendTime();
	
	callStatistics->videoPacketsReceived = session->GetPacketsReceived();
	callStatistics->videoBytesReceived = session->GetOctetsReceived();
	callStatistics->videoMinimumReceiveTime = session->GetMinimumReceiveTime();
	callStatistics->videoAverageReceiveTime = session->GetAverageReceiveTime();
	callStatistics->videoMaximumReceiveTime = session->GetMaximumReceiveTime();
	
	callStatistics->videoPacketsLost = session->GetPacketsLost();
	callStatistics->videoPacketsOutOfOrder = session->GetPacketsOutOfOrder();
	callStatistics->videoPacketsTooLate = session->GetPacketsTooLate();
	
	callStatistics->videoAverageJitterTime = session->GetAvgJitterTime();
	callStatistics->videoMaximumJitterTime = session->GetMaxJitterTime();
  }
  else
  {
	callStatistics->videoPacketsSent = UINT_MAX;
	callStatistics->videoBytesSent = UINT_MAX;
	callStatistics->videoMinimumSendTime = UINT_MAX;
	callStatistics->videoAverageSendTime = UINT_MAX;
	callStatistics->videoMaximumSendTime = UINT_MAX;
	
	callStatistics->videoPacketsReceived = UINT_MAX;
	callStatistics->videoBytesReceived = UINT_MAX;
	callStatistics->videoMinimumReceiveTime = UINT_MAX;
	callStatistics->videoAverageReceiveTime = UINT_MAX;
	callStatistics->videoMaximumReceiveTime = UINT_MAX;
    
	callStatistics->videoPacketsLost = UINT_MAX;
	callStatistics->videoPacketsOutOfOrder = UINT_MAX;
	callStatistics->videoPacketsTooLate = UINT_MAX;
	
	callStatistics->videoAverageJitterTime = UINT_MAX;
	callStatistics->videoMaximumJitterTime = UINT_MAX;
  }
}

#pragma mark -
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

void XMOpalManager::OnReleased(OpalConnection & connection)
{
  unsigned callID = connection.GetCall().GetToken().AsUnsigned();
  
  if (PIsDescendant(&connection, XMConnection)) {
	
	// If the other connection still exists, determine which local address was used
	PSafePtr<OpalConnection> otherConnection = connection.GetCall().GetOtherPartyConnection(connection);
	if (otherConnection != NULL) {
	  OpalTransport *transport = &(otherConnection->GetTransport());
	  if (transport != NULL) {
		PIPSocket::Address address(0);
		OpalTransportAddress transportAddress = transport->GetLocalAddress();
		transportAddress.GetIpAddress(address);
		if (address.IsValid()) {
		  _XMHandleLocalAddress(callID, address.AsString());
		} else {
		  _XMHandleLocalAddress(callID, "");
		}
	  }
	}
	
	XMCallEndReason endReason = (XMCallEndReason)connection.GetCallEndReason();
	
	OpalManager::OnReleased(connection);
	
	// Notifying the obj-c world that the call has ended
	_XMHandleCallCleared(callID, endReason);
	currentAudioPacketTime = 0;
	
  } else {
	
	PSafePtr<OpalConnection> otherConnection = connection.GetCall().GetOtherPartyConnection(connection);
	
	// If the XMConnection instance still exists, this connection is released first.
	// Determine which local address was used, as this cannot be done when the other connection is released,
	// since then this connection has already been removed
	if (otherConnection != NULL) {
	  OpalTransport *transport = &(connection.GetTransport());
	  if (transport != NULL) {
		PIPSocket::Address address(0);
		OpalTransportAddress transportAddress = transport->GetLocalAddress();
		transportAddress.GetIpAddress(address);
		if (address.IsValid()) {
		  _XMHandleLocalAddress(callID, address.AsString());
		} else {
		  _XMHandleLocalAddress(callID, "");
		}
	  }
	}
	
	OpalManager::OnReleased(connection);
  }
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

#pragma mark -
#pragma mark General Setup Methods

void XMOpalManager::SetUserName(const PString & username)
{
  // Forwards this information to the endpoints.
  
  OpalManager::SetDefaultUserName(username);
  GetH323EndPoint()->SetDefaultDisplayName(username);
  GetSIPEndPoint()->SetDefaultDisplayName(username);
}

#pragma mark -
#pragma mark Network Setup Methods

void XMOpalManager::SetNATInformation(const PStringArray & stunServers,
									  const PString & theTranslationAddress)
{
  //
  // In case STUN works as expected, use it. In case of failures,
  // SymmetricNAT, SymmetricFirewall, PartialBlockedNAT, dont' use
  // STUN but rather rely on the translationAddress feature only.
  // In case of STUN problems, connections MAY still work this way.
  //
  if(stun != NULL) {
	delete stun;
	stun = NULL;
  }

  for (PINDEX i = 0; i < stunServers.GetSize(); i++) {
	const PString & stunServer = stunServers[i];
	PTRACE(3, "Trying STUN server " << stunServer);
	stun = new PSTUNClient(stunServer, GetUDPPortBase(), GetUDPPortMax(),
						   GetRtpIpPortBase(), GetRtpIpPortMax());
	PSTUNClient::NatTypes natType = stun->GetNatType();
	  
	switch(natType) {
		
	  case PSTUNClient::UnknownNat:
	  case PSTUNClient::BlockedNat:
		// Communication with STUN server was not successful.
		// Try next STUN server
		PTRACE(3, "Connection to STUN server unsuccessful. Trying next server");
		continue;
		  
	  case PSTUNClient::ConeNat:
	  case PSTUNClient::RestrictedNat:
	  case PSTUNClient::PortRestrictedNat:
	  case PSTUNClient::OpenNat:
		// STUN does work in these cases
		stun->GetExternalAddress(translationAddress);
		if (GetTranslationAddress().IsValid()) {
          const PString & address = GetTranslationAddress().AsString();
		  HandleSTUNInformation(natType, address);
		} else {
		  // something wrong here
		  delete stun;
		  stun = NULL;
		  SetTranslationAddress(theTranslationAddress);
		  HandleSTUNInformation(natType, PString());
		}
		return;
				
	  default:

        // STUN does not work: Use the traditional address translation feature
        PIPSocket::Address stunExternalAddress;
        stun->GetExternalAddress(stunExternalAddress);
        delete stun;
        stun = NULL;
        SetTranslationAddress(theTranslationAddress);
        HandleSTUNInformation(natType, stunExternalAddress.AsString());
        return;
	}
  }
	
  // No STUN servers availalbe: Use the traditional address translation feature
  PTRACE(3, "No valid STUN server found, using translationAddress " << theTranslationAddress);
  delete stun;
  stun = NULL;
  SetTranslationAddress(theTranslationAddress);
  HandleSTUNInformation(PSTUNClient::UnknownNat, "");
}

void XMOpalManager::HandleSTUNInformation(PSTUNClient::NatTypes natType,
                                          const PString & externalAddress)
{
  PTRACE(3, "Determined NAT Type " << natType << ", external address " << externalAddress);
  _XMHandleSTUNInformation((XMNATType)natType, externalAddress);
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

unsigned XMOpalManager::GetKeyFrameIntervalForCurrentCall(XMCodecIdentifier codecIdentifier) const
{
  // Polycom MGC (Accord MGC) has problems decoding QuickTime H.263. If at all, only I-frames should be
  // sent.
  if(codecIdentifier == XMCodecIdentifier_H263 && remoteApplication.Find("ACCORD MGC") != P_MAX_INDEX)
  {
	// zero key frame interval means sending only I-frames
	return 0;
  }
  
  switch (callProtocol)
  {
	case XMCallProtocol_H323:
	  return 200;
	case XMCallProtocol_SIP:
	  return 60; // SIP currently lacks the possibility to send videoFastUpdate requests
	default:
	  return 0;
  }
}

BOOL XMOpalManager::IsValidFormatForSending(const OpalMediaFormat & mediaFormat) const
{
  if (mediaFormat == XM_MEDIA_FORMAT_H263 || mediaFormat == XM_MEDIA_FORMAT_H263PLUS)
  {
	// Polycom MGC (Accord MGC) has problems decoding QuickTime H.263. Disable sending
	// H.263 to this MGC for now.
	if (remoteApplication.Find("ACCORD MGC") != P_MAX_INDEX)
	{
	  return FALSE;
	}
  }
  return TRUE;
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

#pragma mark -
#pragma mark Convenience Functions

unsigned XMOpalManager::GetH261BandwidthLimit()
{
  return std::min(GetManager()->GetVideoBandwidthLimit(), _XMGetMaxH261Bitrate());
}

unsigned XMOpalManager::GetH263BandwidthLimit()
{
  return std::min(GetManager()->GetVideoBandwidthLimit(), _XMGetMaxH263Bitrate());
}

unsigned XMOpalManager::GetH264BandwidthLimit()
{
  return std::min(GetManager()->GetVideoBandwidthLimit(), _XMGetMaxH264Bitrate());
}
