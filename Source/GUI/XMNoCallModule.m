/*
 * $Id: XMNoCallModule.m,v 1.23 2006/03/16 14:13:57 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMeeting.h"

#import "XMNoCallModule.h"

#import "XMApplicationController.h"
#import "XMCallAddressManager.h"
#import "XMSimpleAddressResource.h"
#import "XMPreferencesManager.h"
#import "XMMainWindowController.h"
#import "XMLocalVideoView.h"

#define VIDEO_INSET 5

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
- (void)_recentCallsPopUpButtonAction:(NSMenuItem *)sender;

- (void)_H323NotEnabled:(NSNotification*)notif;
- (void)_appendNetworkInterfacesString:(NSMutableString *)string;

@end

@implementation XMNoCallModule

- (id)init
{
	[[XMMainWindowController sharedInstance] addModule:self];
	
	uncompletedStringLength = 0;
	matchedAddresses = nil;
	completions = [[NSMutableArray alloc] initWithCapacity:10];
	
	nibLoader = nil;
	
	doesShowSelfView = NO;
	isCalling = NO;
	
	return self;
}

- (void)dealloc
{
	[matchedAddresses release];
	[completions release];
	
	[nibLoader release];

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

- (void)awakeFromNib
{	
	// First, register for notifications
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	[notificationCenter addObserver:self selector:@selector(_preferencesDidChange:)
							   name:XMNotification_PreferencesManagerDidChangePreferences
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
	/*[notificationCenter addObserver:self selector:@selector(_callHistoryDataDidChange:)
							   name:XMNotification_CallHistoryCallAddressProviderDataDidChange
							 object:nil];*/
	[notificationCenter addObserver:self selector:@selector(_H323NotEnabled:)
							   name:XMNotification_CallManagerDidNotEnableH323
							 object:nil];
		
	contentViewSizeWithSelfViewHidden = [contentView frame].size;
	contentViewSizeWithSelfViewShown = contentViewSizeWithSelfViewHidden;
	currentContentViewSizeWithSelfViewShown = contentViewSizeWithSelfViewShown;
	
	// substracting the space used by the self view
	contentViewSizeWithSelfViewHidden.height -= (5 + [selfView frame].size.height);
	
	
	[callAddressField setDefaultImage:[NSImage imageNamed:@"DefaultURL"]];

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
	
	if(doesShowSelfView == YES)
	{
		return currentContentViewSizeWithSelfViewShown;
	}
	return contentViewSizeWithSelfViewHidden;
}

- (NSSize)contentViewMinSize
{
	// if not already done, this triggers the loading of the nib file
	[self contentView];
	
	if(doesShowSelfView == YES)
	{
		return contentViewSizeWithSelfViewShown;
	}
	return contentViewSizeWithSelfViewHidden;
}

- (NSSize)contentViewMaxSize
{
	// if not already done, this triggers the loading of the nib file
	[self contentView];
	
	if(doesShowSelfView == YES)
	{
		return NSMakeSize(5000, 5000);
	}
	return contentViewSizeWithSelfViewHidden;
}

- (NSSize)adjustResizeDifference:(NSSize)resizeDifference minimumHeight:(unsigned)minimumHeight
{
	if(doesShowSelfView == NO)
	{
		return resizeDifference;
	}
	
	NSSize size = [contentView bounds].size;
	
	unsigned usedHeight = contentViewSizeWithSelfViewHidden.height + VIDEO_INSET;
	
	int minimumVideoHeight = contentViewSizeWithSelfViewShown.height - usedHeight;
	int currentVideoHeight = (int)size.height - usedHeight;
	
	int availableWidth = (int)size.width + (int)resizeDifference.width - 2*VIDEO_INSET;
	int newHeight = currentVideoHeight + (int)resizeDifference.height;
	
	int calculatedWidth = (int)XMGetVideoWidthForHeight(newHeight, XMVideoSize_CIF);
	int calculatedHeightFromWidth = (int)XMGetVideoHeightForWidth(availableWidth, XMVideoSize_CIF);
	
	if(calculatedHeightFromWidth <= minimumVideoHeight)
	{
		// set the height to the minimum height
		resizeDifference.height = minimumVideoHeight - currentVideoHeight;
	}
	else
	{
		if(calculatedWidth < availableWidth)
		{
			// the height value takes precedence
			int widthDifference = availableWidth - calculatedWidth;
			resizeDifference.width -= widthDifference;
		}
		else
		{
			// the width value takes precedence
			int heightDifference = newHeight - calculatedHeightFromWidth;
			resizeDifference.height -= heightDifference;
		}
	}
	
	return resizeDifference;
}

- (void)becomeActiveModule
{
	[[contentView window] makeFirstResponder:callAddressField];
}

- (void)becomeInactiveModule
{
}

#pragma mark -
#pragma mark User Interface Methods

- (IBAction)toggleShowSelfView:(id)sender
{
	if(doesShowSelfView == NO)
	{
		doesShowSelfView = YES;
		[[XMMainWindowController sharedInstance] noteSizeValuesDidChangeOfModule:self];
		[selfView startDisplayingLocalVideo];
	}
	else
	{
		[selfView stopDisplayingLocalVideo];
		
		currentContentViewSizeWithSelfViewShown = [contentView bounds].size;

		doesShowSelfView = NO;
		[[XMMainWindowController sharedInstance] noteSizeValuesDidChangeOfModule:self];
	}
}

- (IBAction)showInspector:(id)sender{
	[[NSApp delegate] showInspector:self];
}

- (IBAction)showTools:(id)sender{
	[[NSApp delegate] showTools:self];
}

- (IBAction)showAddressBookModuleSheet:(id)sender{
	//[[XMMainWindowController sharedInstance] showAdditionModule:[[NSApp delegate] addressBookModule]];
}

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
		XMSimpleAddressResource *simpleAddressResource = [[[XMSimpleAddressResource alloc] initWithAddress:completedString callProtocol:XMCallProtocol_H323] autorelease];
		return simpleAddressResource;
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

- (NSArray *)imageOptionsForDatabaseField:(XMDatabaseField *)databaseField
{
	id representedObject = [databaseField representedObject];
	
	if(representedObject == nil ||
	   [(id<XMCallAddress>)representedObject displayImage] == nil)
	{
		return [NSArray arrayWithObjects:@"H.323", @"SIP", nil];
	}
	return [NSArray array];
}

- (void)databaseField:(XMDatabaseField *)databaseField userSelectedImageOption:(NSString *)imageOption
{
	if([imageOption isEqualToString:@"H.323"])
	{
		[callAddressField setDefaultImage:[NSImage imageNamed:@"H323URL_Disclosure"]];
	}
	else
	{
		[callAddressField setDefaultImage:[NSImage imageNamed:@"SIPURL_Disclosure"]];
	}
}

- (NSArray *)pulldownObjectsForDatabaseField:(XMDatabaseField *)databaseField
{
	XMCallAddressManager *callAddressManager = [XMCallAddressManager sharedInstance];
	return [callAddressManager allAddresses];
}

#pragma mark Notification Methods

- (void)_preferencesDidChange:(NSNotification *)notif
{
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];

	[locationsPopUpButton removeAllItems];
	[locationsPopUpButton addItemsWithTitles:[preferencesManager locationNames]];
	[locationsPopUpButton selectItemAtIndex:[preferencesManager indexOfActiveLocation]];
	
	[self _gatekeeperRegistrationDidChange:nil];
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
	[statusField setStringValue:NSLocalizedString(@"Preparing to call...", @"")];
}

- (void)_didStartCalling:(NSNotification *)notif
{
	[callButton setEnabled:YES];
	[callButton setImage:[NSImage imageNamed:@"hangup_24.tif"]];
	[callButton setAlternateImage:[NSImage imageNamed:@"hangup_24_down.tif"]];
	[statusField setStringValue:NSLocalizedString(@"Calling...", @"")];
	
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
	[statusField setStringValue:NSLocalizedString(@"Ringing...", @"")];
}

- (void)_didReceiveIncomingCall:(NSNotification *)notif
{
	[locationsPopUpButton setEnabled:NO];
	[callButton setEnabled:NO];
	[statusField setStringValue:NSLocalizedString(@"Incoming Call", @"")];
}

- (void)_didClearCall:(NSNotification *)notif
{
	[locationsPopUpButton setEnabled:YES];
	[callButton setEnabled:YES];
	[callButton setImage:[NSImage imageNamed:@"Call_24.tif"]];
	[callButton setAlternateImage:[NSImage imageNamed:@"Call_24_down.tif"]];
	[self _displayListeningStatusFieldInformation];
	isCalling = NO;
}

- (void)_gatekeeperRegistrationDidChange:(NSNotification *)notif
{
	NSString *gatekeeperName = [[XMCallManager sharedInstance] gatekeeperName];
	NSMutableString *toolTipString = [[NSMutableString alloc] initWithCapacity:50];
	
	if(gatekeeperName != nil)
	{
		// gatekeeperName is only non-nil if using a gatekeeper
		[semaphoreView setImage:[NSImage imageNamed:@"semaphore_green.tif"]];	
		[toolTipString appendString:NSLocalizedString(@"Registered with gatekeeper\n\n",@"")];
	}
	else
	{
		if (![[[XMPreferencesManager sharedInstance] activeLocation] usesGatekeeper]){
			[semaphoreView setImage:[NSImage imageNamed:@"semaphore_green.tif"]];
			[toolTipString appendString:NSLocalizedString(@"Ready. Not using a gatekeeper\n\n",@"")];
		}
		else
		{
			[semaphoreView setImage:[NSImage imageNamed:@"semaphore_yellow.tif"]];
			[toolTipString appendString:NSLocalizedString(@"Gatekeeper registration failed\n\n",@"")];
		}
	}
	
	[self _appendNetworkInterfacesString:toolTipString];
	
	[semaphoreView setToolTip:toolTipString];
}

#pragma mark Private Methods

- (void)_H323NotEnabled:(NSNotification*)notif{
	// at the moment, treat as a fatal error if H.323 is not enabled.
	[statusField setStringValue:NSLocalizedString(@"Offline", @"")];
	[semaphoreView setImage:[NSImage imageNamed:@"semaphore_red.tif"]];
	[semaphoreView setToolTip:NSLocalizedString(@"Offline (H.323 not enabled)",@"")];
}

- (void)_displayListeningStatusFieldInformation
{
	XMCallManager *callManager = [XMCallManager sharedInstance];
	BOOL isH323Listening = [callManager isH323Listening];

	if(!isH323Listening)
	{
		[statusField setStringValue:NSLocalizedString(@"Offline", @"")];
		[semaphoreView setImage:[NSImage imageNamed:@"semaphore_red.tif"]];
		[semaphoreView setToolTip:NSLocalizedString(@"Offline (H.323 is not enabled)",@"")];
		return;
	}
		
	XMUtils *utils = [XMUtils sharedInstance];
	NSArray *localAddresses = [utils localAddresses];
		
	if([localAddresses count] == 0)
	{
		[statusField setStringValue:NSLocalizedString(@"Offline", @"")];
		[semaphoreView setImage:[NSImage imageNamed:@"semaphore_red.tif"]];
		[semaphoreView setToolTip:NSLocalizedString(@"Offline (could not fetch external address)",@"")];
		return;
	}
		
	[statusField setStringValue:NSLocalizedString(@"Idle", @"")];
	[self _gatekeeperRegistrationDidChange:nil];
}

- (void)_appendNetworkInterfacesString:(NSMutableString *)addressString
{
	XMUtils *utils = [XMUtils sharedInstance];
	
	NSArray *localAddresses = [utils localAddresses];
	NSString *externalAddress = [utils externalAddress];
	BOOL useAddressTranslation = [[[XMPreferencesManager sharedInstance] activeLocation] useAddressTranslation];
	
	unsigned count = [localAddresses count];
	if(count == 0)
	{
		[addressString appendString:@"No network addresses"];
		return;
	}
	
	[addressString appendString:@"Network Addresses:"];
	
	unsigned i;
	for(i = 0; i < count; i++)
	{
		NSString *address = (NSString *)[localAddresses objectAtIndex:i];
		[addressString appendString:@"\n"];
		[addressString appendString:address];
		
		if(useAddressTranslation == YES && externalAddress != nil && [externalAddress isEqualToString:address])
		{
			[addressString appendString:@" (External)"];
		}
	}
	
	if(useAddressTranslation == YES && externalAddress != nil && ![localAddresses containsObject:externalAddress])
	{
		[addressString appendString:@"\n"];
		[addressString appendString:externalAddress];
		[addressString appendString:@" (External)"];
	}
}

@end
