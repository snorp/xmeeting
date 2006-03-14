/*
 * $Id: XMCallAddressManager.h,v 1.6 2006/03/14 22:44:38 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CALL_ADDRESS_MANAGER_H__
#define __XM_CALL_ADDRESS_MANAGER_H__

#import <Cocoa/Cocoa.h>
#import "XMeeting.h"

@protocol XMCallAddress;
@protocol XMCallAddressProvider;

/**
 * XMCallResourceManager encapsulates functionality used to
 * obtain resources which can be called. It allows to search
 * for resources matching the search string and allows other
 * parts of the application to initiate a call to a certain
 * resource
 **/
@interface XMCallAddressManager : NSObject {
	
	NSMutableArray *callAddressProviders;
	id<XMCallAddress> activeCallAddress;
}

/**
 * Returns the singleton shared instance of the receiver
 **/
+ (XMCallAddressManager *)sharedInstance;

/**
 * Adds/removes a call resource provider
 **/
- (void)addCallAddressProvider:(id<XMCallAddressProvider>)provider;
- (void)removeCallAddressProvider:(id<XMCallAddressProvider>)provider;

/**
 * queries the manager for matches and completions to a given search string.
 * These queries are forwarded to the appropriate call address providerrs
 **/
- (NSArray *)addressesMatchingString:(NSString *)searchString;
- (NSString *)completionStringForAddress:(id<XMCallAddress>)address uncompletedString:(NSString *)uncompletedString;

/**
 * Returns all available addresses
 **/
- (NSArray *)allAddresses;

/**
 * Returns the call address instance which currently is being called (or in a call).
 * Returns nil if there is no address the receiver tries to call.
 **/
- (id<XMCallAddress>)activeCallAddress;

/**
 * Tries to make a call to the address specified.
 **/
- (void)makeCallToAddress:(id<XMCallAddress>)address;

@end

/**
 * This protocol declares the methods required for an instance
 * to act as a call address provider
 **/
@protocol XMCallAddressProvider <NSObject>

/**
 * This method should return an array of id<XMCallResource> instances which match
 * to searchString.
 **/
- (NSArray *)addressesMatchingString:(NSString *)searchString;

/**
 * This method should return a completion for the given resource and uncompletedString.
 * If uncompletedString does not match the resource, this method should return nil.
 */
- (NSString *)completionStringForAddress:(id<XMCallAddress>)address uncompletedString:(NSString *)uncompletedString;

/**
 * This method should return all id<XMCallResource> instances that this instance can
 * provide
 **/
- (NSArray *)allAddresses;

@end

/**
 * This protocol contains all methods required for the
 * call address system to obtain the desired information
 * both for display and for calling the address
 **/
@protocol XMCallAddress <NSObject>

/**
 * Returns the call resource provider which
 * provided this instance
 **/
- (id<XMCallAddressProvider>)provider;

/**
 * Returns the addressResource associated with this instance
 **/
- (XMAddressResource *)addressResource;

/**
 * This method should return a string used for display
 * representation
 **/
- (NSString *)displayString;

/**
 * Returns the image associated with this instance
 **/
- (NSImage *)displayImage;

@end

#endif // __XM_CALL_ADDRESS_MANAGER_H__