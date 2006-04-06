/*
 * $Id: XMLocation.m,v 1.6 2006/04/06 23:15:31 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMLocation.h"

#import "XMPreferencesManager.h"
#import "XMH323Account.h"
#import "XMSIPAccount.h"

NSString *XMKey_LocationName = @"XMeeting_LocationName";
NSString *XMKey_LocationH323AccountID = @"XMeeting_H323AccountID";
NSString *XMKey_LocationSIPAccountID = @"XMeeting_SIPAccountID";

@interface XMLocation (PrivateMethods)

- (void)_setTag:(unsigned)tag;
- (void)_setGatekeeperPassword:(NSString *)gkPassword registrarPasswords:(NSArray *)registrarPasswords;

@end

/**
 * Important note for -initWithDictionary and -dictionaryRepresentation methods:
 * Since the tag isn't persistent across application launches, not the tag is
 * stored in the dictionary and read there from but rather the index of the
 * account from the preferences manager.
 **/

@implementation XMLocation

#pragma mark -
#pragma mark Init & Deallocation Methods

- (id)initWithName:(NSString *)theName
{
	self = [super init];
	
	[self _setTag:0];
	[self setName:theName];
	
	h323AccountTag = 0;
	sipAccountTag = 0;
	
	gatekeeperPassword = nil;
	registrarPasswords = nil;
	
	return self;
}

- (id)initWithDictionary:(NSDictionary *)dict
{
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	
	self = [super initWithDictionary:dict];
	
	NSString *theName = (NSString *)[dict objectForKey:XMKey_LocationName];
	
	[self _setTag:0];
	[self setName:theName];
	
	NSNumber *number = (NSNumber *)[dict objectForKey:XMKey_LocationH323AccountID];
	if(number != nil)
	{
		unsigned index = [number unsignedIntValue];
		XMH323Account *h323Account = [preferencesManager h323AccountAtIndex:index];
		h323AccountTag = [h323Account tag];
	}
	
	number = (NSNumber *)[dict objectForKey:XMKey_LocationSIPAccountID];
	if(number != nil)
	{
		unsigned index = [number unsignedIntValue];
		XMSIPAccount *sipAccount = [preferencesManager sipAccountAtIndex:index];
		sipAccountTag = [sipAccount tag];
	}
	
	gatekeeperPassword = nil;
	registrarPasswords = nil;
	
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	XMLocation *location = (XMLocation *)[super copyWithZone:zone];
	
	[location _setTag:[self tag]];
	[location setName:[self name]];
	
	[location setH323AccountTag:[self h323AccountTag]];
	[location setSIPAccountTag:[self sipAccountTag]];
	
	return location;
}

- (void)dealloc
{
	[name release];
	
	[gatekeeperPassword release];
	[registrarPasswords release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark NSObject functionality

- (BOOL)isEqual:(id)object
{
	if ([super isEqual:object] && 
		[[self name] isEqualToString:[(XMLocation *)object name]] &&
		[self h323AccountTag] == [(XMLocation *)object h323AccountTag] &&
		[self sipAccountTag] == [(XMLocation *)object sipAccountTag])
	{
		return YES;
	}
	
	return NO;
}

#pragma mark -
#pragma mark Getting different representations

- (NSMutableDictionary *)dictionaryRepresentation
{
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	
	NSMutableDictionary *dict = [super dictionaryRepresentation];
	
	// removing unneded keys
	[dict removeObjectForKey:XMKey_PreferencesUserName];
	[dict removeObjectForKey:XMKey_PreferencesAutomaticallyAcceptIncomingCalls];
	[dict removeObjectForKey:XMKey_PreferencesGatekeeperAddress];
	[dict removeObjectForKey:XMKey_PreferencesGatekeeperUsername];
	[dict removeObjectForKey:XMKey_PreferencesGatekeeperPhoneNumber];
	[dict removeObjectForKey:XMKey_PreferencesGatekeeperPassword];
	[dict removeObjectForKey:XMKey_PreferencesRegistrarRecords];
	[dict removeObjectForKey:XMKey_PreferencesSIPProxyPassword];
	
	NSString *theName = [self name];
	
	if(theName)
	{
		[dict setObject:theName forKey:XMKey_LocationName];
	}
	
	if(h323AccountTag != 0)
	{
		unsigned h323AccountCount = [preferencesManager h323AccountCount];
		unsigned i;
		
		for(i = 0; i < h323AccountCount; i++)
		{
			XMH323Account *h323Account = [preferencesManager h323AccountAtIndex:i];
			if([h323Account tag] == h323AccountTag)
			{
				NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:i];
				[dict setObject:number forKey:XMKey_LocationH323AccountID];
				[number release];
				break;
			}
		}
	}
	
	if(sipAccountTag != 0)
	{
		unsigned sipAccountCount = [preferencesManager sipAccountCount];
		unsigned i;
		
		for(i = 0; i < sipAccountCount; i++)
		{
			XMSIPAccount *sipAccount = [preferencesManager sipAccountAtIndex:i];
			if([sipAccount tag] == sipAccountTag)
			{
				NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:i];
				[dict setObject:number forKey:XMKey_LocationSIPAccountID];
				[number release];
				break;
			}
		}
	}
	
	return dict;
}

- (XMLocation *)duplicateWithName:(NSString *)theName
{
	XMLocation *duplicate = [self copy];
	
	// causing it to assign a new tag to the duplicate
	[duplicate _setTag:0];
	[duplicate setName:theName];
	
	return duplicate;
}

#pragma mark -
#pragma mark Accessor methods

- (unsigned)tag
{
	return tag;
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

- (unsigned)h323AccountTag
{
	return h323AccountTag;
}

- (void)setH323AccountTag:(unsigned)theTag
{
	h323AccountTag = theTag;
}

- (unsigned)sipAccountTag
{
	return sipAccountTag;
}

- (void)setSIPAccountTag:(unsigned)theTag
{
	sipAccountTag = theTag;
}

- (void)storeAccountInformationsInSubsystem
{
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	
	[self setUserName:[preferencesManager userName]];
	
	// cleaning up from previous launch if needed
	[gatekeeperPassword release];
	gatekeeperPassword = nil;
	
	[registrarPasswords release];
	registrarPasswords = nil;
	
	BOOL didFillAccount = NO;
	if(h323AccountTag != 0)
	{
		XMH323Account *h323Account = [preferencesManager h323AccountWithTag:h323AccountTag];
		if(h323Account != nil)
		{
			[self setGatekeeperAddress:[h323Account gatekeeper]];
			[self setGatekeeperUsername:[h323Account username]];
			[self setGatekeeperPhoneNumber:[h323Account phoneNumber]];
			
			gatekeeperPassword = [[h323Account password] copy];
			
			didFillAccount = YES;
		}
	}
	
	if(didFillAccount == NO)
	{
		[self setGatekeeperAddress:nil];
		[self setGatekeeperUsername:nil];
		[self setGatekeeperPhoneNumber:nil];
	}
	
	didFillAccount = NO;
	if(sipAccountTag != 0)
	{
		XMSIPAccount *sipAccount = [preferencesManager sipAccountWithTag:sipAccountTag];
		if(sipAccountTag != 0)
		{
			NSString *registrar = [sipAccount registrar];
			NSString *username = [sipAccount username];
			
			if(registrar != nil && username != nil)
			{
				XMPreferencesRegistrarRecord *record = [[XMPreferencesRegistrarRecord alloc] init];
				
				NSString *authorizationUsername = [sipAccount authorizationUsername];
				NSString *password = [sipAccount password];
				
				[record setHost:registrar];
				[record setUsername:username];
				[record setAuthorizationUsername:authorizationUsername];
				[record setPassword:password];
				
				NSArray *records = [[NSArray alloc] initWithObjects:record, nil];
				[self setRegistrarRecords:records];
				[records release];
			
				didFillAccount = YES;
			}
		}
	}
	
	if(didFillAccount == NO)
	{
		[self setRegistrarRecords:[NSArray array]];
	}
}

#pragma mark overriding methods from XMPreferences

- (BOOL)automaticallyAcceptIncomingCalls
{
	return [[XMPreferencesManager sharedInstance] automaticallyAcceptIncomingCalls];
}

- (void)setAutoAnswerCalls:(BOOL)flag
{
}

- (BOOL)usesGatekeeper
{
	if(h323AccountTag != 0)
	{
		return YES;
	}
	return NO;
}

- (NSString *)gatekeeperPassword
{
	return gatekeeperPassword;
}

- (BOOL)usesRegistrars
{
	if(sipAccountTag != 0)
	{
		return YES;
	}
	return NO;
}

- (NSArray *)registrarPasswords
{
	return registrarPasswords;
}

#pragma mark -
#pragma mark Private Methods

- (void)_setTag:(unsigned)theTag
{
	static unsigned nextTag = 0;
	
	if(theTag == 0)
	{
		theTag = ++nextTag;
	}
	
	tag = theTag;
}

- (void)_setGatekeeperPassword:(NSString *)gkPassword registrarPasswords:(NSArray *)theRegistrarPasswords
{
	NSObject *old = gatekeeperPassword;
	gatekeeperPassword = [gkPassword copy];
	[old release];
	
	old = registrarPasswords;
	registrarPasswords = [theRegistrarPasswords copy];
	[old release];
}

@end
