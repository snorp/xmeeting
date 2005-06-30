/*
 * $Id: XMCallManager.h,v 1.8 2005/06/30 09:33:12 hfriederich Exp $
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
	
	id delegate;
	
	BOOL isOnline;
	
	BOOL doesSubsystemSetup;
	BOOL needsSubsystemSetupAfterCallEnd;
	BOOL needsSubsystemShutdownAfterSubsystemSetup;
	BOOL postSubsystemSetupFailureNotifications;
	
	XMPreferences *activePreferences;
	XMPreferences *activeSetupPreferences;
	BOOL autoAnswerCalls;
	
	XMCallInfo *activeCall;
	XMCallStartFailReason callStartFailReason;
	NSString *addressToCall;
	XMCallProtocol protocolToUse;
	
	// h.323 variables
	NSString *gatekeeperName;
	XMGatekeeperRegistrationFailReason gatekeeperRegistrationFailReason;
	NSTimer *gatekeeperRegistrationCheckTimer;
	
	// call history
	NSMutableArray *recentCalls;
}

/**
 * returns the one single, shared instance of this class
 **/
+ (XMCallManager *)sharedInstance;

/**
 * Manages the delegate.
 * If the delegate implements one of the methods described in XMCallManagerDelegate,
 * the delegate is automatically registered to receive these notifications
 **/
- (id)delegate;
- (void)setDelegate:(id)delegate;

/**
 * If the manager is online, this means that the framework is listening on whatever
 * protocol currently is enabled.
 **/
- (BOOL)isOnline;
- (void)setOnline:(BOOL)flag;

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

/**
 * Returns YES if a subsystem setup process is currently running or not, NO otherwise.
 * While the subsystem is setup, certain actions such as -setActivePreferences are
 * not allowed and do rais an exception
 **/
- (BOOL)doesSubsystemSetup;

#pragma mark Call Management Methods

/**
 * Returns whether the framework is currently in a call or not
 **/
- (BOOL)isInCall;

/**
 * Returns the XMCallInfo instance describing the currently active call.
 * Returns nil if there is no active call
 **/
- (XMCallInfo *)activeCall;

/**
 * Calls the remoteParty using the specified call protocol
 * If the call cannot be made for some reason, (e.g. calling
 * an H.323 client while H.323 is disabled) NO is returned
 * and a notification (XMNotification_CallManagerCallStartFailed) is
 * posted. Otherwise, this method returns YES and the final result of
 * the call attempt will be posted through notifications
 * The call fail reason can be obtained through -callStartFailReason
 **/
- (BOOL)callURL:(XMURL *)remotePartyURL;

/**
 * Returns the reason why the last call start failed.
 **/
- (XMCallStartFailReason)callStartFailReason;

/**
 * This method accepts or rejects the incoming call.
 * If this method is called and there is no incoming call, an expection is raised
 **/
- (void)acceptIncomingCall:(BOOL)acceptCall;

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
 * limited to 100 (a rather theoretical number...)
 **/
- (NSArray *)recentCalls;

#pragma mark H.323-specific methods

/**
 * Returns the name of the gatekeeper registered or nil if the framework
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

@end

/**
 * Informal protocol for any delegates of XMCallManager
 **/
@interface NSObject (XMCallManagerDelegate)

- (void)callManagerDidReceiveIncomingCall:(NSNotification *)notif;
- (void)callManagerDidEstablishCall:(NSNotification *)notif;
- (void)callManagerDidEndCall:(NSNotification *)notif;

@end

#endif // __XM_CALL_MANAGER_H__
