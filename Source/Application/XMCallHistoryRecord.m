/*
 * $Id: XMCallHistoryRecord.m,v 1.3 2005/10/17 12:57:53 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMCallHistoryRecord.h"
#import "XMCallHistoryCallAddressProvider.h"
#import "XMSimpleAddressURL.h"

NSString *XMKey_CallHistoryRecordAddress = @"XMeeting_CallAddress";
NSString *XMKey_CallHistoryRecordDisplayString = @"XMeeting_DisplayString";

@interface XMCallHistoryRecord(PrivateMethods)

- (BOOL)_checkType;
- (void)_addressBookDatabaseDidChange:(NSNotification *)notif;

@end

@implementation XMCallHistoryRecord

#pragma mark Init & Deallocation Methods

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	return nil;
}

- (id)initWithAddress:(NSString *)theAddress displayString:(NSString *)theDisplayString
{
	if(theAddress == nil || theDisplayString == nil)
	{
		// this condition isn't allowed!
		[self release];
		return nil;
	}
	
	self = [super initWithAddress:theAddress];
	
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
	NSString *theDisplayString = [dictionaryRepresentation objectForKey:XMKey_CallHistoryRecordDisplayString];
	
	self = [self initWithAddress:theCallAddress displayString:theDisplayString];
	
	return self;
}

- (void)dealloc
{
	[displayString release];
	[addressBookRecord release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

#pragma mark Getting different Representations

- (NSDictionary *)dictionaryRepresentation
{
	return [NSDictionary dictionaryWithObjectsAndKeys:[self address], XMKey_CallHistoryRecordAddress,
											displayString, XMKey_CallHistoryRecordDisplayString, nil];
}

#pragma mark Getting the attributes

- (XMURL *)url
{
	if(type == XMCallHistoryRecordType_AddressBookRecord)
	{
		return [addressBookRecord callURL];
	}
	return self;
}

- (NSString *)displayString
{
	if(type == XMCallHistoryRecordType_AddressBookRecord)
	{
		return [addressBookRecord displayName];
	}
	else
	{
		return displayString;
	}
}

- (XMCallHistoryRecordType)type
{
	return type;
}

#pragma mark Overriding id<XMCallAddress> methods

- (id<XMCallAddressProvider>)provider
{
	return [XMCallHistoryCallAddressProvider sharedInstance];
}

- (NSImage *)displayImage
{
	if(type == XMCallHistoryRecordType_AddressBookRecord)
	{
		return [NSImage imageNamed:@"AddressBook"];
	}
	else
	{
		return [NSImage imageNamed:@"CallHistory"];
	}
}

#pragma mark Private Methods

- (BOOL)_checkType
{
	[addressBookRecord release];
	
	BOOL didChange = NO;
	
	// check for matches in the AddressBook database
	addressBookRecord = [[[XMAddressBookManager sharedInstance] recordWithCallAddress:[self address]] retain];
	
	
	if(addressBookRecord != nil)
	{
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
		NSNotification *notif = [NSNotification notificationWithName:XMNotification_CallHistoryCallAddressProviderDataDidChange object:self];
		NSNotificationQueue *notificationQueue = [NSNotificationQueue defaultQueue];
		[notificationQueue enqueueNotification:notif postingStyle:NSPostASAP coalesceMask:NSNotificationCoalescingOnName forModes:nil];
	}
}

@end
