/*
 * $Id: XMBridge.cpp,v 1.1 2005/02/11 12:58:44 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#include <ptlib.h>

#include "XMBridge.h"
#include "XMProcess.h"

#include "XMOpalManager.h"
#include "XMPCSSEndPoint.h"
#include "XMVolumeControl.h"

using namespace std;

// reference to the default PProcess
static XMProcess *theProcess = NULL;
static XMOpalManager *theManager = NULL;

// required to implement the volume control
static XMSoundChannel *playerChannel = NULL;
static XMSoundChannel *recorderChannel = NULL;

void initOPAL()
{
	if(theProcess == NULL)
	{
		PProcess::PreInitialise(0, 0, 0);
		theProcess = new XMProcess;
		
		/* temporarily initialise PTracing */
		PTrace::Initialise(5, "/tmp/XMeeting.log", PTrace::Timestamp|PTrace::Thread|PTrace::FileAndLine);
		theManager = new XMOpalManager;
		theManager->Initialise();
		
		/* workaround for the lack of useable volume control in OPAL's PCSSEndPoint */
		playerChannel = new XMSoundChannel(theManager->CurrentPCSSEndPoint()->GetSoundChannelPlayDevice(), PSoundChannel::Player, 1, 8000, 16);
		recorderChannel = new XMSoundChannel(theManager->CurrentPCSSEndPoint()->GetSoundChannelRecordDevice(), PSoundChannel::Recorder, 1, 8000, 16);
	}
}

bool startH323Listeners(unsigned listenerPort)
{
	H323EndPoint *h323EP = theManager->CurrentH323EndPoint();
	
	return h323EP->StartListeners(psprintf("tcp$*:%u", listenerPort));
}

void stopH323Listeners()
{
	// currently not implemented
}

bool isH323Listening()
{
	//not impemented yet
	return false;
}

#pragma mark Call Management functions

void setAcceptCall(bool acceptFlag)
{	
	theManager->CurrentPCSSEndPoint()->SetAcceptIncomingCall(acceptFlag);
}

void setUserName(const char *string)
{
	theManager->SetDefaultUserName(string);
}

const char *getUserName()
{
	return theManager->GetDefaultUserName();
}

void setPortRanges(unsigned int udpPortMin, 
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

const char **getAudioInputDevices()
{
	PStringList devices = PSoundChannel::GetDeviceNames(PSoundChannel::Recorder);
	PINDEX count = devices.GetSize();
	PINDEX i;
	
	//allocating the correct memory
	const char **basePtr = new const char*[count + 1];
	
	for(i = 0; i < count; i++)
	{
		PString *str = (PString *)devices.GetAt(i);
		char *ptr = new char[str->GetLength()];
		strcpy(ptr, *str);
		
		basePtr[i] = ptr;
	}
	
	// terminating the array
	basePtr[count] = NULL;
	
	return basePtr;
}

void getDefaultAudioInputDevice(char *buffer)
{
	// Since the device is obtained as call-by-value, we have to do a copy
	// so that the buffer isn't destroyed at the end of the method
	// We explicitly assume that the buffer's length is 64 chars
	
	PString str = PSoundChannel::GetDefaultDevice(PSoundChannel::Recorder);
	strncpy(buffer, str, 64);
	buffer[63] = '\0';
}

const char **getAudioOutputDevices()
{
	PStringList devices = PSoundChannel::GetDeviceNames(PSoundChannel::Player);
	PINDEX count = devices.GetSize();
	PINDEX i;
	
	//allocating the correct memory
	const char **basePtr = new const char*[count + 1];
	
	for(i = 0; i < count; i++)
	{
		PString *str = (PString *)devices.GetAt(i);
		char *ptr = new char[str->GetLength()];
		strcpy(ptr, *str);
		
		basePtr[i] = ptr;
	}
	
	// terminating the array
	basePtr[count] = NULL;
	
	return basePtr;
}
 
void getDefaultAudioOutputDevice(char *buffer)
{
	// Since the device is obtained as call-by-value, we have to do a copy
	// so that the buffer isn't destroyed at the end of the method
	// We explicitly assume that the buffer's length is 64 chars
	PString str = PSoundChannel::GetDefaultDevice(PSoundChannel::Player);
	strncpy(buffer, str, 64);
	buffer[63] = '\0';
}

// The underlying system is call-by-reference
const char *getSelectedAudioInputDevice()
{
	return theManager->CurrentPCSSEndPoint()->GetSoundChannelRecordDevice();
}

bool setSelectedAudioInputDevice(const char *device)
{
	XMPCSSEndPoint *pcssEP = theManager->CurrentPCSSEndPoint();
	bool result = pcssEP->SetSoundChannelRecordDevice(device);
	
	// deleting the old instance of recorderChannel and replacing with a new one.
	delete recorderChannel;
	recorderChannel = new XMSoundChannel(pcssEP->GetSoundChannelRecordDevice(), PSoundChannel::Recorder, 1, 8000, 16);
	
	return result;
}

// The underlying system is call-by-reference
const char *getSelectedAudioOutputDevice()
{
	return theManager->CurrentPCSSEndPoint()->GetSoundChannelPlayDevice();
}

bool setSelectedAudioOutputDevice(const char *device)
{
	XMPCSSEndPoint *pcssEP = theManager->CurrentPCSSEndPoint();
	bool result = pcssEP->SetSoundChannelPlayDevice(device);
	
	delete playerChannel;
	playerChannel = new XMSoundChannel(pcssEP->GetSoundChannelPlayDevice(), PSoundChannel::Player, 1, 8000, 16);
	
	return result;
}

unsigned getAudioInputVolume()
{
	unsigned vol;
	recorderChannel->GetVolume(vol);
	
	return vol;
}

bool setAudioInputVolume(unsigned value)
{
	return recorderChannel->SetVolume(value);
}

unsigned getAudioOutputVolume()
{
	unsigned vol;
	playerChannel->GetVolume(vol);
	
	return vol;
}

bool setAudioOutputVolume(unsigned value)
{
	return playerChannel->SetVolume(value);
}

#pragma mark H.323 Functions

void setEnableFastStart(bool flag)
{
	theManager->CurrentH323EndPoint()->DisableFastStart(!flag);
}

void setEnableH245Tunnel(bool flag)
{
	theManager->CurrentH323EndPoint()->DisableH245Tunneling(!flag);
}

void setGatekeeper(const char *address, const char *identifier, const char *gkUsername, const char *phoneNumber)
{
	H323EndPoint *h323EP = theManager->CurrentH323EndPoint();
	
	if(identifier != NULL || address != NULL)
	{
		h323EP->UseGatekeeper(address, identifier);
	}
	else
	{
		h323EP->RemoveGatekeeper();
	}
}

