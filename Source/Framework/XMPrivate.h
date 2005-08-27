/*
 * $Id: XMPrivate.h,v 1.9 2005/08/27 22:08:22 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_PRIVATE_H__
#define __XM_PRIVATE_H__

#import "XMTypes.h"
#import "XMCallManager.h"
#import "XMCallInfo.h"
#import "XMPreferences.h"
#import "XMPreferencesCodecListRecord.h"
#import "XMCodec.h"
#import "XMAudioManager.h"
#import "XMVideoManager.h"
#import "XMAddressBookRecordSearchMatch.h"
#import "XMGeneralPurposeURL.h"

@class XMLocalVideoView, XMCallInfo, ABPerson;

@interface XMCallManager (FrameworkMethods)

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
- (void)_handleGatekeeperRegistrationFailure:(XMGatekeeperRegistrationFailReason)reason;

@end

@interface XMCallInfo (FrameworkMethods)

- (id)_initWithCallID:(unsigned)callID
			 protocol:(XMCallProtocol)protocol
	   isOutgoingCall:(BOOL)isOutgoingCall
		   remoteName:(NSString *)remoteName
		 remoteNumber:(NSString *)remoteNumber
		remoteAddress:(NSString *)remoteAddress
	remoteApplication:(NSString *)remoteApplication
		   callStatus:(XMCallStatus)status;

- (unsigned)_callID;
- (void)_setCallID:(unsigned)theCallID;

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

- (XMCallStatistics *)_callStatistics;

@end

@interface XMPreferences (FrameworkMethods)

#define XM_VALUE_TEST_RESULT unsigned
#define XM_VALID_VALUE 0
#define XM_INVALID_KEY 1
#define XM_INVALID_VALUE_TYPE 2
+ (XM_VALUE_TEST_RESULT)_checkValue:(id)value forKey:(NSString *)key;
- (BOOL)_value:(id)value differsFromValueWithKey:(NSString *)key;

@end

@interface XMPreferencesCodecListRecord (FrameworkMethods)

- (id)_initWithIdentifier:(NSString *)identifier enabled:(BOOL)enabled;
- (id)_initWithDictionary:(NSDictionary *)dict;

@end

@interface XMCodec (FrameworkMethods)

- (id)_initWithDictionary:(NSDictionary *)dict;

- (id)_initWithIdentifier:(NSString *)identifier
					 name:(NSString *)name
				bandwidth:(NSString *)bandwidth
				  quality:(NSString *)quality;

@end

@interface XMVideoManager (FrameworkMethods)

- (void)_addLocalVideoView:(XMLocalVideoView *)view;
- (void)_removeLocalVideoView:(XMLocalVideoView *)view;
- (void)_drawToView:(XMLocalVideoView *)view;

- (BOOL)_handleVideoFrame:(void *)buffer width:(unsigned)width
				   height:(unsigned)height bytesPerPixel:(unsigned)bytesPerPixel;

@end

@interface XMAddressBookRecordSearchMatch (FrameworkMethods)

- (id)_initWithRecord:(ABPerson *)record propertyMatch:(XMAddressBookRecordPropertyMatch)propertyMatch;

@end

@interface XMGeneralPurposeURL (FrameworkMethods)

- (BOOL)_doesModifyPreferences:(XMPreferences *)preferences;
- (void)_modifyPreferences:(XMPreferences *)preferences;

@end

#pragma mark private key declarations

/**
 * XMCodecManager keys
 **/
extern NSString *XMKey_CodecManagerCodecDescriptionsFilename;
extern NSString *XMKey_CodecManagerCodecDescriptionsFiletype;
extern NSString *XMKey_CodecManagerAudioCodecs;
extern NSString *XMKey_CodecManagerVideoCodecs;

/**
 * Exception reasons
 **/
extern NSString *XMExceptionReason_InvalidParameterMustNotBeNil;
extern NSString *XMExceptionReason_InvalidParameterMustBeOfCorrectType;
extern NSString *XMExceptionReason_InvalidParameterMustBeValidKey;
extern NSString *XMExceptionReason_UnsupportedCoder;

extern NSString *XMExceptionReason_CallManagerInvalidActionWhileOffline;
extern NSString *XMExceptionReason_CallManagerInvalidActionWhileSubsystemSetup;
extern NSString *XMExceptionReason_CallManagerInvalidActionWhileInCall;
extern NSString *XMExceptionReason_CallManagerInvalidActionWhileNotInCall;
extern NSString *XMExceptionReason_CallManagerInvalidActionWhileH323Listening;
extern NSString *XMExceptionReason_CallManagerInvalidActionWhileH323Disabled;
extern NSString *XMExceptionReason_CallManagerInvalidActionWhileGatekeeperRegistered;
extern NSString *XMExceptionReason_CallManagerInvalidActionWhileGatekeeperDisabled;

extern NSString *XMExceptionReason_CallManagerInternalConsistencyFailureOnCallEstablished;
extern NSString *XMExceptionReason_CallManagerInternalConsistencyFailureOnCallCleared;
extern NSString *XMExceptionReason_CodecManagerInternalConsistencyFailure;

#endif // __XM_PRIVATE_H__
