/*
 * $Id: XMCallAddressManager.h,v 1.8 2006/03/27 15:31:21 hfriederich Exp $
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
 * XMCallAddressManager encapsulates functionality used to
 * obtain resources which can be called. It allows to search
 * for resources matching the search string and allows other
 * parts of the application to initiate a call to a certain
 * resource.
 * Always use this class to initiate calls and never use the
 * XMCallManager API directly to ensure consistent application
 * look and behaviour.
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
 * Returns an array of options for the given address. The array contains NSString instances
 **/
- (NSArray *)alternativesForAddress:(id<XMCallAddress>)address selectedIndex:(unsigned *)selectedIndex;

/**
 * Returns the alternative address for the given index
 **/
- (id<XMCallAddress>)alternativeForAddress:(id<XMCallAddress>)address atIndex:(unsigned)index;

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
 * This method should return an array with alternatives for the given address. The options
 * must be NSString instances
 **/
- (NSArray *)alternativesForAddress:(id<XMCallAddress>)address selectedIndex:(unsigned *)selectedIndex;

/**
 * This method should return the alternative address at index for the given address
 **/
- (id<XMCallAddress>)alternativeForAddress:(id<XMCallAddress>)address atIndex:(unsigned)index;

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