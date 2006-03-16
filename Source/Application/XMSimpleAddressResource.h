/*
 * $Id: XMSimpleAddressResource.h,v 1.3 2006/03/16 14:13:57 hfriederich Exp $
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

/**
 * This class implements the simple most address resource, containing
 * only an address and a protocol information
 **/
@interface XMSimpleAddressResource : XMAddressResource <XMCallAddress> {
	
	NSString *address;
	XMCallProtocol callProtocol;
	
}

- (id)initWithAddress:(NSString *)address callProtocol:(XMCallProtocol)protocol;

- (NSString *)address;

- (XMCallProtocol)callProtocol;
- (void)setCallProtocol:(XMCallProtocol)callProtocol;

@end

#endif // __XM_SIMPLE_ADDRESS_RESOURCE_H__
