/*
 * $Id: XMLocation.m,v 1.2 2005/05/24 15:21:01 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMLocation.h"

NSString *XMKey_LocationName = @"XMeeting_LocationName";

@implementation XMLocation

- (id)initWithName:(NSString *)theName
{
	self = [super init];
	[self setName:theName];
	[self _setTag:0];
	
	return self;
}

- (id)initWithDictionary:(NSDictionary *)dict
{
	self = [super initWithDictionary:dict];
	
	NSString *theName = (NSString *)[dict objectForKey:XMKey_LocationName];
	[self setName:theName];
	[self _setTag:0];
	
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	XMLocation *location = (XMLocation *)[super copyWithZone:zone];
	
	[location setName:[self name]];
	[location _setTag:[self _tag]];
	
	
	return location;
}

- (void)dealloc
{
	[name release];
	
	[super dealloc];
}

- (BOOL)isEqual:(id)object
{
	if ([super isEqual:object] && 
			[[self name] isEqualToString:[(XMLocation *)object name]])
	{
		return YES;
	}
	
	return NO;
}

- (NSMutableDictionary *)dictionaryRepresentation
{
	NSMutableDictionary *dict = [super dictionaryRepresentation];
	
	NSString *theName = [self name];
	
	if(theName)
	{
		[dict setObject:theName forKey:XMKey_LocationName];
	}
	
	return dict;
}

- (NSString *)name
{
	return name;
}

- (void)setName:(NSString *)theName
{
	NSString *old = name;
	name = [theName copy];
	[old release];
}

- (XMLocation *)duplicateWithName:(NSString *)theName
{
	XMLocation *duplicate = [self copy];
	[duplicate setName:theName];
	[duplicate _updateTag];
	
	return duplicate;
}

- (void)_updateTag
{
	static unsigned nextTag = 1;
	
	[self _setTag:nextTag];
	nextTag++;
}

- (void)_setTag:(unsigned)newTag
{
	tag = newTag;
}

- (unsigned)_tag
{
	return tag;
}

#pragma mark overriding methods from XMPreferences

- (NSString *)userName
{
	return @"UserName";
}

- (void)setUserName:(NSString *)name
{
}

- (BOOL)autoAnswerCalls
{
	return NO;
}

- (void)setAutoAnswerCalls:(BOOL)flag
{
}

@end
