/*
 * $Id: XMCallManager.h,v 1.28 2007/09/20 19:14:03 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CALL_MANAGER_H__
#define __XM_CALL_MANAGER_H__

#import <Foundation/Foundation.h>

#import "XMTypes.h"

@class XMPreferences, XMCallInfo, XMAddressResource;

/**
 * XMCallManager is the central class in the XMeeting framework.
 * This class allows to make calls, accept/reject incoming calls
 * and hangup active calls
 * This class is a singleton instance which can be accessed
 * through the +sharedInstance method, but allows to specify
 * a delegate to customize the behaviour.
 **/
@interface XMCallManager : NSObject {
	
@private
  unsigned callManagerStatus;
  
  unsigned h323ListeningStatus;
  unsigned sipListeningStatus;
  
  XMPreferences *activePreferences;
  BOOL automaticallyAcceptIncomingCalls;
  
  XMCallInfo *activeCall;
  BOOL needsSubsystemSetupAfterCallEnd;
  XMCallStartFailReason callStartFailReason;
  
  BOOL canSendCameraEvents;
  
  // External address handling
  BOOL needsCheckipAddress;
  
  // h.323 variables
  NSString *gatekeeperName;
  XMGatekeeperRegistrationFailReason gatekeeperRegistrationFailReason;
  
  // SIP variables
  NSMutableArray *registrations;
  NSMutableArray *sipRegistrationFailReasons;
  
  // InCall variables
  NSTimeInterval callStatisticsUpdateInterval;
  
  // call history
  NSMutableArray *recentCalls;
}

/**
 * returns the singleton, shared instance of this class
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
 * Returns nil if there is no active call or if -makeCall: was called
 * but the call attempt has not yet started.
 * After that XMNotification_CallManagerDidStartCalling has been posted,
 * this method will return the active call instance.
 **/
- (XMCallInfo *)activeCall;

/**
 * Calls the remote party specified by address
 * If the call cannot be made for some reason, (e.g. calling
 * an H.323 client while H.323 is disabled) a notification 
 * (XMNotification_CallManagerCallStartFailed) is
 * posted. Otherwise, the final result of the call attempt will 
 * be posted through notifications
 **/
- (void)makeCall:(XMAddressResource *)address;

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
 * Returns the number of calls currently archived
 **/
- (unsigned)recentCallsCount;

/**
 * Returns the recent call at index
 **/
- (XMCallInfo *)recentCallAtIndex:(unsigned)index;

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
 * (notified with XMNotification_CallManagerDidNotEnableH323)
 * and you want to retry the subsystem setup process.
 * This method raises an exception if the H.323 subsystem is successfully
 * listening or if the current active preferences do not use H.323 at all!
 **/
- (void)retryEnableH323;

/**
 * Call this method if the gatekeeper registration failed somehow
 * (notified with XMNotification_CallManagerDidNotRegisterAtGatekeeper)
 * and you want to retry the gatekeeper registration process.
 * This method raises an exception if the gatekeeper registration was
 * succesful or if the current active preferences does not use a gatekeeper
 * at all
 **/
- (void)retryGatekeeperRegistration;

#pragma mark SIP-specific methods

/**
 * Returns YES if all registrations were succesful or not.
 **/
- (BOOL)isCompletelyRegistered;

/**
 * Returns the number of successful registrations the client has at 
 * the moment 
 **/
- (unsigned)registrationCount;

/**
 * Returns the registration at the given index
 **/
- (NSString *)registrationAtIndex:(unsigned)index;

/**
 * Returns the complete array of registrars the client is currently
 * registered at.
 **/
- (NSArray *)registrations;

/**
 * Returns the number of registration fail reason records the manager
 * currently has. This is the same number as the number of registrars
 * specified in the active XMPreferences instance.
 **/
- (unsigned)sipRegistrationFailReasonCount;

/**
 * Returns the registration fail reason for the particular registration at index.
 **/
- (XMSIPStatusCode)sipRegistrationFailReasonAtIndex:(unsigned)index;

/**
 * Returns the status of the registrations provided.
 * If there client has no registrations in the current preferences set,
 * an empty array is returned.
 **/
- (NSArray *)sipRegistrationFailReasons;

/**
 * Call this method if the enabling of the SIP subsystem failed somehow
 * (notified with XMNotification_CallManagerDidNotEnableSIP)
 * and you want to retry the subsystem setup process.
 * This method raises an exception if the SIP subsystem is successfully
 * listening or if the current active preferences do not use SIP at all!
 **/
- (void)retryEnableSIP;

/**
 * Call this method if one of the registration failed somehow
 * (notified with XMNotification_CallManagerDidNotSIPRegister)
 * and you want to retry the registration process.
 * This method raises an exception if all registrations were
 * succesful or if the current active preferences does not use registrations
 * at all
 **/
- (void)retrySIPRegistrations;

#pragma mark InCall functionality

/**
 * Defines which UserInputMode to send
 **/
- (void)setUserInputMode:(XMUserInputMode)mode;

/**
 * Sends character as a DTMF user input tone
 * character may be one of the following characters:
 * "0123456789*#ABCD!", ! indicates a hook flash.
 * Calling this method is only valid when there is an
 * active call. Otherwise, an exception will be raised
 **/
- (void)sendUserInputTone:(char)tone;

/**
 * Sends string as an UserInput string.
 * Calling this method is only valid when there is an active
 * call. Otherwise, an exception will be raised
 **/
- (void)sendUserInputString:(NSString *)string;

/**
 * Returns whether the manager can transmit camera events to
 * the remote party or not.
 **/
- (BOOL)canSendCameraEvents;

/**
 * Sends a camera event to the remote party. Calling this method is only
 * valid if there is a call. Otherwise, an exception will be raised
 **/
- (void)startCameraEvent:(XMCameraEvent)cameraEvent;

/**
 * stops the camera event initiated by -startCameraEvent:
 * Raises an exception if this method is called while not in a call
 **/
- (void)stopCameraEvent;

@end

#endif // __XM_CALL_MANAGER_H__
