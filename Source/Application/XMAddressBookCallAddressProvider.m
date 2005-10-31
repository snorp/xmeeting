/*
 * $Id: XMAddressBookCallAddressProvider.m,v 1.4 2005/10/31 22:11:50 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMeeting.h"
#import "XMAddressBookCallAddressProvider.h"

@interface XMAddressBookRecordSearchMatch (XMCallAddressMethods)

- (id<XMCallAddressProvider>)provider;
- (XMURL *)url;
- (NSString *)displayString;
- (NSImage *)displayImage;

@end

@interface XMAddressBookCallAddressProvider (PrivateMethods)

- (id)_init;

@end

@implementation XMAddressBookCallAddressProvider

#pragma mark Class Methods

+ (XMAddressBookCallAddressProvider *)sharedInstance
{
	static XMAddressBookCallAddressProvider *sharedInstance = nil;
	
	if(sharedInstance == nil)
	{
		sharedInstance = [[XMAddressBookCallAddressProvider alloc] _init];
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
	
	return self;
}

- (void)dealloc
{	
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

#pragma mark XMCallAddressProvider Methods

- (NSArray *)addressesMatchingString:(NSString *)searchString
{
	XMAddressBookManager *addressBookManager = [XMAddressBookManager sharedInstance];
	NSArray *matchedRecords = [addressBookManager recordsMatchingString:searchString
													mustBeValid:YES
										 returnExtraInformation:YES];
	return matchedRecords;
}

- (NSString *)completionStringForAddress:(id<XMCallAddress>)address uncompletedString:(NSString *)uncompletedString
{
	XMAddressBookRecordSearchMatch *searchMatch = (XMAddressBookRecordSearchMatch *)address;
	id record = [searchMatch record];
	XMAddressBookRecordPropertyMatch propertyMatch = [searchMatch propertyMatch];
	
	if(propertyMatch == XMAddressBookRecordPropertyMatch_CallAddressMatch)
	{
		// we have a match for the Address. In this case, we allow only the call address
		// to be entered. (not e.g. "callAddress" (displayName)". This eases the check
		// since we only have to check wether uncompletedString is a Prefix to the
		// call address.
		NSString *callAddress = [record humanReadableCallURLRepresentation];
		if(![callAddress hasPrefix:uncompletedString])
		{
			// since uncompletedString is not a prefix to the callAddress, this record is
			// not a valid record for completion
			return nil;
		}
		NSString *displayName = [record displayName];
		
		// producing the display string
		return [NSString stringWithFormat:@"%@ (%@)", callAddress, displayName];
		}
	else if(propertyMatch == XMAddressBookRecordPropertyMatch_CompanyMatch)
	{
		// a company match has a similar behavior as a call address match.
		// only if uncompletedString is a prefix to company name, we have a match.
		NSString *companyName = [record companyName];
		if(![companyName hasPrefix:uncompletedString])
		{
			return nil;
		}
		NSString *callAddress = [record humanReadableCallURLRepresentation];
		return [NSString stringWithFormat:@"%@ <%@>", companyName, callAddress];
	}
	else
	{
		// this is the most complicated case. the record matched either a first name or a last name,
		// which determines the order in which to display the two values. In addition, the user may
		// enter e.g. ("firstName" "lastName"), which has to be detected correctly.
		NSString *firstName = [record firstName];
		NSString *lastName = [record lastName];
		
		if(!firstName)
		{
			// only the last name can be shown, if the last name has not the uncompletedString as its prefix
			// this record is discarded as well.
			if(![lastName hasPrefix:uncompletedString])
			{
				return nil;
			}
			return lastName;
		}
		else if(!lastName)
		{
			// the same as in the case of !firstName
			if(![firstName hasPrefix:uncompletedString])
			{
				return nil;
			}
			return firstName;
		}
		else
		{
			// Now, it's getting funny. The uncompletedString may be more than just the property matched,
			// but still the match may be correct
			NSString *firstPart;
			NSString *lastPart;
			
			if(propertyMatch == XMAddressBookRecordPropertyMatch_FirstNameMatch)
			{
				firstPart = firstName;
				lastPart = lastName;
			}
			else
			{
				firstPart = lastName;
				lastPart = firstName;
			}
			
			NSString *displayName = [NSString stringWithFormat:@"%@ %@", firstPart, lastPart];
			if(![displayName hasPrefix:uncompletedString])
			{
				displayName = [NSString stringWithFormat:@"%@ %@", lastPart, firstPart];
				if(![displayName hasPrefix:uncompletedString])
				{
					return nil;
				}
			}
			
			NSString *callAddress = [record humanReadableCallURLRepresentation];
			return [NSString stringWithFormat:@"%@ <%@>", displayName, callAddress];
		}
	}
	return nil;
}

@end

@implementation XMAddressBookRecordSearchMatch (XMCallAddressMethods)

- (id<XMCallAddressProvider>)provider
{
	return [XMAddressBookCallAddressProvider sharedInstance];
}

- (XMURL *)url
{
	return [[self record] callURL];
}

- (NSString *)displayString
{
	return [[self record] displayName];
}

- (NSImage *)displayImage
{
	return [NSImage imageNamed:@"AddressBook"];
}

@end
