/*
 * $Id: XMCallbackBridge.h,v 1.8 2005/10/11 09:03:10 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CALLBACK_BRIDGE_H__
#define __XM_CALLBACK_BRIDGE_H__

#include "XMTypes.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * This file provides the callbacks that may be called by the
 * OPAL subsystem. These callbacks are then forwarded into
 * the Cocoa/Objective-C world.
 *
 * These callbacks are most often NOT called within the main
 * thread. Necessary thread synchronization has to be done
 * within the Cocoa/Objective-C layer, where the framework supports
 * such synchronization in an easy fashion
 **/

/**
 * initializes the callbacks in order to work properly
 **/
void initializeCallbacks();

/**
 * initiates the subsystem setup
 **/
void doSubsystemSetup(void *preferences);

/**
 * If there is an incoming call and autoanswer is off,
 * this callback is called which forwards the request
 * to the Cocoa/Objective-C world
 **/
void noteIncomingCall(unsigned callID, 
					  XMCallProtocol protocol,
					  const char *remoteName, 
					  const char *remoteNumber, 
					  const char *remoteAddress,
					  const char *remoteApplication);

/**
 * This function is called every time a call is established,
 * supplying the callID
 **/
void noteCallEstablished(unsigned callID);

/**
 * This function is called every time a call was ended,
 * supplying the callID and the CallEndReason.
 **/
void noteCallCleared(unsigned callID, XMCallEndReason callEndReason);

/**
 * This function is called every time a new media stream is opened.
 **/
void noteMediaStreamOpened(unsigned callID, bool isInputStream, const char *mediaFormat);

/**
 * This function is called every time an existing media stream is closed.
 * Note that the callID currently is set constantly to 0.
 **/
void noteMediaStreamClosed(unsigned callID, bool isInputStream, const char *mediaFormat);

/**
 * Forwads the received packet to the MediaReceiver
 **/
bool XMProcessPacket(void *packet, unsigned length, unsigned sessionID);

#pragma mark H.323 specific callbacks

void noteGatekeeperRegistration(const char *gatekeeperName);
void noteGatekeeperUnregistration();
void noteGatekeeperRegistrationFailure(XMGatekeeperRegistrationFailReason reason);

#ifdef __cplusplus
}
#endif

#endif // __XM_CALLBACK_BRIDGE_H__
