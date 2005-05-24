/*
 * $Id: XMCallManager.h,v 1.3 2005/05/24 15:21:01 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CALL_MANAGER_H__
#define __XM_CALL_MANAGER_H__

#import <Cocoa/Cocoa.h>

#import "XMTypes.h"

/**
 * Declaration of the notifications posted by XMCallManager
 **/
extern NSString *XMNotification_IncomingCall;		// posted when there is an incoming call, waiting for user acknowledge
extern NSString *XMNotification_CallEstablished;	// posted when a call is established
extern NSString *XMNotification_CallEnd;			// posted when a call did end.

@class XMPreferences, XMCallInfo;

/**
 * XMCallManager is the central class in the XMeeting framework.
 * This class allows to make calls, accept/reject incoming calls
 * and hangup active calls
 * This class is a singleton instance which can be accessed
 * through the +sharedInstance method, but allows to specify
 * a delegate to customize the behaviour.
 **/
@interface XMCallManager : NSObject {
	
	id delegate;	// reference to the delegate (if any)
	
	BOOL isOnline;
	XMPreferences *activePreferences;
	XMCallInfo *activeCall;
	BOOL autoAnswerCalls;
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
- (void)setIsOnline:(BOOL)flag;

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
 * Returns the XMCallInfo instance describing the currently active call.
 * Returns nil if there is no active call
 **/
- (XMCallInfo *)activeCall;

/**
 * Calls the remoteParty using the specified call protocol
 * If the protocol (e.g. H.323) is not active in the current settings, an exception
 * is raise.
 **/
- (XMCallInfo *)callRemoteParty:(NSString *)remoteParty usingProtocol:(XMCallProtocol)protocol;

/**
 * This method accepts or rejects the incoming call.
 * If this method is called if there is no incoming call, an expection is raised
 **/
- (void)acceptIncomingCall:(BOOL)acceptCall;

/**
 * Hang-up of the active call
 **/
- (void)clearActiveCall;

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
