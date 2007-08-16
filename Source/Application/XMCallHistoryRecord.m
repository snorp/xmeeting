/*
 * $Id: XMCallHistoryRecord.m,v 1.15 2007/08/16 15:41:08 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#import "XMCallHistoryRecord.h"

#import "XMAddressBookManager.h"
#import "XMAddressBookRecord.h"
#import "XMCallHistoryCallAddressProvider.h"
#import "XMSimpleAddressResource.h"
#import "XMPreferencesManager.h"

NSString *XMKey_CallHistoryRecordAddress = @"XMeeting_CallAddress";
NSString *XMKey_CallHistoryRecordProtocol = @"XMeeting_Protocol";
NSString *XMKey_CallHistoryRecordDisplayString = @"XMeeting_DisplayString";

@interface XMCallHistoryRecord(PrivateMethods)

- (BOOL)_checkType;
- (void)_addressBookDatabaseDidChange:(NSNotification *)notif;

@end

@implementation XMCallHistoryRecord

#pragma mark -
#pragma mark Init & Deallocation Methods

- (id)init
{
  [self doesNotRecognizeSelector:_cmd];
  [self release];
  return nil;
}

- (id)initWithAddress:(NSString *)theAddress protocol:(XMCallProtocol)theCallProtocol displayString:(NSString *)theDisplayString
{
  if(theAddress == nil || theCallProtocol == XMCallProtocol_UnknownProtocol || theDisplayString == nil)
  {
    // this condition isn't allowed!
    [self release];
    return nil;
  }
  
  self = [super initWithAddress:theAddress callProtocol:theCallProtocol];
  
  displayString = [theDisplayString copy];
  
  addressBookRecord = nil;
  
  [self _checkType];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_addressBookDatabaseDidChange:)
                                               name:XMNotification_AddressBookManagerDidChangeDatabase object:nil];
  
  return self;
}

- (id)initWithDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation
{
  NSString *theCallAddress = [dictionaryRepresentation objectForKey:XMKey_CallHistoryRecordAddress];
  NSNumber *theCallProtocolNumber = [dictionaryRepresentation objectForKey:XMKey_CallHistoryRecordProtocol];
  NSString *theDisplayString = [dictionaryRepresentation objectForKey:XMKey_CallHistoryRecordDisplayString];
  
  XMCallProtocol theCallProtocol = XMCallProtocol_H323;
  
  if(theCallProtocolNumber != nil)
  {
    theCallProtocol = (XMCallProtocol)[theCallProtocolNumber unsignedIntValue];
  }
  
  self = [self initWithAddress:theCallAddress protocol:theCallProtocol displayString:theDisplayString];
  
  return self;
}

- (void)dealloc
{
  if(displayString != nil)
  {
    [displayString release];
  }
  if(addressBookRecord != nil)
  {
    [addressBookRecord release];
  }
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [super dealloc];
}

#pragma mark -
#pragma mark Getting different Representations

- (NSDictionary *)dictionaryRepresentation
{
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:[self callProtocol]];
  
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[self address], XMKey_CallHistoryRecordAddress,
    number, XMKey_CallHistoryRecordProtocol,
    displayString, XMKey_CallHistoryRecordDisplayString, nil];
  
  [number release];
  
  return dict;
}

#pragma mark -
#pragma mark Getting the attributes

- (XMAddressResource *)addressResource
{
  if(type == XMCallHistoryRecordType_AddressBookRecord)
  {
    if(addressBookRecord != nil)
    {
      return (XMAddressResource *)[addressBookRecord callAddress];
    }
    return nil;
  }
  return self;
}

- (NSString *)displayString
{
  NSString *theDisplayString = nil;
  NSString *theAddress = [self address];
  
  if(type == XMCallHistoryRecordType_AddressBookRecord)
  {
    theDisplayString = [addressBookRecord displayName];
  }
  else
  {
    theDisplayString = displayString;
  }
  
  if(theDisplayString == nil)
  {
    return theAddress;
  }
  
  return theDisplayString;
}

- (void)setDisplayString:(NSString *)_displayString
{
  NSString *old = displayString;
  displayString = [_displayString copy];
  [old release];
}

- (XMCallHistoryRecordType)type
{
  return type;
}

#pragma mark -
#pragma mark Overriding XMSimpleAddressResource methods

- (id<XMCallAddressProvider>)provider
{
  return [XMCallHistoryCallAddressProvider sharedInstance];
}

- (void)setProvider
{
}

- (NSImage *)displayImage
{
  if(type == XMCallHistoryRecordType_AddressBookRecord)
  {
    return [NSImage imageNamed:@"AddressBook"];
  }
  else
  {
    if([self callProtocol] == XMCallProtocol_H323)
    {
      return [NSImage imageNamed:@"CallHistory_H323"];
    }
    else
    {
      return [NSImage imageNamed:@"CallHistory_SIP"];
    }
  }
}

- (void)setDisplayImage:(NSImage *)image
{
}

- (void)setCallProtocol:(XMCallProtocol)_callProtocol
{
  [super setCallProtocol:_callProtocol];
  [[XMCallHistoryCallAddressProvider sharedInstance] synchronizeUserDefaults];
}

#pragma mark -
#pragma mark Private Methods

- (BOOL)_checkType
{
  if(addressBookRecord != nil)
  {
    [addressBookRecord release];
    addressBookRecord = nil;
  }
  
  BOOL didChange = NO;
  
  if([[XMPreferencesManager sharedInstance] searchAddressBookDatabase])
  {
    // check for matches in the AddressBook database
    addressBookRecord = [[XMAddressBookManager sharedInstance] recordWithCallAddress:[self address]];
  }
  
  if(addressBookRecord != nil)
  {
    [addressBookRecord retain];
    if(type != XMCallHistoryRecordType_AddressBookRecord)
    {
      type = XMCallHistoryRecordType_AddressBookRecord;
      didChange = YES;
    }
  }
  else
  {
    if(type != XMCallHistoryRecordType_GeneralRecord)
    {
      type = XMCallHistoryRecordType_GeneralRecord;
      didChange = YES;
    }
  }
  
  return didChange;
}

- (void)_addressBookDatabaseDidChange:(NSNotification *)notif
{
  if([self _checkType] == YES)
  {
    NSNotification *notif = [NSNotification notificationWithName:XMNotification_CallHistoryCallAddressProviderDataDidChange 
                                                          object:[XMCallHistoryCallAddressProvider sharedInstance]];
    NSNotificationQueue *notificationQueue = [NSNotificationQueue defaultQueue];
    [notificationQueue enqueueNotification:notif postingStyle:NSPostASAP coalesceMask:NSNotificationCoalescingOnName forModes:nil];
  }
}

@end
