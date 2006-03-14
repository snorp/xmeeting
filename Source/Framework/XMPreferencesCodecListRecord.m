/*
 * $Id: XMPreferencesCodecListRecord.m,v 1.3 2006/03/14 23:05:57 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMStringConstants.h"
#import "XMPreferencesCodecListRecord.h"
#import "XMPrivate.h"

@implementation XMPreferencesCodecListRecord

#pragma mark Init & Deallocation Methods

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	return nil;
}

- (id)_initWithIdentifier:(XMCodecIdentifier)theIdentifier enabled:(BOOL)enabled
{
	self = [super init];
	
	identifier = theIdentifier;
	[self setEnabled:enabled];
	
	return self;
}

- (id)_initWithDictionary:(NSDictionary *)dict
{
	NSObject *obj;
	
	self = [super init];
	
	obj = [dict objectForKey:XMKey_PreferencesCodecListRecordIdentifier];
	if(obj)
	{
		identifier = (XMCodecIdentifier)[(NSNumber *)obj unsignedIntValue];
	}
	else
	{
		identifier = XMCodecIdentifier_UnknownCodec;
	}
	
	obj = [dict objectForKey:XMKey_PreferencesCodecListRecordIsEnabled];
	if(obj)
	{
		isEnabled = [(NSNumber *)obj boolValue];
	}
	else
	{
		isEnabled = NO;
	}
	
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	return [[XMPreferencesCodecListRecord allocWithZone:zone] _initWithIdentifier:[self identifier] enabled:[self isEnabled]];
}

- (id)initWithCoder:(NSCoder *)coder
{
	self = [super init];
	
	if([coder allowsKeyedCoding]) // use keyed coding
	{
		identifier = (XMCodecIdentifier)[coder decodeIntForKey:XMKey_PreferencesCodecListRecordIdentifier];
		[self setEnabled:[coder decodeBoolForKey:XMKey_PreferencesCodecListRecordIsEnabled]];
	}
	else // raise an exception
	{
		[NSException raise:XMException_UnsupportedCoder format:XMExceptionReason_UnsupportedCoder];
		[self release];
		return nil;
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	if([coder allowsKeyedCoding])
	{
		[coder encodeInt:(int)[self identifier] forKey:XMKey_PreferencesCodecListRecordIdentifier];
		[coder encodeBool:[self isEnabled] forKey:XMKey_PreferencesCodecListRecordIsEnabled];
	}
	else
	{
		[NSException raise:XMException_UnsupportedCoder format:XMExceptionReason_UnsupportedCoder];
	}
}

#pragma mark General NSObject Functionality

- (BOOL)isEqual:(id)object
{
	XMPreferencesCodecListRecord *record;
	
	if(object == self)
	{
		return YES;
	}
	
	if(![object isKindOfClass:[self class]])
	{
		return NO;
	}
	
	record = (XMPreferencesCodecListRecord *)object;
	
	if([record identifier] == [self identifier] &&
	   [record isEnabled] == [self isEnabled])
	{
		return YES;
	}
	return NO;
}

#pragma mark Getting Different Representations

- (NSMutableDictionary *)dictionaryRepresentation
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];
	NSNumber *number;
	
	number = [[NSNumber alloc] initWithUnsignedInt:(unsigned)[self identifier]];
	[dict setObject:number forKey:XMKey_PreferencesCodecListRecordIdentifier];
	[number release];
	
	number = [[NSNumber alloc] initWithBool:[self isEnabled]];
	[dict setObject:number forKey:XMKey_PreferencesCodecListRecordIsEnabled];
	[number release];
	
	return dict;
}

#pragma mark Obtaining values through keys

- (id)propertyForKey:(NSString *)key
{
	if([key isEqualToString:XMKey_PreferencesCodecListRecordIdentifier])
	{
		return [NSNumber numberWithUnsignedInt:(unsigned)[self identifier]];
	}
	else if([key isEqualToString:XMKey_PreferencesCodecListRecordIsEnabled])
	{
		return [NSNumber numberWithBool:[self isEnabled]];
	}
	
	return nil;
}

- (void)setProperty:(id)property forKey:(NSString *)key
{
	if([key isEqualToString:XMKey_PreferencesCodecListRecordIsEnabled])
	{
		if([property isKindOfClass:[NSNumber class]])
		{
			[self setEnabled:[(NSNumber *)property boolValue]];
		}
		else
		{
			[NSException raise:XMException_InvalidParameter format:XMExceptionReason_InvalidParameterMustBeOfCorrectType];
		}
	}
	[NSException raise:XMException_InvalidParameter format:XMExceptionReason_InvalidParameterMustBeValidKey];
}

#pragma mark Getter & Setter Methods

- (XMCodecIdentifier)identifier;
{
	return identifier;
}

- (BOOL)isEnabled
{
	return isEnabled;
}

- (void)setEnabled:(BOOL)flag
{
	isEnabled = flag;
}

@end

