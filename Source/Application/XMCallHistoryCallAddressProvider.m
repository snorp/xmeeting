/*
 * $Id: XMCallHistoryCallAddressProvider.m,v 1.4 2006/03/16 14:13:57 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMCallHistoryCallAddressProvider.h"
#import "XMcallHistoryRecord.h"

NSString *XMNotification_CallHistoryCallAddressProviderDataDidChange = @"XMeetingCallHistoryCallAddressProviderDataDidChangeNotification";
NSString *XMKey_CallHistoryRecords = @"XMeeting_CallHistoryRecords";

@interface XMCallHistoryCallAddressProvider (PrivateMethods)

- (id)_init;

- (void)_didStartCalling:(NSNotification *)notif;
- (void)_synchronizeUserDefaults;

@end

@implementation XMCallHistoryCallAddressProvider

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
	}
	else
	{
		[[XMCallAddressManager sharedInstance] removeCallAddressProvider:self];
	}
}

- (NSArray *)recentCalls
{
	return callHistoryRecords;
}

#pragma mark XMCallAddressProvider methods

- (NSArray *)addressesMatchingString:(NSString *)searchString
{
	[searchMatches removeAllObjects];
	
	unsigned i;
	unsigned count = [callHistoryRecords count];
	
	for(i = 0; i < count; i++)
	{
		XMCallHistoryRecord *record = (XMCallHistoryRecord *)[callHistoryRecords objectAtIndex:i];
		
		if([record type] == XMCallHistoryRecordType_GeneralRecord)
		{
			if([[record address] hasPrefix:searchString])
			{
				[searchMatches addObject:record];
			}
		}
	}
	
	return searchMatches;
}

- (NSString *)completionStringForAddress:(id<XMCallAddress>)callAddress uncompletedString:(NSString *)uncompletedString
{
	XMCallHistoryRecord *record = (XMCallHistoryRecord *)callAddress;
	
	if([[record address] hasPrefix:uncompletedString])
	{
		return [record displayString];
	}
	return nil;
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

#pragma mark Private Methods

- (void)_didStartCalling:(NSNotification *)notif
{
	id<XMCallAddress> callAddress = [[XMCallAddressManager sharedInstance] activeCallAddress];
	NSString *address = [[callAddress addressResource] address];
	
	unsigned i;
	unsigned count = [callHistoryRecords count];
	
	for(i = 0; i < count; i++)
	{
		XMCallHistoryRecord *record = (XMCallHistoryRecord *)[callHistoryRecords objectAtIndex:i];
		if([[record address] isEqualToString:address])
		{
			if(i == 0)
			{
				return;
			}
			else
			{
				[callHistoryRecords exchangeObjectAtIndex:i withObjectAtIndex:0];
				[self _synchronizeUserDefaults];
				
				[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallHistoryCallAddressProviderDataDidChange object:self];
				return;
			}
		}
	}
	
	// the address is not in the call history, thus creating a new instance.
	XMCallHistoryRecord *record = [[XMCallHistoryRecord alloc] initWithAddress:address protocol:XMCallProtocol_H323 displayString:[callAddress displayString]];
	
	if(count == 10)
	{
		[callHistoryRecords removeObjectAtIndex:9];
	}
	[callHistoryRecords insertObject:record atIndex:0];
	[record release];
	[self _synchronizeUserDefaults];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallHistoryCallAddressProviderDataDidChange object:self];
}

- (void)_synchronizeUserDefaults
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

@end
