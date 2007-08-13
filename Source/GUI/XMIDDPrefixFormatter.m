/*
 * $Id: XMIDDPrefixFormatter.m,v 1.1 2007/08/13 00:36:34 hfriederich Exp $
 *
 * Copyright (c) 2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2007 Hannes Friederich. All rights reserved.
 */

#import "XMIDDPrefixFormatter.h"
#import "XMeeting.h"

@implementation XMIDDPrefixFormatter

- (NSString *)stringForObjectValue:(id)anObject
{
  if (![anObject isKindOfClass:[NSString class]]) {
    return nil;
  }
  
  if (!XMIsPlainPhoneNumber((NSString *)anObject)) {
    return nil;
  }
  
  return (NSString *)anObject;
}

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error
{
  if (XMIsPlainPhoneNumber(string)) {
    *anObject = string;
    return YES;
  } else {
    if (error != NULL) {
      *error = @"Not a valid dial prefix"; 
    }
    return NO;
  }
}

@end
