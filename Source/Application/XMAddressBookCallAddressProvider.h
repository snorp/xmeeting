/*
 * $Id: XMAddressBookCallAddressProvider.h,v 1.3 2005/10/31 22:11:50 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_ADDRESS_BOOK_CALL_ADDRESS_PROVIDER_H__
#define __XM_ADDRESS_BOOK_CALL_ADDRESS_PROVIDER_H__

#import <Cocoa/Cocoa.h>
#import "XMCallAddressManager.h"

@class XMAddressBookManager;

/**
 * This class implements the XMCallAddressProvider protocol
 * for searching the AddressBook for valid records
 **/
@interface XMAddressBookCallAddressProvider : NSObject <XMCallAddressProvider> {

	BOOL isActiveCallAddressProvider;
	
}

+ (XMAddressBookCallAddressProvider *)sharedInstance;

- (BOOL)isActiveCallAddressProvider;
- (void)setActiveCallAddressProvider:(BOOL)flag;

@end

#endif // __XM_ADDRESS_BOOK_CALL_ADDRESS_PROVIDER_H__