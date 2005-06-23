/*
 * $Id: XMPrivate.h,v 1.6 2005/06/23 12:35:56 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_PRIVATE_H__
#define __XM_PRIVATE_H__

#import "XMCallManager.h"
#import "XMAudioManager.h"
#import "XMVideoManager.h"
#import "XMCallInfo.h"
#import "XMTypes.h"

@class XMLocalVideoView, XMCallInfo;

@interface XMCallManager(FrameworkMethods)

/**
 * This method gets called every time a subsystem setup thread
 * is invoked in order to allow XMCallManager to do the correct
 * setup in a separate thread.
 **/
- (void)_doSubsystemSetupWithPreferences:(XMPreferences *)preferences;

/**
 * This method gets called from the CallbackBridge.
 * The call happens NOT on the main thread.
 * Calls _handleIncomingCall: on the main thread
 **/
- (void)_handleIncomingCall:(unsigned)callID
				   protocol:(XMCallProtocol)protocol
				 remoteName:(NSString *)remoteName 
			   remoteNumber:(NSString *)remoteNumber
			  remoteAddress:(NSString *)remoteAddress
		  remoteApplication:(NSString *)remoteApplication;

/**
 * This method gets called from the CallbackBridge
 * every time a call is established. The call happens
 * not on the main thread.
 **/
- (void)_handleCallEstablished:(unsigned)callID;

/**
 * This method gets called from the CallbackBridge
 * every time a call is cleared. The call happens
 * not on the main thread.
 **/
- (void)_handleCallCleared:(unsigned)callID withCallEndReason:(XMCallEndReason)endReason;

/**
 * This method gets called from the CallbackBridge
 * every time a media stream is opened. The call
 * happens not on the main thread.
 **/
- (void)_handleMediaStreamOpened:(unsigned)callID 
				   isInputStream:(BOOL)isInputStream 
					 mediaFormat:(NSString *)mediaFormat;

/**
 * This method gets called from the CallbackBridge
 * every time a media stream is closed. The call
 * happens not on the main thread.
 **/
- (void)_handleMediaStreamClosed:(unsigned)callID
				   isInputStream:(BOOL)isInputStream
					 mediaFormat:(NSString *)mediaFormat;

#pragma mark H.323 callbacks

/**
 * This method gets called every time the framework registers at a gatekeeper
 * This Method gets not called on the main thread
 **/
- (void)_handleGatekeeperRegistration:(NSString *)gatekeeperName;

/**
 * This method gets called every time the framework unregisters at a gatekeeper
 * This method gets not called on the main thread
 **/
- (void)_handleGatekeeperUnregistration;

/**
 * This method gets called when an attempt to register at a gatekeeper failed.
 * This method is not called on the main thread
 **/
- (void)_handleGatekeeperRegistrationFailure;

@end

@interface XMVideoManager(FrameworkMethods)

- (void)_addLocalVideoView:(XMLocalVideoView *)view;
- (void)_removeLocalVideoView:(XMLocalVideoView *)view;
- (void)_drawToView:(XMLocalVideoView *)view;

- (BOOL)_handleVideoFrame:(void *)buffer width:(unsigned)width
				   height:(unsigned)height bytesPerPixel:(unsigned)bytesPerPixel;

@end

@interface XMCallInfo (FrameworkMethods)

- (id)_initWithCallID:(unsigned)callID 
			   protocol:(XMCallProtocol)protocol
			 remoteName:(NSString *)remoteName
		   remoteNumber:(NSString *)remoteNumber
		  remoteAddress:(NSString *)remoteAddress
	  remoteApplication:(NSString *)remoteApplication
			 callStatus:(XMCallStatus)status;

- (unsigned)_callID;

- (void)_setCallStatus:(XMCallStatus)status;
- (void)_setCallEndReason:(XMCallEndReason)endReason;
- (void)_setRemoteName:(NSString *)remoteName;
- (void)_setRemoteNumber:(NSString *)remoteNumber;
- (void)_setRemoteAddress:(NSString *)remoteAddress;
- (void)_setRemoteApplication:(NSString *)remoteApplication;
- (void)_setIncomingAudioCodec:(NSString *)codec;
- (void)_setOutgoingAudioCodec:(NSString *)codec;
- (void)_setIncomingVideoCodec:(NSString *)codec;
- (void)_setOutgoingVideoCodec:(NSString *)codec;

@end

#pragma mark private key declarations

/**
 * XMPreferences Keys
 **/

// General keys
extern NSString *XMKey_Preferences_UserName;
extern NSString *XMKey_Preferences_AutoAnswerCalls;

// Network-specific keys
extern NSString *XMKey_Preferences_BandwidthLimit;
extern NSString *XMKey_Preferences_UseAddressTranslation;
extern NSString *XMKey_Preferences_ExternalAddress;
extern NSString *XMKey_Preferences_TCPPortBase;
extern NSString *XMKey_Preferences_TCPPortMax;
extern NSString *XMKey_Preferences_UDPPortBase;
extern NSString *XMKey_Preferences_UDPPortMax;

// audio-specific keys
extern NSString *XMKey_Preferences_AudioCodecPreferenceList;
extern NSString *XMKey_Preferences_AudioBufferSize;

// video-specific keys
extern NSString *XMKey_Preferences_EnableVideoReceive;
extern NSString *XMKey_Preferences_EnableVideoTransmit;
extern NSString *XMKey_Preferences_VideoFramesPerSecond;
extern NSString *XMKey_Preferences_VideoSize;
extern NSString *XMKey_Preferences_VideoCodecPreferenceList;

// H323-specific keys
extern NSString *XMKey_Preferences_EnableH323;
extern NSString *XMKey_Preferences_EnableH245Tunnel;
extern NSString *XMKey_Preferences_EnableFastStart;
extern NSString *XMKey_Preferences_UseGatekeeper;
extern NSString *XMKey_Preferences_GatekeeperAddress;
extern NSString *XMKey_Preferences_GatekeeperID;
extern NSString *XMKey_Preferences_GatekeeperUsername;
extern NSString *XMKey_Preferences_GatekeeperPhoneNumber;

// XMCodecListRecord key
extern NSString *XMKey_CodecListRecord_Identifier;
extern NSString *XMKey_CodecListRecord_IsEnabled;

/**
 * XMCodecManager keys
 **/
extern NSString *XMKey_CodecManager_CodecDescriptionsFilename;
extern NSString *XMKey_CodecManager_CodecDescriptionsFiletype;
extern NSString *XMKey_CodecManager_AudioCodecs;
extern NSString *XMKey_CodecManager_VideoCodecs;

/**
 * Exception reasons
 **/
extern NSString *XMExceptionReason_InvalidParameterMustNotBeNil;
extern NSString *XMExceptionReason_UnsupportedCoder;
extern NSString *XMExceptionReason_CallManagerInvalidActionWhileOffline;
extern NSString *XMExceptionReason_CallManagerInvalidActionWhileSubsystemSetup;
extern NSString *XMExceptionReason_CallManagerInvalidActionWhileInCall;
extern NSString *XMExceptionReason_CallManagerInvalidActionWhileNotInCall;
extern NSString *XMExceptionReason_CallManagerCallEstablishedInternalConsistencyFailure;
extern NSString *XMexceptionReason_CallManagerCallClearedInternalConsistencyFailure;
extern NSString *XMExceptionReason_CodecManagerInternalConsistencyFailure;

#endif // __XM_PRIVATE_H__
