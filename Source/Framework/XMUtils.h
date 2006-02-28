/*
 * $Id: XMUtils.h,v 1.14 2006/02/28 18:37:21 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_UTILS_H__
#define __XM_UTILS_H__

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "XMTypes.h"

/**
 * XMUtils provides useful service functionality which
 * does not belong at another place
 **/
@interface XMUtils : NSObject {
	
	SCDynamicStoreRef dynamicStore;
	SCDynamicStoreContext dynamicStoreContext;
	NSArray *localAddresses;
	
	BOOL isFetchingExternalAddress;
	BOOL didSucceedFetchingExternalAddress;
	NSURLConnection *externalAddressURLConnection;
	NSMutableData *externalAddressURLData;
	NSString *externalAddress;
	NSString *externalAddressFetchFailReason;
	
	NSTimer *fetchingExternalAddressTimer;
}

/**
 * Returns the shared singleton instance of XMUtils
 **/
+ (XMUtils *)sharedInstance;

/**
 * Returns the local addresses for this computer
 **/
- (NSArray *)localAddresses;

/**
 * Starts a search for the external address on the network interface.
 * This is a nonblocking action, the end of a search is reported by
 * sending the appropriate notification.
 **/
- (void)startFetchingExternalAddress;

/**
 * Returns whether a search for the external address is running or not.
 **/
- (BOOL)isFetchingExternalAddress;

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

/**
 * This method returns the result of a NAT detection query.
 * Currently, this is done simply by comparing the local
 * and external address for equality. If the external address
 * is not yet available, returns XMNATDetectionResult_Error.
 * If no external address could be fetched, returns
 * XMNATDetectionResult_NoNAT.
 **/
- (XMNATDetectionResult)natDetectionResult;

@end

/**
 * checks whether str is a phone number and consists of only
 * digits, white space and '(' ')' '+' or '-'
 **/
BOOL XMIsPhoneNumber(NSString *phoneNumber);

/**
 * Returns an NSSize containing the width and height
 * of the specified video size
 **/
NSSize XMGetVideoFrameDimensions(XMVideoSize videoSize);

/**
 * calculates the other dimension from the given dimension
 **/
float XMGetVideoHeightForWidth(float width);
float XMGetVideoWidthForHeight(float height);

#endif // __XM_UTILS_H__
