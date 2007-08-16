/*
 * $Id: XMAddressBookPlugin.m,v 1.1 2007/08/16 15:37:37 hfriederich Exp $
 *
 * Copyright (c) 2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2007 Hannes Friederich. All rights reserved.
 */

#import "XMAddressBookPlugin.h"


@implementation XMAddressBookPlugin

- (void)performActionForPerson:(ABPerson *)person identifier:(NSString *)identifier
{
  ABMultiValue *phoneNumbers = [person valueForProperty:kABPhoneProperty];
  int index = [phoneNumbers indexForIdentifier:identifier];
  NSString *phoneNumber = (NSString *)[phoneNumbers valueAtIndex:index];
  phoneNumber = [phoneNumber stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  
  NSString *urlString = [[NSString alloc] initWithFormat:@"xmeeting:%@", phoneNumber];
  NSURL *url = [[NSURL alloc] initWithString:urlString];
  NSArray *urls = [[NSArray alloc] initWithObjects:url, nil];
  
  NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
  
  BOOL result = [workspace openURLs:urls withAppBundleIdentifier:@"net.sourceforge.xmeeting.XMeeting"
                            options:NSWorkspaceLaunchDefault additionalEventParamDescriptor:nil
                  launchIdentifiers:nil];
  
  [urls release];
  [url release];
  [urlString release];
}

- (BOOL)shouldEnableActionForPerson:(ABPerson *)person identifier:(NSString *)identifier
{
  return YES;
}

- (NSString *)titleForPerson:(ABPerson *)person identifier:(NSString *)identifier
{
  return NSLocalizedString(@"Call with XMeeting", @"");
}

- (NSString *)actionProperty
{
  return kABPhoneProperty;
}

@end
