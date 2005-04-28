/*
 * $Id: XMLocation.h,v 1.1 2005/04/28 20:26:26 hfriederich Exp $
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
}

/**
 * initializes the instance with theName as its name.
 **/
- (id)initWithName:(NSString *)theName;

- (NSString *)name;
- (void)setName:(NSString *)name;

@end

#endif // __XM_LOCATION_H__
