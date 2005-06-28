/*
 * $Id: XMGeneralPurposeURL.m,v 1.1 2005/06/28 20:41:06 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMStringConstants.h"
#import "XMTypes.h"
#import "XMGeneralPurposeURL.h"
#import "XMPrivate.h"

@implementation XMGeneralPurposeURL

#pragma mark Class Methods

+ (BOOL)canHandleDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation
{
	NSNumber *number = (NSNumber *)[dictionaryRepresentation objectForKey:XMKey_URLType];
	
	if(number != nil && [number unsignedIntValue] == XMURLType_GeneralPurposeURL)
	{
		return YES;
	}
	return NO;
}
		
+ (XMGeneralPurposeURL *)urlWithDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation
{
	XMGeneralPurposeURL *generalPurposeURL = [[XMGeneralPurposeURL alloc] initWithDictionaryRepresentation:dictionaryRepresentation];
	return [generalPurposeURL autorelease];
}

#pragma mark Init & Deallocation methods

- (id)init
{
	dictionary = [[NSMutableDictionary alloc] initWithCapacity:3];
	NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:XMURLType_GeneralPurposeURL];
	[dictionary setObject:number forKey:XMKey_URLType];
	[number release];
	
	return self;
}

- (id)initWithDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation
{
	NSNumber *number = [dictionaryRepresentation objectForKey:XMKey_URLType];
	
	if(number == nil || [number unsignedIntValue] != XMURLType_GeneralPurposeURL)
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

- (NSDictionary *)dictionaryRepresentation
{
	return [[dictionary copy] autorelease];
}

#pragma mark Getting & Setting the attributes

- (XMCallProtocol)callProtocol
{
	return XMCallProtocol_H323;
}

- (NSString *)address
{
	return [dictionary objectForKey:XMKey_URLAddress];
}

- (void)setAddress:(NSString *)address
{
	if(address != nil)
	{
		[dictionary setObject:address forKey:XMKey_URLAddress];
	}
	else
	{
		[dictionary removeObjectForKey:XMKey_URLAddress];
	}
}

- (NSString *)humanReadableRepresentation
{
	return [self address];
}

- (id)valueForKey:(NSString *)key
{
	return [dictionary objectForKey:key];
}

- (void)setValue:(id)value forKey:(NSString *)key
{
	BOOL correctType = YES;
	
	if([key isEqualToString:XMKey_URLAddress])
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

@end
