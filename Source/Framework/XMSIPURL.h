/*
 * $Id: XMSIPURL.h,v 1.1 2007/05/08 15:17:46 hfriederich Exp $
 *
 * Copyright (c) 2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_SIP_URL_H__
#define __XM_SIP_URL_H__

#import <Foundation/Foundation.h>
#import "XMTypes.h"
#import "XMAddressResource.h"

@interface XMSIPURL : XMAddressResource {
	
	NSString *url;
    NSString *address;
}

/**
 * Returns whether url represents a valid SIP-URL
 * or not. Parsing may still fail.
 **/
+ (BOOL)canHandleStringRepresentation:(NSString *)url;

/**
 * Dictionaries are not supported for SIP-URLs. Returns NO.
 **/
+ (BOOL)canHandleDictionaryRepresentation:(NSDictionary *)dictionary;

/**
 * Parses the URL string and returns a SIP url instance. Returns nil
 * if parsing fails.
 **/
+ (XMSIPURL *)addressResourceWithStringRepresentation:(NSString *)url;

/**
 * Dictionaries are not supported for SIP-URLs. Returns nil
 **/
+ (XMSIPURL *)addressResourceWithDictionaryRepresentation:(NSDictionary *)dictionary;

- (id)initWithStringRepresentation:(NSString *)url;
- (NSString *)stringRepresentation;

@end

#endif // __XM_SIP_URL_H__