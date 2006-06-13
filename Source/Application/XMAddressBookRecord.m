/*
 * $Id: XMAddressBookRecord.m,v 1.4 2006/06/13 20:27:18 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMAddressBookRecord.h"

#import <AddressBook/AddressBook.h>
#import "XMeeting.h"

#import "XMSimpleAddressResource.h"
#import "XMAddressBookManager.h"
#import "XMAddressBookCallAddressProvider.h"
#import "XMPreferencesManager.h"

#define XM_ILLEGAL_INDEX NSNotFound
#define XM_UNKNOWN_INDEX NSNotFound-1

#define XM_PHONE_NUMBER_MASK 0x80000000
#define XM_PHONE_NUMBER_CLEAR_MASK 0x7fffffff

@implementation XMAddressBookRecord

#pragma mark Init & Deallocation Methods

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	return nil;
}

- (id)_initWithPerson:(ABPerson *)person index:(unsigned)theIndex propertyMatch:(XMAddressBookRecordPropertyMatch)thePropertyMatch
{
	self = [super init];
	
	addressBookPerson = [person retain];
	index = theIndex;
	propertyMatch = thePropertyMatch;
	
	return self;
}

- (void)dealloc
{
	[addressBookPerson release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Public Methods

- (NSString *)firstName
{
	return [addressBookPerson valueForProperty:kABFirstNameProperty];
}

- (NSString *)lastName
{
	return [addressBookPerson valueForProperty:kABLastNameProperty];
}

- (NSString *)companyName
{
	return [addressBookPerson valueForProperty:kABOrganizationProperty];
}

- (BOOL)isCompany
{
	NSNumber *number = [addressBookPerson valueForProperty:kABPersonFlags];
	
	if(number)
	{
		int value = [number intValue];
		
		if((value & kABShowAsMask) == kABShowAsCompany)
		{
			return YES;
		}
	}
	return NO;
}

- (XMAddressResource *)callAddress
{
	if(index == XM_UNKNOWN_INDEX)
	{
		return nil;
	}
	
	if((index & XM_PHONE_NUMBER_MASK) != 0)
	{
		ABMultiValue *multiValue = (ABMultiValue *)[addressBookPerson valueForProperty:kABPhoneProperty];
		
		if(multiValue == nil)
		{
			return nil;
		}
		
		NSString *phoneNumber = [multiValue valueAtIndex:(index & XM_PHONE_NUMBER_CLEAR_MASK)];
		
		XMCallProtocol callProtocol = [[XMPreferencesManager sharedInstance] addressBookPhoneNumberProtocol];
		XMSimpleAddressResource *addressResource = [[XMSimpleAddressResource alloc] initWithAddress:phoneNumber callProtocol:callProtocol];
		
		return [addressResource autorelease];
	}
	else
	{
		ABMultiValue *multiValue = (ABMultiValue *)[addressBookPerson valueForProperty:XMAddressBookProperty_CallAddress];
	
		if(multiValue == nil)
		{
			return nil;
		}
	
		NSData *data = (NSData *)[multiValue valueAtIndex:index];
	
		NSDictionary *dictionary = (NSDictionary *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
		XMAddressResource *addressResource = [XMAddressResource addressResourceWithDictionaryRepresentation:dictionary];
	
		return addressResource;
	}
}

- (NSString *)label
{
	if(index == XM_UNKNOWN_INDEX)
	{
		return nil;
	}
	
	if((index & XM_PHONE_NUMBER_MASK) != 0)
	{
		ABMultiValue *multiValue = (ABMultiValue *)[addressBookPerson valueForProperty:kABPhoneProperty];
		
		if(multiValue == nil)
		{
			return nil;
		}
		
		NSString *label = (NSString *)[multiValue labelAtIndex:(index & XM_PHONE_NUMBER_CLEAR_MASK)];
		
		return label;
	}
	else
	{
		ABMultiValue *multiValue = (ABMultiValue *)[addressBookPerson valueForProperty:XMAddressBookProperty_CallAddress];
	
		if(multiValue == nil)
		{
			return nil;
		}
	
		NSString *label = (NSString *)[multiValue labelAtIndex:index];
	
		return label;
	}
}

- (void)setCallAddress:(XMAddressResource *)callAddress label:(NSString *)label
{
	if((index & XM_PHONE_NUMBER_MASK) != 0)
	{
		return;
	}
	
	ABMultiValue *addressMultiValue = (ABMultiValue *)[addressBookPerson valueForProperty:XMAddressBookProperty_CallAddress];
	ABMultiValue *humanReadableAddressMultiValue = (ABMultiValue *)[addressBookPerson valueForProperty:XMAddressBookProperty_HumanReadableCallAddress];
	NSData *data = nil;
	
	if(callAddress != nil)
	{
		data = [NSKeyedArchiver archivedDataWithRootObject:[callAddress dictionaryRepresentation]];
	}
		
	ABMutableMultiValue *newAddressMultiValue = nil;
	ABMutableMultiValue *newHumanReadableAddressMultiValue = nil;
	
	if(addressMultiValue == nil && callAddress != nil)
	{
		newAddressMultiValue = [[ABMutableMultiValue alloc] init];
		newHumanReadableAddressMultiValue = [[ABMutableMultiValue alloc] init];
		
		[newAddressMultiValue addValue:data withLabel:label];
		[newHumanReadableAddressMultiValue addValue:[callAddress humanReadableAddress] withLabel:label];
	}
	else
	{
		newAddressMultiValue = (ABMutableMultiValue *)[addressMultiValue mutableCopy];
		newHumanReadableAddressMultiValue = (ABMutableMultiValue *)[humanReadableAddressMultiValue mutableCopy];
		
		if(callAddress == nil)
		{
			[newAddressMultiValue removeValueAndLabelAtIndex:index];
			[newHumanReadableAddressMultiValue removeValueAndLabelAtIndex:index];
			index = XM_ILLEGAL_INDEX;
		}
		else if(index == XM_UNKNOWN_INDEX)
		{
			[newAddressMultiValue addValue:data withLabel:label];
			NSString *identifier = [newHumanReadableAddressMultiValue addValue:[callAddress humanReadableAddress] withLabel:label];
			index = [newHumanReadableAddressMultiValue indexForIdentifier:identifier];
		}
		else
		{
			[newAddressMultiValue replaceValueAtIndex:index withValue:data];
			[newAddressMultiValue replaceLabelAtIndex:index withLabel:label];
			[newHumanReadableAddressMultiValue replaceValueAtIndex:index withValue:[callAddress humanReadableAddress]];
			[newHumanReadableAddressMultiValue replaceLabelAtIndex:index withLabel:label];
		}
	}
	
	[addressBookPerson setValue:newAddressMultiValue forProperty:XMAddressBookProperty_CallAddress];
	[addressBookPerson setValue:newHumanReadableAddressMultiValue forProperty:XMAddressBookProperty_HumanReadableCallAddress];
	
	[newAddressMultiValue release];
	[newHumanReadableAddressMultiValue release];
	
	[[ABAddressBook sharedAddressBook] save];
}

- (NSString *)humanReadableCallAddress
{
	if((index & XM_PHONE_NUMBER_MASK) != 0)
	{
		ABMultiValue *multiValue = (ABMultiValue *)[addressBookPerson valueForProperty:kABPhoneProperty];
		
		if(multiValue == nil)
		{
			return nil;
		}
		
		return [multiValue valueAtIndex:(index & XM_PHONE_NUMBER_CLEAR_MASK)];
	}
	else
	{
		if(index == XM_UNKNOWN_INDEX)
		{
			return nil;
		}
		
		ABMultiValue *multiValue = (ABMultiValue *)[addressBookPerson valueForProperty:XMAddressBookProperty_HumanReadableCallAddress];
	
		if(multiValue == nil)
		{
			return nil;
		}
	
		return (NSString *)[multiValue valueAtIndex:index];
	}
}

- (NSString *)displayName
{
	BOOL isPerson = YES;
	BOOL displayFirstNameFirst = YES;
	NSString *firstName = [self firstName];
	NSString *lastName = [self lastName];
	NSString *companyName = [self companyName];
	
	if(firstName == nil && lastName == nil && companyName == nil)
	{
		return NSLocalizedString(@"XM_NO_NAME_TEXT", @"");
	}
	
	NSNumber *number = (NSNumber *)[addressBookPerson valueForProperty:kABPersonFlags];
	if(number != nil)
	{
		int personFlags = [number intValue];
		
		if((personFlags & kABShowAsMask) == kABShowAsCompany)
		{
			isPerson = NO;
		}
		
		if((personFlags & kABNameOrderingMask) == kABLastNameFirst)
		{
			displayFirstNameFirst = NO;
		}
	}
	[number release];
	
	// determining which name part has precedence
	NSString *firstPart;
	NSString *lastPart;
	if(displayFirstNameFirst)
	{
		firstPart = firstName;
		lastPart = lastName;
	}
	else
	{
		firstPart = lastName;
		lastPart = firstName;
	}
	
	if(isPerson)
	{
		
		if(firstPart != nil && lastPart != nil)
		{
			return [NSString stringWithFormat:@"%@ %@", firstPart, lastPart];
		}
		if(firstPart != nil)
		{
			return firstPart;
		}
		if(lastPart != nil)
		{
			return lastPart;
		}
	}
	
	// if we reach here, we have either a company or the person does not have any name.
	// However, we are guaranteed that at least a person name or company name exists
	if(companyName)
	{
		return companyName;
	}
	if(firstPart != nil && lastPart != nil)
	{
		return [NSString stringWithFormat:@"%@ %@", firstPart, lastPart];
	}
	if(firstPart != nil)
	{
		return firstPart;
	}
	return lastPart;
}

- (XMAddressBookRecordPropertyMatch)propertyMatch
{
	return propertyMatch;
}

#pragma mark -
#pragma mark XMCallAddress Methods

- (id<XMCallAddressProvider>)provider
{
	return [XMAddressBookCallAddressProvider sharedInstance];
}

- (XMAddressResource *)addressResource
{
	return [self callAddress];
}

- (NSString *)displayString
{
	return [self displayName];
}

- (NSImage *)displayImage
{
	return [NSImage imageNamed:@"AddressBook"];
}

#pragma mark -
#pragma mark Framework Methods

- (ABPerson *)_person
{
	return addressBookPerson;
}

- (unsigned)_index
{
	return index;
}

@end
