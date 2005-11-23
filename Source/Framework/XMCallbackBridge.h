/*
 * $Id: XMCallbackBridge.h,v 1.14 2005/11/23 22:25:30 hfriederich Exp $
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
 * Indicates that the outgoing call is ringing at the remote party
 **/
void _XMHandleCallIsAlerting(unsigned callID);

/**
 * If there is an incoming call and autoanswer is off,
 * this callback is called which forwards the request
 * to the Cocoa/Objective-C world
 **/
void _XMHandleIncomingCall(unsigned callID, 
						   XMCallProtocol protocol,
						   const char *remoteName, 
						   const char *remoteNumber, 
						   const char *remoteAddress,
						   const char *remoteApplication);

/**
 * This function is called every time a call is established,
 * supplying the callID
 **/
void _XMHandleCallEstablished(unsigned callID, bool isIncomingCall);

/**
 * This function is called every time a call was ended,
 * supplying the callID and the CallEndReason.
 **/
void _XMHandleCallCleared(unsigned callID, XMCallEndReason callEndReason);

/**
 * This function is called every time a new media stream is opened.
 **/
void _XMHandleMediaStreamOpened(unsigned callID, bool isIncomingStream, const char *mediaFormat);

/**
 * This function is called every time an existing media stream is closed.
 * Note that the callID currently is set constantly to 0.
 **/
void _XMHandleMediaStreamClosed(unsigned callID, bool isIncomingStream, const char *mediaFormat);

#pragma mark MediaTransmitter & MediaReceiver callbacks

/**
 * Instructs the MediaTransmitter to start sending video data
 **/
void _XMStartMediaTransmit(XMCodecIdentifier codec, XMVideoSize videoSize, unsigned maxFramesPerSecond,
						   unsigned maxBitrate, unsigned sessionID);

/**
 * Instructs the MediaTransmitter to stop sending video data
 **/
void _XMStopMediaTransmit(unsigned sessionID);

/**
 * Tells the MediaReceiver to prepare for incoming data with codec,
 * RTP payload type and the sessionID
 **/
void _XMStartMediaReceiving(XMCodecIdentifier codec, unsigned payloadType, XMVideoSize videoSize, unsigned sessionID);

/**
 * Tells the MediaReceiver that the media stream for the session has
 * ended
 **/
void _XMStopMediaReceiving(unsigned sessionID);

/**
 * Forwads the received packet to the MediaReceiver
 **/
bool _XMProcessPacket(void *packet, unsigned length, unsigned sessionID);

/**
 * Forwards the OpalVideoUpdatePicture media command to the
 * MediaTransmitter
 **/
void _XMUpdatePicture();

#pragma mark H.323 specific callbacks

void _XMHandleGatekeeperRegistration(const char *gatekeeperName);
void _XMHandleGatekeeperUnregistration();

#ifdef __cplusplus
}
#endif

#endif // __XM_CALLBACK_BRIDGE_H__
