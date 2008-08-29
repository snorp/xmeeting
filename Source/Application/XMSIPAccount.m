/*
 * $Id: XMSIPAccount.m,v 1.6 2008/08/29 11:32:29 hfriederich Exp $
 *
 * Copyright (c) 2006-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2007 Hannes Friederich. All rights reserved.
 */

#import "XMSIPAccount.h"

#import "XMPreferencesManager.h"

NSString *XMKey_SIPAccountName = @"XMeeting_SIPAccountName";
NSString *XMKey_SIPAccountDomain = @"XMeeting_SIPAccountRegistrar";
NSString *XMKey_SIPAccountUsername = @"XMeeting_SIPAccountUsername";
NSString *XMKey_SIPAccountAuthorizationUsername = @"XMeeting_SIPAccountAuthorizationUsername";
NSString *XMKey_SIPAccountPassword = @"XMeeting_SIPAccountPassword";

@interface XMSIPAccount (PrivateMethods)

- (id)_initWithTag:(unsigned)tag;

@end

@implementation XMSIPAccount

#pragma mark -
#pragma mark Init & Deallocation Methods

- (id)init
{
  return [self _initWithTag:0];
}

- (id)initWithDictionary:(NSDictionary *)dictionary
{
  self = [self _initWithTag:0];
  
  NSObject *obj;
  Class stringClass = [NSString class];
  
  obj = [dictionary objectForKey:XMKey_SIPAccountName];
  if (obj != nil && [obj isKindOfClass:stringClass]) {
    [self setName:(NSString *)obj];
  }
  obj = [dictionary objectForKey:XMKey_SIPAccountDomain];
  if (obj != nil && [obj isKindOfClass:stringClass]) {
    [self setDomain:(NSString *)obj];
  }
  obj = [dictionary objectForKey:XMKey_SIPAccountUsername];
  if (obj != nil && [obj isKindOfClass:stringClass]) {
    [self setUsername:(NSString *)obj];
  }
  obj = [dictionary objectForKey:XMKey_SIPAccountAuthorizationUsername];
  if (obj != nil && [obj isKindOfClass:stringClass]) {
    [self setAuthorizationUsername:(NSString *)obj];
  }
  
  return self;
}

- (id)copyWithZone:(NSZone *)zone
{
  XMSIPAccount *sipAccount = [[[self class] allocWithZone:zone] _initWithTag:[self tag]];
  
  [sipAccount setName:[self name]];
  [sipAccount setDomain:[self domain]];
  [sipAccount setUsername:[self username]];
  [sipAccount setAuthorizationUsername:[self authorizationUsername]];
  
  if (didSetPassword) {
    [sipAccount setPassword:[self password]];
  }
  
  return sipAccount;
}

- (id)_initWithTag:(unsigned)theTag
{
  self = [super init];
  
  static unsigned nextTag = 0;
  
  if (theTag == 0) {
    theTag = ++nextTag;
  }
  
  tag = theTag;
  name = nil;
  domain = nil;
  username = nil;
  authorizationUsername = nil;
  didSetPassword = NO;
  password = nil;
  
  aor = nil;
  
  [[XMPreferencesManager sharedInstance] addPasswordObject:self];
  
  return self;
}

- (void)dealloc
{
  [name release];
  [domain release];
  [username release];
  [authorizationUsername release];
  [password release];
  
  [[XMPreferencesManager sharedInstance] removePasswordObject:self];
  
  [super dealloc];
}

#pragma mark -
#pragma mark Getting Different Representations

- (NSDictionary *)dictionaryRepresentation
{
  NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:3];
  
  if (name != nil) {
    [dictionary setObject:name forKey:XMKey_SIPAccountName];
  }
  if (domain != nil) {
    [dictionary setObject:domain forKey:XMKey_SIPAccountDomain];
  }
  if (username != nil) {
    [dictionary setObject:username forKey:XMKey_SIPAccountUsername];
  }
  if (authorizationUsername != nil) {
    [dictionary setObject:authorizationUsername forKey:XMKey_SIPAccountAuthorizationUsername];
  }
  
  return dictionary;
}

#pragma mark -
#pragma mark Accessor Methods

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
  if (name != theName) {
    NSString *old = name;
    name = [theName copy];
    [old release];
  }
}

- (NSString *)domain
{
  return domain;
}

- (void)setDomain:(NSString *)theDomain
{
  if (domain != theDomain) {
    NSString *old = domain;
    domain = [theDomain copy];
    [old release];
    
    [aor release];
    aor = nil;
  }
}

- (NSString *)username
{
  return username;
}

- (void)setUsername:(NSString *)theUsername
{
  if (username != theUsername) {
    NSString *old = username;
    username = [theUsername copy];
    [old release];
    
    [aor release];
    aor = nil;
  }
}

- (NSString *)authorizationUsername
{
  return authorizationUsername;
}

- (void)setAuthorizationUsername:(NSString *)theAuthorizationUsername
{
  if (authorizationUsername != theAuthorizationUsername) {
    NSString *old = authorizationUsername;
    authorizationUsername = [theAuthorizationUsername copy];
    [old release];
  }
}

- (NSString *)password
{
  if (didSetPassword) {
    return password;
  }
  return [[XMPreferencesManager sharedInstance] passwordForServiceName:domain accountName:authorizationUsername];
}

- (void)setPassword:(NSString *)thePassword
{
  if (password != thePassword) {
    NSString *old = password;
    password = [thePassword copy];
    [old release];
  }
  didSetPassword = YES;
}

- (void)savePassword
{
  if (didSetPassword == YES) {
    [[XMPreferencesManager sharedInstance] setPassword:password forServiceName:domain accountName:authorizationUsername];
    didSetPassword = NO;
  }
}

- (void)resetPassword
{
  didSetPassword = NO;
}

- (XMPasswordObjectType)type
{
  return XMPasswordObjectType_SIPAccount;
}

- (NSString *)addressOfRecord
{
  if (aor == nil) {
    aor = XMCreateAddressOfRecord(domain, username);
  }
  return aor;
}

@end
