/*
 * $Id: XMNoCallModule.m,v 1.13 2005/10/23 19:59:00 hfriederich Exp $
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
- (void)_didStartCallInitiation:(NSNotification *)notif;
- (void)_didStartCalling:(NSNotification *)notif;
- (void)_didNotStartCalling:(NSNotification *)notif;
- (void)_isRingingAtRemoteParty:(NSNotification *)notif;
- (void)_didReceiveIncomingCall:(NSNotification *)notif;
- (void)_didClearCall:(NSNotification *)notif;
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
	
	isCalling = NO;
	
	return self;
}

- (void)dealloc
{
	[matchedAddresses release];
	[completions release];
	
	[nibLoader release];
	
	[imageItem release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

- (void)awakeFromNib
{	
	// First, register for notifications
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
	[notificationCenter addObserver:self selector:@selector(_didStartCallInitiation:)
							   name:XMNotification_CallManagerDidStartCallInitiation
							 object:nil];
	[notificationCenter addObserver:self selector:@selector(_didStartCalling:)
							   name:XMNotification_CallManagerDidStartCalling
							 object:nil];
	[notificationCenter addObserver:self selector:@selector(_didNotStartCalling:)
							   name:XMNotification_CallManagerDidNotStartCalling
							 object:nil];
	[notificationCenter addObserver:self selector:@selector(_isRingingAtRemoteParty:)
							   name:XMNotification_CallManagerDidStartRingingAtRemoteParty
							 object:nil];
	[notificationCenter addObserver:self selector:@selector(_didReceiveIncomingCall:)
							   name:XMNotification_CallManagerDidReceiveIncomingCall
							 object:nil];
	[notificationCenter addObserver:self selector:@selector(_didClearCall:)
							   name:XMNotification_CallManagerDidClearCall
							 object:nil];
	[notificationCenter addObserver:self selector:@selector(_gatekeeperRegistrationDidChange:)
							   name:XMNotification_CallManagerDidRegisterAtGatekeeper
							 object:nil];
	[notificationCenter addObserver:self selector:@selector(_gatekeeperRegistrationDidChange:)
							   name:XMNotification_CallManagerDidUnregisterFromGatekeeper
							 object:nil];
	[notificationCenter addObserver:self selector:@selector(_callHistoryDataDidChange:)
							   name:XMNotification_CallHistoryCallAddressProviderDataDidChange
							 object:nil];
	
	contentViewSize = [contentView frame].size;
	[callAddressField setDefaultImage:[NSImage imageNamed:@"DefaultURL"]];
	
	imageItem = [[NSMenuItem alloc] init];
	[imageItem setImage:[NSImage imageNamed:@"CallHistory"]];
	
	[self _setupRecentCallsPullDownMenu];

	[self _preferencesDidChange:nil];
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
	// if not already done, this triggers the loading of the nib file
	[self contentView];
	
	return contentViewSize;
}

- (NSSize)contentViewMinSize
{
	// if not already done, this triggers the loading of the nib file
	[self contentView];
	
	return contentViewSize;
}

- (NSSize)contentViewMaxSize
{
	// if not already done, this triggers the loading of the nib file
	[self contentView];
	
	return contentViewSize;
}

- (NSSize)adjustResizeDifference:(NSSize)resizeDifference minimumHeight:(unsigned)minimumHeight
{
	return resizeDifference;
}

- (void)becomeActiveModule
{
}

- (void)becomeInactiveModule
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
		return;
	}
	
	[callAddressField endEditing];
	id<XMCallAddress> callAddress = (id<XMCallAddress>)[callAddressField representedObject];
	if(callAddress == nil)
	{
		NSLog(@"ERROR: NO REPRESENTED OBJECT!");
		return;
	}
	
	[[XMCallAddressManager sharedInstance] makeCallToAddress:callAddress];
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
	XMCallAddressManager *callAddressManager = [XMCallAddressManager sharedInstance];
	NSArray *originalMatchedAddresses;
	unsigned newUncompletedStringLength = [uncompletedString length];
	if(newUncompletedStringLength <= uncompletedStringLength)
	{
		// there may be more valid records than up to now, therefore
		// throwing the cache away.
		if(matchedAddresses != nil)
		{
			[matchedAddresses release];
			matchedAddresses = nil;
		}
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
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
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

- (void)_didStartCallInitiation:(NSNotification *)notif
{
	// until XMNotification_CallManagerDidStartCalling is posted, we have to disable
	// the user GUI. Normally, only very little time passes befor this notification is
	// posted. However, in some cases, it may take some time (3-4) secs, in which the
	// user cannot clear the call
	
	id<XMCallAddress> activeCallAddress = [[XMCallAddressManager sharedInstance] activeCallAddress];
	[callAddressField setRepresentedObject:activeCallAddress];
	[locationsPopUpButton setEnabled:NO];
	[callButton setEnabled:NO];
	[statusFieldOne setStringValue:NSLocalizedString(@"Preparing to call...", @"")];
	[statusFieldTwo setStringValue:@""];
}

- (void)_didStartCalling:(NSNotification *)notif
{
	[callButton setEnabled:YES];
	[callButton setTitle:NSLocalizedString(@"Hangup", @"")];
	[statusFieldOne setStringValue:NSLocalizedString(@"Calling...", @"")];
	[statusFieldTwo setStringValue:@""];
	
	isCalling = YES;
}

- (void)_didNotStartCalling:(NSNotification *)notif
{
	[locationsPopUpButton setEnabled:YES];
	[callButton setEnabled:YES];
	[self _displayListeningStatusFieldInformation];
}

- (void)_isRingingAtRemoteParty:(NSNotification *)notif
{
	[statusFieldOne setStringValue:NSLocalizedString(@"Ringing Phone at Remote Party...", @"")];
}

- (void)_didReceiveIncomingCall:(NSNotification *)notif
{
	[locationsPopUpButton setEnabled:NO];
	[callButton setEnabled:NO];
	[statusFieldOne setStringValue:NSLocalizedString(@"Incoming Call", @"")];
}

- (void)_didClearCall:(NSNotification *)notif
{
	[locationsPopUpButton setEnabled:YES];
	[callButton setEnabled:YES];
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
