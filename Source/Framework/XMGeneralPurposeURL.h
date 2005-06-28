/*
 * $Id: XMGeneralPurposeURL.h,v 1.1 2005/06/28 20:41:06 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_GENERAL_PURPOSE_URL_H__
#define __XM_GENERAL_PURPOSE_URL_H__

#import <Cocoa/Cocoa.h>
#import "XMTypes.h"
#import "XMURL.h"

/**
 * XMGeneralPurposeURL is a very powerful subclass
 * of XMURL since it allows to set specific preferences
 * besides just the usual protocol/address/port stuff.
 * So, it is possible to force gatekeeper usage or use
 * a different gatekeeper than the one specified.
 * This class does not provide the -stringRepresentation
 * or -initWithStringRepresentation: methods.
 **/
@interface XMGeneralPurposeURL : XMURL {
	
	NSMutableDictionary *dictionary;

}

+ (BOOL)canHandleDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation;
+ (XMGeneralPurposeURL *)urlWithDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation;

- (id)initWithDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation;

- (NSDictionary *)dictionaryRepresentation;

- (XMCallProtocol)callProtocol;

- (NSString *)address;
- (void)setAddress:(NSString *)address;

/**
 * Returns the specific value set for key,
 * or nil if no value is set for this key.
 * The allowed keys are the defined XMPreferences keys
 * found in XMStringConstants.h. In addition, the keys
 * XMKey_URLType and XMKey_URLAddress can also be queried.
 **/
- (id)valueForKey:(NSString *)key;

/**
 * Allows you to set the value associated with key.
 * The allowed keys are the defined XMPreferences keys
 * found in XMStringConstants.h. In addition, the key
 * XMKey_URLAddress can also be set (same effect as -setAddress:)
 * If the value does not have the correct type or if the key 
 * is not a valid key, an exception is raised. If value is
 * nil, any value set for key is removed.
 **/
- (void)setValue:(id)property forKey:(NSString *)key;

@end

#endif // __XM_GENERAL_PURPOSE_URL_H__
