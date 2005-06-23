/*
 * $Id: XMURL.h,v 1.2 2005/06/23 12:35:56 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_URL_H__
#define __XM_URL_H__

#import <Foundation/Foundation.h>
#import "XMTypes.h"

extern NSString *XMKey_URLType;
extern NSString *XMKey_URLString;
extern NSString *XMKey_URLAddress;
extern NSString *XMKey_URLPort;

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
 * by url or not. This is done by querying the subclasses whether
 * they can handle url or not.
 **/
+ (BOOL)canHandleString:(NSString *)url;

/**
 * Returns whether the XMURL umbrella can handle an URL represented
 * in the dictionary or not. This is done by querying the subclasses
 * whether they can handle dictionary or not.
 **/
+ (BOOL)canHandleDictionary:(NSDictionary *)dictionary;

/**
 * Returns an instance of an XMURL subclass initialized
 * with the contents of url. The class of the returned instance
 * depends on the type of the URL. If url does not represent an URL
 * which can be handled by the XMURL umbrella, nil is returned but
 * no exception is thrown.
 **/
+ (XMURL *)urlWithString:(NSString *)url;

/**
 * Returns an instance of an XMURL subclass initialized with
 * the contents of dictionary.  The class of the returned instance
 * depends on the type of the URL. If url does not represent an URL
 * which can be handled by the XMURL umbrella, nil is returned but
 * no exception is thrown.
 **/
+ (XMURL *)urlWithDictionary:(NSDictionary *)dict;

/**
 * initializes the instance to the default values.
 * Invoking this on XMURL instances causes an exception
 * to be thrown
 **/
- (id)init;

/**
 * initializes the instance to the values specified in
 * urlString. Invoking this method on XMURL instances causes
 * an exception to be thrown.
 **/
- (id)initWithString:(NSString *)urlString;

/**
 * initializes the instance to the content of dictionary.
 * Invoking this method on XMURL instances causes an exception
 * to be thrown.
 **/
- (id)initWithDictionary:(NSDictionary *)dictionary;

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
 * Returns the port associated with address. Return 0 if port isn't
 * specified, uses the default port in this case.
 **/
- (unsigned)port;

/**
 * Returns a textual representation of the URL which is probably
 * better human readable than just using -address and -port.
 **/
- (NSString *)humanReadableRepresentation;

@end

#endif // __XM_URL_H__