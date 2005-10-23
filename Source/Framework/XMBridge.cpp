/*
 * $Id: XMBridge.cpp,v 1.13 2005/10/23 19:59:00 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
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
	theManager->SetDefaultUserName(string);
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

#pragma mark codec functions

void _XMSetDisabledCodecs(const char * const * codecs, unsigned codecCount)
{
	PStringArray codecsArray = PStringArray(codecCount, codecs, TRUE);
	
	// these codecs are currently disabled by default
	codecsArray.AppendString("*g.726*");
	codecsArray.AppendString("*gsm*");
	codecsArray.AppendString("*ilbc*");
	codecsArray.AppendString("*speex*");
	codecsArray.AppendString("*lpc*");
	codecsArray.AppendString("*ms*");
	
	theManager->SetMediaFormatMask(codecsArray);
}

void _XMSetCodecOrder(const char * const * codecs, unsigned codecCount)
{
	PStringArray codecsArray = PStringArray(codecCount, codecs, TRUE);
	
	theManager->SetMediaFormatOrder(codecsArray);
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

XMGatekeeperRegistrationFailReason _XMSetGatekeeper(const char *address, const char *identifier, const char *gkUsername, const char *phoneNumber)
{
	return h323EndPoint->SetGatekeeper(address, identifier, gkUsername, phoneNumber);
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
