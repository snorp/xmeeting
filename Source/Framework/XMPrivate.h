/*
 * $Id: XMPrivate.h,v 1.19 2005/11/23 19:28:44 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_PRIVATE_H__
#define __XM_PRIVATE_H__

#import "XMTypes.h"
#import "XMUtils.h"
#import "XMCallManager.h"
#import "XMOpalDispatcher.h"
#import "XMCallInfo.h"
#import "XMPreferences.h"
#import "XMPreferencesCodecListRecord.h"
#import "XMCodecManager.h"
#import "XMCodec.h"
#import "XMAudioManager.h"
#import "XMVideoManager.h"
#import "XMMediaTransmitter.h"
#import "XMMediaReceiver.h"
#import "XMVideoView.h"
#import "XMGeneralPurposeAddressResource.h"

extern unsigned _XMInitializedStatus;
extern XMUtils *_XMUtilsSharedInstance;
extern XMCallManager *_XMCallManagerSharedInstance;
extern XMCodecManager *_XMCodecManagerSharedInstance;
extern XMAudioManager *_XMAudioManagerSharedInstance;
extern XMVideoManager *_XMVideoManagerSharedInstance;
extern XMOpalDispatcher *_XMOpalDispatcherSharedInstance;
extern XMMediaTransmitter *_XMMediaTransmitterSharedInstance;
extern XMMediaReceiver *_XMMediaReceiverSharedInstance;

void _XMThreadExit();
void _XMCheckCloseStatus();

@class ABPerson, XMCallStatistics;

@interface XMUtils (FrameworkMethods)

- (id)_init;
- (void)_close;

@end

@interface XMCallManager (FrameworkMethods)

- (id)_init;
- (void)_close;

// Called when the OpalDispatcher did complete the
// subsystem setup end
- (void)_handleSubsystemSetupEnd;

// Called every time a call was succesfully initiated
// The CallManager takes ownership of this object
// without retaining it
- (void)_handleCallInitiated:(XMCallInfo *)call;

// Called every time initiating a call failed
- (void)_handleCallInitiationFailed:(NSNumber *)failReason;

// Called when the phone is ringing at the remote party
- (void)_handleCallIsAlerting;

// Called when there is an incoming call
- (void)_handleIncomingCall:(XMCallInfo *)call;

// Called when the call is established
- (void)_handleCallEstablished:(NSArray *)remotePartyInformations;

// Called when the call is cleared
- (void)_handleCallCleared:(NSNumber *)endReason;

// Called when the call statistics are updated
- (void)_handleCallStatisticsUpdate:(XMCallStatistics *)callStatistics;

#pragma mark Media callbacks

- (void)_handleOutgoingAudioStreamOpened:(NSString *)codec;
- (void)_handleIncomingAudioStreamOpened:(NSString *)codec;
- (void)_handleOutgoingVideoStreamOpened:(NSString *)codec;
- (void)_handleIncomingVideoStreamOpened:(NSString *)codec;

- (void)_handleOutgoingAudioStreamClosed;
- (void)_handleIncomingAudioStreamClosed;
- (void)_handleOutgoingVideoStreamClosed;
- (void)_handleIncomingVideoStreamClosed;

#pragma mark H.323 callbacks

// called every time enabling the H.323 stack failed
- (void)_handleH323EnablingFailure;

// Called when the Frameworks starts the gatekeeper registration
// process. This might be a lengthy task
- (void)_handleGatekeeperRegistrationProcessStart;

// Called when the framework ends the gatekeeper registration
// process.
- (void)_handleGatekeeperRegistrationProcessEnd;

// Called every time the Framework registers at a gatekeeper
- (void)_handleGatekeeperRegistration:(NSString *)gatekeeperName;

// Called every time the Framework unregisters from a gatekeeper
- (void)_handleGatekeeperUnregistration;

// Called every time an attempt to register at a gatekeeper failed
- (void)_handleGatekeeperRegistrationFailure:(NSNumber *)gatekeeperRegistrationFailReason;

@end

@interface XMCallInfo (FrameworkMethods)

- (id)_initWithCallID:(unsigned)callID
			 protocol:(XMCallProtocol)protocol
		   remoteName:(NSString *)remoteName
		 remoteNumber:(NSString *)remoteNumber
		remoteAddress:(NSString *)remoteAddress
	remoteApplication:(NSString *)remoteApplication
		  callAddress:(NSString *)callAddress
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

- (void)_updateCallStatistics:(XMCallStatistics *)callStatistics;

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

- (id)_initWithIdentifier:(XMCodecIdentifier)identifier enabled:(BOOL)enabled;
- (id)_initWithDictionary:(NSDictionary *)dict;

@end

@interface XMCodecManager (FrameworkMethods)

- (id)_init;
- (void)_close;

@end

@interface XMCodec (FrameworkMethods)

- (id)_initWithDictionary:(NSDictionary *)dict;

- (id)_initWithIdentifier:(XMCodecIdentifier)identifier
					 name:(NSString *)name
				bandwidth:(NSString *)bandwidth
				  quality:(NSString *)quality;

@end

@interface XMAudioManager (FrameworkMethods)

- (id)_init;
- (void)_close;

@end

@interface XMVideoManager (FrameworkMethods)

- (id)_init;
- (void)_close;

- (void)_addLocalVideoView:(XMVideoView *)videoView;
- (void)_removeLocalVideoView:(XMVideoView *)videoView;
- (void)_addRemoteVideoView:(XMVideoView *)videoView;
- (void)_removeRemoteVideoView:(XMVideoView *)videoView;
- (void)_drawLocalVideoInRect:(NSRect)rect;
- (void)_drawRemoteVideoInRect:(NSRect)rect;
- (void)_handleDeviceList:(NSArray *)deviceList;
- (void)_handleInputDeviceChangeComplete:(NSString *)selectedDevice;
- (void)_handlePreviewImage:(CIImage *)previewImage;
- (void)_handleVideoReceivingStart:(NSNumber *)videoSize;
- (void)_handleVideoReceivingEnd;
- (void)_handleRemoteImage:(CIImage *)remoteImage;

@end

@interface XMVideoView (FrameworkMethods)

- (void)_startBusyIndicator;
- (void)_stopBusyIndicator;

@end

@interface XMGeneralPurposeAddressResource (FrameworkMethods)

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
 * XMCodec private keys
 **/
extern NSString *XMKey_CodecTypes;
extern NSString *XMKey_CodecTypeVideoSize;
extern NSString *XMKey_CodecTypeIdentifier;

/**
 * XMAddressResource private keys
 **/
extern NSString *XMKey_GeneralPurposeAddressResource;

/**
 * Exception reasons
 **/
extern NSString *XMExceptionReason_InvalidParameterMustNotBeNil;
extern NSString *XMExceptionReason_InvalidParameterMustBeOfCorrectType;
extern NSString *XMExceptionReason_InvalidParameterMustBeValidKey;
extern NSString *XMExceptionReason_UnsupportedCoder;

extern NSString *XMExceptionReason_CallManagerInvalidActionIfInSubsystemSetupOrInCall;
extern NSString *XMExceptionReason_CallManagerInvalidActionIfNotInCall;
extern NSString *XMExceptionReason_CallManagerInvalidActionIfCallStatusNotIncoming;
extern NSString *XMExceptionReason_CallManagerInvalidActionIfH323Listening;
extern NSString *XMExceptionReason_CallManagerInvalidActionIfH323Disabled;
extern NSString *XMExceptionReason_CallManagerInvalidActionIfGatekeeperRegistered;
extern NSString *XMExceptionReason_CallManagerInvalidActionIfGatekeeperDisabled;

extern NSString *XMExceptionReason_CallManagerInternalConsistencyFailureOnCallEstablished;
extern NSString *XMExceptionReason_CallManagerInternalConsistencyFailureOnCallCleared;
extern NSString *XMExceptionReason_CodecManagerInternalConsistencyFailure;

#endif // __XM_PRIVATE_H__
