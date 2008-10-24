/*
 * $Id: XMCalltoURL.h,v 1.5 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CALLTO_URL_H__
#define __XM_CALLTO_URL_H__

#import <Foundation/Foundation.h>
#import "XMTypes.h"
#import "XMAddressResource.h"

@interface XMCalltoURL : XMAddressResource {
  
@private
  NSString *address;
  NSString *username;
  NSString *host;
}

/**
 * Returns whether url represents a callto: URL or not.
 * This does not check whether the url is valid and can
 * be correctly parsed. All this method does is to check
 * whether url has the "callto://" prefix
 **/
+ (BOOL)canHandleStringRepresentation:(NSString *)url;

/**
 * Returns whether dictionary represents a callto: URL or not.
 * This method does not check whether the contents of dictionary
 * represent a valid url or not.
 **/
+ (BOOL)canHandleDictionaryRepresentation:(NSDictionary *)dictionary;

/**
 * Creates an autoreleased instance of XMCalltoURL with the parsed
 * contents of url. If the parsing fails, nil is returned
 **/
+ (XMCalltoURL *)addressResourceWithStringRepresentation:(NSString *)url;

/**
 * Creates an autoreleased instance of XMCalltoURL with the contents
 * of dictionary.
 **/
+ (XMCalltoURL *)addressResourceWithDictionaryRepresentation:(NSDictionary *)dictionary;

- (id)initWithStringRepresentation:(NSString *)string;

- (NSString *)address;
- (NSString *)username;
- (NSString *)host;

@end

#endif // __XM_CALLTO_URL_H__