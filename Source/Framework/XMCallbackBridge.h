/*
 * $Id: XMCallbackBridge.h,v 1.41 2008/10/12 12:24:12 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
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
	
#pragma mark -
#pragma mark Setup Related Callbacks

/**
 * Reports NAT-Type and External Address
 **/
void _XMHandleSTUNInformation(XMNATType natType,
							  const char *publicAddress);
	
#pragma mark -
#pragma mark Call Related Callbacks

/**
 * callback information when calling _XMInitiateCall()
 **/
void _XMHandleCallStartInfo(const char *callToken, XMCallEndReason endReason);
	
/**
 * Indicates that the outgoing call is ringing at the remote party
 **/
void _XMHandleCallIsAlerting(const char *callToken);

/**
 * If there is an incoming call and autoanswer is off,
 * this callback is called which forwards the request
 * to the Cocoa/Objective-C world
 **/
void _XMHandleIncomingCall(const char *callToken, 
                           XMCallProtocol protocol,
                           const char *remoteName, 
                           const char *remoteNumber, 
                           const char *remoteAddress,
                           const char *remoteApplication,
                           const char *localAddress);

/**
 * This function is called every time a call is established,
 * supplying the callToken and remote party information
 **/
void _XMHandleCallEstablished(const char *callToken,
                              const char *remoteName,
                              const char *remoteNumber,
                              const char *remoteAddress,
                              const char *remoteApplication,
                              const char *localAddress);

/**
 * This function is called every time a call was ended,
 * supplying the callToken and the CallEndReason.
 **/
void _XMHandleCallCleared(const char *callToken, XMCallEndReason callEndReason);

/**
 * Reports the local interface used when the call is released
 **/
void _XMHandleLocalAddress(const char *callToken, const char *localAddress);

/**
 * This function is called every time a new audio stream is opened.
 **/
void _XMHandleAudioStreamOpened(const char *callToken, const char *codec, bool isIncomingStream);

/**
 * This function is called every time a new video stream is opened.
 **/
void _XMHandleVideoStreamOpened(const char *callToken, const char *codec, 
                                XMVideoSize videoSize, 
                                bool isIncomingStream,
                                unsigned videoWidth,
                                unsigned videoHeight);

/**
 * This function is called every time an existing audio stream is closed.
 **/
void _XMHandleAudioStreamClosed(const char *callToken, bool isIncomingStream);

/**
 * This function is called every time an existing video stream is closed.
 **/
void _XMHandleVideoStreamClosed(const char *callToken, bool IsIncomingStream);

/**
 * This function is called every time a FECC channel is opened
 **/
void _XMHandleFECCChannelOpened();

#pragma mark -
#pragma mark MediaTransmitter & MediaReceiver callbacks

/**
 * Instructs the MediaTransmitter to start sending video data
 **/
void _XMStartMediaTransmit(unsigned sessionID, XMCodecIdentifier codec, 
                           XMVideoSize videoSize, unsigned maxFramesPerSecond,
                           unsigned maxBitrate, unsigned keyframeInterval, unsigned flags);

/**
 * Instructs the MediaTransmitter to stop sending video data
 **/
void _XMStopMediaTransmit(unsigned sessionID);

/**
 * Tells the MediaReceiver to prepare for incoming data with codec,
 * RTP payload type and the sessionID
 **/
void _XMStartMediaReceiving(unsigned sessionID, XMCodecIdentifier codec);

/**
 * Tells the MediaReceiver that the media stream for the session has
 * ended
 **/
void _XMStopMediaReceiving(unsigned sessionID);

/**
 * Forwads the received packet to the MediaReceiver
 **/
bool _XMProcessFrame(const char *callToken, unsigned sessionID, void *packet, unsigned length);

/**
 * Forwards a received SPS atom of a H.264 stream to the MediaReceiver
 **/
void _XMHandleH264SPSAtomData(void *data, unsigned length);

/**
 * Forwards a received PPS atom of a H.264 stream to the MediaReceiver
 **/
void _XMHandleH264PPSAtomData(void *data, unsigned length);

/**
 * Forwards the OpalVideoUpdatePicture media command to the
 * MediaTransmitter
 **/
void _XMUpdatePicture();

/**
 * Adjusts the bandwidth limit to use
 **/
void _XMSetMaxVideoBitrate(unsigned maxVideoBitrate);

/**
 * Reports the audio level of the recorder stream
 **/
void _XMHandleAudioInputLevel(double level);

/**
 * Reports the audio level of the player stream
 **/
void _XMHandleAudioOutputLevel(double level);

/**
 * Reports that the audio test stopped
 **/
void _XMHandleAudioTestEnd();

#pragma mark -
#pragma mark H.323 specific callbacks

void _XMHandleGatekeeperRegistration(const char *gatekeeperName, const char *gatekeeperAliases);
void _XMHandleGatekeeperRegistrationFailure(XMGatekeeperRegistrationStatus failure);
void _XMHandleGatekeeperUnregistration();
void _XMHandleGatekeeperRegistrationComplete();

#pragma mark -
#pragma mark SIP specific callbacks

void _XMHandleSIPRegistration(const char *domain, const char *username, const char *aor);
void _XMHandleSIPUnregistration(const char *aor);
void _XMHandleSIPRegistrationFailure(const char *domain, const char *username,
                                     const char *registration, XMSIPStatusCode failReason);
void _XMHandleSIPRegistrationComplete();

#ifdef __cplusplus
}
#endif

#endif // __XM_CALLBACK_BRIDGE_H__
