/*
 * $Id: XMH323URL.m,v 1.4 2009/01/11 18:58:26 hfriederich Exp $
 *
 * Copyright (c) 2007-2009 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2007-2009 Hannes Friederich. All rights reserved.
 */

#import "XMH323URL.h"

#import "XMStringConstants.h"
#import "XMPrivate.h"
#import "XMURLParser.h"

#define PREFIX @"h323:"

@implementation XMH323URL

#pragma mark -
#pragma mark Class Methods

+ (BOOL)canHandleStringRepresentation:(NSString *)url
{
  return [url hasPrefix:PREFIX];
}

+ (BOOL)canHandleDictionaryRepresentation:(NSDictionary *)dict
{
  return NO;
}

+ (XMH323URL *)addressResourceWithStringRepresentation:(NSString *)url
{
  XMH323URL *h323URL = [[XMH323URL alloc] initWithStringRepresentation:url];
  if (h323URL != nil) {
    return [h323URL autorelease];
  }
  return nil;
}

+ (XMH323URL *)addressResourceWithDictionaryRepresentation:(NSDictionary *)dict
{
  return nil;
}

#pragma mark -
#pragma mark Overriding from XMURL

- (XMCallProtocol)callProtocol
{
  return XMCallProtocol_H323;
}

- (NSString *)_prefix
{
  return PREFIX;
}

- (BOOL)_parseString:(const char *)string usingCallback:(XMURLParseCallback)callback
{
  return _XMParseH323URL(string, callback, (void*)self);
}

@end
