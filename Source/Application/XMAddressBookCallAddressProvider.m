/*
 * $Id: XMAddressBookCallAddressProvider.m,v 1.9 2006/05/17 11:48:38 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMAddressBookCallAddressProvider.h"

#import "XMeeting.h"
#import "XMAddressBookManager.h"
#import "XMAddressBookRecord.h"

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
	NSArray *matchedRecords = [addressBookManager recordsMatchingString:searchString];
	return matchedRecords;
}

- (NSString *)completionStringForAddress:(id<XMCallAddress>)address uncompletedString:(NSString *)uncompletedString
{
	XMAddressBookRecord *record = (XMAddressBookRecord *)address;
	XMAddressBookRecordPropertyMatch propertyMatch = [record propertyMatch];
	NSRange searchRange = NSMakeRange(0, [uncompletedString length]);
	
	if(propertyMatch == XMAddressBookRecordPropertyMatch_CallAddressMatch)
	{
		// we have a match for the Address. In this case, we allow only the call address
		// to be entered. (not e.g. "callAddress" (displayName)". This eases the check
		// since we only have to check wether uncompletedString is a Prefix to the
		// call address.
		NSString *callAddress = [record humanReadableCallAddress];
		if(searchRange.length > [callAddress length])
		{
			return nil;
		}
		
		NSRange prefixRange = [callAddress rangeOfString:uncompletedString
												 options:(NSCaseInsensitiveSearch | NSLiteralSearch | NSAnchoredSearch)
												   range:searchRange];
		if(prefixRange.location == NSNotFound)
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
		if(searchRange.length > [companyName length])
		{
			return nil;
		}
		
		NSRange prefixRange = [companyName rangeOfString:uncompletedString
												 options:(NSCaseInsensitiveSearch | NSAnchoredSearch)
												   range:searchRange];
		if(prefixRange.location == NSNotFound)
		{
			return nil;
		}
	
		NSString *callAddress = [record humanReadableCallAddress];
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
			if(searchRange.length > [lastName length])
			{
				return nil;
			}
			
			NSRange prefixRange = [lastName rangeOfString:uncompletedString
												  options:(NSCaseInsensitiveSearch | NSAnchoredSearch)
													range:searchRange];
			if(prefixRange.location == NSNotFound)
			{
				return nil;
			}
			
			return lastName;
		}
		else if(!lastName)
		{
			// the same as in the case of !firstName
			if(searchRange.length > [firstName length])
			{
				return nil;
			}
			
			NSRange prefixRange = [firstName rangeOfString:uncompletedString
												   options:(NSCaseInsensitiveSearch | NSAnchoredSearch)
													 range:searchRange];
			if(prefixRange.location == NSNotFound)
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
			
			if(searchRange.length > [displayName length])
			{
				return nil;
			}
			
			NSRange prefixRange = [displayName rangeOfString:uncompletedString
													 options:(NSCaseInsensitiveSearch | NSAnchoredSearch)
													   range:searchRange];
			if(prefixRange.location == NSNotFound)
			{
				displayName = [NSString stringWithFormat:@"%@ %@", lastPart, firstPart];
				
				prefixRange = [displayName rangeOfString:uncompletedString
												 options:(NSCaseInsensitiveSearch | NSAnchoredSearch)
												   range:searchRange];
				if(prefixRange.location == NSNotFound)
				{
					return nil;
				}
			}
			
			NSString *callAddress = [record humanReadableCallAddress];
			return [NSString stringWithFormat:@"%@ <%@>", displayName, callAddress];
		}
	}
}

- (NSArray *)alternativesForAddress:(id<XMCallAddress>)address selectedIndex:(unsigned *)selectedIndex
{
	XMAddressBookRecord *record = (XMAddressBookRecord *)address;
	
	NSArray *records = [[XMAddressBookManager sharedInstance] recordsForPersonWithRecord:record indexOfRecord:selectedIndex];
	
	unsigned i;
	unsigned count = [records count];
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:count];
	
	for(i = 0; i < count; i++)
	{
		XMAddressBookRecord *theRecord = (XMAddressBookRecord *)[records objectAtIndex:i];
		NSString *callAddress = [theRecord humanReadableCallAddress];
		[array addObject:callAddress];
	}
	
	return array;
}

- (id<XMCallAddress>)alternativeForAddress:(id<XMCallAddress>)address atIndex:(unsigned)index
{
	XMAddressBookRecord *record = (XMAddressBookRecord *)address;
	
	unsigned indexOfRecord;
	NSArray *records = [[XMAddressBookManager sharedInstance] recordsForPersonWithRecord:record indexOfRecord:&indexOfRecord];
	
	return (id<XMCallAddress>)[records objectAtIndex:index];
}

- (NSArray *)allAddresses
{
	XMAddressBookManager *addressBookManager = [XMAddressBookManager sharedInstance];
	return [addressBookManager records];
}

@end
