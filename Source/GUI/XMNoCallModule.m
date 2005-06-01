/*
 * $Id: XMNoCallModule.m,v 1.4 2005/06/01 11:00:37 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMeeting.h"
#import "XMNoCallModule.h"
#import "XMMainWindowController.h"
#import "XMCallAddressManager.h"
#import "XMPreferencesManager.h"
#import "XMDatabaseField.h"

@interface XMNoCallModule (PrivateMethods)

- (void)_preferencesDidChange:(NSNotification *)notif;
- (void)_didInitiateCall:(NSNotification *)notif;

- (NSArray *)_searchMatchesForString:(NSString *)string;

@end

@interface XMAddressBookRecordSearchMatch (XMCallAddressWrapperMethods)

- (XMURL *)url;
- (NSString *)displayString;
- (NSImage *)displayImage;

@end

@implementation XMNoCallModule

- (id)init
{
	[[XMMainWindowController sharedInstance] addMainModule:self];
	
	uncompletedStringLength = 0;
	matchedAddresses = nil;
	completions = [[NSMutableArray alloc] initWithCapacity:10];
	
	nibLoader = nil;
	
	callAddressManager = [[XMCallAddressManager sharedInstance] retain];
	preferencesManager = [[XMPreferencesManager sharedInstance] retain];
}

- (void)dealloc
{
	[matchedAddresses release];
	[completions release];
	
	[nibLoader release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[callAddressManager release];
	[preferencesManager release];
	
	[super dealloc];
}

- (void)awakeFromNib
{	
	contentViewSize = [contentView frame].size;
	[callAddressField setDefaultImage:[NSImage imageNamed:@"DefaultURL"]];

	[self _preferencesDidChange:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_preferencesDidChange:)
												 name:XMNotification_PreferencesDidChange object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didInitiateCall:)
												 name:XMNotification_CallAddressManagerDidInitiateCall
											   object:nil];
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

- (void)_preferencesDidChange:(NSNotification *)notif
{
	[locationsPopUp removeAllItems];
	[locationsPopUp addItemsWithTitles:[preferencesManager locationNames]];
	[locationsPopUp selectItemAtIndex:[preferencesManager indexOfActiveLocation]];
}

- (void)_didInitiateCall:(NSNotification *)notif
{
	id<XMCallAddress> activeCallAddress = [callAddressManager activeCallAddress];
	[callAddressField setRepresentedObject:activeCallAddress];
}

#pragma mark Call Address XMDatabaseComboBox Data Source Methods

- (NSArray *)databaseField:(XMDatabaseField *)databaseField
		 completionsForString:(NSString *)uncompletedString
		  indexOfSelectedItem:(unsigned *)indexOfSelectedItem
{	
	NSArray *originalMatchedAddresses;
	unsigned newUncompletedStringLength = [uncompletedString length];
	if(newUncompletedStringLength <= uncompletedStringLength)
	{
		// there may be more valid records than up to now, therefore
		// throwing the cache away.
		[matchedAddresses release];
		matchedAddresses = nil;
	}
	
	if(matchedAddresses == nil)
	{
		// Tokenizing the currentTokenField string, obtaining matches for the first
		// token from XMCallAddressManager
		NSArray *stringTokens = [uncompletedString componentsSeparatedByString:@" "];
		NSString *firstToken = [stringTokens objectAtIndex:0];
		originalMatchedAddresses = [[callAddressManager addressesMatchingString:firstToken] retain];
	}
	else
	{
		originalMatchedAddresses = matchedAddresses;
	}
	
	matchedAddresses = [[NSMutableArray alloc] initWithCapacity:[originalMatchedAddresses count]];
	[completions removeAllObjects];
	
	// All matched records have to be verified whether they actually contain the substring
	// at the correct place.
	unsigned i;
	unsigned count = [originalMatchedAddresses count];
	for(i = 0; i < count; i++)
	{
		id<XMCallAddress> callAddress = (id<XMCallAddress>)[originalMatchedAddresses objectAtIndex:i];
		NSString *completion = [callAddressManager completionStringForAddress:callAddress uncompletedString:uncompletedString];
		if(completion != nil)
		{
			[matchedAddresses addObject:callAddress];
			[completions addObject:completion];
		}
	}
	[originalMatchedAddresses release];
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
	return [matchedAddresses objectAtIndex:index];
}

- (NSString *)databaseField:(XMDatabaseField *)databaseField displayStringForRepresentedObject:(id)representedObject
{
	NSString *displayString = [(id<XMCallAddress>)representedObject displayString];
	return displayString;
}

- (NSImage *)databaseField:(XMDatabaseField *)databaseField imageForRepresentedObject:(id)representedObject
{
	NSImage *image = [(id<XMCallAddress>)representedObject displayImage];
	return image;
}

@end

/**
 * Implementing the XMCallAddressWrapper category methods for
 * XMAddressBookRecordSearchMatch
 **/
@implementation XMAddressBookRecordSearchMatch (XMCallAddressWrapperMethods)

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
