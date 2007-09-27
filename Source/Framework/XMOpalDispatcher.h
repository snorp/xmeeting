/*
 * $Id: XMOpalDispatcher.h,v 1.21 2007/09/27 21:13:11 hfriederich Exp $
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
  
  unsigned callID;
  
  NSTimer *callStatisticsUpdateIntervalTimer;
  
  NSLock *sipRegistrationWaitLock;
	
}

+ (void)_setPreferences:(XMPreferences *)preferences externalAddress:(NSString *)externalAddress
   networkStatusChanged:(BOOL)networkStatusChanged;
+ (void)_retryEnableH323:(XMPreferences *)preferences;
+ (void)_retryGatekeeperRegistration:(XMPreferences *)preferences;
+ (void)_retryEnableSIP:(XMPreferences *)preferences;
+ (void)_retrySIPRegistrations:(XMPreferences *)preferences;
+ (void)_handleNetworkStatusChange;

+ (void)_initiateCallToAddress:(NSString *)address protocol:(XMCallProtocol)protocol;
+ (void)_initiateSpecificCallToAddress:(NSString *)address 
							  protocol:(XMCallProtocol)protocol
						   preferences:(XMPreferences *)preferences 
					   externalAddress:(NSString *)externalAddress;
+ (void)_callIsAlerting:(unsigned)callID;
+ (void)_incomingCall:(unsigned)callID
			 protocol:(XMCallProtocol)callProtocol
		   remoteName:(NSString *)remoteName
		 remoteNumber:(NSString *)remoteNumber
		remoteAddress:(NSString *)remoteAddress
	remoteApplication:(NSString *)remoteApplication
		 localAddress:(NSString *)localAddress;
+ (void)_acceptIncomingCall:(unsigned)callID;
+ (void)_rejectIncomingCall:(unsigned)callID;
+ (void)_callEstablished:(unsigned)callID 
				incoming:(BOOL)isIncomingCall
			localAddress:(NSString *)localAddress;
+ (void)_clearCall:(unsigned)callID;
+ (void)_callCleared:(unsigned)callID reason:(XMCallEndReason)callEndReason;
+ (void)_callReleased:(unsigned)callID localAddress:(NSString *)localAddress;

+ (void)_audioStreamOpened:(unsigned)callID 
					 codec:(NSString *)codec
				  incoming:(BOOL)isIncomingStream;
+ (void)_videoStreamOpened:(unsigned)callID 
					 codec:(NSString *)codec 
					  size:(XMVideoSize)videoSize
				  incoming:(BOOL)isIncomingStream
					 width:(unsigned)width
					height:(unsigned)height;

+ (void)_audioStreamClosed:(unsigned)callID
				  incoming:(BOOL)isIncomingStream;
+ (void)_videoStreamClosed:(unsigned)callID 
				  incoming:(BOOL)isIncomingStream;

+ (void)_feccChannelOpened;

+ (void)_setUserInputMode:(XMUserInputMode)userInputMode;
+ (void)_sendUserInputToneForCall:(unsigned)callID
							 tone:(char)tone;
+ (void)_sendUserInputStringForCall:(unsigned)callID
							 string:(NSString *)string;
+ (void)_startCameraEventForCall:(unsigned)callID 
						   event:(XMCameraEvent)event;
+ (void)_stopCameraEventForCall:(unsigned)callID;

- (id)_init;
- (void)_close;

- (void)_runOpalDispatcherThread:(NSString *)pTracePath;

	// called every time the STUN information is updated
- (void)_handleNATType:(XMNATType)natType externalAddress:(NSString *)externalAddress;

	// called every time the Framework (re-)registers at a gatekeeper
- (void)_handleGatekeeperRegistration:(NSString *)gatekeeperName aliases:(NSArray *)gkAliases;

- (void)_handleGatekeeperRegistrationFailure:(XMGatekeeperRegistrationFailReason)reason;

- (void)_handleGatekeeperUnregistration;

- (void)_handleSIPRegistration:(NSString *)registration;

- (void)_handleSIPUnregistration:(NSString *)registration;

- (void)_handleSIPRegistrationFailure:(NSString *)registration failReason:(XMSIPStatusCode)failReason;

	// called every time the Framework completes SIP Registration
  // may be called on any thread
- (void)_handleRegistrationSetupCompleted;

@end

#endif // _XM_OPAL_DISPATCHER_H__
