/*
 * $Id: XMAddressBookCallAddressProvider.h,v 1.1 2005/06/01 08:51:41 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import <Cocoa/Cocoa.h>
#import "XMCallAddressManager.h"

@class XMAddressBookManager;

/**
 * This class implements the XMCallAddressProvider protocol
 * for searching the AddressBook for valid records
 **/
@interface XMAddressBookCallAddressProvider : NSObject <XMCallAddressProvider> {

	BOOL isActiveCallAddressProvider;
	XMAddressBookManager *addressBookManager;
	
}

+ (XMAddressBookCallAddressProvider *)sharedInstance;

- (BOOL)isActiveCallAddressProvider;
- (void)setActiveCallAddressProvider:(BOOL)flag;

@end
