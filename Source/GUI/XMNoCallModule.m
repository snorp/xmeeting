/*
 * $Id: XMNoCallModule.m,v 1.7 2005/06/30 09:33:13 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMeeting.h"
#import "XMNoCallModule.h"
#import "XMMainWindowController.h"
#import "XMCallAddressManager.h"
#import "XMSimpleAddressURL.h"
#import "XMCallHistoryCallAddressProvider.h"
#import "XMCallHistoryRecord.h"
#import "XMPreferencesManager.h"
#import "XMDatabaseField.h"

@interface XMNoCallModule (PrivateMethods)

- (void)_preferencesDidChange:(NSNotification *)notif;
- (void)_didStartSubsystemSetup:(NSNotification *)notif;
- (void)_didEndSubsystemSetup:(NSNotification *)notif;
- (void)_didStartCalling:(NSNotification *)notif;
- (void)_callCleared:(NSNotification *)notif;
- (void)_gatekeeperRegistrationDidChange:(NSNotification *)notif;
- (void)_callHistoryDataDidChange:(NSNotification *)notif;

- (void)_displayListeningStatusFieldInformation;
- (void)_setupRecentCallsPullDownMenu;
- (void)_recentCallsPopUpButtonAction:(NSMenuItem *)sender;

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
	
	isCalling = NO;
	
	return self;
}

- (void)dealloc
{
	[matchedAddresses release];
	[completions release];
	
	[nibLoader release];
	
	[imageItem release];
	
	[callAddressManager release];
	[preferencesManager release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

- (void)awakeFromNib
{	
	contentViewSize = [contentView frame].size;
	[callAddressField setDefaultImage:[NSImage imageNamed:@"DefaultURL"]];
	
	imageItem = [[NSMenuItem alloc] init];
	[imageItem setImage:[NSImage imageNamed:@"CallHistory"]];
	
	[self _setupRecentCallsPullDownMenu];

	[self _preferencesDidChange:nil];
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	[notificationCenter addObserver:self selector:@selector(_preferencesDidChange:)
							   name:XMNotification_PreferencesDidChange 
							 object:nil];
	[notificationCenter addObserver:self selector:@selector(_didEndFetchingExternalAddress:)
							   name:XMNotification_UtilsDidEndFetchingExternalAddress
							 object:nil];
	[notificationCenter addObserver:self selector:@selector(_didStartSubsystemSetup:)
							   name:XMNotification_CallManagerDidStartSubsystemSetup
							 object:nil];
	[notificationCenter addObserver:self selector:@selector(_didEndSubsystemSetup:)
							   name:XMNotification_CallManagerDidEndSubsystemSetup
							 object:nil];
	[notificationCenter addObserver:self selector:@selector(_didStartCalling:)
							   name:XMNotification_CallManagerDidStartCalling
							 object:nil];
	[notificationCenter addObserver:self selector:@selector(_callStartFailed:)
							   name:XMNotification_CallManagerCallStartFailed
							 object:nil];
	[notificationCenter addObserver:self selector:@selector(_callCleared:)
							   name:XMNotification_CallManagerCallCleared
							 object:nil];
	[notificationCenter addObserver:self selector:@selector(_gatekeeperRegistrationDidChange:)
							   name:XMNotification_CallManagerGatekeeperRegistration
							 object:nil];
	[notificationCenter addObserver:self selector:@selector(_gatekeeperRegistrationDidChange:)
							   name:XMNotification_CallManagerGatekeeperUnregistration
							 object:nil];
	[notificationCenter addObserver:self selector:@selector(_callHistoryDataDidChange:)
							   name:XMNotification_CallHistoryCallAddressProviderDataDidChange
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
	if(isCalling == YES)
	{
		// we are calling someone but the call has not yet been established
		// therefore, we simply hang up the call again
		[[XMCallManager sharedInstance] clearActiveCall];
	}
	
	[callAddressField endEditing];
	id<XMCallAddress> callAddress = (id<XMCallAddress>)[callAddressField representedObject];
	if(callAddress == nil)
	{
		NSLog(@"ERROR: NO REPRESENTED OBJECT!");
		return;
	}
	[callAddressManager makeCallToAddress:callAddress];
}

- (IBAction)changeActiveLocation:(id)sender
{
	unsigned selectedIndex = [locationsPopUpButton indexOfSelectedItem];
	[[XMPreferencesManager sharedInstance] activateLocationAtIndex:selectedIndex];
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
		XMSimpleAddressURL *simpleAddressURL = [[[XMSimpleAddressURL alloc] initWithAddress:completedString] autorelease];
		return simpleAddressURL;
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

#pragma mark Notification Methods

- (void)_preferencesDidChange:(NSNotification *)notif
{
	[locationsPopUpButton removeAllItems];
	[locationsPopUpButton addItemsWithTitles:[preferencesManager locationNames]];
	[locationsPopUpButton selectItemAtIndex:[preferencesManager indexOfActiveLocation]];
}

- (void)_didEndFetchingExternalAddress:(NSNotification *)notif
{
	[self _displayListeningStatusFieldInformation];
}

- (void)_didStartSubsystemSetup:(NSNotification *)notif
{
	[locationsPopUpButton setEnabled:NO];
	[callButton setEnabled:NO];
}

- (void)_didEndSubsystemSetup:(NSNotification *)notif
{
	[locationsPopUpButton setEnabled:YES];
	[callButton setEnabled:YES];
	[self _displayListeningStatusFieldInformation];
}

- (void)_didStartCalling:(NSNotification *)notif
{
	id<XMCallAddress> activeCallAddress = [callAddressManager activeCallAddress];
	[callAddressField setRepresentedObject:activeCallAddress];
	[locationsPopUpButton setEnabled:NO];
	[callButton setTitle:NSLocalizedString(@"Hangup", @"")];
	[statusFieldOne setStringValue:NSLocalizedString(@"Calling...", @"")];
	[statusFieldTwo setStringValue:@""];
	
	isCalling = YES;
}

- (void)_callStartFailed:(NSNotification *)notif
{
	NSString *displayFormat = NSLocalizedString(@"Calling the address failed (%@)", @"");
	NSString *failReasonText;
	
	XMCallStartFailReason failReason = [[XMCallManager sharedInstance] callStartFailReason];
	
	switch(failReason)
	{
		case XMCallStartFailReason_ProtocolNotEnabled:
			failReasonText = NSLocalizedString(@"Protocol not enabled", @"");
			break;
		case XMCallStartFailReason_GatekeeperUsedButNotSpecified:
			failReasonText = NSLocalizedString(@"Address uses a gatekeeper but no gatekeeper is specified in the active location", @"");
			break;
		default:
			failReasonText = NSLocalizedString(@"Unknown reason", @"");
			break;
	}
	
	NSString *displayString = [[NSString alloc] initWithFormat:displayFormat, failReasonText];
	
	[statusFieldOne setStringValue:displayString];
	
	[displayString release];
}

- (void)_callCleared:(NSNotification *)notif
{
	[locationsPopUpButton setEnabled:YES];
	[callButton setTitle:NSLocalizedString(@"Call", @"")];
	[self _displayListeningStatusFieldInformation];
	isCalling = NO;
}

- (void)_gatekeeperRegistrationDidChange:(NSNotification *)notif
{
	NSString *gatekeeperName = [[XMCallManager sharedInstance] gatekeeperName];
	
	if(gatekeeperName != nil)
	{
		NSString *gatekeeperFormat = NSLocalizedString(@"Registered at gatekeeper: %@", @"");
		NSString *gatekeeperString = [[NSString alloc] initWithFormat:gatekeeperFormat, gatekeeperName];
		[statusFieldThree setStringValue:gatekeeperString];
		[gatekeeperString release];
	}
	else
	{
		[statusFieldThree setStringValue:@""];
	}
}

- (void)_callHistoryDataDidChange:(NSNotification *)notif
{
	[self _setupRecentCallsPullDownMenu];
}

#pragma mark Private Methods

- (void)_displayListeningStatusFieldInformation
{
	XMCallManager *callManager = [XMCallManager sharedInstance];
	BOOL isH323Listening = [callManager isH323Listening];
	
	if(!isH323Listening)
	{
		[statusFieldOne setStringValue:NSLocalizedString(@"Offline", @"")];
		[statusFieldTwo setStringValue:@""];
		return;
	}
		
	XMUtils *utils = [XMUtils sharedInstance];
	NSString *externalAddress = [utils externalAddress];
	NSString *localAddress = [utils localAddress];
		
	if(localAddress == nil)
	{
		[statusFieldOne setStringValue:NSLocalizedString(@"Offline (No Network Address)", @"")];
		[statusFieldTwo setStringValue:@""];
		return;
	}
		
	[statusFieldOne setStringValue:NSLocalizedString(@"Waiting for incoming calls", @"")];
	
	if(externalAddress == nil || [externalAddress isEqualToString:localAddress])
	{
		NSString *displayFormat = NSLocalizedString(@"ip: %@", @"");
		NSString *displayString = [[NSString alloc] initWithFormat:displayFormat, localAddress];
		[statusFieldTwo setStringValue:displayString];
		[displayString release];
	}
	else
	{
		NSString *displayFormat = NSLocalizedString(@"ip: %@ (%@)", @"");
		NSString *displayString = [[NSString alloc] initWithFormat:displayFormat, localAddress, externalAddress];
		[statusFieldTwo setStringValue:displayString];
		[displayString release];
	}
}

- (void)_setupRecentCallsPullDownMenu
{
	[recentCallsPopUpButton setMenu:nil];
	
	NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
	[menu addItem:imageItem];
	NSArray *recentCalls = [[XMCallHistoryCallAddressProvider sharedInstance] recentCalls];
	
	unsigned i;
	unsigned count = [recentCalls count];
	
	for(i = 0; i < count; i++)
	{
		XMCallHistoryRecord *record = [recentCalls objectAtIndex:i];
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[record displayString] action:@selector(_recentCallsPopUpButtonAction:) keyEquivalent:@""];
		[menuItem setTarget:self];
		[menuItem setTag:i];
		[menu addItem:menuItem];
		[menuItem release];
	}
	
	[recentCallsPopUpButton setMenu:menu];
	[menu release];
}

- (void)_recentCallsPopUpButtonAction:(NSMenuItem *)sender
{
	unsigned index = [sender tag];
	NSArray *recentCalls = [[XMCallHistoryCallAddressProvider sharedInstance] recentCalls];
	XMCallHistoryRecord *record = [recentCalls objectAtIndex:index];
	
	[callAddressField setRepresentedObject:record];
	[[contentView window] makeFirstResponder:nil];
}

@end
