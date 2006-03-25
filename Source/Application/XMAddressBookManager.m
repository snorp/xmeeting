/*
 * $Id: XMAddressBookManager.m,v 1.4 2006/03/25 10:41:55 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMAddressBookManager.h"

#import <AddressBook/AddressBook.h>

extern CFStringRef const kABPersonRecordType;

#import "XMAddressBookRecordSearchMatch.h"

NSString *XMNotification_AddressBookManagerDidChangeDatabase = @"XMeetingAddressBookManagerDidChangeDatabaseNotification";

NSString *XMAddressBookProperty_CallAddress = @"XMeeting_CallAddress2";
NSString *XMAddressBookProperty_HumanReadableCallAddress = @"XMeeting_HumanReadableCallAddress2";
NSString *XMAddressBookProperty_CallAddress_0_1 = @"XMeeting_CallAddress";
NSString *XMAddressBookProperty_HumanReadableCallAddress_0_1 = @"XMeeting_HumanReadableCallAddress";

@interface XMAddressBookManager (PrivateMethods)

- (id)_init;
- (void)_addressBookDatabaseDidChange:(NSNotification *)notif;

- (void)_transformRecordsFrom_0_1;

@end

@interface XMAddressBookRecordSearchMatch (FrameworkMethods)

- (id)_initWithRecord:(ABPerson *)record propertyMatch:(XMAddressBookRecordPropertyMatch)propertyMatch;

@end

/**
 * Extends the functionality of ABPerson instances
 * by adding this category
 **/
@interface ABPerson (XMeetingFrameworkCategoryMethods) <XMAddressBookRecord>

- (BOOL)isValid;
- (NSString *)firstName;
- (NSString *)lastName;
- (NSString *)companyName;
- (BOOL)isCompany;
- (XMAddressResource *)callAddress;
- (void)setCallAddress:(XMAddressResource *)callAddress;

- (NSString *)humanReadableCallAddress;
- (NSString *)displayName;

@end

@implementation XMAddressBookManager

#pragma mark Class Methods

+ (XMAddressBookManager *)sharedInstance
{
	static XMAddressBookManager *sharedInstance = nil;
	if(sharedInstance == nil)
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
	addressBook = [[ABAddressBook sharedAddressBook] retain];
	
	// adding XMAddressBookProperty_CallAddress and XMAddressBookProperty_HumanReadableCallAddress
	// to the list of Properties in ABPerson
	NSNumber *number = [[NSNumber alloc] initWithInt:kABMultiDataProperty];
	NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:number, XMAddressBookProperty_CallAddress, nil];
	[ABPerson addPropertiesAndTypes:dict];
	[dict release];
	[number release];
	
	number = [[NSNumber alloc] initWithInt:kABMultiStringProperty];
	dict = [[NSDictionary alloc] initWithObjectsAndKeys:number, XMAddressBookProperty_HumanReadableCallAddress, nil];
	[ABPerson addPropertiesAndTypes:dict];
	[dict release];
	[number release];
	
	// ensure backwards compatibility
	[self _transformRecordsFrom_0_1];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_addressBookDatabaseDidChange:)
												 name:kABDatabaseChangedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_addressBookDatabaseDidChange:)
												 name:kABDatabaseChangedExternallyNotification object:nil];
	
	return self;
}

- (void)dealloc
{
	if(addressBook != nil)
	{
		[addressBook release];
		addressBook = nil;
	}
	
	[super dealloc];
}

#pragma mark Obtaining records

- (NSArray *)records
{
	return [addressBook people];
}

- (NSArray *)validRecords
{
	NSArray *people = [addressBook people];
	
	unsigned i;
	unsigned count = [people count];
	
	NSMutableArray *validRecords = [[NSMutableArray alloc] initWithCapacity:count];
	
	for(i = 0; i < count; i++)
	{
		ABPerson *person = (ABPerson *)[people objectAtIndex:i];
		
		if([person valueForProperty:XMAddressBookProperty_CallAddress] != nil)
		{
			[validRecords addObject:person];
		}
	}
	
	return [validRecords autorelease];
}

#pragma mark Adding new Records

- (id)createRecordWithFirstName:(NSString *)firstName lastName:(NSString *)lastName
					companyName:(NSString *)companyName isCompany:(BOOL)isCompany
					callAddress:(XMAddressResource *)address
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

	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[address dictionaryRepresentation]];
	[newRecord setValue:data forProperty:XMAddressBookProperty_CallAddress];
	
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
	ABSearchElement *callAddressSearchElement = [ABPerson searchElementForProperty:XMAddressBookProperty_HumanReadableCallAddress
																			 label:nil key:nil value:searchString
																		comparison:kABPrefixMatchCaseInsensitive];
	NSArray *stringSearchElements = [[NSArray alloc] initWithObjects:firstNameSearchElement, lastNameSearchElement, companyNameSearchElement,
		callAddressSearchElement, nil];
	finalSearchElement = [ABSearchElement searchElementForConjunction:kABSearchOr children:stringSearchElements];
	[stringSearchElements release];
	
	NSArray *matchedRecords = [addressBook recordsMatchingSearchElement:finalSearchElement];
	
	if(!mustBeValid && !returnExtraInformation)
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
		
		if(mustBeValid)
		{
			if([record valueForProperty:XMAddressBookProperty_CallAddress] == nil)
			{
				continue;
			}
		}
		
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

- (id<XMAddressBookRecord>)recordWithCallAddress:(NSString *)callAddress
{
	ABSearchElement *callAddressSearchElement = [ABPerson searchElementForProperty:XMAddressBookProperty_HumanReadableCallAddress
																			 label:nil key:nil value:callAddress
																		comparison:kABEqual];
	
	NSArray *matchedRecords = [addressBook recordsMatchingSearchElement:callAddressSearchElement];
	
	if([matchedRecords count] > 0)
	{
		return [matchedRecords objectAtIndex:0];
	}
	
	return nil;
}

#pragma mark Private Methods

- (void)_addressBookDatabaseDidChange:(NSNotification *)notif
{
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_AddressBookManagerDidChangeDatabase object:self];
}

- (void)_transformRecordsFrom_0_1
{
	NSArray *people = [addressBook people];
	
	unsigned i;
	unsigned count = [people count];
	
	for(i = 0; i < count; i++)
	{
		ABPerson *person = (ABPerson *)[people objectAtIndex:i];
		
		NSData *oldCallAddress = [person valueForProperty:XMAddressBookProperty_CallAddress_0_1];
		
		if(oldCallAddress != nil)
		{
			NSString *oldHumanReadableCallAddress = [person valueForProperty:XMAddressBookProperty_HumanReadableCallAddress_0_1];
			
			ABMutableMultiValue *callAddress = [[ABMutableMultiValue alloc] init];
			[callAddress addValue:oldCallAddress withLabel:@"H.323"];
			
			ABMutableMultiValue *humanReadableCallAddress = [[ABMutableMultiValue alloc] init];
			[humanReadableCallAddress addValue:oldHumanReadableCallAddress withLabel:@"H.323"];
			
			[person setValue:callAddress forProperty:XMAddressBookProperty_CallAddress];
			[person setValue:humanReadableCallAddress forProperty:XMAddressBookProperty_HumanReadableCallAddress];
			
			[callAddress release];
			[humanReadableCallAddress release];
			
			// delete the old record
			BOOL a = [person removeValueForProperty:XMAddressBookProperty_CallAddress_0_1];
			BOOL b = [person removeValueForProperty:XMAddressBookProperty_HumanReadableCallAddress_0_1];
		}
	}
}

@end

@implementation ABPerson (XMeetingFrameworkCategoryMethods)

- (BOOL)isValid
{
	if([self valueForProperty:XMAddressBookProperty_CallAddress] != nil)
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

- (XMAddressResource *)callAddress
{
	NSData *data  = [self valueForProperty:XMAddressBookProperty_CallAddress];
	
	if(data == nil)
	{
		return nil;
	}
	
	NSDictionary *dictionary = (NSDictionary *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
	XMAddressResource *addressResource = [XMAddressResource addressResourceWithDictionaryRepresentation:dictionary];
	
	return addressResource;
}

- (void)setCallAddress:(XMAddressResource *)callAddress
{
	if(callAddress)
	{
		NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[callAddress dictionaryRepresentation]];
		[self setValue:data forProperty:XMAddressBookProperty_CallAddress];
		
		/*ABMutableMultiValue *multiValue = [[ABMutableMultiValue alloc] init];
		NSString *addr = [callAddress humanReadableAddress];
		[multiValue addValue:addr withLabel:@"1"];
		[multiValue addValue:addr withLabel:@"2"];*/
		[self setValue:[callAddress humanReadableAddress] forProperty:XMAddressBookProperty_HumanReadableCallAddress];
		//[multiValue release];
	}
	else
	{
		[self removeValueForProperty:XMAddressBookProperty_CallAddress];
		[self removeValueForProperty:XMAddressBookProperty_HumanReadableCallAddress];
	}
	[[ABAddressBook sharedAddressBook] save];
}

- (NSString *)humanReadableCallAddress
{
	return [self valueForProperty:XMAddressBookProperty_HumanReadableCallAddress];
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