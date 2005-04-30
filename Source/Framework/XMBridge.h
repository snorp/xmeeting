/*
 * $Id: XMBridge.h,v 1.2 2005/04/28 20:26:26 hfriederich Exp $
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
 * to PWLib. This approach does work around big hacks and has the
 * advantage that it generates a clear interface centered in one file
 * without adding too much overhead.
 * However, this apporach requires a good MemoryManagement policy in order not
 * to waste memory through leaks. Above each function is defined who is
 * responsible for the memory management if there is any memory to manage.
 **/

#include "XMTypes.h"

#pragma mark Init & Startup/Stop functions

/** 
 * Calling this function initializes the whole OPAL system
 * and makes it ready to be used.
 * It is safe to call initOPAL() multiple times.
 **/
void initOPAL();

/**
 * makes the h323 system listen and thereby ready for calls
 **/
bool startH323Listeners(unsigned listenerPort = 1720);

/**
 * stops the h323 system from being active
 **/
void stopH323Listeners();

bool isH323Listening();

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
 * Note that this information is only valid when the call is established.
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

/*
 * Returns the current user name
 * The value is obtained call-by-reference.
 */
const char *getUserName();

void setPortRanges(unsigned int udpPortMin,
				   unsigned int udpPortMax,
				   unsigned int tcpPortMin,
				   unsigned int tcpPortMax,
				   unsigned int rtpPortMin,
				   unsigned int rtpPortMax);

void setTranslationAddress(const char *address);

void setVideoFunctionality(bool receiveVideo, bool transmitVideo);

#pragma mark Audio Functions

// the pointer-array returned must explicitely be deleted by the caller
const char **getAudioInputDevices();

// copies a NULL-terminated-string into buffer
void getDefaultAudioInputDevice(char *buffer);

// the pointer-array returned must explicitely be deleted by the caller
const char **getAudioOutputDevices();

// copies a NULL-terminated-string into buffer
void getDefaultAudioOutputDevice(char *buffer);

// The underlying system is call-by-reference
const char *getSelectedAudioInputDevice();
bool setSelectedAudioInputDevice(const char *device);

// The underlying system is call-by-reference
const char *getSelectedAudioOutputDevice();
bool setSelectedAudioOutputDevice(const char *device);

unsigned getAudioInputVolume();
bool setAudioInputVolume(unsigned value);

unsigned getAudioOutputVolume();
bool setAudioOutputVolume(unsigned value);

#pragma mark H.323 Setup Functions

void setH323Functionality(bool enableFastStart, bool enableH245Tunnel);

bool setGatekeeper(const char *address, const char *identifier, const char *gkUsername, const char *phoneNumber);

#pragma mark SIP Setup Functions