/*
 * $Id: XMCallHistoryCallAddressProvider.h,v 1.2 2006/03/14 22:44:38 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CALL_HISTORY_CALL_ADDRESS_PROVIDER_H__
#define __XM_CALL_HISTORY_CALL_ADDRESS_PROVIDER_H__

#import <Cocoa/Cocoa.h>
#import "XMCallAddressManager.h"

extern NSString *XMNotification_CallHistoryCallAddressProviderDataDidChange;

@interface XMCallHistoryCallAddressProvider : NSObject <XMCallAddressProvider> {
	
	BOOL isActiveCallAddressProvider;
	NSMutableArray *callHistoryRecords;
	NSMutableArray *searchMatches;

}

+ (XMCallHistoryCallAddressProvider *)sharedInstance;

- (BOOL)isActiveCallAddressProvider;
- (void)setActiveCallAddressProvider:(BOOL)flag;

/**
 * Returns an array containing the last 10 calls
 * this client has done. The returned objects
 * are XMCallHistoryRecord instance.
 **/
- (NSArray *)recentCalls;

@end

#endif // __XM_CALL_HISTORY_CALL_ADDRESS_PROVIDER_H__
