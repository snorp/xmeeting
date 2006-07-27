/*
 * $Id: XMBridge.cpp,v 1.29 2006/07/27 21:13:21 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#include "XMBridge.h"

#include <ptlib.h>
#include "XMTypes.h"
#include "XMOpalManager.h"
#include "XMEndPoint.h"
#include "XMH323EndPoint.h"
#include "XMSIPEndPoint.h"
#include "XMSoundChannel.h"
#include "XMMediaFormats.h"
#include "XMTransmitterMediaPatch.h"

using namespace std;

// reference to the active OPAL manager.
static XMOpalManager *theManager = NULL;

// reference to the XMEndpoint
static XMEndPoint *callEndPoint = NULL;

// reference to the H.323 Endpoint
static XMH323EndPoint *h323EndPoint = NULL;

// reference to the SIP Endpoint
static XMSIPEndPoint *sipEndPoint = NULL;

void _XMInitSubsystem(const char *pTracePath)
{
	if(theManager == NULL)
	{
		XMOpalManager::InitOpal(pTracePath);
		
		theManager = new XMOpalManager;
		theManager->Initialise();
		
		callEndPoint = theManager->CallEndPoint();
		h323EndPoint = theManager->H323EndPoint();
		sipEndPoint = theManager->SIPEndPoint();
		
		XMSoundChannel::Init();
	}
}

#pragma mark -
#pragma mark General Setup functions

void _XMSetUserName(const char *string)
{
	theManager->SetUserName(string);
}

const char *_XMGetUserName()
{
	return theManager->GetDefaultUserName();
}

#pragma mark -
#pragma mark Network Setup functions

void _XMSetBandwidthLimit(unsigned limit)
{
	XMOpalManager::SetBandwidthLimit(limit);
}

void _XMResetAvailableBandwidth()
{
	XMOpalManager::ResetAvailableBandwidth();
}

void _XMSetSTUNServer(const char *address)
{
	PString str = address;
	theManager->XMSetSTUNServer(str);
}

void _XMSetTranslationAddress(const char *a)
{
	PString str = a;
	theManager->SetTranslationAddress(str);
}

void _XMSetPortRanges(unsigned int udpPortMin, 
					  unsigned int udpPortMax, 
					  unsigned int tcpPortMin, 
					  unsigned int tcpPortMax,
					  unsigned int rtpPortMin,
					  unsigned int rtpPortMax)
{
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

void _XMSetAudioBufferSize(unsigned size)
{
	// currently not enabled
	//callEndPoint->SetSoundChannelBufferDepth(size);
}

void _XMStopAudio()
{
	XMSoundChannel::StopChannels();
}

#pragma mark -
#pragma mark Video functions

void _XMSetEnableVideo(bool enableVideo)
{
	callEndPoint->SetEnableVideo(enableVideo);
}

void _XMSetEnableH264LimitedMode(bool enableH264LimitedMode)
{
	_XMSetH264EnableLimitedMode(enableH264LimitedMode);
}

#pragma mark -
#pragma mark codec functions

void _XMSetCodecs(const char * const * orderedCodecs, unsigned orderedCodecCount,
				  const char * const * disabledCodecs, unsigned disabledCodecCount)
{
	PStringArray orderedCodecsArray = PStringArray(orderedCodecCount, orderedCodecs, TRUE);
	PStringArray disabledCodecsArray = PStringArray(disabledCodecCount, disabledCodecs, TRUE);
	
	// these codecs are currently disabled by default
	disabledCodecsArray.AppendString("DUMMY");
	
	theManager->SetMediaFormatMask(disabledCodecsArray);
	theManager->SetMediaFormatOrder(orderedCodecsArray);
}

#pragma mark -
#pragma mark H.323 Functions

bool _XMEnableH323Listeners(bool flag)
{
	return h323EndPoint->EnableListeners(flag);
}

bool _XMIsH323Enabled()
{
	return h323EndPoint->IsListening();
}

void _XMSetH323Functionality(bool enableFastStart, bool enableH245Tunnel)
{
	h323EndPoint->DisableFastStart(!enableFastStart);
	h323EndPoint->DisableH245Tunneling(!enableH245Tunnel);
}

XMGatekeeperRegistrationFailReason _XMSetGatekeeper(const char *address, 
													const char *gkUsername, 
													const char *phoneNumber,
													const char *password)
{
	return h323EndPoint->SetGatekeeper(address, gkUsername, phoneNumber, password);
}

bool _XMIsRegisteredAtGatekeeper()
{
	return h323EndPoint->IsRegisteredWithGatekeeper();
}

void _XMCheckGatekeeperRegistration()
{
	h323EndPoint->CheckGatekeeperRegistration();
}

#pragma mark -
#pragma mark SIP Setup Functions

bool _XMEnableSIPListeners(bool flag)
{
	return sipEndPoint->EnableListeners(flag);
}

bool _XMIsSIPEnabled()
{
	return sipEndPoint->IsListening();
}

void _XMSetSIPProxy(const char *host,
					const char *username,
					const char *password)
{
	sipEndPoint->SetProxy(host, username, password);
}

void _XMPrepareRegistrarSetup()
{
	sipEndPoint->PrepareRegistrarSetup();
}

void _XMUseRegistrar(const char *host,
					 const char *username,
					 const char *authorizationUsername,
					 const char *password)
{
	sipEndPoint->UseRegistrar(host, username, authorizationUsername, password);
}

void _XMFinishRegistrarSetup()
{
	sipEndPoint->FinishRegistrarSetup();
}

#pragma mark -
#pragma mark Call Management functions

unsigned _XMInitiateCall(XMCallProtocol protocol, const char *remoteParty)
{	
	PString token;
	
	BOOL returnValue = callEndPoint->StartCall(protocol, remoteParty, token);
	
	if(returnValue == TRUE)
	{
		return token.AsUnsigned();
	}
	else
	{
		return 0;
	}
}

void _XMAcceptIncomingCall(unsigned callID)
{
	//PString callToken = PString(callID);
	callEndPoint->AcceptIncomingCall();
}

void _XMRejectIncomingCall(unsigned callID)
{
	//PString callToken = PString(callID);
	callEndPoint->RejectIncomingCall();
}

void _XMClearCall(unsigned callID)
{
	PString callToken = PString(callID);
	callEndPoint->ClearCall(callToken);
}

void _XMGetCallInformation(unsigned callID,
						   const char** remoteName, 
						   const char** remoteNumber,
						   const char** remoteAddress, 
						   const char** remoteApplication)
{
	PString nameStr;
	PString numberStr;
	PString addressStr;
	PString appStr;
	
	theManager->GetCallInformation(nameStr, numberStr, addressStr, appStr);
	
	*remoteName = nameStr;
	*remoteNumber = numberStr;
	*remoteAddress = addressStr;
	*remoteApplication = appStr;
}

void _XMGetCallStatistics(unsigned callID,
						  XMCallStatisticsRecord *callStatistics)
{
	theManager->GetCallStatistics(callStatistics);
}

#pragma mark -
#pragma mark InCall Functions

bool _XMSendUserInputTone(unsigned callID, const char tone)
{
	PString callIDString = PString(callID);
	return callEndPoint->SendUserInputTone(callIDString, tone);
}

bool _XMSendUserInputString(unsigned callID, const char *string)
{
	PString callIDString = PString(callID);
	return callEndPoint->SendUserInputString(callIDString, string);
}

bool _XMStartCameraEvent(unsigned callID, XMCameraEvent cameraEvent)
{
	PString callIDString = PString(callID);
	return callEndPoint->StartCameraEvent(callIDString, cameraEvent);
}

void _XMStopCameraEvent(unsigned callID)
{
	PString callIDString = PString(callID);
	return callEndPoint->StopCameraEvent(callIDString);
}

#pragma mark -
#pragma mark MediaTransmitter Functions

void _XMSetTimeStamp(unsigned sessionID, unsigned timeStamp)
{
	XMTransmitterMediaPatch::SetTimeStamp(sessionID, timeStamp);
}

void _XMAppendData(unsigned sessionID, void *data, unsigned length)
{
	XMTransmitterMediaPatch::AppendData(sessionID, data, length);
}

void _XMSendPacket(unsigned sessionID, bool setMarkerBit)
{
	XMTransmitterMediaPatch::SendPacket(sessionID, setMarkerBit);
}

void _XMDidStopTransmitting(unsigned sessionID)
{
	XMTransmitterMediaPatch::HandleDidStopTransmitting(sessionID);
}

#pragma mark -
#pragma mark Message Logging

void _XMLogMessage(const char *message)
{
	XMOpalManager::LogMessage(message);
}
