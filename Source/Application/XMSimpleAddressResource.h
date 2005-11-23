/*
 * $Id: XMSimpleAddressResource.h,v 1.1 2005/11/23 19:28:44 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
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
