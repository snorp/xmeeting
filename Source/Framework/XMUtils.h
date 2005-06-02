/*
 * $Id: XMUtils.h,v 1.4 2005/06/02 12:47:33 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_UTILS_H__
#define __XM_UTILS_H__

/**
 * Posted every time the receiver starts a search for an external
 * address.
 **/
extern NSString *XMNotification_DidStartFetchingExternalAddress;

/**
 * Posted every time a search for an external address ends.
 * The success or failure of the operation can be queried
 * from the XMUtil instance.
 **/
extern NSString *XMNotification_DidEndFetchingExternalAddress;

#import <Cocoa/Cocoa.h>

/**
 * XMUtils provides useful service functionality which
 * does not belong at another place
 **/
@interface XMUtils : NSObject {
	
	NSURLConnection *externalAddressURLConnection;
	NSMutableData *externalAddressURLData;
	NSTimer *fetchingExternalAddressTimer;
	BOOL isFetchingExternalAddress;
	BOOL didSucceedFetchingExternalAddress;
	NSString *externalAddress;
	NSString *externalAddressFetchFailReason;
}

/**
 * Returns the shared singleton instance of XMUtils
 **/
+ (XMUtils *)sharedInstance;

/**
 * parses whether str is a phone number and consists of only
 * digits, white space and '(' ')' '+' or '-'
 **/
+ (BOOL)isPhoneNumber:(NSString *)str;

/**
 * Starts a search for the external address on the network interface.
 * This is a nonblocking action, the end of a search is reported by
 * sending the appropriate notification.
 **/
- (void)startFetchingExternalAddress;

/**
 * Returns whether the last action of an external address fetch
 * was succesful or not. Returns YES if no external address has been
 * fetched yet, even if -externalAddress returns nil in this case.
 **/
- (BOOL)didSucceedFetchingExternalAddress;

/**
 * Returns the external address. If the external address hasn't been
 * obtained yet, this method starts a search but returns nil. Thus, this
 * method is nonblocking even if there is no external address yet.
 **/
- (NSString *)externalAddress;

/**
 * Returns the fail reason for the external address fetch
 **/
- (NSString *)externalAddressFetchFailReason;

@end

#endif // __XM_UTILS_H__
