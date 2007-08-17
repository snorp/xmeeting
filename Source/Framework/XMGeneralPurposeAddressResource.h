/*
 * $Id: XMGeneralPurposeAddressResource.h,v 1.4 2007/08/17 11:36:41 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_GENERAL_PURPOSE_ADDRESS_RESOURCE_H__
#define __XM_GENERAL_PURPOSE_ADDRESS_RESOURCE_H__

#import <Foundation/Foundation.h>
#import "XMTypes.h"
#import "XMAddressResource.h"

/**
 * XMGeneralPurposeAddressResource is a very powerful subclass
 * of XMAddressResource since it allows to set specific preferences
 * besides just the usual protocol/address/port stuff. So, it is
 * possible to force gatekeeper usage or use a different gatekeeper
 * than the one specified. This class does not provide the -stringRepresentation
 * or -initWithStringRepresentation: methods, as they do not make sense
 * for this subclass
 **/
@interface XMGeneralPurposeAddressResource : XMAddressResource {
	
@private
  NSMutableDictionary *dictionary;

}

+ (BOOL)canHandleStringRepresentation:(NSString *)stringRepresentation;
+ (BOOL)canHandleDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation;
+ (XMGeneralPurposeAddressResource *)addressResourceWithStringRepresentation:(NSString *)stringRepresentation;
+ (XMGeneralPurposeAddressResource *)addressResourceWithDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation;

- (id)initWithDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation;

- (NSDictionary *)dictionaryRepresentation;

- (XMCallProtocol)callProtocol;
- (void)setCallProtocol:(XMCallProtocol)callProtocol;

- (NSString *)address;
- (void)setAddress:(NSString *)address;

/**
 * This class does not create a human readable
 * address. Therefore, simply -address is returned
 **/
- (NSString *)humanReadableAddress;

/**
 * Returns the specific value set for key,
 * or nil if no value is set for this key.
 * The allowed keys are the defined XMPreferences keys
 * found in XMStringConstants.h. In addition, the keys
 * XMKey_AddressResourceCallProtocol, XMKey_AddressResourceAddress
 * and XMKey_AddressResourceHumanReadableAddress can also be queried
 **/
- (id)valueForKey:(NSString *)key;

/**
 * Allows you to set the value associated with key.
 * The allowed keys are the defined XMPreferences keys
 * found in XMStringConstants.h. In addition, the keys
 * XMKey_AddressResourceCallProtocol and XMKey_AddressResourceAddress
 * can also be set.
 * If the value does not have the correct type or if the key 
 * is not a valid key, an exception is raised. If value is
 * nil, any value set for key is removed.
 **/
- (void)setValue:(id)property forKey:(NSString *)key;

@end

#endif // __XM_GENERAL_PURPOSE_ADDRESS_RESOURCE_H__
