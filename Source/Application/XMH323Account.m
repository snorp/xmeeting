/*
 * $Id: XMH323Account.m,v 1.5 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2006-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2008 Hannes Friederich. All rights reserved.
 */

#import "XMH323Account.h"

#import "XMPreferencesManager.h"

NSString *XMKey_H323AccountName = @"XMeeting_H323AccountName";
NSString *XMKey_H323AccountGatekeeperHost = @"XMeeting_H323AccountGatekeeperHost";
NSString *XMKey_H323AccountTerminalAlias1 = @"XMeeting_H323AccountTerminalAlias1";
NSString *XMKey_H323AccountTerminalAlias2 = @"XMeeting_H323AccountTerminalAlias2";
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
  obj = [dictionary objectForKey:XMKey_H323AccountGatekeeperHost];
  if(obj != nil && [obj isKindOfClass:stringClass])
  {
    [self setGatekeeperHost:(NSString *)obj];
  }
  obj = [dictionary objectForKey:XMKey_H323AccountTerminalAlias1];
  if(obj != nil && [obj isKindOfClass:stringClass])
  {
    [self setTerminalAlias1:(NSString *)obj];
  }
  obj = [dictionary objectForKey:XMKey_H323AccountTerminalAlias2];
  if(obj != nil && [obj isKindOfClass:stringClass])
  {
    [self setTerminalAlias2:(NSString *)obj];
  }
  
  return self;
}

- (id)copyWithZone:(NSZone *)zone
{
  XMH323Account *h323Account = [[[self class] allocWithZone:zone] _initWithTag:[self tag]];
  
  [h323Account setName:[self name]];
  [h323Account setGatekeeperHost:[self gatekeeperHost]];
  [h323Account setTerminalAlias1:[self terminalAlias1]];
  [h323Account setTerminalAlias2:[self terminalAlias2]];
  
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
  gatekeeperHost = nil;
  terminalAlias1 = nil;
  terminalAlias2 = nil;
  didSetPassword = NO;
  password = nil;
  
  [[XMPreferencesManager sharedInstance] addPasswordObject:self];
  
  return self;
}

- (void)dealloc
{
  [name release];
  [gatekeeperHost release];
  [terminalAlias1 release];
  [terminalAlias2 release];
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
  if(gatekeeperHost != nil)
  {
    [dictionary setObject:gatekeeperHost forKey:XMKey_H323AccountGatekeeperHost];
  }
  if(terminalAlias1 != nil)
  {
    [dictionary setObject:terminalAlias1 forKey:XMKey_H323AccountTerminalAlias1];
  }
  if(terminalAlias2 != nil)
  {
    [dictionary setObject:terminalAlias2 forKey:XMKey_H323AccountTerminalAlias2];
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

- (NSString *)gatekeeperHost
{
  return gatekeeperHost;
}

- (void)setGatekeeperHost:(NSString *)theGatekeeperHost
{
  if(gatekeeperHost != theGatekeeperHost)
  {
    NSString *old = gatekeeperHost;
    gatekeeperHost = [theGatekeeperHost copy];
    [old release];
  }
}

- (NSString *)terminalAlias1
{
  return terminalAlias1;
}

- (void)setTerminalAlias1:(NSString *)theTerminalAlias1
{
  if(terminalAlias1 != theTerminalAlias1)
  {
    NSString *old = terminalAlias1;
    terminalAlias1 = [theTerminalAlias1 copy];
    [old release];
  }
}

- (NSString *)terminalAlias2
{
  return terminalAlias2;
}

- (void)setTerminalAlias2:(NSString *)theTerminalAlias2
{
  if(terminalAlias2 != theTerminalAlias2)
  {
    NSString *old = terminalAlias2;
    terminalAlias2 = [theTerminalAlias2 copy];
    [old release];
  }
}

- (NSString *)password
{
  if (didSetPassword == YES) {
    return password;
  }
  return [[XMPreferencesManager sharedInstance] passwordForServiceName:gatekeeperHost accountName:terminalAlias1];
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
    [[XMPreferencesManager sharedInstance] setPassword:password forServiceName:gatekeeperHost accountName:terminalAlias1];
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
