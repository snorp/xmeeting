/*
 * $Id: XMSimpleAddressResource.h,v 1.2 2006/03/14 22:44:38 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_SIMPLE_ADDRESS_RESOURCE_H__
#define __XM_SIMPLE_ADDRESS_RESOURCE_H__

#import <Cocoa/Cocoa.h>
#import "XMeeting.h"
#import "XMCallAddressManager.h"

@interface XMSimpleAddressResource : XMAddressResource <XMCallAddress> {
	
	NSString *address;

}

- (id)initWithAddress:(NSString *)address;

- (NSString *)address;

@end

#endif // __XM_SIMPLE_ADDRESS_RESOURCE_H__
