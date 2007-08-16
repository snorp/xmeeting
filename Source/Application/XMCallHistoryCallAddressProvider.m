/*
 * $Id: XMCallHistoryCallAddressProvider.m,v 1.12 2007/08/16 15:41:08 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#import "XMCallHistoryCallAddressProvider.h"
#import "XMcallHistoryRecord.h"

NSString *XMNotification_CallHistoryCallAddressProviderDataDidChange = @"XMeetingCallHistoryCallAddressProviderDataDidChangeNotification";
NSString *XMKey_CallHistoryRecords = @"XMeeting_CallHistoryRecords";

@interface XMCallHistoryCallAddressProvider (PrivateMethods)

- (id)_init;

- (void)_didStartCalling:(NSNotification *)notif;

@end

@implementation XMCallHistoryCallAddressProvider

#pragma mark -
#pragma mark Class Methods

+ (XMCallHistoryCallAddressProvider *)sharedInstance
{
  static XMCallHistoryCallAddressProvider *sharedInstance = nil;
  
  if(sharedInstance == nil)
  {
    sharedInstance = [[XMCallHistoryCallAddressProvider alloc] _init];
  }
  
  return sharedInstance;
}

#pragma mark -
#pragma mark Init & Deallocation Methods

- (id)init
{
  [self doesNotRecognizeSelector:_cmd];
  [self release];
  return nil;
}

- (id)_init
{
  isActiveCallAddressProvider = NO;
  
  NSArray *storedHistory = [[NSUserDefaults standardUserDefaults] arrayForKey:XMKey_CallHistoryRecords];
  unsigned i;
  unsigned count = 0;
  
  if(storedHistory != nil)
  {
    count = [storedHistory count];
  }
  
  callHistoryRecords = [[NSMutableArray alloc] initWithCapacity:count];
  
  for(i = 0; i < count; i++)
  {
    NSDictionary *dictionaryRepresentation = [storedHistory objectAtIndex:i];
    XMCallHistoryRecord *callHistoryRecord = [[XMCallHistoryRecord alloc] initWithDictionaryRepresentation:dictionaryRepresentation];
    
    if(callHistoryRecord)
    {
      [callHistoryRecords addObject:callHistoryRecord];
    }
    
    [callHistoryRecord release];
  }
  
  searchMatches = [[NSMutableArray alloc] initWithCapacity:2];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didStartCalling:)
                                               name:XMNotification_CallManagerDidStartCalling object:nil];
  
  return self;
}

- (void)dealloc
{
  [callHistoryRecords release];
  [searchMatches release];
  
  if(isActiveCallAddressProvider)
  {
    [[XMCallAddressManager sharedInstance] removeCallAddressProvider:self];
  }
  
  [super dealloc];
}

#pragma mark -
#pragma mark Activating / Deactivating this provider

- (BOOL)isActiveCallAddressProvider
{
  return isActiveCallAddressProvider;
}

- (void)setActiveCallAddressProvider:(BOOL)flag
{
  if(flag == isActiveCallAddressProvider)
  {
    return;
  }
  
  if(flag == YES)
  {
    [[XMCallAddressManager sharedInstance] addCallAddressProvider:self];
    isActiveCallAddressProvider = YES;
  }
  else
  {
    [[XMCallAddressManager sharedInstance] removeCallAddressProvider:self];
    isActiveCallAddressProvider = NO;
  }
}

#pragma mark -
#pragma mark Public Methods

- (NSArray *)recentCalls
{
  return callHistoryRecords;
}

- (void)synchronizeUserDefaults
{
  unsigned i;
  unsigned count = [callHistoryRecords count];
  
  NSMutableArray *dictionaryRepresentations = [[NSMutableArray alloc] initWithCapacity:count];
  
  for(i = 0; i < count; i++)
  {
    XMCallHistoryRecord *record = (XMCallHistoryRecord *)[callHistoryRecords objectAtIndex:i];
    NSDictionary *dictionaryRepresentation = [record dictionaryRepresentation];
    [dictionaryRepresentations addObject:dictionaryRepresentation];
  }
  
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:dictionaryRepresentations forKey:XMKey_CallHistoryRecords];
  
  [dictionaryRepresentations release];
}

#pragma mark -
#pragma mark XMCallAddressProvider methods

- (NSArray *)addressesMatchingString:(NSString *)searchString
{
  NSRange searchRange = NSMakeRange(0, [searchString length]);
  
  [searchMatches removeAllObjects];
  
  unsigned i;
  unsigned count = [callHistoryRecords count];
  
  for(i = 0; i < count; i++)
  {
    XMCallHistoryRecord *record = (XMCallHistoryRecord *)[callHistoryRecords objectAtIndex:i];
    
    if([record type] == XMCallHistoryRecordType_GeneralRecord)
    {
      NSString *address = [record address];
      
      if(searchRange.length <= [address length])
      {
        NSRange prefixRange = [address rangeOfString:searchString
                                             options:(NSCaseInsensitiveSearch | NSLiteralSearch | NSAnchoredSearch)
                                               range:searchRange];
      
        if(prefixRange.location != NSNotFound)
        {
          [searchMatches addObject:record];
        }
      }
    }
  }
  
  return searchMatches;
}

- (NSString *)completionStringForAddress:(id<XMCallAddress>)callAddress uncompletedString:(NSString *)uncompletedString
{
  XMCallHistoryRecord *record = (XMCallHistoryRecord *)callAddress;
  
  NSRange searchRange = NSMakeRange(0, [uncompletedString length]);
  NSString *address = [record address];
  
  if(searchRange.length > [address length])
  {
    return nil;
  }
  
  NSRange prefixRange = [address rangeOfString:uncompletedString
                                       options:(NSCaseInsensitiveSearch | NSLiteralSearch | NSAnchoredSearch)
                                         range:searchRange];
  
  if(prefixRange.location == NSNotFound)
  {
    return nil;
  }
  
  NSString *displayString = [record displayString];
  
  if ([address isEqualToString:displayString]) {
    return address;
  }
  return [NSString stringWithFormat:@"%@ (%@)", address, displayString];
}

- (id<XMCallAddress>)addressMatchingResource:(XMAddressResource *)addressResource
{
  NSString *address = [addressResource address];
  XMCallProtocol callProtocol = [addressResource callProtocol];
  
  unsigned i;
  unsigned count = [callHistoryRecords count];
  
  for(i = 0; i < count; i++)
  {
    XMCallHistoryRecord *record = (XMCallHistoryRecord *)[callHistoryRecords objectAtIndex:i];
    
    if ([record type] == XMCallHistoryRecordType_GeneralRecord &&
        [record callProtocol] == callProtocol && 
        [[record address] caseInsensitiveCompare:address] == NSOrderedSame)
    {
      [record setDisplayString:[addressResource humanReadableAddress]]; // keep the display string up-to-date
      return record;
    }
  }
  
  return nil;
}

- (NSArray *)alternativesForAddress:(id<XMCallAddress>)callAddress selectedIndex:(unsigned *)selectedIndex
{
  XMCallHistoryRecord *record = (XMCallHistoryRecord *)callAddress;
  
  if([record callProtocol] == XMCallProtocol_H323)
  {
    *selectedIndex = 0;
  }
  else
  {
    *selectedIndex = 1;
  }
  
  return [NSArray arrayWithObjects:@"H.323", @"SIP", nil];
}

- (id<XMCallAddress>)alternativeForAddress:(id<XMCallAddress>)callAddress atIndex:(unsigned)index
{
  XMCallHistoryRecord *record = (XMCallHistoryRecord *)callAddress;
  
  if(index == 0)
  {
    [record setCallProtocol:XMCallProtocol_H323];
  }
  else
  {
    [record setCallProtocol:XMCallProtocol_SIP];
  }
  
  return record;
}

- (NSArray *)allAddresses
{
  unsigned i;
  unsigned count = [callHistoryRecords count];
  
  NSMutableArray *addresses = [NSMutableArray arrayWithCapacity:count];
  
  for(i = 0; i < count; i++)
  {
    XMCallHistoryRecord *record = (XMCallHistoryRecord *)[callHistoryRecords objectAtIndex:i];
    
    if([record type] == XMCallHistoryRecordType_GeneralRecord)
    {
      [addresses addObject:record];
    }
  }
  
  return addresses;
}

- (XMProviderPriority)priorityForAllAddresses
{
  return XMProviderPriority_Normal;
}

#pragma mark -
#pragma mark Private Methods

- (void)_didStartCalling:(NSNotification *)notif
{
  id<XMCallAddress> callAddress = [[XMCallAddressManager sharedInstance] activeCallAddress];
  NSString *address = [[callAddress addressResource] address];
  XMCallProtocol callProtocol = [[callAddress addressResource] callProtocol];
  
  unsigned i;
  unsigned count = [callHistoryRecords count];
  
  for(i = 0; i < count; i++)
  {
    XMCallHistoryRecord *record = (XMCallHistoryRecord *)[callHistoryRecords objectAtIndex:i];
    if([[record address] isEqualToString:address])
    {
      if(i == 0)
      {
        // Update the user defaults in case the user chose a different cal protocol
        [self synchronizeUserDefaults];
        return;
      }
      else
      {
        [record retain];
        [callHistoryRecords removeObjectAtIndex:i];
        [callHistoryRecords insertObject:record atIndex:0];
        [record release];
        [self synchronizeUserDefaults];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallHistoryCallAddressProviderDataDidChange object:self];
        return;
      }
    }
  }
  
  // the address is not in the call history, thus creating a new instance.
  XMCallHistoryRecord *record = [[XMCallHistoryRecord alloc] initWithAddress:address protocol:callProtocol displayString:[callAddress displayString]];
  
  if(count == 10)
  {
    [callHistoryRecords removeObjectAtIndex:9];
  }
  [callHistoryRecords insertObject:record atIndex:0];
  [record release];
  [self synchronizeUserDefaults];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallHistoryCallAddressProviderDataDidChange object:self];
}

@end
