/*
 * $Id: XMH323URL.h,v 1.2 2007/08/16 15:41:08 hfriederich Exp $
 *
 * Copyright (c) 2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_H323_URL_H__
#define __XM_H323_URL_H__

#import <Foundation/Foundation.h>
#import "XMTypes.h"
#import "XMAddressResource.h"

@interface XMH323URL : XMURL {
}

/**
 * Returns whether url represents a valid H323-URL
 * or not. Parsing may still fail.
 **/
+ (BOOL)canHandleStringRepresentation:(NSString *)url;

/**
 * Dictionaries are not supported for H323-URLs. Returns NO.
 **/
+ (BOOL)canHandleDictionaryRepresentation:(NSDictionary *)dictionary;

/**
 * Parses the URL string and returns a h323 url instance. Returns nil
 * if parsing fails.
 **/
+ (XMH323URL *)addressResourceWithStringRepresentation:(NSString *)url;

/**
 * Dictionaries are not supported for H323-URLs. Returns nil
 **/
+ (XMH323URL *)addressResourceWithDictionaryRepresentation:(NSDictionary *)dictionary;

@end

#endif // __XM_H323_URL_H__