/*
 * $Id: XMAddressBookManager.m,v 1.1 2005/05/31 15:01:01 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import <AddressBook/AddressBook.h>
#import "XMAddressBookManager.h"
#import "XMURL.h"

NSString *XMAddressBookCallURLProperty = @"XMeetingCallURL";
NSString *XMAddressBookHumanReadableCallAddressProperty = @"XMeetingHumanReadableCallAddress";

@interface XMAddressBookManager (PrivateMethods)

- (id)_init;

@end

@interface XMAddressBookRecordSearchMatch(PrivateMethods)

- (id)_initWithRecord:(ABPerson *)record propertyMatch:(XMAddressBookRecordPropertyMatch)propertyMatch;

@end

/**
 * Extends the functionality of ABPerson instances
 * by adding this category
 **/
@interface ABPerson (XMeetingFrameworkCategoryMethods)

- (BOOL)isValid;
- (NSString *)firstName;
- (NSString *)lastName;
- (NSString *)companyName;
- (BOOL)isCompany;
- (XMURL *)callURL;
- (void)setCallURL:(XMURL *)callURL;

- (NSString *)humanReadableCallAddress;
- (NSString *)displayName;

@end

@implementation XMAddressBookManager

#pragma mark Class Methods

+ (XMAddressBookManager *)sharedInstance
{
	static XMAddressBookManager *sharedInstance = nil;
	
	if(!sharedInstance)
	{
		sharedInstance = [[XMAddressBookManager alloc] _init];
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
	addressBook = [ABAddressBook sharedAddressBook];
	
	// adding the XMAddressBookCallURLProperty and the XMAddressBookHumanReadableCallAddressProperty
	// to the list of Properties in ABPerson
	NSNumber *number = [[NSNumber alloc] initWithInt:kABStringProperty];
	NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:number, XMAddressBookCallURLProperty, nil];
	[ABPerson addPropertiesAndTypes:dict];
	[dict release];
	dict = [[NSDictionary alloc] initWithObjectsAndKeys:number, XMAddressBookHumanReadableCallAddressProperty, nil];
	[ABPerson addPropertiesAndTypes:dict];
	[dict release];
	[number release];
	
	// creating the search elements
	validRecordsSearchElement = [[ABPerson searchElementForProperty:XMAddressBookCallURLProperty label:nil key:nil
															  value:@":/" comparison:kABContainsSubString] retain];
	
	return self;
}

- (void)dealloc
{
	[validRecordsSearchElement release];
	
	[super dealloc];
}

#pragma mark Obtaining records

- (NSArray *)records
{
	return [addressBook people];
}

- (NSArray *)validRecords
{
	return [addressBook recordsMatchingSearchElement:validRecordsSearchElement];
}

#pragma mark Adding new Records

- (id)createRecordWithFirstName:(NSString *)firstName lastName:(NSString *)lastName
					companyName:(NSString *)companyName isCompany:(BOOL)isCompany
						callURL:(XMURL *)callURL
{
	ABPerson *newRecord = [[ABPerson alloc] init];
	
	if(firstName && ![firstName isEqualToString:@""])
	{
		[newRecord setValue:firstName forProperty:kABFirstNameProperty];
	}
	if(lastName && ![lastName isEqualToString:@""])
	{
		[newRecord setValue:lastName forProperty:kABLastNameProperty];
	}
	if(companyName && ![companyName isEqualToString:@""])
	{
		[newRecord setValue:companyName forProperty:kABOrganizationProperty];
	}
	
	if(isCompany)
	{
		NSNumber *number = [[NSNumber alloc] initWithInt:kABShowAsCompany];
		[newRecord setValue:number forProperty:kABPersonFlags];
		[number release];
	}
	
	[newRecord setValue:callURL forProperty:XMAddressBookCallURLProperty];
	
	return [newRecord autorelease];
}

- (BOOL)addRecord:(id)record
{
	BOOL isSuccessfullyAdded = [addressBook addRecord:record];
	
	if(isSuccessfullyAdded)
	{
		[addressBook save];
	}
	return isSuccessfullyAdded;
}

#pragma mark Searching the Database

- (NSArray *)recordsMatchingString:(NSString *)searchString mustBeValid:(BOOL)mustBeValid 
			returnExtraInformation:(BOOL)returnExtraInformation
{
	ABSearchElement *finalSearchElement;	// the searchElement with which we actually query the database
	
	// we search the firstName, lastName, companyName and HumanReadableCallAddress properties
	// for a match (in this order) and record which part matched as well
	ABSearchElement *firstNameSearchElement = [ABPerson searchElementForProperty:kABFirstNameProperty label:nil key:nil
																		   value:searchString
																	  comparison:kABPrefixMatchCaseInsensitive];
	ABSearchElement *lastNameSearchElement = [ABPerson searchElementForProperty:kABLastNameProperty label:nil key:nil
																		  value:searchString
																	 comparison:kABPrefixMatchCaseInsensitive];
	ABSearchElement *companyNameSearchElement = [ABPerson searchElementForProperty:kABOrganizationProperty label:nil key:nil
																			 value:searchString
																		comparison:kABPrefixMatchCaseInsensitive];
	ABSearchElement *callAddressSearchElement = [ABPerson searchElementForProperty:XMAddressBookHumanReadableCallAddressProperty
																			 label:nil key:nil value:searchString
																		comparison:kABPrefixMatchCaseInsensitive];
	NSArray *stringSearchElements = [[NSArray alloc] initWithObjects:firstNameSearchElement, lastNameSearchElement, companyNameSearchElement,
		callAddressSearchElement, nil];
	finalSearchElement = [ABSearchElement searchElementForConjunction:kABSearchOr children:stringSearchElements];
	[stringSearchElements release];
	
	if(mustBeValid)
	{
		NSArray *searchElements = [[NSArray alloc] initWithObjects:validRecordsSearchElement, finalSearchElement, nil];
		finalSearchElement = [ABSearchElement searchElementForConjunction:kABSearchAnd children:searchElements];
		[searchElements release];
	}
	
	NSArray *matchedRecords = [addressBook recordsMatchingSearchElement:finalSearchElement];
	
	if(!returnExtraInformation)
	{
		return matchedRecords;
	}
	
	// have have to find out the additional information about the matched records and
	// returns this instance
	unsigned i;
	unsigned count = [matchedRecords count];
	NSMutableArray *searchMatches = [NSMutableArray arrayWithCapacity:count];
	for(i = 0; i < count; i++)
	{
		ABPerson *record = (ABPerson *)[matchedRecords objectAtIndex:i];
		XMAddressBookRecordPropertyMatch propertyMatch = XMAddressBookRecordPropertyMatch_CallAddressMatch;
		
		if([firstNameSearchElement matchesRecord:record])
		{
			propertyMatch = XMAddressBookRecordPropertyMatch_FirstNameMatch;
		}
		else if([lastNameSearchElement matchesRecord:record])
		{
			propertyMatch = XMAddressBookRecordPropertyMatch_LastNameMatch;
		}
		else if([companyNameSearchElement matchesRecord:record])
		{
			propertyMatch = XMAddressBookRecordPropertyMatch_CompanyMatch;
		}
		
		XMAddressBookRecordSearchMatch *searchMatch = [[XMAddressBookRecordSearchMatch alloc] _initWithRecord:record propertyMatch:propertyMatch];
		[searchMatches addObject:searchMatch];
		[searchMatch release];
	}
	
	return searchMatches;
}

@end

@implementation XMAddressBookRecordSearchMatch

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	return nil;
}

- (id)_initWithRecord:(ABPerson *)theRecord propertyMatch:(XMAddressBookRecordPropertyMatch)thePropertyMatch
{
	record = [theRecord retain];
	propertyMatch = thePropertyMatch;
	
	return self;
}

- (void)dealloc
{
	[record release];
	
	[super dealloc];
}

- (id)record
{
	return record;
}

- (XMAddressBookRecordPropertyMatch)propertyMatch
{
	return propertyMatch;
}

@end

@implementation ABPerson (XMeetingFrameworkCategoryMethods)

- (BOOL)isValid
{
	if([self valueForProperty:XMAddressBookCallURLProperty] != nil)
	{
		return YES;
	}
	return NO;
}
- (NSString *)firstName
{
	return [self valueForProperty:kABFirstNameProperty];
}

- (NSString *)lastName
{
	return [self valueForProperty:kABLastNameProperty];
}

- (NSString *)companyName
{
	return [self valueForProperty:kABOrganizationProperty];
}

- (BOOL)isCompany
{
	NSNumber *number = [self valueForProperty:kABPersonFlags];
	
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

- (XMURL *)callURL
{
	NSString *urlString = [self valueForProperty:XMAddressBookCallURLProperty];
	XMURL *url = nil;
	
	if(urlString)
	{
		url = [[[XMURL alloc] initWithString:urlString] autorelease];
	}
	
	return url;
}

- (void)setCallURL:(XMURL *)callURL
{
	if(callURL)
	{
		[self setValue:[callURL stringRepresentation] forProperty:XMAddressBookCallURLProperty];
		[self setValue:[callURL humanReadableRepresentation] forProperty:XMAddressBookHumanReadableCallAddressProperty];
	}
	else
	{
		[self removeValueForProperty:XMAddressBookCallURLProperty];
		[self removeValueForProperty:XMAddressBookHumanReadableCallAddressProperty];
	}
	[[ABAddressBook sharedAddressBook] save];
}

- (NSString *)humanReadableCallAddress
{
	return [self valueForProperty:XMAddressBookHumanReadableCallAddressProperty];
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
		return @"<No Name>";
	}
	
	NSNumber *number = (NSNumber *)[self valueForProperty:kABPersonFlags];
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

@end