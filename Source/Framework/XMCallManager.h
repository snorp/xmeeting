/*
 * $Id: XMCallManager.h,v 1.14 2005/10/17 17:00:27 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CALL_MANAGER_H__
#define __XM_CALL_MANAGER_H__

#import <Cocoa/Cocoa.h>

#import "XMTypes.h"

@class XMPreferences, XMCallInfo, XMURL;

/**
 * XMCallManager is the central class in the XMeeting framework.
 * This class allows to make calls, accept/reject incoming calls
 * and hangup active calls
 * This class is a singleton instance which can be accessed
 * through the +sharedInstance method, but allows to specify
 * a delegate to customize the behaviour.
 **/
@interface XMCallManager : NSObject {
	
	unsigned callManagerStatus;
	
	unsigned h323ListeningStatus;
	
	XMPreferences *activePreferences;
	BOOL automaticallyAcceptIncomingCalls;
	
	XMCallInfo *activeCall;
	BOOL needsSubsystemSetupAfterCallEnd;
	XMCallStartFailReason callStartFailReason;
	
	// h.323 variables
	NSString *gatekeeperName;
	XMGatekeeperRegistrationFailReason gatekeeperRegistrationFailReason;
	
	// InCall variables
	NSTimeInterval callStatisticsUpdateInterval;
	
	// call history
	NSMutableArray *recentCalls;
}

/**
 * returns the one single, shared instance of this class
 **/
+ (XMCallManager *)sharedInstance;

/**
 * Returns YES if changes to the setup are allowed or not.
 * If this method returns NO, attempts to change the
 * setup will raise an exception
 **/
- (BOOL)doesAllowModifications;

/**
 * Returns whether we are currently listening on the specified protocol. Which
 * protocols are enabled is by defined in the active XMPreferences instance
 **/
- (BOOL)isH323Listening;
- (BOOL)isSIPListening;

/**
 * Returns the currently active preferences
 **/
- (XMPreferences *)activePreferences;

/**
 * Sets the active set of preferences used.
 * The XMPreferences instance is copied and not just retained, so it is safe to alter
 * the settings afterwards without affecting XMCallManager
 **/
- (void)setActivePreferences:(XMPreferences *)prefs;

#pragma mark Call Management Methods

/**
 * Returns whether the framework is currently in a call or not.
 * In call means that an either a call is established, there is
 * a pending incoming call or the framework is calling someone.
 **/
- (BOOL)isInCall;

/**
 * Returns the XMCallInfo instance describing the currently active call.
 * Returns nil if there is no active call or if -callURL: was called
 * but the call attempt has not yet started.
 * After that XMNotification_CallManagerDidStartCalling has been posted,
 * this method will return the active call instance.
 **/
- (XMCallInfo *)activeCall;

/**
 * Calls the remoteParty using the specified call protocol
 * If the call cannot be made for some reason, (e.g. calling
 * an H.323 client while H.323 is disabled) a notification 
 * (XMNotification_CallManagerCallStartFailed) is
 * posted. Otherwise, the final result of the call attempt will 
 * be posted through notifications
 **/
- (void)callURL:(XMURL *)remotePartyURL;

/**
 * Returns the reason why the last call start failed.
 **/
- (XMCallStartFailReason)callStartFailReason;

/**
 * This method accepts the incoming call.
 * If this method is called and there is no incoming call, an expection is raised
 **/
- (void)acceptIncomingCall;

/**
 * This method rejects the incoming call.
 * if this method is called and there is no incoming call, an exception is raised
 **/
- (void)rejectIncomingCall;

/**
 * Clears the active call. If there is no active call, an exception
 * is raised
 **/
- (void)clearActiveCall;

/**
 * Returns the last calls made, NOT including any active call.
 * The most recent call is found at the lowest index.
 * The framework does not store any calls beyond the application
 * process's lifetime, and the number of calls recorded is
 * limited to 100
 **/
- (NSArray *)recentCalls;

#pragma mark H.323-specific methods

/**
 * Returns whether the client is registered at a gatekeeper or not
 **/
- (BOOL)isGatekeeperRegistered;

/**
 * Returns the name of the gatekeeper registered or nil if the client
 * is not registered at a gatekeeper
 **/
- (NSString *)gatekeeperName;

/**
 * Returns the reason indicating what caused the gatekeeper registration
 * to fail
 **/
- (XMGatekeeperRegistrationFailReason)gatekeeperRegistrationFailReason;

/**
 * Call this method if the enabling of the H.323 subsystem failed somehow
 * (notified with XMNotification_CallManagerEnablingH323Failed)
 * and you want to retry the subsystem setup process.
 * This method raises an exception if the H.323 subsystem is successfully
 * listening or if the current active preferences do not use H.323 at all!
 **/
- (void)retryEnableH323;

/**
 * Call this method if the gatekeeper registration failed somehow
 * (notified with XMNotification_CallManagerGatekeeperRegistrationFailed)
 * and you want to retry the gatekeeper registration process.
 * This method raises an exception if the gatekeeper registration was
 * succesful or if the current active preferences do not use a gatekeeper
 * at all
 **/
- (void)retryGatekeeperRegistration;

#pragma mark InCall functionality

/**
 * Returns the interval at which the call statistics are updated.
 * The default value is 1.0 seconds. If no statistics should be
 * fetched, returns 0.
 **/
- (NSTimeInterval)callStatisticsUpdateInterval;

/**
 * Sets the interval at which the call statistics should be updated.
 * If you don't want any statistics at all, set interval to 0.0 seconds.
 * Changing this value does not affect the interval of a call already
 * in progress.
 **/
- (void)setCallStatisticsUpdateInterval:(NSTimeInterval)interval;

@end

#endif // __XM_CALL_MANAGER_H__
