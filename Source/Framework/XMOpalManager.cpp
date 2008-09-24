/*
 * $Id: XMOpalManager.cpp,v 1.73 2008/09/24 06:52:42 hfriederich Exp $
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
#include "XMNetworkConfiguration.h"

#define XM_MAX_BANDWIDTH 1100000

using namespace std;

#pragma mark -
#pragma mark Init & Deallocation

static XMProcess *theProcess = NULL;
static XMOpalManager * managerInstance = NULL;
static XMEndPoint *callEndPointInstance = NULL;
static XMH323EndPoint *h323EndPointInstance = NULL;
static XMSIPEndPoint *sipEndPointInstance = NULL;

void XMOpalManager::InitOpal(const PString & pTracePath, bool logCallStatistics)
{	
  if (theProcess == NULL) {
    PProcess::PreInitialise(0, 0, 0);
    theProcess = new XMProcess;
    
    if (pTracePath != NULL) {
      PTrace::Initialise(5, pTracePath, PTrace::Timestamp|PTrace::Thread|PTrace::FileAndLine);
    }
    
    managerInstance = new XMOpalManager(logCallStatistics);
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

XMOpalManager::XMOpalManager(bool _logCallStatistics)
: logCallStatistics(_logCallStatistics)
{	
  bandwidthLimit = XM_MAX_BANDWIDTH;
  
  defaultAudioPacketTime = 0;
  currentAudioPacketTime = 0;
  
  callEndReason = XMCallEndReasonCount;
  
  // do NOT run the interface monitor update thread, as we're doing this through callbacks from the system. 
  // Also use a custom interface filter to ensure that only ever one interface is used.
  PInterfaceMonitor::GetInstance().SetRunMonitorThread(false);
  PInterfaceMonitor::GetInstance().SetInterfaceFilter(new XMInterfaceFilter());
  
  OpalEchoCanceler::Params params(OpalEchoCanceler::Cancelation);
  SetEchoCancelParams(params);
  
  SetAutoStartTransmitVideo(true);
  SetAutoStartReceiveVideo(true);
  
  AddRouteEntry("xm:.*   = h323:<da>");
  AddRouteEntry("h323:.* = xm:<da>");
  AddRouteEntry("xm:.*   = sip:<da>");
  AddRouteEntry("sip:.*  = xm:<da>");
  
  stun = new XMSTUNClient();
  interfaceMonitor = new XMInterfaceMonitor(*this);
  interfaceUpdateThread = NULL;
}

XMOpalManager::~XMOpalManager()
{
  h323EndPointInstance->CleanUp();
  sipEndPointInstance->CleanUp();
  
  if (interfaceUpdateThread != NULL) {
    interfaceUpdateThread->WaitForTermination();
    delete interfaceUpdateThread;
  }
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

void XMOpalManager::InitiateCall(XMCallProtocol protocol, 
                                 const char * remoteParty, 
                                 const char * origAddressString)
{
  // Attempting to call without any network interfaces may lead to nasty error messages
  // and blocking timeouts
  if (!HasNetworkInterfaces()) {
    _XMHandleCallStartInfo(NULL, XMCallEndReason_EndedByNoNetworkInterfaces);
    return;
  }

  // prepare A and B party
  PString partyB;
  switch (protocol) {
    case XMCallProtocol_H323:
      partyB = "h323:";
      break;
    case XMCallProtocol_SIP:
      partyB = "sip:";
      break;  
    default: // should not happen, serious logic error
      _XMHandleCallStartInfo(NULL, XMCallEndReasonCount);
      return;
  }
  PString partyA = "xm:*";
  partyB += remoteParty;
    
  // Start the call
  callMutex.Wait();
  PString callToken;
  bool success = SetUpCall(partyA, partyB, callToken);
  callMutex.Signal();
  
  if (success) {
    _XMHandleCallStartInfo(callToken, XMCallEndReasonCount);
  } else {
    _XMHandleCallStartInfo(NULL, callEndReason);
  }
}

void XMOpalManager::HandleCallInitiationFailed(XMCallEndReason endReason)
{
  callEndReason = endReason;
}

#pragma mark -
#pragma mark Getting remote application info

PString XMOpalManager::GetRemoteApplicationString(const OpalProductInfo & info)
{
  return info.name + ", " + info.version;
}

#pragma mark -
#pragma mark Getting Call Statistics

void XMOpalManager::GetCallStatistics(const PString & callToken, XMCallStatisticsRecord *callStatistics)
{
  PSafePtr<OpalCall> call = FindCallWithLock(callToken);
  if (call == NULL) {
    return;
  }
  
  // obtain the other connection than the XMConnection instance
  PSafePtr<OpalConnection> connection = call->GetConnection(0);
  if (PSafePtrCast<OpalConnection, XMConnection>(connection) != NULL) { // need to take the other connection
    connection = call->GetConnection(1);
  }
  
  // H.323 also has round trip delay information
  PSafePtr<H323Connection> h323Connection = PSafePtrCast<OpalConnection, H323Connection>(connection);
  if (h323Connection != NULL) {
    callStatistics->roundTripDelay = h323Connection->GetRoundTripDelay().GetMilliSeconds();
  } else {
    callStatistics->roundTripDelay = UINT_MAX;
  }
  
  PSafePtr<OpalRTPConnection> rtpConnection = PSafePtrCast<OpalConnection, OpalRTPConnection>(connection);
  
  // sanity check
  if (rtpConnection == NULL) {
    return;
  }
  
  RTP_Session *session = rtpConnection->GetSession(OpalMediaFormat::DefaultAudioSessionID);
  if (session != NULL) {
    callStatistics->audioPacketsSent        = session->GetPacketsSent();
    callStatistics->audioBytesSent          = session->GetOctetsSent();
    callStatistics->audioMinimumSendTime    = session->GetMinimumSendTime();
    callStatistics->audioAverageSendTime    = session->GetAverageSendTime();
    callStatistics->audioMaximumSendTime    = session->GetMaximumSendTime();
    
    callStatistics->audioPacketsReceived    = session->GetPacketsReceived();
    callStatistics->audioBytesReceived      = session->GetOctetsReceived();
    callStatistics->audioMinimumReceiveTime = session->GetMinimumReceiveTime();
    callStatistics->audioAverageReceiveTime = session->GetAverageReceiveTime();
    callStatistics->audioMaximumReceiveTime = session->GetMaximumReceiveTime();
    
    callStatistics->audioPacketsLost        = session->GetPacketsLost();
    callStatistics->audioPacketsOutOfOrder  = session->GetPacketsOutOfOrder();
    callStatistics->audioPacketsTooLate     = session->GetPacketsTooLate();
    
    callStatistics->audioAverageJitterTime  = session->GetAvgJitterTime();
    callStatistics->audioMaximumJitterTime  = session->GetMaxJitterTime();
    callStatistics->audioJitterBufferSize   = session->GetJitterBufferSize();
  } else {
    callStatistics->audioPacketsSent        = UINT_MAX;
    callStatistics->audioBytesSent          = UINT_MAX;
    callStatistics->audioMinimumSendTime    = UINT_MAX;
    callStatistics->audioAverageSendTime    = UINT_MAX;
    callStatistics->audioMaximumSendTime    = UINT_MAX;
    
    callStatistics->audioPacketsReceived    = UINT_MAX;
    callStatistics->audioBytesReceived      = UINT_MAX;
    callStatistics->audioMinimumReceiveTime = UINT_MAX;
    callStatistics->audioAverageReceiveTime = UINT_MAX;
    callStatistics->audioMaximumReceiveTime = UINT_MAX;
    
    callStatistics->audioPacketsLost        = UINT_MAX;
    callStatistics->audioPacketsOutOfOrder  = UINT_MAX;
    callStatistics->audioPacketsTooLate     = UINT_MAX;
    
    callStatistics->audioAverageJitterTime  = UINT_MAX;
    callStatistics->audioMaximumJitterTime  = UINT_MAX;
    callStatistics->audioJitterBufferSize   = UINT_MAX;
  }
  
  session = rtpConnection->GetSession(OpalMediaFormat::DefaultVideoSessionID);
  if (session != NULL) {
    callStatistics->videoPacketsSent        = session->GetPacketsSent();
    callStatistics->videoBytesSent          = session->GetOctetsSent();
    callStatistics->videoMinimumSendTime    = session->GetMinimumSendTime();
    callStatistics->videoAverageSendTime    = session->GetAverageSendTime();
    callStatistics->videoMaximumSendTime    = session->GetMaximumSendTime();
    
    callStatistics->videoPacketsReceived    = session->GetPacketsReceived();
    callStatistics->videoBytesReceived      = session->GetOctetsReceived();
    callStatistics->videoMinimumReceiveTime = session->GetMinimumReceiveTime();
    callStatistics->videoAverageReceiveTime = session->GetAverageReceiveTime();
    callStatistics->videoMaximumReceiveTime = session->GetMaximumReceiveTime();
    
    callStatistics->videoPacketsLost        = session->GetPacketsLost();
    callStatistics->videoPacketsOutOfOrder  = session->GetPacketsOutOfOrder();
    callStatistics->videoPacketsTooLate     = session->GetPacketsTooLate();
    
    callStatistics->videoAverageJitterTime  = session->GetAvgJitterTime();
    callStatistics->videoMaximumJitterTime  = session->GetMaxJitterTime();
  } else {
    callStatistics->videoPacketsSent        = UINT_MAX;
    callStatistics->videoBytesSent          = UINT_MAX;
    callStatistics->videoMinimumSendTime    = UINT_MAX;
    callStatistics->videoAverageSendTime    = UINT_MAX;
    callStatistics->videoMaximumSendTime    = UINT_MAX;
    
    callStatistics->videoPacketsReceived    = UINT_MAX;
    callStatistics->videoBytesReceived      = UINT_MAX;
    callStatistics->videoMinimumReceiveTime = UINT_MAX;
    callStatistics->videoAverageReceiveTime = UINT_MAX;
    callStatistics->videoMaximumReceiveTime = UINT_MAX;
    
    callStatistics->videoPacketsLost        = UINT_MAX;
    callStatistics->videoPacketsOutOfOrder  = UINT_MAX;
    callStatistics->videoPacketsTooLate     = UINT_MAX;
    
    callStatistics->videoAverageJitterTime  = UINT_MAX;
    callStatistics->videoMaximumJitterTime  = UINT_MAX;
  }
  
  PTRACE_IF(3, logCallStatistics,
         "XMeeting Call Statistics:" <<
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

#pragma mark -
#pragma mark overriding some callbacks

void XMOpalManager::OnEstablishedCall(OpalCall & call)
{
  const PString & callToken = call.GetToken();
  
  // Determine the IP address this call is running on.
  // the connection instance other than the local XMConnection instance is required
  const PString & prefix = call.GetConnection(0)->GetEndPoint().GetPrefixName();
  PSafePtr<OpalConnection> connection;
  if (prefix == XM_LOCAL_ENDPOINT_PREFIX) {
    connection = call.GetConnection(1);
  } else {
    connection = call.GetConnection(0);
  }
  PIPSocket::Address address(0);
  connection->GetTransport().GetLocalAddress().GetIpAddress(address);
  
  PString addressString = "";
  if (address.IsValid()) {
    addressString = address.AsString();
  }
  
  _XMHandleCallEstablished(callToken, 
                           connection->GetRemotePartyName(),
                           connection->GetRemotePartyNumber(),
                           connection->GetRemotePartyAddress(),
                           XMOpalManager::GetRemoteApplicationString(connection->GetRemoteProductInfo()),
                           addressString);
  
  OpalManager::OnEstablishedCall(call);
}

void XMOpalManager::OnReleased(OpalConnection & connection)
{
  // inform the framework, that a call has ended, if the released
  // connection is an XMConnection instance.
  // also provide the framework with informations about the local address
  // (useful for call statistics)
  
  const PString & callToken = connection.GetCall().GetToken();
  
  if (PIsDescendant(&connection, XMConnection)) {
    // If the other connection still exists, determine which local address was used
    PSafePtr<OpalConnection> otherConnection = connection.GetOtherPartyConnection();
    if (otherConnection != NULL) {
      ExtractLocalAddress(callToken, otherConnection);
    }
	
    // obtain the call end reason
    XMCallEndReason endReason = (XMCallEndReason)connection.GetCallEndReason();
	
    // complete the released callback before notifying the framework
    OpalManager::OnReleased(connection);
	
    // Notify the framework that the call has ended
    _XMHandleCallCleared(callToken, endReason);
    
    // reset some per-call variables
    currentAudioPacketTime = 0;
	
  } else {
	
    // obtain the XMConnection instance
    PSafePtr<OpalConnection> otherConnection = connection.GetCall().GetOtherPartyConnection(connection);
	
    // If the XMConnection instance still exists, the non-XMConnection instance is released first.
    // extract the local address here, as this cannot be done when the XMConnection instance is released,
    // since by then the current connection has already been removed.
    if (otherConnection != NULL) { // first release
      ExtractLocalAddress(callToken, &connection);
    }
	
    OpalManager::OnReleased(connection);
  }
}

void XMOpalManager::ExtractLocalAddress(const PString & callToken, OpalConnection *connection)
{
  OpalTransport *transport = &(connection->GetTransport()); // don't use the reference, as the transport may be NULL
  if (transport != NULL) {
    PIPSocket::Address address;
    OpalTransportAddress transportAddress = transport->GetLocalAddress();
    transportAddress.GetIpAddress(address);
    PString addressString = "";
    if (address.IsValid()) {
      addressString = address.AsString();
    }
    _XMHandleLocalAddress(callToken, addressString);
  }
}

OpalMediaPatch * XMOpalManager::CreateMediaPatch(OpalMediaStream & source, bool requiresPatchThread)
{
  // Incoming video streams are treated using a special patch instance.
  // The other streams have the default OpalMediaPatch / OpalPassiveMediaPatch instance
  /*if (requiresPatchThread == true && source.GetMediaFormat().GetMediaType() == OpalDefaultVideoMediaType) {
	return new XMReceiverMediaPatch(source);
  }*/
  
  return OpalManager::CreateMediaPatch(source, requiresPatchThread);
}

void XMOpalManager::OnOpenRTPMediaStream(const OpalConnection & connection, const OpalMediaStream & stream)
{
  // Called when an RTP stream is opened.
  // The main purpose of this callback is to forward this information to the Obj-C world
  
  unsigned callID = connection.GetCall().GetToken().AsUnsigned();
  OpalMediaFormat mediaFormat = stream.GetMediaFormat();
  const OpalMediaType & mediaType = mediaFormat.GetMediaType();
  /*if (mediaType == OpalDefaultVideoMediaType)
  {
	// The incoming video stream (source for OPAL) is treated as being open as soon the
	// first data is decoded and the exact parameters of the stream are
	// known.
	if (stream.IsSink())
	{
	  XMVideoSize videoSize = _XMGetMediaFormatSize(mediaFormat);
	  const char *mediaFormatName = _XMGetMediaFormatName(mediaFormat);
	  
	  _XMHandleVideoStreamOpened(callID, mediaFormatName, videoSize, false, 0, 0);
	}
  }
  else if (mediaType == OpalDefaultAudioMediaType)
  {
	_XMHandleAudioStreamOpened(callID, mediaFormat, stream.IsSource());
  }*/
}

void XMOpalManager::OnClosedRTPMediaStream(const OpalConnection & connection, const OpalMediaStream & stream)
{
  // Called when an RTP stream is closed.
  // The main purpose of this callback is to forward this information to the Obj-C world
  
  unsigned callID = connection.GetCall().GetToken().AsUnsigned();
  OpalMediaFormat mediaFormat = stream.GetMediaFormat();
  const OpalMediaType & mediaType = mediaFormat.GetMediaType();
  /*if (mediaType == OpalDefaultVideoMediaType) 
  {
	_XMHandleVideoStreamClosed(callID, stream.IsSource());
  }
  else if (mediaType == OpalDefaultAudioMediaType)
  {
	_XMHandleAudioStreamClosed(callID, stream.IsSource());
  }*/
}

#pragma mark -
#pragma mark General Setup Methods

void XMOpalManager::SetUserName(const PString & username)
{
  // Forwards this information to the endpoints
  OpalManager::SetDefaultUserName(username);
  GetH323EndPoint()->SetDefaultDisplayName(username);
  GetSIPEndPoint()->SetDefaultDisplayName(username);
}

#pragma mark -
#pragma mark Network Setup Methods

void XMOpalManager::HandleNetworkConfigurationChange()
{
  // When the interfaces change, the STUN values should be updated
  // If there is a BlockedNat in between, the update task takes quite some time.
  // However, the STUN information should be updated BEFORE other parties
  // (gatekeepers, reigstrations) update themselves. Therefore, the STUN
  // has to be updated before they get informed about the interface changes.
  //
  // On the other side, the OpalDispatcher thread should not block for a long
  // time. Hence, the interface update is done in a separate thread
  if (interfaceUpdateThread != NULL) {
    interfaceUpdateThread->WaitForTermination();
    delete interfaceUpdateThread;
  }
  interfaceUpdateThread = new XMInterfaceUpdateThread(*this);
}

void XMOpalManager::SetNATInformation(const PStringArray & _stunServers,
                                      const PString & _publicAddress)
{
  PWaitAndSignal m(natMutex);
  
  XMSTUNClient *stunClient = (XMSTUNClient *)stun;
  
  // update the public address
  publicAddress = _publicAddress;
  if (stunClient->GetEnabled() == false) {
    SetTranslationAddress(publicAddress);
  }
  
  // Don't re-fetch the NAT type if the STUN server list didn't change
  if (stunClient->GetEnabled() == true && stunServers.Compare(_stunServers) == PObject::EqualTo) {
    return;
  }
  
  stunServers = _stunServers;
  
  SetupNATTraversal();
}

void XMOpalManager::UpdateNetworkInterfaces()
{
  PWaitAndSignal m(natMutex);
  PInterfaceMonitor::GetInstance().RefreshInterfaceList();
}

void XMOpalManager::SetupNATTraversal()
{
  
  XMSTUNClient *stunClient = (XMSTUNClient *)stun;
  stun->InvalidateCache();
  
  // Don't try the STUN servers if there are no network interfaces present,
  // as this only leads to timeouts
  if (!HasNetworkInterfaces()) {
    PTRACE(3, "No usable network interfaces present, don't use STUN");
    stunClient->SetEnabled(false);
    HandleSTUNInformation(PSTUNClient::UnknownNat, PString());
    return;
  }
  
  // iterate through the stun servers list
  for (unsigned i = 0; i < stunServers.GetSize(); i++) {
    const PString & stunServer = stunServers[i];
    PTRACE(3, "Trying STUN server " << stunServer);
    stunClient->SetServer(stunServer);
    PSTUNClient::NatTypes natType = stunClient->GetNatType();
    
    switch (natType) {
      case PSTUNClient::UnknownNat:
      case PSTUNClient::BlockedNat:
        // Communication with STUN server was not successful
        // Try next STUN server
        PTRACE(3, "Connection to STUN server unsuccessful. Trying next server");
        continue;
        
        // NAT detection successful, external address known. Special cases like
        // SymmetricNat, etc. are handled at a lower level by circumventing STUN
      default:
        stunClient->GetExternalAddress(translationAddress);
        if (GetTranslationAddress().IsValid()) {
          const PString & address = GetTranslationAddress().AsString();
          HandleSTUNInformation(natType, address);
          stunClient->SetEnabled(true);
          return;
        } else { // should not happen
          PTRACE(3, "Invalid external address reported by STUN server. Trying next server");
          continue;
        }
    }
  }
  
  // No useful STUN servers availale: Use the traditional address translation only
  stunClient->SetEnabled(false);
  SetTranslationAddress(publicAddress);
  HandleSTUNInformation(PSTUNClient::UnknownNat, PString());
}

void XMOpalManager::HandlePublicAddressUpdate(const PString & _publicAddress)
{
  PWaitAndSignal m(natMutex);
  
  publicAddress = _publicAddress;
  
  // update the translation address if needed
  XMSTUNClient *stunClient = (XMSTUNClient *)stun;
  if (stunClient->GetEnabled() == false) {
    SetTranslationAddress(publicAddress);
  }
}

void XMOpalManager::HandleSTUNInformation(PSTUNClient::NatTypes natType,
                                          const PString & publicAddress)
{
  PTRACE(3, "Determined NAT Type " << natType << ", external address " << publicAddress);
  _XMHandleSTUNInformation((XMNATType)natType, publicAddress);
}

bool XMOpalManager::HasNetworkInterfaces() const
{
  PIPSocket::InterfaceTable interfaces;
  PIPSocket::GetInterfaceTable(interfaces);
  if (interfaces.GetSize() == 0 || (interfaces.GetSize() == 1 && interfaces[0].GetAddress().IsLoopback())) {
    return false;
  }
  return true;
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
  if (currentAudioPacketTime != 0) // remote party signaled special value
  {
	return currentAudioPacketTime;
  }
  if (defaultAudioPacketTime != 0) // user defined special value
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
  /*if (codecIdentifier == XMCodecIdentifier_H263 && remoteApplication.Find("ACCORD MGC") != P_MAX_INDEX)
  {
	// zero key frame interval means sending only I-frames
	return 0;
  }*/
  
  /*switch (callProtocol) // call protocol no longer stored
  {
	case XMCallProtocol_H323:
	  return 200;
	case XMCallProtocol_SIP:
	  return 60; // SIP currently lacks the possibility to send videoFastUpdate requests
	default:
	  return 0;
  }*/
  return 0;
}

bool XMOpalManager::IsValidFormatForSending(const OpalMediaFormat & mediaFormat) const
{
  /*if (mediaFormat == XM_MEDIA_FORMAT_H263 || mediaFormat == XM_MEDIA_FORMAT_H263PLUS)
  {
	// Polycom MGC (Accord MGC) has problems decoding QuickTime H.263. Disable sending
	// H.263 to this MGC for now.
	/*if (remoteApplication.Find("ACCORD MGC") != P_MAX_INDEX)
	{
	  return false;
	}
  }
  return true;*/
    return true;
}

#pragma mark -
#pragma mark UserInput methods

bool XMOpalManager::SetUserInputMode(XMUserInputMode userInputMode)
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
	  return false;
  }
  
  GetH323EndPoint()->SetSendUserInputMode(mode);
  GetSIPEndPoint()->SetSendUserInputMode(mode);
  GetCallEndPoint()->SetSendUserInputMode(mode);
  
  return true;
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

#pragma mark -
#pragma mark STUN Classes

XMOpalManager::XMInterfaceMonitor::XMInterfaceMonitor(XMOpalManager & _manager)
: OpalManager::InterfaceMonitor(_manager),
  manager(_manager)
{
}

void XMOpalManager::XMInterfaceMonitor::OnAddInterface(const PIPSocket::InterfaceEntry & entry)
{
  manager.SetupNATTraversal();
}

void XMOpalManager::XMInterfaceMonitor::OnRemoveInterface(const PIPSocket::InterfaceEntry & entry)
{
  manager.SetupNATTraversal();
}

XMOpalManager::XMSTUNClient::XMSTUNClient()
: PSTUNClient(),
  enabled(false)
{
}

XMOpalManager::XMInterfaceUpdateThread::XMInterfaceUpdateThread(XMOpalManager & _manager)
: PThread(10000, NoAutoDeleteThread), // stack size no longer used apparently
  manager(_manager)
{
  Resume();
}

void XMOpalManager::XMInterfaceUpdateThread::Main()
{
  // The DNS lookup using gethostbyname() apparently does not yet work right after
  // the interfaces have come up. Wait some time and hope it works afterwards.
  PThread::Sleep(100);
  manager.UpdateNetworkInterfaces();
}
