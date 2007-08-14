/*
 * $Id: XMH323Account.m,v 1.3 2007/08/14 10:56:39 hfriederich Exp $
 *
 * Copyright (c) 2006-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2007 Hannes Friederich. All rights reserved.
 */

#import "XMH323Account.h"

#import "XMPreferencesManager.h"

NSString *XMKey_H323AccountName = @"XMeeting_H323AccountName";
NSString *XMKey_H323AccountGatekeeper = @"XMeeting_H323AccountGatekeeper";
NSString *XMKey_H323AccountUsername = @"XMeeting_H323AccountUsername";
NSString *XMKey_H323AccountPhoneNumber = @"XMeeting_H323AccountPhoneNumber";
NSString *XMKey_H323AccountPassword = @"XMeeting_H323AccountPassword";

@interface XMH323Account (PrivateMethods)

- (id)_initWithTag:(unsigned)tag;

@end

@implementation XMH323Account

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
  
  obj = [dictionary objectForKey:XMKey_H323AccountName];
  if(obj != nil && [obj isKindOfClass:stringClass])
  {
    [self setName:(NSString *)obj];
  }
  obj = [dictionary objectForKey:XMKey_H323AccountGatekeeper];
  if(obj != nil && [obj isKindOfClass:stringClass])
  {
    [self setGatekeeper:(NSString *)obj];
  }
  obj = [dictionary objectForKey:XMKey_H323AccountUsername];
  if(obj != nil && [obj isKindOfClass:stringClass])
  {
    [self setUsername:(NSString *)obj];
  }
  obj = [dictionary objectForKey:XMKey_H323AccountPhoneNumber];
  if(obj != nil && [obj isKindOfClass:stringClass])
  {
    [self setPhoneNumber:(NSString *)obj];
  }
  
  return self;
}

- (id)copyWithZone:(NSZone *)zone
{
  XMH323Account *h323Account = [[[self class] allocWithZone:zone] _initWithTag:[self tag]];
  
  [h323Account setName:[self name]];
  [h323Account setGatekeeper:[self gatekeeper]];
  [h323Account setUsername:[self username]];
  [h323Account setPhoneNumber:[self phoneNumber]];
  
  if (didSetPassword) {
    [h323Account setPassword:[self password]];
  }
  
  return h323Account;
}

-(id)_initWithTag:(unsigned)theTag
{
  self = [super init];
  
  static int nextTag = 0;
  
  if(theTag == 0)
  {
    theTag = ++nextTag;
  }	
  
  tag = theTag;
  name = nil;
  gatekeeper = nil;
  username = nil;
  phoneNumber = nil;
  didSetPassword = NO;
  password = nil;
  
  [[XMPreferencesManager sharedInstance] addPasswordObject:self];
  
  return self;
}

- (void)dealloc
{
  [name release];
  [gatekeeper release];
  [username release];
  [phoneNumber release];
  [password release];
  
  [[XMPreferencesManager sharedInstance] removePasswordObject:self];
  
  [super dealloc];
}

#pragma mark -
#pragma mark Getting Different Representations

- (NSDictionary *)dictionaryRepresentation
{
  NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:4];
  
  if(name != nil)
  {
    [dictionary setObject:name forKey:XMKey_H323AccountName];
  }
  if(gatekeeper != nil)
  {
    [dictionary setObject:gatekeeper forKey:XMKey_H323AccountGatekeeper];
  }
  if(username != nil)
  {
    [dictionary setObject:username forKey:XMKey_H323AccountUsername];
  }
  if(phoneNumber != nil)
  {
    [dictionary setObject:phoneNumber forKey:XMKey_H323AccountPhoneNumber];
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
  if(name != theName)
  {
    NSString *old = name;
    name = [theName copy];
    [old release];
  }
}

- (NSString *)gatekeeper
{
  return gatekeeper;
}

- (void)setGatekeeper:(NSString *)theGatekeeper
{
  if(gatekeeper != theGatekeeper)
  {
    NSString *old = gatekeeper;
    gatekeeper = [theGatekeeper copy];
    [old release];
  }
}

- (NSString *)username
{
  return username;
}

- (void)setUsername:(NSString *)theUsername
{
  if(username != theUsername)
  {
    NSString *old = username;
    username = [theUsername copy];
    [old release];
  }
}

- (NSString *)phoneNumber
{
  return phoneNumber;
}

- (void)setPhoneNumber:(NSString *)thePhoneNumber
{
  if(phoneNumber != thePhoneNumber)
  {
    NSString *old = phoneNumber;
    phoneNumber = [thePhoneNumber copy];
    [old release];
  }
}

- (NSString *)password
{
  if (didSetPassword == YES) {
    return password;
  }
  return [[XMPreferencesManager sharedInstance] passwordForServiceName:gatekeeper accountName:username];
}

- (void)setPassword:(NSString *)thePassword
{
  if(password != thePassword)
  {
    NSString *old = password;
    password = [thePassword copy];
    [old release];
  }
  didSetPassword = YES;
}

- (void)savePassword
{
  if (didSetPassword == YES) {
	[[XMPreferencesManager sharedInstance] setPassword:password forServiceName:gatekeeper accountName:username];
    didSetPassword = NO;
  }
}

- (void)resetPassword
{
  didSetPassword = NO;
}

- (XMPasswordObjectType)type
{
  return XMPasswordObjectType_H323Account;
}

@end
