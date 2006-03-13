/*
 * $Id: XMLocation.h,v 1.4 2006/03/13 23:46:21 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_LOCATION_H__
#define __XM_LOCATION_H__

#import <Cocoa/Cocoa.h>
#import "XMeeting.h"

extern NSString *XMKey_LocationName;
extern NSString *XMKey_LocationH323AccountID;
extern NSString *XMKey_LocationSIPAccountID;

@interface XMLocation : XMPreferences {
	
	unsigned tag;
	NSString *name;
	unsigned h323AccountTag;
	unsigned sipAccountTag;
	
	NSString *gatekeeperPassword;
	NSArray *registrarPasswords;
	
}

/**
 * initializes the instance with theName as its name.
 **/
- (id)initWithName:(NSString *)theName;

/**
 * Returns a duplicate of the location with the
 * new name set. Using this method is preferred instead
 * of -copy and then -setName: since it makes sure that
 * several internal optimizations work
 **/
- (XMLocation *)duplicateWithName:(NSString *)name;

- (unsigned)tag;

- (NSString *)name;
- (void)setName:(NSString *)name;

- (unsigned)h323AccountTag;
- (void)setH323AccountTag:(unsigned)tag;

- (unsigned)sipAccountTag;
- (void)setSIPAccountTag:(unsigned)tag;

/**
 * Stores the information from the accounts in the data storage
 * provided by the XMPreferences superclass so that the subsystem
 * can be setup consistently
 **/
- (void)storeAccountInformationsInSubsystem;

@end

#endif // __XM_LOCATION_H__
