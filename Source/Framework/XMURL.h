/*
 * $Id: XMURL.h,v 1.3 2005/06/28 20:41:06 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_URL_H__
#define __XM_URL_H__

#import <Foundation/Foundation.h>
#import "XMTypes.h"

/**
 * XMURL encapsulates the basic features of an URL in conjunction with
 * the XMeeting framework. XMURL does not provide functionality similar 
 * to NSURL, is is just an interface for switching between the textual
 * representation of such an URL and its parsed contents.
 * XMURL is an abstract superclass which does not much work on it's own,
 * the subclasses such as XMCalltoURL do the actual work.
 **/
@interface XMURL : NSObject {

}

/**
 * Returns whether the XMURL umbrella can handle an URL represented
 * by stringRepresentation or not.
 **/
+ (BOOL)canHandleStringRepresentation:(NSString *)stringRepresentation;

/**
 * Returns whether the XMURL umbrella can handle an URL represented
 * by dictionaryRepresentation or not.
 **/
+ (BOOL)canHandleDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation;

/**
 * Returns an instance of an XMURL subclass initialized
 * with stringRepresentation. The class of the returned instance
 * depends on the type of the URL. If url does not represent an URL
 * which can be handled by the XMURL umbrella, nil is returned but
 * no exception is thrown.
 **/
+ (XMURL *)urlWithStringRepresentation:(NSString *)stringRepresentation;

/**
 * Returns an instance of an XMURL subclass initialized with
 * dictionaryRepresentation.  The class of the returned instance
 * depends on the type of the URL. If url does not represent an URL
 * which can be handled by the XMURL umbrella, nil is returned but
 * no exception is thrown.
 **/
+ (XMURL *)urlWithDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation;

/**
 * initializes the instance to the default values.
 * Invoking this on XMURL instances causes an exception
 * to be thrown
 **/
- (id)init;

/**
 * initializes the instance to stringRepresentation.
 * Invoking this method on XMURL instances causes
 * an exception to be thrown.
 **/
- (id)initWithStringRepresentation:(NSString *)stringRepresentation;

/**
 * initializes the instance to the content of dictionaryRepresentation.
 * Invoking this method on XMURL instances causes an exception
 * to be thrown.
 **/
- (id)initWithDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation;

/**
 * Returns the content of the URL in a string representation
 **/
- (NSString *)stringRepresentation;

/**
 * Returns the content of the URL in a dictionary representation
 **/
- (NSDictionary *)dictionaryRepresentation;

/**
 * Returns the protocol to be used by the framework to make this call
 **/
- (XMCallProtocol)callProtocol;

/**
 * Returns the address of the URL in a form that is machine
 * understandable.
 **/
- (NSString *)address;

/**
 * Returns a textual representation of the URL which is eventually
 * better human readable than just using -address
 **/
- (NSString *)humanReadableRepresentation;

@end

#endif // __XM_URL_H__