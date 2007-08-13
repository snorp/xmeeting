/*
 * $Id: XMIPAddressFormatter.m,v 1.1 2007/08/13 00:36:34 hfriederich Exp $
 *
 * Copyright (c) 2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2007 Hannes Friederich. All rights reserved.
 */

#import "XMIPAddressFormatter.h"
#import "XMeeting.h"

@implementation XMIPAddressFormatter

- (NSString *)stringForObjectValue:(id)anObject
{
  if (![anObject isKindOfClass:[NSString class]]) {
    return nil;
  }
  
  if (!XMIsIPAddress((NSString *)anObject)) {
    return nil;
  }
  
  return (NSString *)anObject;
}

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error
{
  if (XMIsIPAddress(string)) {
    *anObject = string;
    return YES;
  } else {
    if (error != NULL) {
      *error = @"Not an IP Address"; 
    }
    return NO;
  }
}

@end
