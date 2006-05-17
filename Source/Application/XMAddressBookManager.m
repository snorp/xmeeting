/*
 * $Id: XMAddressBookManager.m,v 1.6 2006/05/17 11:48:38 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMAddressBookManager.h"

#import <AddressBook/AddressBook.h>

#import "XMAddressBookRecord.h"

#define XM_UNKNOWN_INDEX NSNotFound-1

NSString *XMNotification_AddressBookManagerDidChangeDatabase = @"XMeetingAddressBookManagerDidChangeDatabaseNotification";

NSString *XMAddressBookProperty_CallAddress = @"XMeeting_CallAddress2";
NSString *XMAddressBookProperty_HumanReadableCallAddress = @"XMeeting_HumanReadableCallAddress2";
NSString *XMAddressBookProperty_CallAddress_0_1 = @"XMeeting_CallAddress";
NSString *XMAddressBookProperty_HumanReadableCallAddress_0_1 = @"XMeeting_HumanReadableCallAddress";

@interface XMAddressBookManager (PrivateMethods)

- (id)_init;

- (void)_addressBookDatabaseDidChange:(NSNotification *)notif;
- (void)_transformRecordsFrom_0_1;

- (unsigned)_indexOfPrimaryAddressForPerson:(ABPerson *)person;

@end

@interface XMAddressBookRecord (FrameworkMethods)

- (id)_initWithPerson:(ABPerson *)person index:(unsigned)index propertyMatch:(XMAddressBookRecordPropertyMatch)propertyMatch;

- (ABPerson *)_person;
- (unsigned)_index;

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

#pragma mark -
#pragma mark Obtaining records

- (NSArray *)records
{
	NSArray *people = [addressBook people];
	
	unsigned i;
	unsigned count = [people count];
	
	NSMutableArray *validRecords = [[NSMutableArray alloc] initWithCapacity:count];
	
	for(i = 0; i < count; i++)
	{
		ABPerson *person = (ABPerson *)[people objectAtIndex:i];
		ABMultiValue *multiValue = (ABMultiValue *)[person valueForProperty:XMAddressBookProperty_HumanReadableCallAddress];
		
		if(multiValue == nil)
		{
			continue;
		}
		
		unsigned index = [self _indexOfPrimaryAddressForPerson:person];
		
		XMAddressBookRecord *record = [[XMAddressBookRecord alloc] _initWithPerson:person index:index
																	 propertyMatch:XMAddressBookRecordPropertyMatch_NoMatch];
		[validRecords addObject:record];
		[record release];
	}
	
	return [validRecords autorelease];
}

#pragma mark -
#pragma mark Adding new Records

- (ABPerson *)createPersonWithFirstName:(NSString *)firstName lastName:(NSString *)lastName
					companyName:(NSString *)companyName isCompany:(BOOL)isCompany
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
	
	return [newRecord autorelease];
}

- (BOOL)addPerson:(ABPerson *)record
{
	BOOL isSuccessfullyAdded = [addressBook addRecord:record];
	
	if(isSuccessfullyAdded)
	{
		[addressBook save];
	}
	return isSuccessfullyAdded;
}

- (BOOL)addRecord:(XMAddressBookRecord *)record
{
	ABPerson *person = [record _person];
	
	return [self addPerson:person];
}

#pragma mark -
#pragma mark Searching the Database

- (XMAddressBookRecord *)recordForPerson:(ABPerson *)person identifier:(NSString *)identifier
{
	unsigned index;
	
	if(identifier == nil)
	{
		index = XM_UNKNOWN_INDEX;
	}
	else
	{
		ABMultiValue *multiValue = [person valueForProperty:XMAddressBookProperty_HumanReadableCallAddress];
		index = [multiValue indexForIdentifier:identifier];
	}
	
	XMAddressBookRecord *record = [[XMAddressBookRecord alloc] _initWithPerson:person index:index propertyMatch:XMAddressBookRecordPropertyMatch_NoMatch];
	return [record autorelease];
}

- (void)setPrimaryAddressForPerson:(ABPerson *)person withIdentifier:(NSString *)identifier
{
	ABMultiValue *multiValue = (ABMultiValue *)[person valueForProperty:XMAddressBookProperty_HumanReadableCallAddress];
	ABMutableMultiValue *mutableMultiValue = [multiValue mutableCopy];
	
	unsigned index = [mutableMultiValue indexForIdentifier:identifier];
	[mutableMultiValue setPrimaryIdentifier:identifier];
	
	[person setValue:mutableMultiValue forProperty:XMAddressBookProperty_HumanReadableCallAddress];
	[mutableMultiValue release];
	
	// also adjust the primary identifier of the XMAddressBookProperty_CallAddress property
	multiValue = (ABMultiValue *)[person valueForProperty:XMAddressBookProperty_CallAddress];
	mutableMultiValue = [multiValue mutableCopy];
	
	NSString *callAddressIdentifier = [mutableMultiValue identifierAtIndex:index];
	[mutableMultiValue setPrimaryIdentifier:callAddressIdentifier];
	
	[person setValue:mutableMultiValue forProperty:XMAddressBookProperty_CallAddress];
	[mutableMultiValue release];
	
	[[ABAddressBook sharedAddressBook] save];
}

- (NSArray *)recordsMatchingString:(NSString *)searchString
{
	NSRange searchStringRange = NSMakeRange(0, [searchString length]);
	
	ABSearchElement *finalSearchElement;	// the searchElement with which we actually query the database
	
	// we search the firstName, lastName, companyName and HumanReadableCallAddress properties
	// for a match (in this order) and keep the information which part matched if needed
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
	
	// check for validity if required, store the information which key matched if required
	unsigned i;
	unsigned count = [matchedRecords count];
	NSMutableArray *searchMatches = [NSMutableArray arrayWithCapacity:count];
	for(i = 0; i < count; i++)
	{
		ABPerson *record = (ABPerson *)[matchedRecords objectAtIndex:i];
		
		ABMultiValue *multiValue = [record valueForProperty:XMAddressBookProperty_HumanReadableCallAddress];
		unsigned multiValueCount = [multiValue count];
		if(multiValue == nil || multiValueCount == 0)
		{
			continue;
		}
		
		if([firstNameSearchElement matchesRecord:record])
		{
			unsigned primaryIndex = [self _indexOfPrimaryAddressForPerson:record];
			
			XMAddressBookRecord *theRecord = [[XMAddressBookRecord alloc] _initWithPerson:record index:primaryIndex
																			propertyMatch:XMAddressBookRecordPropertyMatch_FirstNameMatch];
			[searchMatches addObject:theRecord];
			[theRecord release];
			
			unsigned j;
			for(j = 0; j < multiValueCount; j++)
			{
				if(j == primaryIndex)
				{
					continue;
				}
				XMAddressBookRecord *addressBookRecord = [[XMAddressBookRecord alloc] _initWithPerson:record index:j 
																						propertyMatch:XMAddressBookRecordPropertyMatch_FirstNameMatch];
				[searchMatches addObject:addressBookRecord];
				[addressBookRecord release];
			}
		}
		if([lastNameSearchElement matchesRecord:record])
		{
			unsigned primaryIndex = [self _indexOfPrimaryAddressForPerson:record];
			
			XMAddressBookRecord *theRecord = [[XMAddressBookRecord alloc] _initWithPerson:record index:primaryIndex
																			propertyMatch:XMAddressBookRecordPropertyMatch_LastNameMatch];
			[searchMatches addObject:theRecord];
			[theRecord release];
			
			unsigned j;
			for(j = 0; j < multiValueCount; j++)
			{
				if(j == primaryIndex)
				{
					continue;
				}
				XMAddressBookRecord *addressBookRecord = [[XMAddressBookRecord alloc] _initWithPerson:record index:j 
																						propertyMatch:XMAddressBookRecordPropertyMatch_LastNameMatch];
				[searchMatches addObject:addressBookRecord];
				[addressBookRecord release];
			}
		}
		if([companyNameSearchElement matchesRecord:record])
		{
			unsigned primaryIndex = [self _indexOfPrimaryAddressForPerson:record];
			
			XMAddressBookRecord *theRecord = [[XMAddressBookRecord alloc] _initWithPerson:record index:primaryIndex
																			propertyMatch:XMAddressBookRecordPropertyMatch_CompanyMatch];
			[searchMatches addObject:theRecord];
			[theRecord release];
			
			unsigned j;
			for(j = 0; j < multiValueCount; j++)
			{
				if(j == primaryIndex)
				{
					continue;
				}
				XMAddressBookRecord *addressBookRecord = [[XMAddressBookRecord alloc] _initWithPerson:record index:j 
																						propertyMatch:XMAddressBookRecordPropertyMatch_CompanyMatch];
				[searchMatches addObject:addressBookRecord];
				[addressBookRecord release];
			}
		}
		if([callAddressSearchElement matchesRecord:record])
		{
			unsigned j;
			for(j = 0; j < multiValueCount; j++)
			{
				NSString *address = (NSString *)[multiValue valueAtIndex:j];
				
				if(searchStringRange.length > [address length])
				{
					continue;
				}
				
				NSRange range = [address rangeOfString:searchString 
											   options:(NSCaseInsensitiveSearch | NSLiteralSearch | NSAnchoredSearch)
												 range:searchStringRange];
				if(range.location != NSNotFound)
				{
					XMAddressBookRecord *addressBookRecord = [[XMAddressBookRecord alloc] _initWithPerson:record index:j 
																							propertyMatch:XMAddressBookRecordPropertyMatch_CallAddressMatch];
					[searchMatches addObject:addressBookRecord];
					[addressBookRecord release];
				}
			}
		}
	}
	
	return searchMatches;
}

- (XMAddressBookRecord *)recordWithCallAddress:(NSString *)callAddress
{
	ABSearchElement *callAddressSearchElement = [ABPerson searchElementForProperty:XMAddressBookProperty_HumanReadableCallAddress
																			 label:nil key:nil value:callAddress
																		comparison:kABEqualCaseInsensitive];
	
	NSArray *matchedRecords = [addressBook recordsMatchingSearchElement:callAddressSearchElement];
	
	if([matchedRecords count] == 0)
	{
		return nil;
	}
	ABPerson *person = (ABPerson *)[matchedRecords objectAtIndex:0];
	ABMultiValue *multiValue = (ABMultiValue *)[person valueForProperty:XMAddressBookProperty_HumanReadableCallAddress];
	
	unsigned i;
	unsigned count = [multiValue count];
	
	for(i = 0; i < count; i++)
	{
		NSString *address = (NSString *)[multiValue valueAtIndex:i];
		
		NSComparisonResult result = [address compare:callAddress options:(NSCaseInsensitiveSearch | NSLiteralSearch)
											   range:NSMakeRange(0, [address length]) locale:nil];
		
		if(result == NSOrderedSame)
		{
			
			XMAddressBookRecord *record = [[XMAddressBookRecord alloc] _initWithPerson:person index:i
																		 propertyMatch:XMAddressBookRecordPropertyMatch_CallAddressMatch];
			return [record autorelease];
		}
	}
	
	return nil;
}

- (NSArray *)recordsForPersonWithRecord:(XMAddressBookRecord *)record indexOfRecord:(unsigned *)indexOfRecord
{
	ABPerson *person = [record _person];
	
	*indexOfRecord = [record _index];
	
	ABMultiValue *multiValue = [person valueForProperty:XMAddressBookProperty_HumanReadableCallAddress];
	
	unsigned i;
	unsigned count = [multiValue count];
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:count];
	
	for(i = 0; i < count; i++)
	{
		XMAddressBookRecord *theRecord = [[XMAddressBookRecord alloc] _initWithPerson:person index:i
																		propertyMatch:XMAddressBookRecordPropertyMatch_NoMatch];
		[array addObject:theRecord];
		[theRecord release];
	}
	
	return array;
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
			[person removeValueForProperty:XMAddressBookProperty_CallAddress_0_1];
			[person removeValueForProperty:XMAddressBookProperty_HumanReadableCallAddress_0_1];
		}
	}
}

- (unsigned)_indexOfPrimaryAddressForPerson:(ABPerson *)person
{
	ABMultiValue *multiValue = (ABMultiValue *)[person valueForProperty:XMAddressBookProperty_HumanReadableCallAddress];
	
	unsigned index = [multiValue indexForIdentifier:[multiValue primaryIdentifier]];
	
	return index;
}

@end