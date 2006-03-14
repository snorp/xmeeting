/*
 * $Id: XMCalltoURL.h,v 1.3 2006/03/14 23:05:57 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CALLTO_URL_H__
#define __XM_CALLTO_URL_H__
#else

#import <Foundation/Foundation.h>
#import "XMTypes.h"
#import "XMURL.h"

extern NSString *XMKey_CalltoURLType;
extern NSString *XMKey_CalltoURLConferenceToJoin;
extern NSString *XMKey_CalltoURLGatekeeperHost;

@interface XMCalltoURL : XMURL {
	
	NSString *url;

	XMCalltoURLType type;
	NSString *address;
	unsigned port;
	NSString *conferenceToJoin;
	
	NSString *gkHost;
}

/**
 * Returns whether url represents a callto: URL or not.
 * This does not check whether the url is valid and can
 * be correctly parsed. All this method does is to check
 * whether url has the "callto://" prefix
 **/
+ (BOOL)canHandleString:(NSString *)url;

/**
 * Returns whether dictionary represents a callto: URL or not.
 * This method does not check whether the contents of dictionary
 * represent a valid url or not.
 **/
+ (BOOL)canHandleDictionary:(NSDictionary *)dictionary;

/**
 * Creates an autoreleased instance of XMCalltoURL with the parsed
 * contents of url. If the parsing fails, nil is returned
 **/
+ (XMCalltoURL *)urlWithString:(NSString *)url;

/**
 * Creates an autoreleased instance of XMCalltoURL with the contents
 * of dictionary.
 **/
+ (XMCalltoURL *)urlWithDictionary:(NSDictionary *)dictionary;

/**
 * Sets/Gets the values of the URL
 **/
- (XMCalltoURLType)type;
- (void)setType:(XMCalltoURLType)theType;
- (void)setAddress:(NSString *)theAddress;
- (void)setPort:(unsigned)port;
- (NSString *)conferenceToJoin;
- (void)setConferenceToJoin:(NSString *)conferenceToJoin;
- (NSString *)gatekeeperHost;
- (void)setGatekeeperHost:(NSString *)host;

// this deals with the complete address section "address(:port)(**conferenceToJoin)"
- (NSString *)addressPart;
- (BOOL)setAddressPart:(NSString *)addressPart;	// returns the success of this operation

@end

#endif // __XM_CALLTO_URL_H__