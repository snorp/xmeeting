/*
 * $Id: XMPreferencesRegistrarRecord.m,v 1.1 2006/04/06 23:15:32 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMPreferencesRegistrarRecord.h"

#import "XMStringConstants.h"
#import "XMPrivate.h"

@implementation XMPreferencesRegistrarRecord

#pragma mark Init & Deallocation Methods

- (id)init
{
	self = [super init];
	
	host = nil;
	username = nil;
	authorizationUsername = nil;
	password = nil;
	
	return self;
}

- (id)_initWithDictionary:(NSDictionary *)dictionary
{
	self = [self init];
	
	Class stringClass = [NSString class];
	
	NSString *string = (NSString *)[dictionary objectForKey:XMKey_PreferencesRegistrarRecordHost];
	if(string && [string isKindOfClass:stringClass])
	{
		host = [string retain];
	}
	
	string = (NSString *)[dictionary objectForKey:XMKey_PreferencesRegistrarRecordUsername];
	if(string && [string isKindOfClass:stringClass])
	{
		username = [string retain];
	}
	
	string = (NSString *)[dictionary objectForKey:XMKey_PreferencesRegistrarRecordAuthorizationUsername];
	if(string && [string isKindOfClass:stringClass])
	{
		authorizationUsername = [string retain];
	}
	
	string = (NSString *)[dictionary objectForKey:XMKey_PreferencesRegistrarRecordPassword];
	if(string && [string isKindOfClass:stringClass])
	{
		password = [string retain];
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder *)coder
{	self = [super init];
	
	if([coder allowsKeyedCoding]) // use keyed coding
	{
		[self setHost:(NSString *)[coder decodeObjectForKey:XMKey_PreferencesRegistrarRecordHost]];
		[self setUsername:(NSString *)[coder decodeObjectForKey:XMKey_PreferencesRegistrarRecordUsername]];
		[self setAuthorizationUsername:(NSString *)[coder decodeObjectForKey:XMKey_PreferencesRegistrarRecordAuthorizationUsername]];
		[self setPassword:(NSString *)[coder decodeObjectForKey:XMKey_PreferencesRegistrarRecordPassword]];
	}
	else // raise an exception
	{
		[NSException raise:XMException_UnsupportedCoder format:XMExceptionReason_UnsupportedCoder];
		[self release];
		return nil;
	}
	
	return self;	
}

- (id)copyWithZone:(NSZone *)zone
{
	XMPreferencesRegistrarRecord *record = [[XMPreferencesRegistrarRecord alloc] init];
	
	[record setHost:[self host]];
	[record setUsername:[self username]];
	[record setAuthorizationUsername:[self authorizationUsername]];
	[record setPassword:[self password]];
	
	return record;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	if([coder allowsKeyedCoding])
	{
		[coder encodeObject:[self host] forKey:XMKey_PreferencesRegistrarRecordHost];
		[coder encodeObject:[self username] forKey:XMKey_PreferencesRegistrarRecordUsername];
		[coder encodeObject:[self authorizationUsername] forKey:XMKey_PreferencesRegistrarRecordAuthorizationUsername];
		[coder encodeObject:[self password] forKey:XMKey_PreferencesRegistrarRecordPassword];
	}
	else
	{
		[NSException raise:XMException_UnsupportedCoder format:XMExceptionReason_UnsupportedCoder];
	}
}

#pragma mark -
#pragma mark NSObject functionality

- (BOOL)isEqual:(id)object
{
	if(object == self)
	{
		return YES;
	}
	
	if(![object isKindOfClass:[self class]])
	{
		return NO;
	}
	
	XMPreferencesRegistrarRecord *record = (XMPreferencesRegistrarRecord *)object;
	
	if([[self host] isEqualToString:[record host]] &&
	   [[self username] isEqualToString:[record username]] &&
	   [[self authorizationUsername] isEqualToString:[record authorizationUsername]] &&
	   [[self password] isEqualToString:[record password]])
	{
		return YES;
	}
	
	return NO;
}

- (NSMutableDictionary *)dictionaryRepresentation
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:4];
	
	NSString *string = [self host];
	if(string)
	{
		[dict setObject:string forKey:XMKey_PreferencesRegistrarRecordHost];
	}
	
	string = [self username];
	if(string)
	{
		[dict setObject:string forKey:XMKey_PreferencesRegistrarRecordUsername];
	}
	
	string = [self authorizationUsername];
	if(string)
	{
		[dict setObject:string forKey:XMKey_PreferencesRegistrarRecordAuthorizationUsername];
	}
	
	string = [self password];
	if(string)
	{
		[dict setObject:string forKey:XMKey_PreferencesRegistrarRecordPassword];
	}
	
	return dict;
}

#pragma mark -
#pragma mark Get & Set Methods

- (NSString *)host
{
	return host;
}

- (void)setHost:(NSString *)theHost
{
	NSString *old = host;
	host = [theHost copy];
	[old release];
}

- (NSString *)username
{
	return username;
}

- (void)setUsername:(NSString *)theUsername
{
	NSString *old = username;
	username = [theUsername copy];
	[old release];
}

- (NSString *)authorizationUsername
{
	return authorizationUsername;
}

- (void)setAuthorizationUsername:(NSString *)theAuthorizationUsername
{
	NSString *old = authorizationUsername;
	authorizationUsername = [theAuthorizationUsername copy];
	[old release];
}

- (NSString *)password
{
	return password;
}

- (void)setPassword:(NSString *)thePassword
{
	NSString *old = password;
	password = [thePassword copy];
	[old release];
}

@end
