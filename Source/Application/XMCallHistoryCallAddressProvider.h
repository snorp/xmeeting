/*
 * $Id: XMCallHistoryCallAddressProvider.h,v 1.6 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CALL_HISTORY_CALL_ADDRESS_PROVIDER_H__
#define __XM_CALL_HISTORY_CALL_ADDRESS_PROVIDER_H__

#import <Cocoa/Cocoa.h>
#import "XMCallAddressManager.h"

extern NSString *XMNotification_CallHistoryCallAddressProviderDataDidChange;

/**
 * This class implements the XMCallAddressProvider protocol for providing
 * search result on the recent calls made
 **/
@interface XMCallHistoryCallAddressProvider : NSObject <XMCallAddressProvider> {
	
@private
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

/**
 * Synchronizes the User Defaults database with the
 * current call history records
 **/
- (void)synchronizeUserDefaults;

@end

#endif // __XM_CALL_HISTORY_CALL_ADDRESS_PROVIDER_H__
