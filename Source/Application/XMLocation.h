/*
 * $Id: XMLocation.h,v 1.3 2005/10/31 22:11:50 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_LOCATION_H__
#define __XM_LOCATION_H__

#import <Cocoa/Cocoa.h>
#import "XMeeting.h"

extern NSString *XMKey_LocationName;

@interface XMLocation : XMPreferences {
	
	NSString *name;
	unsigned tag;
}

/**
 * initializes the instance with theName as its name.
 **/
- (id)initWithName:(NSString *)theName;

- (NSString *)name;
- (void)setName:(NSString *)name;

/**
 * Returns a duplicate of the location with the
 * new name set. Using this method is preferred instead
 * of -copy and then -setName: since it makes sure that
 * several internal optimisations work
 **/
- (XMLocation *)duplicateWithName:(NSString *)name;

- (NSString *)temporaryGatekeeperPassword;
- (void)setTemporaryGatekeeperPassword:(NSString *)password;

@end

@interface XMLocation (PrivateMethods)

/**
 * internal optimization to ensure correct object identification
 **/
- (void)_updateTag;
- (void)_setTag:(unsigned)tag;
- (unsigned)_tag;

@end

#endif // __XM_LOCATION_H__
