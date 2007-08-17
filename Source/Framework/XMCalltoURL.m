/*
 * $Id: XMCalltoURL.m,v 1.4 2007/08/17 19:38:56 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMStringConstants.h"
#import "XMPrivate.h"

#import "XMCalltoURL.h"
#import "XMUtils.h"

#define PREFIX @"callto:"
#define PREFIX_LENGTH 7

@interface XMCalltoURL (PrivateMethods)

- (void)_parseParam:(NSString *)param;
- (void)_parseKeyValuePair:(NSString *)kvp;

@end

@implementation XMCalltoURL

#pragma mark Class Methods

+ (BOOL)canHandleStringRepresentation:(NSString *)url
{
  return [url hasPrefix:PREFIX];
}

+ (BOOL)canHandleDictionaryRepresentation:(NSDictionary *)dict
{
  return NO;
}

+ (XMCalltoURL *)addressResourceWithStringRepresentation:(NSString *)url
{
  XMCalltoURL *calltoURL = [[XMCalltoURL alloc] initWithStringRepresentation:url];
  if (calltoURL != nil) {
    return [calltoURL autorelease];
  }
  return nil;
}

+ (XMCalltoURL *)addressResourceWithDictionaryRepresentation:(NSDictionary *)dict
{
  return nil;
}

#pragma mark -
#pragma mark Init & Deallocation Methods

- (id)initWithStringRepresentation:(NSString *)stringRepresentation
{
  address = nil;
  username = nil;
  host = nil;
  
  BOOL valid = YES;
  
  if (![stringRepresentation hasPrefix:PREFIX]) {
    valid = NO;
    goto bail;
  }
  
  // Remove preceeding '//' if present. Not according to standard,
  // But may be present in order to force Safari to do the correct
  // URL lookup
  if ([[stringRepresentation substringWithRange:NSMakeRange(PREFIX_LENGTH, 2)] isEqualToString:@"//"]) {
    stringRepresentation = [stringRepresentation substringFromIndex:(PREFIX_LENGTH+2)];
  } else {
    stringRepresentation = [stringRepresentation substringFromIndex:(PREFIX_LENGTH)];
  }
  
  NSString *addressPart = nil;
  NSRange addressRange = [stringRepresentation rangeOfString:@"+"];
  if (addressRange.location == NSNotFound) {
    addressPart = stringRepresentation;
  } else {
    addressPart = [stringRepresentation substringToIndex:(addressRange.location)];
    NSString *paramPart = [stringRepresentation substringFromIndex:(addressRange.location+1)];
    [self _parseParam:paramPart];
  }
  
  // check if there is a directory service specified
  NSRange slashRange = [addressPart rangeOfString:@"/"];
  if (slashRange.location != NSNotFound) {
    addressPart = [addressPart substringFromIndex:(slashRange.location+1)];
    // directory service is currently not supported
  }
  
  address = [addressPart retain];
  
  NSRange atRange = [addressPart rangeOfString:@"@"];
  if (atRange.location == NSNotFound) {
    username = [addressPart retain];
  } else {
    username = [[addressPart substringToIndex:atRange.location] retain];
    host = [[addressPart substringFromIndex:(atRange.location+1)] retain];
  }
  
bail:
  if (valid == NO) {
    [self release];
    return nil;
  }
  return self;
}

- (void)dealloc
{
  [address release];
  [username release];
  [host release];
  
  [super dealloc];
}

#pragma mark -
#pragma mark XMAddressResource methods

- (NSString *)stringRepresentation
{
  return [self address];
}

- (XMCallProtocol)callProtocol
{
  return XMCallProtocol_H323;
}

- (NSString *)address
{
  return address;
}

- (NSString *)humanReadableAddress
{
  return [self address];
}

- (NSString *)username
{
  return username;
}

- (NSString *)host
{
  return host;
}

#pragma mark -
#pragma mark Private Methods

- (void)_parseParam:(NSString *)param
{
  NSRange searchRange = NSMakeRange(0, [param length]);
  NSRange plusRange = [param rangeOfString:@"+" options:NSLiteralSearch range:searchRange];
  
  while(plusRange.location != NSNotFound) {
    
    NSRange substrRange = NSMakeRange(searchRange.location, plusRange.location-searchRange.location);
    NSString *kvcString = [param substringWithRange:substrRange];
    [self _parseKeyValuePair:kvcString];
    
    unsigned substrLength = substrRange.length+1;
    searchRange.location += substrLength;
    searchRange.length -= substrLength;
    plusRange = [param rangeOfString:@"+" options:NSLiteralSearch range:searchRange];
  }
  
  [self _parseKeyValuePair:[param substringFromIndex:searchRange.location]];
}

- (void)_parseKeyValuePair:(NSString *)kvp
{
  // Currently not implemented
}

@end
