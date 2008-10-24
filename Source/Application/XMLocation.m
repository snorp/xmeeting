/*
 * $Id: XMLocation.m,v 1.18 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#import "XMLocation.h"

#import "XMApplicationFunctions.h"
#import "XMPreferencesManager.h"
#import "XMH323Account.h"
#import "XMSIPAccount.h"

NSString *XMKey_LocationName = @"XMeeting_LocationName";
NSString *XMKey_LocationH323AccountID = @"XMeeting_H323AccountID";
NSString *XMKey_LocationSIPAccountIDs = @"XMeeting_SIPAccountIDs";
NSString *XMKey_LocationDefaultSIPAccountID = @"XMeeting_DefaultSIPAccountID";
NSString *XMKey_LocationSIPProxyID = @"XMeeting_SIPProxyID";

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
  sipAccountTags = [[NSArray array] retain];
  defaultSIPAccountTag = 0;
  sipProxyTag = 0;
  didSetSIPProxyPassword = NO;
  _sipProxyPassword = nil;
  
  [self setSTUNServers:XMDefaultSTUNServers()];
  
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
  
  NSArray *array = [dict objectForKey:XMKey_LocationSIPAccountIDs];
  if(array != nil)
  {
    [sipAccountTags release];
    
    unsigned count = [array count];
    unsigned i;
    NSMutableArray *tags = [[NSMutableArray alloc] initWithCapacity:count];
    
    for (i = 0; i < count; i++) {
      number = (NSNumber *)[array objectAtIndex:i];
      unsigned index = [number unsignedIntValue];
      XMSIPAccount *sipAccount = [sipAccounts objectAtIndex:index];
      [tags addObject:[NSNumber numberWithUnsignedInt:[sipAccount tag]]];
    }
    sipAccountTags = [tags copy];
    [tags release];
  }
  
  number = (NSNumber *)[dict objectForKey:XMKey_LocationDefaultSIPAccountID];
  if (number != nil) {
    unsigned index = [number unsignedIntValue];
    XMSIPAccount *sipAccount = [sipAccounts objectAtIndex:index];
    defaultSIPAccountTag = [sipAccount tag];
  }
  
  number = (NSNumber *)[dict objectForKey:XMKey_LocationSIPProxyID];
  if (number != nil)
  {
    unsigned index = [number unsignedIntValue];
    if (index == UINT_MAX) {
      sipProxyTag = XMCustomSIPProxyTag;
    } else {
      XMSIPAccount *sipAccount = [sipAccounts objectAtIndex:index];
      sipProxyTag = [sipAccount tag];
    }
  }
  
  didSetSIPProxyPassword = NO;
  _sipProxyPassword = nil;
  
  return self;
}

- (id)copyWithZone:(NSZone *)zone
{
  XMLocation *location = (XMLocation *)[super copyWithZone:zone];
  
  [location _setTag:[self tag]];
  [location setName:[self name]];
  
  [location setH323AccountTag:[self h323AccountTag]];
  [location setSIPAccountTags:[self sipAccountTags]];
  [location setDefaultSIPAccountTag:[self defaultSIPAccountTag]];
  [location setSIPProxyTag:[self sipProxyTag]];
  
  if (didSetSIPProxyPassword) {
    [location _setSIPProxyPassword:[self _sipProxyPassword]];
  }
  
  return location;
}

- (void)dealloc
{
  [name release];
  [sipAccountTags release];
  [_sipProxyPassword release];
  
  [super dealloc];
}

#pragma mark -
#pragma mark NSObject functionality

- (BOOL)isEqual:(id)object
{
  if ([super isEqual:object] && 
      [[self name] isEqualToString:[(XMLocation *)object name]] &&
      [self h323AccountTag] == [(XMLocation *)object h323AccountTag] &&
      [self sipAccountTags] == [(XMLocation *)object sipAccountTags] &&
      [self defaultSIPAccountTag] == [(XMLocation *)object defaultSIPAccountTag] &&
      [self sipProxyTag] == [(XMLocation *)object sipProxyTag])
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
  [dict removeObjectForKey:XMKey_PreferencesGatekeeperTerminalAlias1];
  [dict removeObjectForKey:XMKey_PreferencesGatekeeperTerminalAlias2];
  [dict removeObjectForKey:XMKey_PreferencesGatekeeperPassword];
  [dict removeObjectForKey:XMKey_PreferencesSIPRegistrationRecords];
  [dict removeObjectForKey:XMKey_PreferencesSIPProxyPassword];
  
  if (sipProxyTag != XMCustomSIPProxyTag) {
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
  
  unsigned count = [sipAccountTags count];
  unsigned i;
  NSMutableArray *sipAccountIndexes = [[NSMutableArray alloc] initWithCapacity:count];
  for (i = 0; i < count; i++) {
    unsigned _tag = [(NSNumber *)[sipAccountTags objectAtIndex:i] unsignedIntValue];
    unsigned sipAccountCount = [sipAccounts count];
    unsigned j;
    
    for(j = 0; j < sipAccountCount; j++)
    {
      XMSIPAccount *sipAccount = [sipAccounts objectAtIndex:j];
      if([sipAccount tag] == _tag)
      {
        NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:j];
        [sipAccountIndexes addObject:number];
        [number release];
        break;
      }
    }
  }
  [dict setObject:sipAccountIndexes forKey:XMKey_LocationSIPAccountIDs];
  [sipAccountIndexes release];
  
  if (defaultSIPAccountTag != 0) {
    unsigned sipAccountCount = [sipAccounts count];
    unsigned i;
    
    for(i = 0; i < sipAccountCount; i++)
    {
      XMSIPAccount *sipAccount = [sipAccounts objectAtIndex:i];
      if([sipAccount tag] == defaultSIPAccountTag)
      {
        NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:i];
        [dict setObject:number forKey:XMKey_LocationDefaultSIPAccountID];
        [number release];
        break;
      }
    }
  }
  
  if(sipProxyTag != 0)
  {
    if (sipProxyTag != XMCustomSIPProxyTag) {
      unsigned sipAccountCount = [sipAccounts count];
      unsigned i;
    
      for(i = 0; i < sipAccountCount; i++)
      {
        XMSIPAccount *sipAccount = (XMSIPAccount *)[sipAccounts objectAtIndex:i];
        if([sipAccount tag] == sipProxyTag)
        {
          NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:i];
          [dict setObject:number forKey:XMKey_LocationSIPProxyID];
          [number release];
          break;
        }
      }
    } else {
      [dict setObject:[NSNumber numberWithUnsignedInt:UINT_MAX] forKey:XMKey_LocationSIPProxyID];
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

- (NSArray *)sipAccountTags
{
  return sipAccountTags;
}

- (void)setSIPAccountTags:(NSArray *)tags
{
  NSArray *old = sipAccountTags;
  sipAccountTags = [tags copy];
  [old release];
}

- (unsigned)defaultSIPAccountTag
{
  if ([sipAccountTags count] == 0) {
    return 0;
  }
  return defaultSIPAccountTag;
}

- (void)setDefaultSIPAccountTag:(unsigned)_tag
{
  defaultSIPAccountTag = _tag;
}

- (unsigned)sipProxyTag
{
  return sipProxyTag;
}

- (void)setSIPProxyTag:(unsigned)_sipProxyTag
{
  sipProxyTag = _sipProxyTag;
}

- (NSString *)_sipProxyPassword
{
  if (didSetSIPProxyPassword) {
    return _sipProxyPassword;
  }
  return [[XMPreferencesManager sharedInstance] passwordForServiceName:[super sipProxyHost] accountName:[super sipProxyUsername]];
}

- (void)_setSIPProxyPassword:(NSString *)password
{
  NSString *old = _sipProxyPassword;
  _sipProxyPassword = [password copy];
  [old release];
  didSetSIPProxyPassword = YES;
}

- (void)savePassword
{
  if (didSetSIPProxyPassword == YES) {
    [[XMPreferencesManager sharedInstance] setPassword:_sipProxyPassword 
                                        forServiceName:[super sipProxyHost] 
                                           accountName:[super sipProxyUsername]];
    didSetSIPProxyPassword = NO;
  }
}

- (void)resetPassword
{
  didSetSIPProxyPassword = NO;
}

- (XMPasswordObjectType)type
{
  return XMPasswordObjectType_SIPProxyPassword;
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
      [self setGatekeeperAddress:[h323Account gatekeeperHost]];
      [self setGatekeeperTerminalAlias1:[h323Account terminalAlias1]];
      [self setGatekeeperTerminalAlias2:[h323Account terminalAlias2]];
      [self setGatekeeperPassword:[h323Account password]];
      
      didFillAccount = YES;
    }
  }
  
  if(didFillAccount == NO)
  {
    [self setGatekeeperAddress:nil];
    [self setGatekeeperTerminalAlias1:nil];
    [self setGatekeeperTerminalAlias2:nil];
    [self setGatekeeperPassword:nil];
  }
  
  didFillAccount = NO;
  unsigned count = [sipAccountTags count];
  unsigned i;
  NSMutableArray *sipInfo = [[NSMutableArray alloc] initWithCapacity:count];
  XMSIPAccount *sipAccount = [preferencesManager sipAccountWithTag:defaultSIPAccountTag];
  if (sipAccount != nil) {
    XMPreferencesRegistrationRecord *record = [[XMPreferencesRegistrationRecord alloc] init];
    [record setDomain:[sipAccount domain]];
    [record setUsername:[sipAccount username]];
    [record setAuthorizationUsername:[sipAccount authorizationUsername]];
    [record setPassword:[sipAccount password]];
    
    [sipInfo addObject:record];
    [record release];
  }
  for (i = 0; i < count; i++) {
    unsigned _tag = [(NSNumber *)[sipAccountTags objectAtIndex:i] unsignedIntValue];
    if (_tag == defaultSIPAccountTag) {
      continue;
    }
    XMSIPAccount *sipAccount = [preferencesManager sipAccountWithTag:_tag];
    if (sipAccount != nil) {
      XMPreferencesRegistrationRecord *record = [[XMPreferencesRegistrationRecord alloc] init];
      [record setDomain:[sipAccount domain]];
      [record setUsername:[sipAccount username]];
      [record setAuthorizationUsername:[sipAccount authorizationUsername]];
      [record setPassword:[sipAccount password]];
      
      [sipInfo addObject:record];
      [record release];
    }
  }
  [self setSIPRegistrationRecords:sipInfo];
  [sipInfo release];
  
  if (sipProxyTag == XMCustomSIPProxyTag) {
    [self setSIPProxyPassword:[self _sipProxyPassword]];
    // Username and host should already be present
  } else if (sipProxyTag != 0) {
    XMSIPAccount *account = [preferencesManager sipAccountWithTag:sipProxyTag];
    if (account != nil) {
      [self setSIPProxyHost:[account domain]];
      [self setSIPProxyUsername:[account username]];
      [self setSIPProxyPassword:[account password]];
    } else {
      [self setSIPProxyHost:nil];
      [self setSIPProxyUsername:nil];
      [self setSIPProxyPassword:nil];
    }
  } else {
    [self setSIPProxyHost:nil];
    [self setSIPProxyUsername:nil];
    [self setSIPProxyPassword:nil];
  }
}

#pragma mark -
#pragma mark Methods for Preferences Editing

- (NSNumber *)enableSilenceSuppressionNumber
{
  return [NSNumber numberWithBool:[self enableSilenceSuppression]];
}

- (void)setEnableSilenceSuppressionNumber:(NSNumber *)number
{
  [self setEnableSilenceSuppression:[number boolValue]];
}

- (NSNumber *)enableEchoCancellationNumber
{
  return [NSNumber numberWithBool:[self enableEchoCancellation]];
}

- (void)setEnableEchoCancellationNumber:(NSNumber *)number
{
  [self setEnableEchoCancellation:[number boolValue]];
}

- (NSNumber *)enableVideoNumber
{
  return [NSNumber numberWithBool:[self enableVideo]];
}

- (void)setEnableVideoNumber:(NSNumber *)number
{
  [self setEnableVideo:[number boolValue]];
}

- (NSNumber *)enableH264LimitedModeNumber
{
  return [NSNumber numberWithBool:[self enableH264LimitedMode]];
}

- (void)setEnableH264LimitedModeNumber:(NSNumber *)number
{
  [self setEnableH264LimitedMode:[number boolValue]];
}

- (NSNumber *)enableH323Number
{
  return [NSNumber numberWithBool:[self enableH323]];
}

- (void)setEnableH323Number:(NSNumber *)number
{
  [self setEnableH323:[number boolValue]];
}

- (NSNumber *)enableH245TunnelNumber
{
  return [NSNumber numberWithBool:[self enableH245Tunnel]];
}

- (void)setEnableH245TunnelNumber:(NSNumber *)number
{
  [self setEnableH245Tunnel:[number boolValue]];
}

- (NSNumber *)enableFastStartNumber
{
  return [NSNumber numberWithBool:[self enableFastStart]];
}

- (void)setEnableFastStartNumber:(NSNumber *)number
{
  [self setEnableFastStart:[number boolValue]];
}

- (NSNumber *)enableSIPNumber
{
  return [NSNumber numberWithBool:[self enableSIP]];
}

- (void)setEnableSIPNumber:(NSNumber *)number
{
  [self setEnableSIP:[number boolValue]];
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

- (BOOL)usesRegistrations
{
  if([sipAccountTags count] != 0)
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
