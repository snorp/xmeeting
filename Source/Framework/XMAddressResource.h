/*
 * $Id: XMAddressResource.h,v 1.3 2007/08/16 15:41:08 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_ADDRESS_RESOURCE_H__
#define __XM_ADDRESS_RESOURCE_H__

#import <Foundation/Foundation.h>
#import "XMTypes.h"

/**
 * XMAddressResource declares the interface for all sort of
 * addresses used within the XMeeting framework. This class
 * does only implement a couple of comfortability methods and can
 * be considered as an abstract base class.
 * The XMCallManager requires subclasses of this instance to be passed
 * when making calls.
 * Subclasses should/must override -callProtocol, -address and
 * -humanReadableAddress.
 **/
@interface XMAddressResource : NSObject {

}

/**
 * Returns whether the XMAddressResource umbrella can handle an
 * address resource represented by stringRepresentation or not.
 **/
+ (BOOL)canHandleStringRepresentation:(NSString *)stringRepresentation;

/**
 * Returns whether the XMAddressResource umbrella can handle an 
 * address resource represented by dictionaryRepresentation or not.
 **/
+ (BOOL)canHandleDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation;

/**
 * Returns an instance of an XMAddressResource subclass initialized
 * with stringRepresentation. The class of the returned instance
 * depends on the type of the string represenation. If stringRepresentation
 * does not represent an valid AddressResource known by the
 * XMAddressResource umbrella, nil is returned but no exception is thrown.
 **/
+ (XMAddressResource *)addressResourceWithStringRepresentation:(NSString *)stringRepresentation;

/**
 * Returns an instance of an XMAddressResource subclass initialized with
 * dictionaryRepresentation.  The class of the returned instance
 * depends on the type of the dictionary representation. If
 * dictionaryRepresnetation does not represent an AddressResource
 * known by the XMAddressResource umbrella, nil is returned but no
 * exception is thrown.
 **/
+ (XMAddressResource *)addressResourceWithDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation;

/**
 * initializes the instance to the default values.
 * Invoking this on XMAddressResource instances causes an exception
 * to be thrown
 **/
- (id)init;

/**
 * initializes the instance to stringRepresentation.
 * Invoking this method on XMAddressResource instances causes
 * an exception to be thrown.
 **/
- (id)initWithStringRepresentation:(NSString *)stringRepresentation;

/**
 * initializes the instance to the content of dictionaryRepresentation.
 * Invoking this method on XMAddressResource instances causes an exception
 * to be thrown.
 **/
- (id)initWithDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation;

/**
 * Returns the content of the addressResource in a string representation
 **/
- (NSString *)stringRepresentation;

/**
 * Returns the content of the addressResource in a dictionary representation
 **/
- (NSDictionary *)dictionaryRepresentation;

/**
 * Returns the protocol to be used by the framework to make this call
 **/
- (XMCallProtocol)callProtocol;

/**
 * Returns the address to be called in a form that is machine
 * understandable.
 **/
- (NSString *)address;

/**
 * Returns a textual representation of the address which is eventually
 * better human readable than just using -address
 **/
- (NSString *)humanReadableAddress;

/**
 * Return the 'username' part of the call address if such a feature exists.
 * Else returns nil
 **/
- (NSString *)username;

/**
 * Returns the 'host' part of the call address if such a feature exists.
 * Else returns nil
 **/
- (NSString *)host;

@end

@interface XMURL : XMAddressResource {
  NSString *url;
  NSString *displayName;
  NSString *username;
  NSString *host;
}

- (id)initWithStringRepresentation:(NSString *)url;
- (NSString *)stringRepresentation;

- (NSString *)displayName; // Equivalent to -humanReadableAddress

@end

#endif // __XM_ADDRESS_RESOURCE_H__