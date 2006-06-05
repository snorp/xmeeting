/*
 * $Id: XMBridge.h,v 1.24 2006/06/05 22:24:08 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

/**
 * The purpose of XMBridge is to provide a clean bridge between
 * the objective-c world using the Cocoa framework and the c++ world,
 * using PWLib / OPAL.
 *
 * Mixing the two languages itself isn't the problem, all one has to do
 * is to use objective-c++. However, objective-c++ itself looks quite ugly
 * and its usage should me minimized.
 * The real problem is the inclusion of headers. PWLib does redefine a
 * couple of stuff defined in Cocoa and adjusting the headers in PWLib
 * is just too painful.
 *
 * Therefore, this file provides a couple of c++ functions which can
 * safely be called by the Cocoa-part of the code and which bridge over
 * to PWLib/OPAL. This approach does work around big hacks and has the
 * advantage that it generates a clear interface centered in one file
 * without adding too much overhead.
 * However, this apporach requires a good MemoryManagement policy in order not
 * to leak memory. Above each function is defined who is
 * responsible for the memory management if there is any memory to manage.
 **/

#ifndef __XM_BRIDGE_H__
#define __XM_BRIDGE_H__

#include "XMTypes.h"

#ifdef __cplusplus
extern "C" {
#endif

#pragma mark Init & Startup/Stop functions

/** 
 * Calling this function initializes the whole OPAL system
 * and makes it ready to be used.
 * It is safe to call initOPAL() multiple times.
 **/
void _XMInitSubsystem(const char *pTracePath);

#pragma mark General Setup Functions

/**
 * sets the user name to be used.
 **/
void _XMSetUserName(const char *string);

/**
 * Returns the current user name
 * The value is obtained call-by-reference.
 **/
const char *_XMGetUserName();

#pragma mark Network setup functions

/**
 * sets the bandwidth limit to the value as specified
 **/
void _XMSetBandwidthLimit(unsigned limit);

/**
 * Resets the available bandwidth to the default value
 * after a call has finished
 **/
void _XMResetAvailableBandwidth();

/**
 * Sets the STUN Server to be used.
 * The results of this operation are reported back
 * separately
 **/
void _XMSetSTUNServer(const char *address);

/**
 * Causes the System to update it's STUN information
 * (NAT-Type, external address)
 **/
void _XMUpdateSTUNInformation();

/**
 * Sets the translation address (usually the NAT address)
 * to enable NAT-Tunneling
 **/
void _XMSetTranslationAddress(const char *address);

/**
 * defines which port ranges to use to establish
 * the media streams
 **/
void _XMSetPortRanges(unsigned int udpPortMin,
					  unsigned int udpPortMax,
					  unsigned int tcpPortMin,
					  unsigned int tcpPortMax,
					  unsigned int rtpPortMin,
					  unsigned int rtpPortMax);

#pragma mark Audio Functions

// The underlying system is call-by-reference
//const char *getSelectedAudioInputDevice();
//bool setSelectedAudioInputDevice(const char *device);
void setSelectedAudioInputDevice(unsigned int device);
void setMuteAudioInputDevice(bool muteFlag);

// The underlying system is call-by-reference
//const char *getSelectedAudioOutputDevice();
//bool setSelectedAudioOutputDevice(const char *device);
void setSelectedAudioOutputDevice(unsigned int device);
void setMuteAudioOutputDevice(bool muteFlag);

void _XMSetAudioBufferSize(unsigned value);
void _XMStopAudio();

#pragma mark Video Setup Functions

void _XMSetEnableVideo(bool enableVideo);

void _XMSetEnableH264LimitedMode(bool enableH264LimitedMode);

#pragma mark Codec Functions

/**
 * Sets the ordered & disabled codec lists appropriately
 **/
void _XMSetCodecs(const char * const * orderedCodecs, unsigned orderedCodecCount,
				  const char * const * disabledCodecs, unsigned disabledCodecCount);

#pragma mark H.323 Setup Functions

/**
 * makes the H.323 system listen and thereby ready for calls
 **/
bool _XMEnableH323Listeners(bool flag);

/**
 * Returns whether H.323 is currently enabled or not
 **/
bool _XMIsH323Enabled();

/**
 * enables/disables FastStart and H.245 tunneling through H.323
 **/
void _XMSetH323Functionality(bool enableFastStart, bool enableH245Tunnel);

/**
 * sets up the gatekeeper. If all variables are NULL, no gatekeeper is used
 **/
XMGatekeeperRegistrationFailReason _XMSetGatekeeper(const char *address, 
													const char *username, 
													const char *phoneNumber,
													const char *password);

/**
 * reports whether we are registered at a gk or not
 **/
bool _XMIsRegisteredAtGatekeeper();

/**
 * Checks whether we still are registered at the gatekeeper or not.
 **/
void _XMCheckGatekeeperRegistration();

#pragma mark SIP Setup Functions

bool _XMEnableSIPListeners(bool enable);

bool _XMIsSIPEnabled();

void _XMSetSIPProxy(const char *host,
					const char *username,
					const char *password);

void _XMPrepareRegistrarSetup();
void _XMUseRegistrar(const char *host,
					 const char *username,
					 const char *authorizationUsername,
					 const char *password);
void _XMFinishRegistrarSetup();

#pragma mark Call Management functions

 // This function causes the OPAL system to call the specified
 // remote party, using the specified protocol.
 // The return value is the callID for this call, or zero if the call
 // failed. A non-zero return value does not mean that the call was 
 // successful in itself, only that the attempt to call the remote
 // party was successful. The result of the call will then be reported
 // back through callbacks.
unsigned _XMInitiateCall(XMCallProtocol protocol, const char *remoteParty);

// Causes the OPAL system to accept the incoming call
void _XMAcceptIncomingCall(unsigned callID);

// Causes the OPAL system to reject the incomgin call
void _XMRejectIncomingCall(unsigned callID);

// Causes the OPAL system to clear the existing call
void _XMClearCall(unsigned callID);

// This function provides additional information about the remote party. 
//Note that calling this function is only safe when the call is established
void _XMGetCallInformation(unsigned callID,
						   const char** remoteName, 
						   const char** remoteNumber,
						   const char** remoteAddress, 
						   const char** remoteApplication);

// Provides the relevant statistics data
void _XMGetCallStatistics(unsigned callID,
						  XMCallStatisticsRecord *callStatistics);

#pragma mark InCall Functions

bool _XMSendUserInputTone(unsigned callID, const char tone);
bool _XMSendUserInputString(unsigned callID, const char *string);
bool _XMStartCameraEvent(unsigned callID, XMCameraEvent cameraEvent);
void _XMStopCameraEvent(unsigned callID);

#pragma mark MediaTransmitter Functions

void _XMSetTimeStamp(unsigned sessionID, unsigned timeStamp);
void _XMAppendData(unsigned sessionID, void *data, unsigned length);
void _XMSendPacket(unsigned sessionID, bool setMarkerBit);
void _XMDidStopTransmitting(unsigned sessionID);

#pragma mark MediaFormat Functions

unsigned _XMMaxMediaFormatsPerCodecIdentifier();
const char *_XMMediaFormatForCodecIdentifier(XMCodecIdentifier codecIdentifier);
const char *_XMMediaFormatForCodecIdentifierWithVideoSize(XMCodecIdentifier codecIdentifier,
														  XMVideoSize videoSize);

#pragma mark Constants

/**
 * Device Names used within OPAL
 **/
#define XMSoundChannelDevice "XMSoundChannelDevice"

#ifdef __cplusplus
}
#endif

#endif // __XM_BRIDGE_H__