/*
 * $Id: XMPrivate.h,v 1.53 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
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
#import "XMPreferencesRegistrationRecord.h"
#import "XMCodecManager.h"
#import "XMCodec.h"
#import "XMAudioManager.h"
#import "XMVideoManager.h"
#import "XMMediaTransmitter.h"
#import "XMMediaReceiver.h"
#import "XMVideoView.h"
#import "XMGeneralPurposeAddressResource.h"
#import "XMCallRecorder.h"
#import "XMURLParser.h"

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

void _XMLaunchFramework(NSString *pTracePath, BOOL logCallStatistics);
void _XMSubsystemInitialized();
void _XMThreadExit();
void _XMCheckCloseStatus();

@class ABPerson, XMCallStatistics;

#pragma mark -

@interface XMUtils (FrameworkMethods)

- (id)_init;
- (void)_close;

- (void)_handleSTUNInformation:(NSArray *)info;
- (NSString *)_checkipPublicAddress;
- (BOOL)_doesUpdateCheckipInformation;

@end

@interface XMCallManager (FrameworkMethods)

- (id)_initWithPTracePath:(NSString *)pTracePath logCallStatistics:(BOOL)logCallStatistics;
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

// feedback about the H323 protocol status
- (void)_handleH323ProtocolStatus:(NSNumber *)protocolStatus;

// Called every time the Framework registers at a gatekeeper
- (void)_handleGatekeeperRegistration:(NSArray *)objects;

// Called every time the Framework unregisters from a gatekeeper
- (void)_handleGatekeeperUnregistration;

// Called every time an attempt to register at a gatekeeper failed
- (void)_handleGatekeeperRegistrationFailure:(NSNumber *)gatekeeperRegistrationFailReason;

#pragma mark SIP callbacks

// feedback about the SIP protocol status
- (void)_handleSIPProtocolStatus:(NSNumber *)protocolStatus;

// Called every time the Framework register at a SIP registrar
- (void)_handleSIPRegistration:(NSArray *)info;

// Called every time the Framework unregisters from a SIP registrar
- (void)_handleSIPUnregistration:(NSString *)aor;

// Called every time an attempt to register at a SIP registrar failed
- (void)_handleSIPRegistrationFailure:(NSArray *)info;

#pragma mark Misc

// Called when the network configuration changed
- (void)_networkConfigurationChanged;

// Called when the checkip address changed
- (void)_checkipAddressUpdated;

@end

#pragma mark -

@interface XMCallInfo (FrameworkMethods)

- (id)_initWithCallToken:(NSString *)callToken
                protocol:(XMCallProtocol)protocol
              remoteName:(NSString *)remoteName
            remoteNumber:(NSString *)remoteNumber
           remoteAddress:(NSString *)remoteAddress
       remoteApplication:(NSString *)remoteApplication
             callAddress:(NSString *)callAddress
            localAddress:(NSString *)localAddress
              callStatus:(XMCallStatus)status;

- (NSString *)_callToken;
- (void)_setCallToken:(NSString *)theCallToken;

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
- (void)_setIsReceivingAudio:(BOOL)flag;
- (void)_setIsSendingAudio:(BOOL)flag;
- (void)_setIsReceivingVideo:(BOOL)flag;
- (void)_setIsSendingVideo:(BOOL)flag;

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

@interface XMPreferencesRegistrationRecord (FrameworkMethods)

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
- (void)_handleAudioTestEnd;

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
- (void)_handleErrorDescription:(NSString *)errorDescription;

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
- (void)_handleCompressedLocalVideoFrame:(UInt8 *)encodedFrame
								  length:(UInt32)length
						imageDescription:(ImageDescriptionHandle)imageDesc;
- (BOOL)_handleCompressedRemoteVideoFrame:(UInt8 *)encodedFrame
								   length:(UInt32)length
						 imageDescription:(ImageDescriptionHandle)imageDesc;
- (void)_handleLocalVideoRecordingDidEnd;

@end

@interface XMURL (FrameworkMethods)

- (NSString *)_prefix;
- (BOOL)_parseString:(const char *)string usingCallback:(XMURLParseCallback)callback;

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
extern NSString *XMExceptionReason_CallManagerInvalidActionIfCompletelySIPRegistered;
extern NSString *XMexceptionReason_CallManagerInvalidActionIfSIPRegistrationDisabled;

extern NSString *XMExceptionReason_CodecManagerInternalConsistencyFailure;

#endif // __XM_PRIVATE_H__
