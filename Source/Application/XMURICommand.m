/*
 * $Id: XMURICommand.m,v 1.5 2007/08/17 19:38:56 hfriederich Exp $
 *
 * Copyright (c) 2006-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2007 Hannes Friederich. All rights reserved.
 */

#import "XMeeting.h"
#import "XMURICommand.h"
#import "XMCallAddressManager.h"
#import "XMSimpleAddressResource.h"
#import "XMPreferencesManager.h"

#define PREFIX @"xmeeting:"
#define PREFIX_LENGTH 9

#define PROTOCOL_KEY @"protocol"

#define PROTOCOL_H323 @"h323"
#define PROTOCOL_SIP @"sip"

@implementation XMURICommand

+ (NSString *)tryToCallAddress:(NSString *)addressString
{
  XMCallAddressManager * callManager = [XMCallAddressManager sharedInstance];
  
  if (![[XMCallManager sharedInstance] isInCall]) // not in a call
  {  
    XMAddressResource *addressResource = nil;
    // Try if it is an XMeeting-URL
    if ([XMeetingURL isXMeetingURL:addressString]) {
      addressResource = [[XMeetingURL alloc] initWithString:addressString];
    } else {
      addressResource = [XMAddressResource addressResourceWithStringRepresentation:addressString];
    }
    if (addressResource != nil) {
      NSLog(@"A");
      id<XMCallAddress> callAddress = [callManager addressMatchingResource:addressResource];
      if (callAddress == nil) {
        callAddress = [[[XMSimpleAddressResourceWrapper alloc] initWithAddressResource:addressResource] autorelease];
      }
      [callManager makeCallToAddress:callAddress];
      return nil;
    }
    else
    {
      NSLog(@"b");
      NSString *formatString = NSLocalizedString(@"XM_ILLEGAL_URI", @"");
      return [NSString stringWithFormat:formatString, addressString];
    }
  }
  else
  {
    return NSLocalizedString(@"XM_ALREADY_IN_CALL", @"");
  }
}

- (id)performDefaultImplementation
{
  NSString *command = [[self commandDescription] commandName];
  NSString *urlString = [self directParameter]; 
  
  urlString = [urlString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  
  NSString *errorString = nil;
  
  if ([command isEqualToString:@"GetURL"] ||
      [command isEqualToString:@"OpenURL"])
  {
    errorString = [XMURICommand tryToCallAddress:urlString];
  }
  else
  {
    errorString = @"<Unknown command>";
  }
  
  if (errorString != nil)
  {
    [[NSSound soundNamed:@"Funk"] play];
    [self setScriptErrorString:errorString];
  }
  
  return nil;
}

@end

@interface XMeetingURL (PrivateMethods)

- (void)_parseParam:(NSString *)param;
- (void)_parseKeyValuePair:(NSString *)kvp;

@end

@implementation XMeetingURL

+ (BOOL)isXMeetingURL:(NSString *)url
{
  return [url hasPrefix:PREFIX];
}

- (id)initWithString:(NSString *)_url
{
  username = nil;
  host = nil;
  callProtocol = XMCallProtocol_UnknownProtocol;
  
  BOOL valid = YES;
  
  if(![XMeetingURL isXMeetingURL:_url]) {
    valid = NO;
    goto bail;
  }
  
  // Remove preceeding '//' if present. Not according to standard,
  // But may be present in order to force Safari to do the correct
  // URL lookup
  if ([[_url substringWithRange:NSMakeRange(PREFIX_LENGTH, 2)] isEqualToString:@"//"]) {
    url = [[_url substringFromIndex:(PREFIX_LENGTH+2)] retain];
  } else {
    url = [[_url substringFromIndex:(PREFIX_LENGTH)] retain];
  }
  
  NSString *addressPart;
  NSRange addressRange = [url rangeOfString:@";"];
  if (addressRange.location == NSNotFound) {
    addressPart = url;
  } else {
    addressPart = [url substringToIndex:addressRange.location];
    NSString *paramPart = [url substringFromIndex:(addressRange.location+1)];
    [self _parseParam:paramPart];
  }
  
  NSRange atRange = [addressPart rangeOfString:@"@"];
  if (atRange.location == NSNotFound) {
    username = [addressPart retain];
    if (callProtocol == XMCallProtocol_UnknownProtocol && !XMIsPhoneNumber(username)) {
      // Can't call since protocol unknown
      valid = NO;
      goto bail;
    } else if (callProtocol == XMCallProtocol_UnknownProtocol) {
      callProtocol = [[XMPreferencesManager sharedInstance] addressBookPhoneNumberProtocol];
    }
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
  [url release];
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
  return callProtocol;
}

- (NSString *)address
{
  return url;
}

- (NSString *)humanReadableAddress
{
  if (username != nil && host != nil) {
    return [NSString stringWithFormat:@"%@@%@", username, host];
  } else if (username != nil) {
    return username;
  } else if (host != nil) {
    return host;
  } else {
    return [self address];
  }
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
  NSRange ampRange = [param rangeOfString:@"&" options:NSLiteralSearch range:searchRange];
  
  while(ampRange.location != NSNotFound) {
    
    NSRange substrRange = NSMakeRange(searchRange.location, ampRange.location-searchRange.location);
    NSString *kvcString = [param substringWithRange:substrRange];
    [self _parseKeyValuePair:kvcString];
    
    unsigned substrLength = substrRange.length+1;
    searchRange.location += substrLength;
    searchRange.length -= substrLength;
    ampRange = [param rangeOfString:@"&" options:NSLiteralSearch range:searchRange];
  }
  
  [self _parseKeyValuePair:[param substringFromIndex:searchRange.location]];
}

- (void)_parseKeyValuePair:(NSString *)kvp
{
  NSRange eqRange = [kvp rangeOfString:@"="];
  if (eqRange.location != NSNotFound) {
    NSString *key = [kvp substringToIndex:eqRange.location];
    NSString *value = [kvp substringFromIndex:(eqRange.location+1)];
    
    if ([key isEqualToString:PROTOCOL_KEY]) {
      if ([value isEqualToString:PROTOCOL_H323]) {
        callProtocol = XMCallProtocol_H323;
      } else if ([value isEqualToString:PROTOCOL_SIP]) {
        callProtocol = XMCallProtocol_SIP;
      }
    }
  }
}

@end
