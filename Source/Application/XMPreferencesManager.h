/*
 * $Id: XMPreferencesManager.h,v 1.11 2006/03/13 23:46:21 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_PREFERENCES_MANAGER_H__
#define __XM_PREFERENCES_MANAGER_H__

#import <Cocoa/Cocoa.h>

@class XMH323Account, XMSIPAccount, XMLocation;

extern NSString *XMNotification_PreferencesManagerDidChangePreferences;
extern NSString *XMNotification_PreferencesManagerDidChangeActiveLocation;

extern NSString *XMKey_PreferencesManagerPreferencesAvailable;
extern NSString *XMKey_PreferencesManagerH323Accounts;
extern NSString *XMKey_PreferencesManagerSIPAccounts;
extern NSString *XMKey_PreferencesManagerLocations;
extern NSString *XMKey_PreferencesManagerActiveLocation;
extern NSString *XMKey_PreferencesManagerAutomaticallyAcceptIncomingCall;
extern NSString *XMKey_PreferencesManagerUserName;
extern NSString *XMKey_PreferencesManagerDisabledVideoModules;
extern NSString *XMKey_PreferencesManagerPreferredVideoInputDevice;

/**
 * XMPreferencesManager deals with the various task concerning
 * the management of user preferences.
 * There are three types of preferences in XMeeting.app:
 * - Location-independent preferences such as window setup, default
 * device for video recording etc. For these preferences, this
 * class directly bridges to NSUserDefaults.
 * - Another type of preferences are the accounts for H.323 and SIP,
 * which aren't directly bridged to NSUserDefaults but still considered
 * independent of the current active location. The locations use these
 * accounts to get gatekeeper/registrar informations if needed.
 * - The last type of preferences are the location-dependent ones.
 * They are stored in instances of XMLocation, a subclass of
 * XMPreferences. XMPreferencesManager manages the collection of
 * XMLocation instances and allows the import/export of Locations.
 * Also, the necessary methods for storing the locations in the
 * UserDefaults database are provided.
 **/
@interface XMPreferencesManager : NSObject {

	NSMutableArray *h323Accounts;
	NSMutableArray *sipAccounts;
	NSMutableArray *locations;
	unsigned activeLocation;
	BOOL automaticallyAcceptIncomingCalls;
	
}

/**
 * Returns the shared singleton instance of XMPrefrencesManager
 **/
+ (XMPreferencesManager *)sharedInstance;

/**
 * Returns whether there exists a preferences file or not
 **/
+ (BOOL)doesHavePreferences;

/**
 * Instructs XMPreferencesManager to synchronize the UserDefaults
 * database and to post the PreferencesDidChange notification.
 * This is useful after major changes in the preferences
 * such as after closing the Preferences window
 **/
- (void)synchronizeAndNotify;

/**
 * Synchronizes the UserDefaults database without any
 * notifications being posted
 **/
- (void)synchronize;

/**
 * Returns the number of H.323 accounts in the system
 **/
- (unsigned)h323AccountCount;

/**
 * Returns the H.323 account at index
 **/
- (XMH323Account *)h323AccountAtIndex:(unsigned)index;

/**
 * Returns the H.323 account with tag
 **/
- (XMH323Account *)h323AccountWithTag:(unsigned)tag;

/**
 * Returns an array containing all available H.323 accounts on this system.
 * The XMH323Account instances in this array are copies of the ones
 * stored by XMPreferencesManager. It is therefore safe to modify these
 * instances without directly affecting the stored h323 accounts
 **/
- (NSArray *)h323Accounts;

/**
 * Replaces the stored H.323 account instances by the ones contained
 * in the array. The instances are copied so that it is safe to modify
 * after invoking this method.
 *
 * All emelents in the array which are not instances of XMH323Account
 * are simply ignored.
 *
 * If the accounts array is empty, the account set currently in
 * preferences is activated
 **/
- (void)setH323Accounts:(NSArray *)h323Accounts;

/**
 * Returns the number of SIP accounts in the system
 **/
- (unsigned)sipAccountCount;

/**	
 * Returns the SIP account at index
 **/
- (XMSIPAccount *)sipAccountAtIndex:(unsigned)index;

/**
 * Returns the SIP account with tag
 **/
- (XMSIPAccount *)sipAccountWithTag:(unsigned)tag;

/**
 * Returns an array containing all available SIP accounts on this system.
 * The XMSIPAccount instances in this array are copies of the ones
 * stored by XMPreferencesManager. It is therefore safe to modify these
 * instances without directly affecting the stored SIP accounts
 **/
- (NSArray *)sipAccounts;

/**
 * Replaces the stored SIP account instances by the ones contained
 * in the array. The instances are copied so that it is safe to modify
 * after invoking this method.
 *
 * All emelents in the array which are not instances of XMSIPAccount
 * are simply ignored.
 *
 * If the accounts array is empty, the account set currently in
 * preferences is activated
 **/
- (void)setSIPAccounts:(NSArray *)SIPAccounts;

/**
 * returns an array containing the available locations on this system.
 * The XMLocation instances in this array are copies of the ones
 * stored by XMPreferencesManager. It is therefore safe to modify
 * these instances without directly affecting the stored locations.
 **/
- (NSArray *)locations;

/**
 * Replaces the stored location instances by the ones contained in
 * the array. The instances are copied so that it is safe to modify
 * the contents after invoking this method.
 *
 * All elements in the array which are not instances of XMLocation
 * are simply ignored.
 *
 * If the locations array is empty, the locations set currently
 * in preferencs is activated
 **/
- (void)setLocations:(NSArray *)locations;

/**
 * convenience method to access just the names of the locations
 **/
- (NSArray *)locationNames;

/**
 * Returns the number of locations currently stored in preferences
 **/
- (unsigned)locationCount;

/**
 * Returns the current active location.
 **/
- (XMLocation *)activeLocation;

/**
 * Returns the index of the active loation
 **/
- (unsigned)indexOfActiveLocation;

/**
 * Makes the location at index the active location
 **/
- (void)activateLocationAtIndex:(unsigned)index;

/**
 * Manages the user name
 **/
- (NSString *)userName;
- (void)setUserName:(NSString *)name;

/**
 * Manages the autoanswer behaviour
 **/
- (BOOL)automaticallyAcceptIncomingCalls;
- (void)setAutomaticallyAcceptIncomingCalls:(BOOL)flag;

- (BOOL)defaultAutomaticallyAcceptIncomingCalls;
- (void)setDefaultAutomaticallyAcceptIncomingCalls:(BOOL)flag;

/**
 * Returns the password found for the service and account specified
 **/
- (NSString *)passwordForServiceName:(NSString *)serviceName accountName:(NSString *)accountName;

/**
 * Sets the password for service and account specified
 **/
- (void)setPassword:(NSString *)password forServiceName:(NSString *)serviceName accountName:(NSString *)accountName;

/**
 * Returns an array containing identifiers of the disabled video modules
 **/
- (NSArray *)disabledVideoModules;

/**
 * Sets which video modules are disabled and which aren't
 **/
- (void)setDisabledVideoModules:(NSArray *)disabledVideoModules;

/**
 * Returns the name of the preferred video input device.
 **/
- (NSString *)preferredVideoInputDevice;

/**
 * Sets the name of the preferred video input device.
 **/
- (void)setPreferredVideoInputDevice:(NSString *)device;

@end

#endif // __XM_PREFERENCES_MANAGER_H__
