/*
 * $Id: XMSimpleAddressURL.h,v 1.1 2005/06/28 20:41:06 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_SIMPLE_ADDRESS_URL_H__
#define __XM_SIMPLE_ADDRESS_URL_H__

#import <Cocoa/Cocoa.h>
#import "XMeeting.h"
#import "XMCallAddressManager.h"

@interface XMSimpleAddressURL : XMURL <XMCallAddress> {
	
	NSString *address;

}

- (id)initWithAddress:(NSString *)address;

- (NSString *)address;

@end

#endif // __XM_SIMPLE_ADDRESS_URL_H__
