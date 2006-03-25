/*
 * $Id: XMGeneralPurposeAddressResource.m,v 1.3 2006/03/25 10:41:56 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMGeneralPurposeAddressResource.h"

#import "XMStringConstants.h"
#import "XMTypes.h"
#import "XMPrivate.h"

@implementation XMGeneralPurposeAddressResource

#pragma mark Class Methods

+ (BOOL)canHandleStringRepresentation:(NSString *)stringRepresentation
{
	return NO;
}

+ (BOOL)canHandleDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation
{
	NSNumber *number = (NSNumber *)[dictionaryRepresentation objectForKey:XMKey_GeneralPurposeAddressResource];
	
	if(number != nil)
	{
		return YES;
	}
	return NO;
}

+ (XMGeneralPurposeAddressResource *)addressResourceWithStringRepresentation:(NSString *)stringRepresentation
{
	return nil;
}
		
+ (XMGeneralPurposeAddressResource *)addressResourceWithDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation
{
	XMGeneralPurposeAddressResource *generalPurposeAddressResource = [[XMGeneralPurposeAddressResource alloc] initWithDictionaryRepresentation:dictionaryRepresentation];
	if(generalPurposeAddressResource != nil)
	{
		[generalPurposeAddressResource autorelease];
	}
	return generalPurposeAddressResource;
}

#pragma mark Init & Deallocation methods

- (id)init
{
	dictionary = [[NSMutableDictionary alloc] initWithCapacity:3];
	NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:1];
	[dictionary setObject:number forKey:XMKey_GeneralPurposeAddressResource];
	[number release];
	
	return self;
}

- (id)initWithDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation
{
	NSNumber *number = [dictionaryRepresentation objectForKey:XMKey_GeneralPurposeAddressResource];
	
	if(number == nil)
	{
		[self release];
		return nil;
	}
	
	dictionary = [dictionaryRepresentation mutableCopy];
	
	return self;
}

- (void)dealloc
{
	[dictionary release];
	
	[super dealloc];
}

#pragma mark Getting different Representations

- (NSString *)stringRepresentation
{
	return nil;
}

- (NSDictionary *)dictionaryRepresentation
{
	return [[dictionary copy] autorelease];
}

#pragma mark Getting & Setting the attributes

- (XMCallProtocol)callProtocol
{
	NSNumber *number = [dictionary objectForKey:XMKey_AddressResourceCallProtocol];
	if(number == nil)
	{
		return XMCallProtocol_H323; // backwards compatibility
	}
	
	XMCallProtocol callProtocol = (XMCallProtocol)[number unsignedIntValue];
	return callProtocol;
}

- (void)setCallProtocol:(XMCallProtocol)callProtocol
{
	NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:callProtocol];
	
	[dictionary setObject:number forKey:XMKey_AddressResourceCallProtocol];
	
	[number release];
}

- (NSString *)address
{
	return [dictionary objectForKey:XMKey_AddressResourceAddress];
}

- (void)setAddress:(NSString *)address
{
	if(address != nil)
	{
		[dictionary setObject:address forKey:XMKey_AddressResourceAddress];
	}
	else
	{
		[dictionary removeObjectForKey:XMKey_AddressResourceAddress];
	}
}

- (NSString *)humanReadableAddress
{
	return [self address];
}

- (id)valueForKey:(NSString *)key
{
	if([key isEqualToString:XMKey_GeneralPurposeAddressResource])
	{
		return nil;
	}
	if([key isEqualToString:XMKey_AddressResourceCallProtocol])
	{
		XMCallProtocol callProtocol = [self callProtocol];
		return [NSNumber numberWithUnsignedInt:callProtocol];
	}
	if([key isEqualToString:XMKey_AddressResourceHumanReadableAddress])
	{
		return [self humanReadableAddress];
	}
	return [dictionary objectForKey:key];
}

- (void)setValue:(id)value forKey:(NSString *)key
{
	BOOL correctType = YES;
	
	if([key isEqualToString:XMKey_AddressResourceCallProtocol])
	{
		// do nothing right now
	}
	else if([key isEqualToString:XMKey_AddressResourceAddress])
	{
		if([value isKindOfClass:[NSString class]])
		{
			[self setAddress:(NSString *)value];
		}
		else
		{
			correctType = NO;
		}
	}
	else
	{
		XM_VALUE_TEST_RESULT result = [XMPreferences _checkValue:value forKey:key];
		
		if(result == XM_INVALID_KEY)
		{
			[NSException raise:XMException_InvalidParameter format:XMExceptionReason_InvalidParameterMustBeValidKey];
		}
		else if(result == XM_INVALID_VALUE_TYPE)
		{
			if(value == nil)
			{
				[dictionary removeObjectForKey:key];
			}
			else
			{
				correctType = NO;
			}
		}
		else
		{
			if(value == nil)
			{
				[dictionary removeObjectForKey:key];
			}
			else
			{
				[dictionary setObject:value forKey:key];
			}
		}
	}
	
	if(correctType == NO)
	{
		[NSException raise:XMException_InvalidParameter format:XMExceptionReason_InvalidParameterMustBeOfCorrectType];
	}
}

#pragma mark Framework Methods

- (BOOL)_doesModifyPreferences:(XMPreferences *)preferences
{
	NSArray *keys = [dictionary allKeys];
	
	unsigned i;
	unsigned count = [keys count];
	
	for(i = 0; i < count; i++)
	{
		NSString *key = [keys objectAtIndex:i];
		
		if([key isEqualToString:XMKey_GeneralPurposeAddressResource] ||
		   [key isEqualToString:XMKey_AddressResourceAddress])
		{
			continue;
		}
		
		NSObject *value = [dictionary objectForKey:key];
		if(![[preferences valueForKey:key] isEqual:value])
		{
			// at least one property changed, this is sufficiant
			// to return YES
			return YES;
		}
	}
	
	return NO;
}

- (void)_modifyPreferences:(XMPreferences *)preferences
{
	NSArray *keys = [dictionary allKeys];
	
	unsigned i;
	unsigned count = [keys count];
	
	for(i = 0; i < count; i++)
	{
		NSString *key = [keys objectAtIndex:i];
		
		if([key isEqualToString:XMKey_GeneralPurposeAddressResource] ||
		   [key isEqualToString:XMKey_AddressResourceAddress])
		{
			continue;
		}
		
		NSObject *value = [dictionary objectForKey:key];
		
		[preferences setValue:value forKey:key];
	}
}

@end
