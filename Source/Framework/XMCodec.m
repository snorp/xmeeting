/*
 * $Id: XMCodec.m,v 1.1 2005/06/28 20:41:06 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMStringConstants.h"
#import "XMCodec.h"
#import "XMPrivate.h"

@implementation XMCodec

#pragma mark Init & Deallocation Methods

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	return nil;
}

- (id)_initWithDictionary:(NSDictionary *)dict
{
	NSString *anIdentifier = [dict objectForKey:XMKey_CodecIdentifier];
	NSString *aName = [dict objectForKey:XMKey_CodecName];
	NSString *aBandwidth = [dict objectForKey:XMKey_CodecBandwidth];
	NSString *aQuality = [dict objectForKey:XMKey_CodecQuality];
	
	if(anIdentifier == nil || aName == nil || aBandwidth == nil || aQuality == nil)
	{
		[NSException raise:XMException_InternalConsistencyFailure
					format:XMExceptionReason_CodecManagerInternalConsistencyFailure];
	}
	
	return [self _initWithIdentifier:anIdentifier name:aName bandwidth:aBandwidth quality:aQuality];
}

- (id)_initWithIdentifier:(NSString *)anIdentifier
					 name:(NSString *)aName 
				bandwidth:(NSString *)aBandwidth 
				  quality:(NSString *)aQuality
{
	self = [super init];
	
	identifier = [anIdentifier copy];
	name = [aName copy];
	bandwidth = [aBandwidth copy];
	quality = [aQuality copy];
	
	return self;
}

- (void)dealloc
{
	[identifier release];
	[name release];
	[bandwidth release];
	[quality release];
	
	[super dealloc];
}

#pragma mark General NSObject Functionality

- (BOOL)isEqual:(NSObject *)object
{
	if(self == object)
	{
		return YES;
	}
	
	if([object isKindOfClass:[self class]])
	{
		XMCodec *codec = (XMCodec *)object;
		if([identifier isEqualToString:[codec identifier]] &&
		   [name isEqualToString:[codec name]] &&
		   [bandwidth isEqualToString:[codec bandwidth]] &&
		   [quality isEqualToString:[codec quality]])
		{
			return YES;
		}
	}
	return NO;
}

#pragma mark Accessors

- (NSString *)propertyForKey:(NSString *)theKey
{
	if([theKey isEqualToString:XMKey_CodecIdentifier])
	{
		return identifier;
	}
	
	if([theKey isEqualToString:XMKey_CodecName])
	{
		return name;
	}
	
	if([theKey isEqualToString:XMKey_CodecBandwidth])
	{
		return bandwidth;
	}
	
	if([theKey isEqualToString:XMKey_CodecQuality])
	{
		return quality;
	}
	
	return nil;
}

- (NSString *)identifier
{
	return identifier;
}

- (NSString *)name
{
	return name;
}

- (NSString *)bandwidth
{
	return bandwidth;
}

- (NSString *)quality
{
	return quality;
}

@end
