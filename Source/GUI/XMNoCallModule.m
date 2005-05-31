/*
 * $Id: XMNoCallModule.m,v 1.2 2005/05/31 14:59:52 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMeeting.h"
#import "XMNoCallModule.h"
#import "XMMainWindowController.h"
#import "XMPreferencesManager.h"
#import "XMDatabaseField.h"

@interface XMNoCallModule (PrivateMethods)

- (void)preferencesDidChange:(NSNotification *)notif;
- (void)activeLocationDidChange:(NSNotification *)notif;

@end

@implementation XMNoCallModule

- (id)init
{
	[[XMMainWindowController sharedInstance] addMainModule:self];
	
	uncompletedStringLength = 0;
	matchedValidRecords = nil;
	completions = [[NSMutableArray alloc] initWithCapacity:10];
	
	addressBookManager = [[XMAddressBookManager sharedInstance] retain];
	nibLoader = nil;
	
	preferencesManager = [[XMPreferencesManager sharedInstance] retain];
}

- (void)dealloc
{
	[matchedValidRecords release];
	[completions release];
	
	[addressBookManager release];
	[nibLoader release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[preferencesManager release];
	
	[super dealloc];
}

- (void)awakeFromNib
{	
	contentViewSize = [contentView frame].size;
	[callAddressField setDefaultImage:[NSImage imageNamed:@"DefaultURL"]];

	[self preferencesDidChange:nil];
	
	//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activeLocationDidChange:)
	//											 name:XMNotification_ActiveLocationDidChange object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesDidChange:)
												 name:XMNotification_PreferencesDidChange object:nil];
}

#pragma mark XMMainWindowModule methods

- (NSString *)name
{
	return @"NoCall";
}

- (NSView *)contentView
{
	if(nibLoader == nil)
	{
		nibLoader = [[NSNib alloc] initWithNibNamed:@"NoCallModule" bundle:nil];
		[nibLoader instantiateNibWithOwner:self topLevelObjects:nil];
	}
	return contentView;
}

- (NSSize)contentViewSize
{
	return contentViewSize;
}

- (NSSize)contentViewMinSize
{
	return contentViewSize;
}

- (BOOL)allowsContentViewResizing
{
	return NO;
}

- (void)prepareForDisplay
{
}

#pragma mark User Interface Methods

- (IBAction)call:(id)sender
{
}

- (IBAction)changeActiveLocation:(id)sender
{
	unsigned selectedIndex = [locationsPopUp indexOfSelectedItem];
	[[XMPreferencesManager sharedInstance] activateLocationAtIndex:selectedIndex];
}

- (IBAction)showCallHistory:(id)sender
{
}

#pragma mark Notification Methods

- (void)preferencesDidChange:(NSNotification *)notif
{
	NSLog(@"preferencesDidChange");
	[locationsPopUp removeAllItems];
	[locationsPopUp addItemsWithTitles:[preferencesManager locationNames]];
	[locationsPopUp selectItemAtIndex:[preferencesManager indexOfActiveLocation]];
}

#pragma mark Call Address XMDatabaseComboBox Data Source Methods

- (NSArray *)databaseField:(XMDatabaseField *)databaseField
		 completionsForString:(NSString *)uncompletedString
		  indexOfSelectedItem:(unsigned *)indexOfSelectedItem
{	
	NSArray *matchedRecords;
	unsigned newUncompletedStringLength = [uncompletedString length];
	if(newUncompletedStringLength <= uncompletedStringLength)
	{
		// there may be more valid records than up to now, therefore
		// throwing the cache away.
		[matchedValidRecords release];
		matchedValidRecords = nil;
	}
	
	if(matchedValidRecords == nil)
	{
		// Tokenizing the currentTokenField string, searching the AddressBook database for the first
		// match
		NSArray *stringTokens = [uncompletedString componentsSeparatedByString:@" "];
		NSString *firstToken = [stringTokens objectAtIndex:0];
		matchedRecords = [[addressBookManager recordsMatchingString:firstToken 
															mustBeValid:YES
												 returnExtraInformation:YES] retain];
	}
	else
	{
		matchedRecords = matchedValidRecords;
	}
	
	matchedValidRecords = [[NSMutableArray alloc] initWithCapacity:[matchedRecords count]];
	[completions removeAllObjects];
	
	// All matched records have to be verified whether they actually contain the substring
	// at the correct place.
	unsigned i;
	unsigned count = [matchedRecords count];
	for(i = 0; i < count; i++)
	{
		XMAddressBookRecordSearchMatch *searchMatch = (XMAddressBookRecordSearchMatch *)[matchedRecords objectAtIndex:i];
		id record = [searchMatch record];	// the record found
		XMAddressBookRecordPropertyMatch propertyMatch = [searchMatch propertyMatch];	// the property that matched the record
		NSString *completionString;		// the string which should be displayed on screen.
		
		if(propertyMatch == XMAddressBookRecordPropertyMatch_CallAddressMatch)
		{
			// we have a match for the Address. In this case, we allow only the call address
			// to be entered. (not e.g. "callAddress" (displayName)". This eases the check
			// since we only have to check wether fullTokenFieldString is a Prefix to the
			// call address.
			NSString *callAddress = [record humanReadableCallAddress];
			if(![callAddress hasPrefix:uncompletedString])
			{
				// since uncompletedString is not a prefix to the callAddress, this record is
				// not a valid record for completion
				continue;
			}
			NSString *displayName = [record displayName];
			
			// producing the display string
			completionString = [NSString stringWithFormat:@"%@ (%@)", callAddress, displayName];
		}
		else if(propertyMatch == XMAddressBookRecordPropertyMatch_CompanyMatch)
		{
			// a company match has a similar behavior as a call address match.
			// only if uncompletedString is a prefix to company name, we have a match.
			NSString *companyName = [record companyName];
			if(![companyName hasPrefix:uncompletedString])
			{
				continue;
			}
			NSString *callAddress = [self humanReadableCallAddress];
			completionString = [NSString stringWithFormat:@"%@ <%@>", companyName, callAddress];
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
					continue;
				}
				completionString = lastName;
			}
			else if(!lastName)
			{
				// the same as in the case of !firstName
				if(![firstName hasPrefix:uncompletedString])
				{
					continue;
				}
				completionString = firstName;
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
						continue;
					}
				}
				
				NSString *callAddress = [record humanReadableCallAddress];
				completionString = [NSString stringWithFormat:@"%@ <%@>", displayName, callAddress];
			}
		}
		[matchedValidRecords addObject:searchMatch];
		[completions addObject:completionString];
	}
	[matchedRecords release];
	uncompletedStringLength = newUncompletedStringLength;
	return completions;
}

- (id)databaseField:(XMDatabaseField *)databaseField representedObjectForCompletedString:(NSString *)completedString
{
	unsigned index = [completions indexOfObject:completedString];
	
	if(index == NSNotFound)
	{
		return nil;
	}
	return [matchedValidRecords objectAtIndex:index];
}

- (NSString *)databaseField:(XMDatabaseField *)databaseField displayStringForRepresentedObject:(id)representedObject
{
	id record = [(XMAddressBookRecordSearchMatch *)representedObject record];
	return [record displayName];
}

- (NSImage *)databaseField:(XMDatabaseField *)databaseField imageForRepresentedObject:(id)representedObject
{
	return [NSImage imageNamed:@"AddressBook"];
}

@end
