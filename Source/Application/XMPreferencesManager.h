/*
 * $Id: XMPreferencesManager.h,v 1.3 2005/05/24 15:21:01 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_PREFERENCES_MANAGER_H__
#define __XM_PREFERENCES_MANAGER_H__

#import <Cocoa/Cocoa.h>

@class XMLocation;

extern NSString *XMNotification_PreferencesDidChange;
extern NSString *XMNotification_ActiveLocationDidChange;

extern NSString *XMKey_Locations;
extern NSString *XMKey_ActiveLocation;

/**
 * XMPreferencesManager deals with the various task concerning
 * the management of user preferences.
 * There are two types of preferences in XMeeting.app:
 * Location-independent preferences such as window setup, default
 * device for video recording etc. For these preferences, this
 * class directly bridges to NSUserDefaults.
 * The other type of preferences are the location-dependent ones.
 * They are stored in instances of XMLocation, a subclass of
 * XMPreferences. XMPreferencesManager manages the collection of
 * XMLocation instances and allows the import/export of Locations.
 * Also, the necessary methods for storing the locations in the
 * UserDefaults database are provided.
 **/

@interface XMPreferencesManager : NSObject {

	NSMutableArray *locations;
	int activeLocation;
	BOOL autoAnswerCalls;
}

/**
 * Returns the shared singleton instance of XMPrefrencesManager
 **/
+ (XMPreferencesManager *)sharedInstance;

/**
 * Instructs XMPreferencesManager to synchronize the UserDefaults
 * database and to post the PreferencesDidChange notification.
 * This is useful after major changes in the preferences
 * such as after closing the Preferences window
 **/
- (void)synchronizeAndNotify;

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
 * Makes the location found at index the active location
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
- (BOOL)autoAnswerCalls;
- (void)setAutoAnswerCalls:(BOOL)flag;

- (BOOL)defaultAutoAnswerCalls;
- (void)setDefaultAutoAnswerCalls:(BOOL)flag;

@end

#endif // __XM_PREFERENCES_MANAGER_H__
