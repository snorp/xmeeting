/*
 * $Id: XMBridge.h,v 1.10 2005/10/17 12:57:53 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

/**
 * The purpose of XMBridge is to provide a clean bridge between
 * the objective-c world using the Cocoa framework and the c++ world,
 * using PWLib / OPAL.
 *
 * Mixing the two languages itself isn't the problem, all one has to do
 * is to use objective-c++. However, objective-c++ itself looks quite upgly
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
void _XMInitSubsystem();

/**
 * Used by XMCallManager to allow preferences initialization
 * in a separate thread
 **/
//void initiateSubsystemSetup(void *preferences);

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

#pragma mark Video Setup Functions

/**
 * Sets whether we are able to send / receive video
 **/
void _XMSetVideoFunctionality(bool receiveVideo, bool transmitVideo);

#pragma mark Codec Functions

/**
 * disables the codecs as listed in the array of strings
 **/
void _XMSetDisabledCodecs(const char * const * codecs, unsigned codecCount);

/**
 * Maintains the codec preference order as listed in the array of strings
 **/
void _XMSetCodecOrder(char const * const * codecs, unsigned codecCount);

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
													const char *identifier, 
													const char *username, 
													const char *phoneNumber);

/**
 * Checks whether we still are registered at the gatekeeper or not.
 **/
void _XMCheckGatekeeperRegistration();

#pragma mark SIP Setup Functions

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

#pragma mark MediaTransmitter Functions

void _XMSetTimeStamp(unsigned sessionID, unsigned timeStamp);
void _XMAppendData(unsigned sessionID, void *data, unsigned length);
void _XMSendPacket(unsigned sessionID, bool setMarkerBit);
void _XMDidStopTransmitting(unsigned sessionID);

#pragma mark Constants

/**
 * Device Names used within OPAL
 **/
#define XMSoundChannelDevice "XMSoundChannelDevice"

#ifdef __cplusplus
}
#endif

#endif // __XM_BRIDGE_H__