/*
 * $Id: XMLocation.m,v 1.9 2006/10/17 21:07:30 hfriederich Exp $
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
NSString *XMKey_LocationSIPProxyMode = @"XMeeting_SIPProxyMode";

@interface XMLocation (PrivateMethods)

- (void)_setTag:(unsigned)tag;

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
	proxyMode = XMSIPProxyMode_NoProxy;
	
	temporarySIPProxyPassword = nil;
	
	return self;
}

- (id)initWithDictionary:(NSDictionary *)dict h323Accounts:(NSArray *)h323Accounts sipAccounts:(NSArray *)sipAccounts
{	
	self = [super initWithDictionary:dict];
	
	NSString *theName = (NSString *)[dict objectForKey:XMKey_LocationName];
	
	[self _setTag:0];
	[self setName:theName];
	
	NSNumber *number = (NSNumber *)[dict objectForKey:XMKey_LocationH323AccountID];
	if(number != nil)
	{
		unsigned index = [number unsignedIntValue];
		XMH323Account *h323Account = [h323Accounts objectAtIndex:index];
		h323AccountTag = [h323Account tag];
	}
	
	number = (NSNumber *)[dict objectForKey:XMKey_LocationSIPAccountID];
	if(number != nil)
	{
		unsigned index = [number unsignedIntValue];
		XMSIPAccount *sipAccount = [sipAccounts objectAtIndex:index];
		sipAccountTag = [sipAccount tag];
	}
	
	number = (NSNumber *)[dict objectForKey:XMKey_LocationSIPProxyMode];
	if(number != nil)
	{
		proxyMode = (XMSIPProxyMode)[number unsignedIntValue];
	}
	else
	{
		proxyMode = XMSIPProxyMode_NoProxy;
	}
	
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	XMLocation *location = (XMLocation *)[super copyWithZone:zone];
	
	[location _setTag:[self tag]];
	[location setName:[self name]];
	
	[location setH323AccountTag:[self h323AccountTag]];
	[location setSIPAccountTag:[self sipAccountTag]];
	[location setSIPProxyMode:[self sipProxyMode]];
	
	return location;
}

- (void)dealloc
{
	[name release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark NSObject functionality

- (BOOL)isEqual:(id)object
{
	if ([super isEqual:object] && 
		[[self name] isEqualToString:[(XMLocation *)object name]] &&
		[self h323AccountTag] == [(XMLocation *)object h323AccountTag] &&
		[self sipAccountTag] == [(XMLocation *)object sipAccountTag] &&
		[self sipProxyMode] == [(XMLocation *)object sipProxyMode])
	{
		return YES;
	}
	
	return NO;
}

#pragma mark -
#pragma mark Getting different representations

- (NSMutableDictionary *)dictionaryRepresentationWithH323Accounts:(NSArray *)h323Accounts
													  sipAccounts:(NSArray *)sipAccounts
{	
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
	[dict removeObjectForKey:XMKey_PreferencesEnableSilenceSuppression];
	[dict removeObjectForKey:XMKey_PreferencesEnableEchoCancellation];
	
	if(proxyMode != XMSIPProxyMode_CustomProxy)
	{
		[dict removeObjectForKey:XMKey_PreferencesSIPProxyHost];
		[dict removeObjectForKey:XMKey_PreferencesSIPProxyUsername];
	}
	
	NSString *theName = [self name];
	
	if(theName)
	{
		[dict setObject:theName forKey:XMKey_LocationName];
	}
	
	if(h323AccountTag != 0)
	{
		unsigned h323AccountCount = [h323Accounts count];
		unsigned i;
		
		for(i = 0; i < h323AccountCount; i++)
		{
			XMH323Account *h323Account = [h323Accounts objectAtIndex:i];
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
		unsigned sipAccountCount = [sipAccounts count];
		unsigned i;
		
		for(i = 0; i < sipAccountCount; i++)
		{
			XMSIPAccount *sipAccount = [sipAccounts objectAtIndex:i];
			if([sipAccount tag] == sipAccountTag)
			{
				NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:i];
				[dict setObject:number forKey:XMKey_LocationSIPAccountID];
				[number release];
				break;
			}
		}
	}
	
	NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:proxyMode];
	[dict setObject:number forKey:XMKey_LocationSIPProxyMode];
	
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

- (XMSIPProxyMode)sipProxyMode
{
	return proxyMode;
}

- (void)setSIPProxyMode:(XMSIPProxyMode)sipProxyMode
{
	proxyMode = sipProxyMode;
}

- (void)storeGlobalInformationsInSubsystem
{
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	
	[self setUserName:[preferencesManager userName]];
	
	BOOL didFillAccount = NO;
	if(h323AccountTag != 0)
	{
		XMH323Account *h323Account = [preferencesManager h323AccountWithTag:h323AccountTag];
		if(h323Account != nil)
		{
			[self setGatekeeperAddress:[h323Account gatekeeper]];
			[self setGatekeeperUsername:[h323Account username]];
			[self setGatekeeperPhoneNumber:[h323Account phoneNumber]];
			[self setGatekeeperPassword:[h323Account password]];
			
			didFillAccount = YES;
		}
	}
	
	if(didFillAccount == NO)
	{
		[self setGatekeeperAddress:nil];
		[self setGatekeeperUsername:nil];
		[self setGatekeeperPhoneNumber:nil];
		[self setGatekeeperPassword:nil];
	}
	
	didFillAccount = NO;
	XMSIPAccount *sipAccount = nil;
	NSString *registrar = nil;
	NSString *username = nil;
	NSString *authorizationUsername = nil;
	NSString *password = nil;
	
	if(sipAccountTag != 0)
	{
		sipAccount = [preferencesManager sipAccountWithTag:sipAccountTag];
		if(sipAccount != nil)
		{
			registrar = [sipAccount registrar];
			username = [sipAccount username];
			authorizationUsername = [sipAccount authorizationUsername];
			password = [sipAccount password];
		}
	}
			
	if(registrar != nil && username != nil)
	{
		XMPreferencesRegistrarRecord *record = [[XMPreferencesRegistrarRecord alloc] init];
				
		[record setHost:registrar];
		[record setUsername:username];
		[record setAuthorizationUsername:authorizationUsername];
		[record setPassword:password];
				
		NSArray *records = [[NSArray alloc] initWithObjects:record, nil];
		[self setRegistrarRecords:records];
		[records release];
			
		didFillAccount = YES;
	}
	
	if(didFillAccount == NO)
	{
		[self setRegistrarRecords:[NSArray array]];
	}
	
	switch(proxyMode)
	{
		case XMSIPProxyMode_NoProxy:
			[self setSIPProxyHost:nil];
			[self setSIPProxyUsername:nil];
			[self setSIPProxyPassword:nil];
			break;
		case XMSIPProxyMode_UseSIPAccount:
			[self setSIPProxyHost:registrar];
			[self setSIPProxyUsername:authorizationUsername];
			[self setSIPProxyPassword:password];
			break;
		default:
			// don't change proxy host & username
			password = [preferencesManager passwordForServiceName:[self sipProxyHost] accountName:[self sipProxyUsername]];
			[self setSIPProxyPassword:password];
			break;
	}
	
	[self setEnableSilenceSuppression:[preferencesManager enableSilenceSuppression]];
	[self setEnableEchoCancellation:[preferencesManager enableEchoCancellation]];
}

#pragma mark -
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

- (BOOL)usesRegistrars
{
	if(sipAccountTag != 0)
	{
		return YES;
	}
	return NO;
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

@end
