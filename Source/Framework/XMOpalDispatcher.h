/*
 * $Id: XMOpalDispatcher.h,v 1.30 2008/10/12 12:24:12 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_OPAL_DISPATCHER_H__
#define __XM_OPAL_DISPATCHER_H__

#import <Foundation/Foundation.h>

#import "XMTypes.h"
#import "XMPreferences.h"

/**
 * Interface to Worker thread that dispatches commands to the OPAL subsystem
 **/
@interface XMOpalDispatcher : NSObject {

@private
  NSPort *receivePort;
  XMPreferences *currentPreferences;
  
  NSString *callToken;
  XMCallEndReason callEndReason; // used during -_doInitiateCall
  
  NSTimer *controlTimer;
  NSTimer *callStatisticsUpdateIntervalTimer;
  
  unsigned resyncSubsystemCounter;
  NSLock *gatekeeperRegistrationWaitLock;
  NSLock *sipRegistrationWaitLock;
  BOOL doesWaitForSIPRegistrationCompletion;
  
  BOOL logCallStatistics;
}

+ (void)_setPreferences:(XMPreferences *)preferences publicAddress:(NSString *)publicAddress;
+ (void)_handleNetworkConfigurationChange;
+ (void)_handlePublicAddressUpdate:(NSString *)publicAddress;

+ (void)_initiateCallToAddress:(NSString *)address protocol:(XMCallProtocol)protocol;
+ (void)_initiateSpecificCallToAddress:(NSString *)address 
                              protocol:(XMCallProtocol)protocol
                           preferences:(XMPreferences *)preferences 
                         publicAddress:(NSString *)publicAddress;
+ (void)_callIsAlerting:(NSString *)callToken;
+ (void)_incomingCall:(NSString *)callToken
             protocol:(XMCallProtocol)callProtocol
           remoteName:(NSString *)remoteName
         remoteNumber:(NSString *)remoteNumber
        remoteAddress:(NSString *)remoteAddress
    remoteApplication:(NSString *)remoteApplication
         localAddress:(NSString *)localAddress;
+ (void)_acceptIncomingCall:(NSString *)callToken;
+ (void)_rejectIncomingCall:(NSString *)callToken;
+ (void)_callEstablished:(NSString *)callToken 
              remoteName:(NSString *)remoteName
            remoteNumber:(NSString *)remoteNumber
           remoteAddress:(NSString *)remoteAddress
       remoteApplication:(NSString *)remoteApplication
            localAddress:(NSString *)localAddress;
+ (void)_clearCall:(NSString *)callToken;
+ (void)_callCleared:(NSString *)callToken reason:(XMCallEndReason)callEndReason;
+ (void)_callReleased:(NSString *)callToken localAddress:(NSString *)localAddress;

+ (void)_audioStreamOpened:(NSString *)callToken 
                     codec:(NSString *)codec
                  incoming:(BOOL)isIncomingStream;
+ (void)_videoStreamOpened:(NSString *)callToken 
                     codec:(NSString *)codec 
                      size:(XMVideoSize)videoSize
                  incoming:(BOOL)isIncomingStream
                     width:(unsigned)width
                    height:(unsigned)height;

+ (void)_audioStreamClosed:(NSString *)callToken
                  incoming:(BOOL)isIncomingStream;
+ (void)_videoStreamClosed:(NSString *)callToken 
                  incoming:(BOOL)isIncomingStream;

+ (void)_feccChannelOpened;

+ (void)_setUserInputMode:(XMUserInputMode)userInputMode;
+ (void)_sendUserInputToneForCall:(NSString *)callToken
                             tone:(char)tone;
+ (void)_sendUserInputStringForCall:(NSString *)callToken
                             string:(NSString *)string;
+ (void)_startCameraEventForCall:(NSString *)callToken 
                           event:(XMCameraEvent)event;
+ (void)_stopCameraEventForCall:(NSString *)callToken;

- (id)_init;
- (void)_close;

- (void)_setLogCallStatistics:(BOOL)logCallStatistics;
- (void)_runOpalDispatcherThread:(NSString *)pTracePath;

	// called every time the STUN information is updated
- (void)_handleNATType:(XMNATType)natType publicAddress:(NSString *)publicAddress;

	// called every time the Framework (re-)registers at a gatekeeper
- (void)_handleGatekeeperRegistration:(NSString *)gatekeeperName aliases:(NSArray *)gkAliases;

- (void)_handleGatekeeperRegistrationFailure:(XMGatekeeperRegistrationStatus)failReason;

- (void)_handleGatekeeperUnregistration;

- (void)_handleSIPRegistrationForDomain:(NSString *)domain username:(NSString *)username aor:(NSString *)aor;

- (void)_handleSIPUnregistration:(NSString *)aor;

- (void)_handleSIPRegistrationFailureForDomain:(NSString *)domain username:(NSString *)username
                                           aor:(NSString *)aor failReason:(XMSIPStatusCode)failReason;

  // called every time the Framework completes the Gatekeeper registration
  // may be called on any thread
- (void)_handleGatekeeperRegistrationComplete;

	// called every time the Framework completes the SIP registration
  // may be called on any thread
- (void)_handleSIPRegistrationComplete;

- (void)_handleCallStartToken:(NSString *)callToken callEndReason:(XMCallEndReason)callEndReason;

@end

#endif // _XM_OPAL_DISPATCHER_H__
