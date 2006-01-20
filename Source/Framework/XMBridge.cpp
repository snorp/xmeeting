/*
 * $Id: XMBridge.cpp,v 1.17 2006/01/20 17:17:03 hfriederich Exp $
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
#include "XMSoundChannel.h"
#include "XMTransmitterMediaPatch.h"

using namespace std;

// reference to the active OPAL manager.
static XMOpalManager *theManager = NULL;

// reference to the XMEndpoint
static XMEndPoint *callEndPoint = NULL;

// reference to the H.323 Endpoint
static XMH323EndPoint *h323EndPoint = NULL;

void _XMInitSubsystem()
{
	if(theManager == NULL)
	{
		XMOpalManager::InitOpal();
		
		theManager = new XMOpalManager;
		theManager->Initialise();
		
		callEndPoint = theManager->CallEndPoint();
		h323EndPoint = theManager->H323EndPoint();
		
		XMSoundChannel::Init();
	}
}

#pragma mark General Setup functions

void _XMSetUserName(const char *string)
{
	theManager->SetUserName(string);
}

const char *_XMGetUserName()
{
	return theManager->GetDefaultUserName();
}

#pragma mark Network Setup functions

void _XMSetBandwidthLimit(unsigned limit)
{
	theManager->SetBandwidthLimit(limit);
}

unsigned _XMGetVideoBandwidthLimit()
{
	return theManager->GetVideoBandwidthLimit();
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

#pragma mark Audio Functions

void setSelectedAudioInputDevice(unsigned int deviceID)
{
	XMSoundChannel::SetRecordDevice(deviceID);
}

void setMuteAudioInputDevice(bool muteFlag)
{
	XMSoundChannel::SetRecordDeviceMuted(muteFlag);
}

void setSelectedAudioOutputDevice(unsigned int deviceID)
{
	XMSoundChannel::SetPlayDevice(deviceID);
}

void setMuteAudioOutputDevice(bool muteFlag)
{
	XMSoundChannel::SetPlayDeviceMuted(muteFlag);
}

void _XMSetAudioBufferSize(unsigned size)
{
	// currently not enabled
	//callEndPoint->SetSoundChannelBufferDepth(size);
}

#pragma mark Video functions

void _XMSetEnableVideo(bool enableVideo)
{
	callEndPoint->SetEnableVideo(enableVideo);
}

void _XMSetEnableH264LimitedMode(bool enableH264LimitedMode)
{
	XMTransmitterMediaPatch::SetH264EnableLimitedMode(enableH264LimitedMode);
}

#pragma mark codec functions

void _XMSetCodecs(const char * const * orderedCodecs, unsigned orderedCodecCount,
				  const char * const * disabledCodecs, unsigned disabledCodecCount)
{
	PStringArray orderedCodecsArray = PStringArray(orderedCodecCount, orderedCodecs, TRUE);
	PStringArray disabledCodecsArray = PStringArray(disabledCodecCount, disabledCodecs, TRUE);
	
	// these codecs are currently disabled by default
	disabledCodecsArray.AppendString("G.726-16k");
	disabledCodecsArray.AppendString("G.726-24k");
	disabledCodecsArray.AppendString("G.726-32k");
	disabledCodecsArray.AppendString("G.726-40k");
	disabledCodecsArray.AppendString("SpeexNarrow-18.2k");
	disabledCodecsArray.AppendString("SpeexNarrow-5.95k");
	disabledCodecsArray.AppendString("SpeexNarrow-8k");
	disabledCodecsArray.AppendString("SpeexNarrow-11k");
	disabledCodecsArray.AppendString("SpeexNarrow-15k");
	disabledCodecsArray.AppendString("SpeexWide-20.6k");
	disabledCodecsArray.AppendString("GSM-06.10");
	disabledCodecsArray.AppendString("iLBC-13k3");
	disabledCodecsArray.AppendString("iLBC-15k2");
	disabledCodecsArray.AppendString("LPC-10");
	disabledCodecsArray.AppendString("MS-GSM");
	disabledCodecsArray.AppendString("MS-IMA-ADPCM");
	
	theManager->SetMediaFormatMask(disabledCodecsArray);
	theManager->SetMediaFormatOrder(orderedCodecsArray);
}

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

XMGatekeeperRegistrationFailReason _XMSetGatekeeper(const char *address, const char *identifier, 
													const char *gkUsername, const char *phoneNumber,
													const char *password)
{
	return h323EndPoint->SetGatekeeper(address, identifier, gkUsername, phoneNumber, password);
}

void _XMCheckGatekeeperRegistration()
{
	h323EndPoint->CheckGatekeeperRegistration();
}

#pragma mark SIP Setup Functions

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
	
	h323EndPoint->GetCallInformation(nameStr, numberStr, addressStr, appStr);
	
	*remoteName = nameStr;
	*remoteNumber = numberStr;
	*remoteAddress = addressStr;
	*remoteApplication = appStr;
}

void _XMGetCallStatistics(unsigned callID,
						  XMCallStatisticsRecord *callStatistics)
{
	h323EndPoint->GetCallStatistics(callStatistics);
}

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
