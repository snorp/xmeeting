/*
 * $Id: XMAddressResource.m,v 1.5 2007/08/17 19:38:56 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#import "XMAddressResource.h"

#import "XMGeneralPurposeAddressResource.h"
#import "XMH323URL.h"
#import "XMSIPURL.h"
#import "XMCalltoURL.h"
#import "XMURLParser.h"
#import "XMPrivate.h"

void _XMParseURLCallback(const char *displayName,
                         const char *username,
                         const char *host,
                         void *userData);

@interface XMURL (PrivateMethods)

- (void)_setDisplayName:(NSString *)displayName;
- (void)_setUsername:(NSString *)username;
- (void)_setHost:(NSString *)host;

@end

@implementation XMAddressResource

#pragma mark Class Methods

+ (BOOL)canHandleStringRepresentation:(NSString *)stringRepresentation
{
  if([XMGeneralPurposeAddressResource canHandleStringRepresentation:stringRepresentation] ||
     [XMH323URL canHandleStringRepresentation:stringRepresentation] ||
     [XMSIPURL canHandleStringRepresentation:stringRepresentation] ||
     [XMCalltoURL canHandleStringRepresentation:stringRepresentation])
  {
    return YES;
  }
  return NO;
}

+ (BOOL)canHandleDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation
{
  if([XMGeneralPurposeAddressResource canHandleDictionaryRepresentation:dictionaryRepresentation] ||
     [XMH323URL canHandleDictionaryRepresentation:dictionaryRepresentation] ||
     [XMSIPURL canHandleDictionaryRepresentation:dictionaryRepresentation] ||
     [XMCalltoURL canHandleDictionaryRepresentation:dictionaryRepresentation])
  {
    return YES;
  }
  return NO;
}

+ (XMAddressResource *)addressResourceWithStringRepresentation:(NSString *)stringRepresentation
{
  XMAddressResource *instance = nil;
  
  if([XMGeneralPurposeAddressResource canHandleStringRepresentation:stringRepresentation])
  {
    instance = [XMGeneralPurposeAddressResource addressResourceWithStringRepresentation:stringRepresentation];
  }
  else if ([XMH323URL canHandleStringRepresentation:stringRepresentation])
  {
    instance = [XMH323URL addressResourceWithStringRepresentation:stringRepresentation];
  }
  else if ([XMSIPURL canHandleStringRepresentation:stringRepresentation])
  {
    instance = [XMSIPURL addressResourceWithStringRepresentation:stringRepresentation];
  } 
  else if ([XMCalltoURL canHandleStringRepresentation:stringRepresentation])
  {
    instance = [XMCalltoURL addressResourceWithStringRepresentation:stringRepresentation];
  }
  
  return instance;
}

+ (XMAddressResource *)addressResourceWithDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation
{
  XMAddressResource *instance = nil;
  
  if([XMGeneralPurposeAddressResource canHandleDictionaryRepresentation:dictionaryRepresentation])
  {
    instance = [XMGeneralPurposeAddressResource addressResourceWithDictionaryRepresentation:dictionaryRepresentation];
  }
  else if ([XMH323URL canHandleDictionaryRepresentation:dictionaryRepresentation])
  {
    instance = [XMH323URL addressResourceWithDictionaryRepresentation:dictionaryRepresentation];
  }
  else if ([XMSIPURL canHandleDictionaryRepresentation:dictionaryRepresentation])
  {
    instance = [XMSIPURL addressResourceWithDictionaryRepresentation:dictionaryRepresentation];
  } 
  else if ([XMCalltoURL canHandleDictionaryRepresentation:dictionaryRepresentation])
  {
    instance = [XMCalltoURL addressResourceWithDictionaryRepresentation:dictionaryRepresentation];
  }
  
  return instance;
}

#pragma mark Init & Deallocation Methods

- (id)init
{
  [self doesNotRecognizeSelector:_cmd];
  [self release];
  return nil;
}

- (id)initWithStringRepresentation:(NSString *)stringRepresentation
{
  // cleanup
  [self release];
  
  if([XMGeneralPurposeAddressResource canHandleStringRepresentation:stringRepresentation])
  {
    return [[XMGeneralPurposeAddressResource alloc] initWithStringRepresentation:stringRepresentation];
  }
  else if ([XMH323URL canHandleStringRepresentation:stringRepresentation])
  {
    return [[XMH323URL alloc] initWithStringRepresentation:stringRepresentation];
  }
  else if ([XMSIPURL canHandleStringRepresentation:stringRepresentation])
  {
    return [[XMSIPURL alloc] initWithStringRepresentation:stringRepresentation];
  }
  else if ([XMCalltoURL canHandleStringRepresentation:stringRepresentation])
  {
    return [[XMCalltoURL alloc] initWithStringRepresentation:stringRepresentation];
  }
  
  return nil;
}

- (id)initWithDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation
{
  // cleanup
  [self release];
  
  if([XMGeneralPurposeAddressResource canHandleDictionaryRepresentation:dictionaryRepresentation])
  {
    return [[XMGeneralPurposeAddressResource alloc] initWithDictionaryRepresentation:dictionaryRepresentation];
  }
  else if ([XMH323URL canHandleDictionaryRepresentation:dictionaryRepresentation])
  {
    return [[XMH323URL alloc] initWithDictionaryRepresentation:dictionaryRepresentation];
  }
  else if ([XMSIPURL canHandleDictionaryRepresentation:dictionaryRepresentation])
  {
    return [[XMSIPURL alloc] initWithDictionaryRepresentation:dictionaryRepresentation];
  }
  else if ([XMCalltoURL canHandleDictionaryRepresentation:dictionaryRepresentation])
  {
    return [[XMCalltoURL alloc] initWithDictionaryRepresentation:dictionaryRepresentation];
  }
  
  return nil;
}

#pragma mark Public Methods

- (NSString *)stringRepresentation
{
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (NSDictionary *)dictionaryRepresentation
{
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (XMCallProtocol)callProtocol
{
  [self doesNotRecognizeSelector:_cmd];
  return XMCallProtocol_UnknownProtocol;
}

- (NSString *)address
{
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (NSString *)humanReadableAddress
{
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (NSString *)username
{
  return nil;
}

- (NSString *)host
{
  return nil;
}

@end

@implementation XMURL

- (id)initWithStringRepresentation:(NSString *)stringRepresentation
{
  self = [super init];
  displayName = nil;
  username = nil;
  host = nil;
  
  BOOL valid = YES;
  
  NSString * prefix = [self _prefix];
  unsigned prefixLength = [prefix length];
  
  if (![stringRepresentation hasPrefix:prefix]) {
    valid = NO;
    goto bail;
  }
  
  // Remove preceeding '//' if present. Not according to standard,
  // But may be present in order to force Safari to do the correct
  // URL lookup
  if ([[stringRepresentation substringWithRange:NSMakeRange(prefixLength, 2)] isEqualToString:@"//"]) {
    stringRepresentation = [NSString stringWithFormat:@"%@%@", prefix, [stringRepresentation substringFromIndex:(prefixLength+2)]];
  }  
  
  valid = [self _parseString:[stringRepresentation cStringUsingEncoding:NSASCIIStringEncoding] usingCallback:_XMParseURLCallback];

  if (valid) {
    url = [[stringRepresentation substringFromIndex:prefixLength] retain];
  }
  
bail:
    if (valid == NO)
    {
      [self release];
      return nil;
    }
  
  return self;
}

- (void)dealloc
{
  [url release];
  [displayName release];
  [username release];
  [host release];
  
  [super dealloc];
}

#pragma mark -
#pragma mark Getting Different Representations

- (NSString *)stringRepresentation
{
  return url;
}

- (NSDictionary *)dictionaryRepresentation
{
  return nil;
}

#pragma mark -
#pragma mark XMAddressResource interface

- (XMCallProtocol)callProtocol
{
  return XMCallProtocol_UnknownProtocol;
}

- (NSString *)address
{
  return url;
}

- (NSString *)humanReadableAddress
{
  return [self displayName];
}

- (NSString *)displayName
{
  return displayName;
}

- (void)_setDisplayName:(NSString *)_displayName
{
  NSString *old = displayName;
  displayName = [_displayName copy];
  [old release];
}

- (NSString *)username
{
  return username;
}

- (void)_setUsername:(NSString *)_username
{
  NSString *old = username;
  username = [_username copy];
  [old release];
}

- (NSString *)host
{
  return host;
}

- (void)_setHost:(NSString *)_host
{
  NSString *old = host;
  host = [_host copy];
  [old release];
}

#pragma mark -
#pragma mark Framework Methods

- (NSString *)_prefix
{
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (BOOL)_parseString:(const char *)string usingCallback:(XMURLParseCallback)callback
{
  [self doesNotRecognizeSelector:_cmd];
  return NO;
}

@end

void _XMParseURLCallback(const char *displayName,
                         const char *username,
                         const char *domain,
                         void *userData)
{
  XMURL *url = (XMURL *)userData;
  
  NSString *name = [[NSString alloc] initWithCString:displayName encoding:NSASCIIStringEncoding];
  NSString *user = [[NSString alloc] initWithCString:username encoding:NSASCIIStringEncoding];
  NSString *host = [[NSString alloc] initWithCString:domain encoding:NSASCIIStringEncoding];
  
  [url _setDisplayName:name];
  [url _setUsername:user];
  [url _setHost:host];
  
  [name release];
  [user release];
  [host release];
}
