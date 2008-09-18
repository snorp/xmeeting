/*
 * $Id: XMBridge.cpp,v 1.60 2008/09/18 23:08:49 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#include "XMBridge.h"

#include <ptlib.h>
#include "XMTypes.h"
#include "XMOpalManager.h"
#include "XMEndPoint.h"
#include "XMH323EndPoint.h"
#include "XMSIPEndPoint.h"
#include "XMSoundChannel.h"
#include "XMAudioTester.h"
#include "XMMediaFormats.h"
#include "XMMediaStream.h"

using namespace std;

void _XMInitSubsystem(const char *pTracePath)
{
  XMOpalManager::InitOpal(pTracePath);
}

void _XMCloseSubsystem()
{
  XMOpalManager::CloseOpal();
}

#pragma mark -
#pragma mark General Setup functions

void _XMSetUserName(const char *string)
{
  XMOpalManager::GetManager()->SetUserName(string);
}

const char *_XMGetUserName()
{
  return XMOpalManager::GetManager()->GetDefaultUserName();
}

#pragma mark -
#pragma mark Network Setup functions

void _XMSetBandwidthLimit(unsigned limit)
{
  XMOpalManager::GetManager()->SetBandwidthLimit(limit);
}

void _XMHandleNetworkConfigurationChange()
{
  XMOpalManager::GetManager()->HandleNetworkConfigurationChange();
}

void _XMSetNATInformation(const char * const *stunServers,
                          unsigned stunServerCount,
                          const char *_publicAddress)
{
  PStringArray servers = PStringArray(stunServerCount, stunServers, TRUE);
  PString publicAddress = _publicAddress;
  XMOpalManager::GetManager()->SetNATInformation(servers, publicAddress);
}

void _XMHandlePublicAddressUpdate(const char *_publicAddress)
{
  PString publicAddress = _publicAddress;
  XMOpalManager::GetManager()->HandlePublicAddressUpdate(publicAddress);
}

void _XMSetPortRanges(unsigned int udpPortMin, 
                      unsigned int udpPortMax, 
                      unsigned int tcpPortMin, 
                      unsigned int tcpPortMax,
                      unsigned int rtpPortMin,
                      unsigned int rtpPortMax)
{
  tcpPortMin = 22;
  tcpPortMax = 22;
  XMOpalManager *theManager = XMOpalManager::GetManager();
  theManager->SetUDPPorts(udpPortMin, udpPortMax);
  theManager->SetTCPPorts(tcpPortMin, tcpPortMax);
  theManager->SetRtpIpPorts(rtpPortMin, rtpPortMax);
}

#pragma mark -
#pragma mark Audio Functions

void _XMSetSelectedAudioInputDevice(unsigned int deviceID)
{
  XMSoundChannel::SetRecordDevice(deviceID);
}

void _XMSetMuteAudioInputDevice(bool muteFlag)
{
  XMSoundChannel::SetRecordDeviceMuted(muteFlag);
}

void _XMSetSelectedAudioOutputDevice(unsigned int deviceID)
{
  XMSoundChannel::SetPlayDevice(deviceID);
}

void _XMSetMuteAudioOutputDevice(bool muteFlag)
{
  XMSoundChannel::SetPlayDeviceMuted(muteFlag);
}

void _XMSetMeasureAudioSignalLevels(bool flag)
{
  XMSoundChannel::SetMeasureSignalLevels(flag);
}

void _XMSetRecordAudio(bool flag)
{
  XMSoundChannel::SetRecordAudio(flag);
}

void _XMSetAudioFunctionality(bool enableSilenceSuppression,
                              bool enableEchoCancellation,
                              unsigned packetTime)
{
  XMOpalManager::GetCallEndPoint()->SetEnableSilenceSuppression(enableSilenceSuppression);
  XMOpalManager::GetCallEndPoint()->SetEnableEchoCancellation(enableEchoCancellation);
  XMOpalManager::GetManager()->SetAudioPacketTime(packetTime);
}

void _XMStopAudio()
{
  XMSoundChannel::StopChannels();
}

void _XMStartAudioTest(unsigned delay)
{
  XMAudioTester::Start(delay);
}

void _XMStopAudioTest()
{
  XMAudioTester::Stop();
}

#pragma mark -
#pragma mark Video functions

void _XMSetEnableVideo(bool enableVideo)
{
  XMOpalManager::GetCallEndPoint()->SetEnableVideo(enableVideo);
}

void _XMSetEnableH264LimitedMode(bool enableH264LimitedMode)
{
  XMOpalManager::GetManager()->SetEnableH264LimitedMode(enableH264LimitedMode);
}

#pragma mark -
#pragma mark codec functions

void _XMSetCodecs(const char * const * orderedCodecs, unsigned orderedCodecCount,
                  const char * const * disabledCodecs, unsigned disabledCodecCount)
{
  PStringArray orderedCodecsArray = PStringArray(orderedCodecCount, orderedCodecs, TRUE);
  PStringArray disabledCodecsArray = PStringArray(disabledCodecCount, disabledCodecs, TRUE);
  
  XMOpalManager *theManager = XMOpalManager::GetManager();
  theManager->SetMediaFormatMask(disabledCodecsArray);
  theManager->SetMediaFormatOrder(orderedCodecsArray);
}

#pragma mark -
#pragma mark H.323 Functions

bool _XMEnableH323(bool flag)
{
  return XMOpalManager::GetH323EndPoint()->EnableListeners(flag);
}

bool _XMIsH323Enabled()
{
  return XMOpalManager::GetH323EndPoint()->IsListening();
}

void _XMSetH323Functionality(bool enableFastStart, bool enableH245Tunnel)
{
  XMH323EndPoint *h323EndPoint = XMOpalManager::GetH323EndPoint();
  h323EndPoint->DisableFastStart(!enableFastStart);
  h323EndPoint->DisableH245Tunneling(!enableH245Tunnel);
}

void _XMSetGatekeeper(const char *address, 
                      const char *terminalAlias1, 
                      const char *terminalAlias2,
                      const char *password)
{
  XMOpalManager::GetH323EndPoint()->SetGatekeeper(address, terminalAlias1, terminalAlias2, password);
}

bool _XMIsRegisteredAtGatekeeper()
{
  return XMOpalManager::GetH323EndPoint()->IsRegisteredWithGatekeeper();
}

#pragma mark -
#pragma mark SIP Setup Functions

bool _XMEnableSIP(bool flag)
{
  return XMOpalManager::GetSIPEndPoint()->EnableListeners(flag);
}

bool _XMIsSIPEnabled()
{
  return XMOpalManager::GetSIPEndPoint()->IsListening();
}

bool _XMSetSIPProxy(const char *host,
                    const char *username,
                    const char *password)
{
  return XMOpalManager::GetSIPEndPoint()->UseProxy(host, username, password);
}

void _XMPrepareRegistrationSetup(bool proxyChanged)
{
  XMOpalManager::GetSIPEndPoint()->PrepareRegistrationSetup(proxyChanged);
}

void _XMUseRegistration(const char *domain,
                        const char *username,
                        const char *authorizationUsername,
                        const char *password,
                        bool proxyChanged)
{
  XMOpalManager::GetSIPEndPoint()->UseRegistration(domain, username, authorizationUsername, password, proxyChanged);
}

void _XMFinishRegistrationSetup(bool proxyChanged)
{
  XMOpalManager::GetSIPEndPoint()->FinishRegistrationSetup(proxyChanged);
}

bool _XMIsSIPRegistered()
{
  return (XMOpalManager::GetSIPEndPoint()->GetRegistrationsCount() != 0);
}

#pragma mark -
#pragma mark Call Management functions

void _XMInitiateCall(XMCallProtocol protocol, const char *remoteParty, const char *origAddressString)
{	
  XMOpalManager::GetManager()->InitiateCall(protocol, remoteParty, origAddressString);
}

void _XMAcceptIncomingCall(const char *callToken)
{
  XMOpalManager::GetCallEndPoint()->DoAcceptIncomingCall(callToken);
}

void _XMRejectIncomingCall(const char *callToken)
{
  XMOpalManager::GetCallEndPoint()->DoRejectIncomingCall(callToken);
}

void _XMClearCall(const char *callToken)
{
  XMOpalManager::GetCallEndPoint()->ClearCall(callToken);
}

void _XMLockCallInformation()
{
  XMOpalManager::GetManager()->LockCallInformation();
}

void _XMUnlockCallInformation()
{
  XMOpalManager::GetManager()->UnlockCallInformation();
}

void _XMGetCallInformation(const char *callToken,
                           const char** remoteName, 
                           const char** remoteNumber,
                           const char** remoteAddress, 
                           const char** remoteApplication)
{
  PString nameStr;
  PString numberStr;
  PString addressStr;
  PString appStr;
  
  XMOpalManager::GetManager()->GetCallInformation(nameStr, numberStr, addressStr, appStr);
  
  *remoteName = nameStr;
  *remoteNumber = numberStr;
  *remoteAddress = addressStr;
  *remoteApplication = appStr;
}

void _XMGetCallStatistics(const char *callToken,
                          XMCallStatisticsRecord *callStatistics)
{
  XMOpalManager::GetManager()->GetCallStatistics(callStatistics);
}

#pragma mark -
#pragma mark InCall Functions

bool _XMSetUserInputMode(XMUserInputMode userInputMode)
{
  return XMOpalManager::GetManager()->SetUserInputMode(userInputMode);
}

bool _XMSendUserInputTone(const char *_callToken, const char tone)
{
  PString callToken = _callToken;
  return XMOpalManager::GetCallEndPoint()->SendUserInputTone(callToken, tone);
}

bool _XMSendUserInputString(const char *_callToken, const char *string)
{
  PString callToken = _callToken;
  return XMOpalManager::GetCallEndPoint()->SendUserInputString(callToken, string);
}

bool _XMStartCameraEvent(const char *_callToken, XMCameraEvent cameraEvent)
{
  PString callToken = _callToken;
  return XMOpalManager::GetCallEndPoint()->StartCameraEvent(callToken, cameraEvent);
}

void _XMStopCameraEvent(const char *_callToken)
{
  PString callToken = _callToken;
  return XMOpalManager::GetCallEndPoint()->StopCameraEvent(callToken);
}

#pragma mark -
#pragma mark MediaTransmitter Functions

void _XMSetTimeStamp(unsigned sessionID, unsigned timeStamp)
{
  XMMediaStream::SetTimeStamp(sessionID, timeStamp);
}

void _XMAppendData(unsigned sessionID, void *data, unsigned length)
{
  XMMediaStream::AppendData(sessionID, data, length);
}

void _XMSendPacket(unsigned sessionID, bool setMarkerBit)
{
  XMMediaStream::SendPacket(sessionID, setMarkerBit);
}

void _XMDidStopTransmitting(unsigned sessionID)
{
  XMMediaStream::HandleDidStopTransmitting(sessionID);
}

#pragma mark -
#pragma mark Message Logging

void _XMLogMessage(const char *message)
{
  XMOpalManager::LogMessage(message);
}
