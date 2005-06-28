/*
 * $Id: XMBridge.h,v 1.5 2005/06/28 20:41:06 hfriederich Exp $
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

#pragma mark Init & Startup/Stop functions

/** 
 * Calling this function initializes the whole OPAL system
 * and makes it ready to be used.
 * It is safe to call initOPAL() multiple times.
 **/
void initOPAL();

/**
 * Used by XMCallManager to allow preferences initialization
 * in a separate thread
 **/
void initiateSubsystemSetup(void *preferences);

#pragma mark Call Management functions

/**
 * This function causes the OPAL system to call the specified
 * remote party, using the specified protocol.
 * The return value is the callID for this call, or zero if the call
 * failed. A non-zero return value does not mean that the call was 
 * successful in itself, only that the attempt to call the remote
 * party was successful. The result of the call will then be reported
 * back through the CallbackBridge.
 **/
unsigned startCall(XMCallProtocol protocol, const char *remoteParty);

/**
 * Call this function if you want to accept an incoming call.
 * Note that calling this function is only valid if there is
 * a pending incoming call!
 **/
void setAcceptIncomingCall(unsigned callID, bool acceptFlag);

/**
 * Tells the OPAL system to clear an existing call
 **/
void clearCall(unsigned callID);

/**
 * This function provides additional information about the remote party. 
 * Note that calling this function is only safe when the call is established
 **/
void getCallInformation(unsigned callID,
						const char** remoteName, 
						const char** remoteNumber,
						const char** remoteAddress, 
						const char** remoteApplication);

#pragma mark General Setup Functions

/**
 * sets the user name to be used.
 **/
void setUserName(const char *string);

/**
 * Returns the current user name
 * The value is obtained call-by-reference.
 **/
const char *getUserName();

#pragma mark Network setup functions

/**
 * sets the bandwidth limit to the value as specified
 **/
void setBandwidthLimit(unsigned limit);

/**
 * defines which port ranges to use to establish
 * the media streams
 **/
void setPortRanges(unsigned int udpPortMin,
				   unsigned int udpPortMax,
				   unsigned int tcpPortMin,
				   unsigned int tcpPortMax,
				   unsigned int rtpPortMin,
				   unsigned int rtpPortMax);

/**
 * Sets the translation address (usually the NAT address)
 * to enable NAT-Tunneling
 **/
void setTranslationAddress(const char *address);

#pragma mark Audio Functions

// The underlying system is call-by-reference
const char *getSelectedAudioInputDevice();
bool setSelectedAudioInputDevice(const char *device);

// The underlying system is call-by-reference
const char *getSelectedAudioOutputDevice();
bool setSelectedAudioOutputDevice(const char *device);

unsigned getAudioBufferSize();
void setAudioBufferSize(unsigned value);

#pragma mark Video Setup Functions

/**
 * Sets whether we are able to send / receive video
 **/
void setVideoFunctionality(bool receiveVideo, bool transmitVideo);

#pragma mark Codec Functions

/**
 * disables the codecs as listed in the array of strings
 **/
void setDisabledCodecs(const char * const * codecs, unsigned codecCount);

/**
 * Maintains the codec preference order as listed in the array of strings
 **/
void setCodecOrder(char const * const * codecs, unsigned codecCount);

#pragma mark H.323 Setup Functions

/**
 * makes the h323 system listen and thereby ready for calls
 **/
bool enableH323Listeners(bool flag);
bool isH323Listening();

/**
 * enables/disables FastStart and H.245 tunneling through H.323
 **/
void setH323Functionality(bool enableFastStart, bool enableH245Tunnel);

/**
 * sets up the gatekeeper. If all variables are NULL, no gatekeeper is used
 **/
bool setGatekeeper(const char *address, const char *identifier, const char *gkUsername, const char *phoneNumber);

/**
 * Checks whether we still are registered at gatekeeper or not.
 **/
void checkGatekeeperRegistration();

#pragma mark SIP Setup Functions

#endif // __XM_BRIDGE_H__