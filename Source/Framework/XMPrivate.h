/*
 * $Id: XMPrivate.h,v 1.35 2006/09/13 21:23:46 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
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
#import "XMPreferencesRegistrarRecord.h"
#import "XMCodecManager.h"
#import "XMCodec.h"
#import "XMAudioManager.h"
#import "XMVideoManager.h"
#import "XMMediaTransmitter.h"
#import "XMMediaReceiver.h"
#import "XMVideoView.h"
#import "XMGeneralPurposeAddressResource.h"
#import "XMCallRecorder.h"

extern unsigned _XMInitializedStatus;
extern XMUtils *_XMUtilsSharedInstance;
extern XMCallManager *_XMCallManagerSharedInstance;
extern XMCodecManager *_XMCodecManagerSharedInstance;
extern XMAudioManager *_XMAudioManagerSharedInstance;
extern XMVideoManager *_XMVideoManagerSharedInstance;
extern XMOpalDispatcher *_XMOpalDispatcherSharedInstance;
extern XMMediaTransmitter *_XMMediaTransmitterSharedInstance;
extern XMMediaReceiver *_XMMediaReceiverSharedInstance;
extern XMCallRecorder *_XMCallRecorderSharedInstance;

void _XMThreadExit();
void _XMCheckCloseStatus();

@class ABPerson, XMCallStatistics;

#pragma mark -

@interface XMUtils (FrameworkMethods)

- (id)_init;
- (void)_close;

- (void)_handleSTUNInformation:(NSArray *)info;

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
- (void)_handleCallInitiationFailed:(NSArray *)info;

// Called when the phone is ringing at the remote party
- (void)_handleCallIsAlerting;

// Called when there is an incoming call
- (void)_handleIncomingCall:(XMCallInfo *)call;

// Called when the call is established
- (void)_handleCallEstablished:(NSArray *)remotePartyInformations;

// Called when the call is cleared
- (void)_handleCallCleared:(NSNumber *)endReason;

// Called to determine the local address
- (void)_handleLocalAddress:(NSString *)localAddress;

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

- (void)_handleFECCChannelOpened;

#pragma mark H.323 callbacks

// called every time enabling the H.323 stack failed
- (void)_handleH323EnablingFailure;

// Called when the Framework starts the gatekeeper registration
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

#pragma mark SIP callbacks

// Called every time enabling the SIP stack failed
- (void)_handleSIPEnablingFailure;

// called every time when the framework starts a SIP registration
// process, trying to register at possibly multiple registrars.
// This might be a lengthy task
- (void)_handleSIPRegistrationProcessStart;

// Called when the framework ends the SIP registration process
- (void)_handleSIPRegistrationProcessEnd;

// Called every time the Framework register at a SIP registrar
- (void)_handleSIPRegistration:(NSArray *)info;

// Called every time the Framework unregisters from a SIP registrar
- (void)_handleSIPUnregistration:(NSArray *)info;

// Called every time an attempt to register at a SIP registrar failed
- (void)_handleSIPRegistrationFailure:(NSArray *)info;

#pragma mark Misc.

- (void)_updateSTUNInformation;
- (BOOL)_usesSTUN;
- (NSString *)_stunServer;

@end

#pragma mark -

@interface XMCallInfo (FrameworkMethods)

- (id)_initWithCallID:(unsigned)callID
			 protocol:(XMCallProtocol)protocol
		   remoteName:(NSString *)remoteName
		 remoteNumber:(NSString *)remoteNumber
		remoteAddress:(NSString *)remoteAddress
	remoteApplication:(NSString *)remoteApplication
		  callAddress:(NSString *)callAddress
		 localAddress:(NSString *)localAddress
		   callStatus:(XMCallStatus)status;

- (unsigned)_callID;
- (void)_setCallID:(unsigned)theCallID;

- (void)_setCallStatus:(XMCallStatus)status;
- (void)_setCallEndReason:(XMCallEndReason)endReason;
- (void)_setRemoteName:(NSString *)remoteName;
- (void)_setRemoteNumber:(NSString *)remoteNumber;
- (void)_setRemoteAddress:(NSString *)remoteAddress;
- (void)_setRemoteApplication:(NSString *)remoteApplication;
- (void)_setLocalAddress:(NSString *)localAddress;
- (void)_setLocalAddressInterface:(NSString *)localAddressInterface;
- (void)_setIncomingAudioCodec:(NSString *)codec;
- (void)_setOutgoingAudioCodec:(NSString *)codec;
- (void)_setIncomingVideoCodec:(NSString *)codec;
- (void)_setOutgoingVideoCodec:(NSString *)codec;

- (void)_updateCallStatistics:(XMCallStatistics *)callStatistics;

@end

#pragma mark -

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

@interface XMPreferencesRegistrarRecord (FrameworkMethods)

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
				  quality:(NSString *)quality
			   canDisable:(BOOL)canDisable;

@end

@interface XMAudioManager (FrameworkMethods)

- (id)_init;
- (void)_close;

- (void)_handleAudioInputLevel:(NSNumber *)level;
- (void)_handleAudioOutputLevel:(NSNumber *)level;

@end

@interface XMVideoManager (FrameworkMethods)

- (id)_init;
- (void)_close;

- (void)_handleDeviceList:(NSArray *)deviceList;
- (void)_handleInputDeviceChangeComplete:(NSArray *)info;
- (void)_handleVideoReceivingStart:(NSArray *)info;
- (void)_handleVideoReceivingEnd;
- (void)_handleVideoTransmittingStart:(NSNumber *)videoSize;
- (void)_handleVideoTransmittingEnd;

// runs NOT on the main thread!
- (void)_handleLocalVideoFrame:(CVPixelBufferRef)frame;
- (void)_handleRemoteVideoFrame:(CVPixelBufferRef)frame;

@end

@interface XMGeneralPurposeAddressResource (FrameworkMethods)

- (BOOL)_doesModifyPreferences:(XMPreferences *)preferences;
- (void)_modifyPreferences:(XMPreferences *)preferences;

@end

@interface XMCallRecorder (FrameworkMethods)

- (id)_init;
- (void)_close;

- (void)_handleUncompressedLocalVideoFrame:(CVPixelBufferRef)localVideoFrame;
- (void)_handleUncompressedRemoteVideoFrame:(CVPixelBufferRef)remoteVideoFrame;

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
extern NSString *XMExceptionReason_CallManagerInvalidActionIfSIPListening;
extern NSString *XMExceptionReason_CallManagerInvalidActionIfSIPDisabled;
extern NSString *XMExceptionReason_CallManagerInvalidActionIfAllRegistrarsRegistered;
extern NSString *XMexceptionReason_CallManagerInvalidActionIfRegistrarsDisabled;

extern NSString *XMExceptionReason_CodecManagerInternalConsistencyFailure;

#endif // __XM_PRIVATE_H__
