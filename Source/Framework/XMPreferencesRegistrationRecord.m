/*
 * $Id: XMPreferencesRegistrationRecord.m,v 1.4 2008/10/12 12:24:12 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#import "XMPreferencesRegistrationRecord.h"

#import "XMStringConstants.h"
#import "XMPrivate.h"

@implementation XMPreferencesRegistrationRecord

#pragma mark Init & Deallocation Methods

- (id)init
{
	self = [super init];
	
	domain = nil;
	username = nil;
	authorizationUsername = nil;
	password = nil;
  aor = nil;
	
	return self;
}

- (id)_initWithDictionary:(NSDictionary *)dictionary
{
	self = [self init];
	
	Class stringClass = [NSString class];
	
	NSString *string = (NSString *)[dictionary objectForKey:XMKey_PreferencesRegistrationRecordDomain];
	if (string && [string isKindOfClass:stringClass]) {
		domain = [string retain];
	}
	
	string = (NSString *)[dictionary objectForKey:XMKey_PreferencesRegistrationRecordUsername];
	if (string && [string isKindOfClass:stringClass]) {
		username = [string retain];
	}
	
	string = (NSString *)[dictionary objectForKey:XMKey_PreferencesRegistrationRecordAuthorizationUsername];
	if (string && [string isKindOfClass:stringClass]) {
		authorizationUsername = [string retain];
	}
	
	string = (NSString *)[dictionary objectForKey:XMKey_PreferencesRegistrationRecordPassword];
	if (string && [string isKindOfClass:stringClass]) {
		password = [string retain];
	}
  
  aor = nil;
	
	return self;
}

- (id)initWithCoder:(NSCoder *)coder
{	self = [super init];
	
	if ([coder allowsKeyedCoding]) { // use keyed coding
		[self setDomain:(NSString *)[coder decodeObjectForKey:XMKey_PreferencesRegistrationRecordDomain]];
		[self setUsername:(NSString *)[coder decodeObjectForKey:XMKey_PreferencesRegistrationRecordUsername]];
		[self setAuthorizationUsername:(NSString *)[coder decodeObjectForKey:XMKey_PreferencesRegistrationRecordAuthorizationUsername]];
		[self setPassword:(NSString *)[coder decodeObjectForKey:XMKey_PreferencesRegistrationRecordPassword]];
	} else { // raise an exception
		[NSException raise:XMException_UnsupportedCoder format:XMExceptionReason_UnsupportedCoder];
		[self release];
		return nil;
	}
  
  aor = nil;
	
	return self;	
}

- (id)copyWithZone:(NSZone *)zone
{
	XMPreferencesRegistrationRecord *record = [[XMPreferencesRegistrationRecord alloc] init];
	
	[record setDomain:[self domain]];
	[record setUsername:[self username]];
	[record setAuthorizationUsername:[self authorizationUsername]];
	[record setPassword:[self password]];
	
	return record;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	if ([coder allowsKeyedCoding]) {
		[coder encodeObject:[self domain] forKey:XMKey_PreferencesRegistrationRecordDomain];
		[coder encodeObject:[self username] forKey:XMKey_PreferencesRegistrationRecordUsername];
		[coder encodeObject:[self authorizationUsername] forKey:XMKey_PreferencesRegistrationRecordAuthorizationUsername];
		[coder encodeObject:[self password] forKey:XMKey_PreferencesRegistrationRecordPassword];
	} else {
		[NSException raise:XMException_UnsupportedCoder format:XMExceptionReason_UnsupportedCoder];
	}
}

#pragma mark -
#pragma mark NSObject functionality

- (BOOL)isEqual:(id)object
{
	if (object == self) {
		return YES;
	}
	
	if (![object isKindOfClass:[self class]]) {
		return NO;
	}
	
	XMPreferencesRegistrationRecord *record = (XMPreferencesRegistrationRecord *)object;
	
	if ([[self domain] isEqualToString:[record domain]] &&
	    [[self username] isEqualToString:[record username]] &&
	    [[self authorizationUsername] isEqualToString:[record authorizationUsername]] &&
	    [[self password] isEqualToString:[record password]]) {
		return YES;
	}
	
	return NO;
}

- (NSMutableDictionary *)dictionaryRepresentation
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:4];
	
	NSString *string = [self domain];
	if (string) {
		[dict setObject:string forKey:XMKey_PreferencesRegistrationRecordDomain];
	}
	
	string = [self username];
	if (string) {
		[dict setObject:string forKey:XMKey_PreferencesRegistrationRecordUsername];
	}
	
	string = [self authorizationUsername];
	if (string) {
		[dict setObject:string forKey:XMKey_PreferencesRegistrationRecordAuthorizationUsername];
	}
	
	string = [self password];
	if (string) {
		[dict setObject:string forKey:XMKey_PreferencesRegistrationRecordPassword];
	}
	
	return dict;
}

#pragma mark -
#pragma mark Get & Set Methods

- (NSString *)domain
{
	return domain;
}

- (void)setDomain:(NSString *)theDomain
{
	NSString *old = domain;
	domain = [theDomain copy];
	[old release];
  
  [aor release];
  aor = nil;
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
  
  [aor release];
  aor = nil;
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
