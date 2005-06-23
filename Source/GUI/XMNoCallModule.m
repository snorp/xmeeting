/*
 * $Id: XMNoCallModule.m,v 1.5 2005/06/23 12:35:57 hfriederich Exp $
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
- (void)_didStartSubsystemSetup:(NSNotification *)notif;
- (void)_didEndSubsystemSetup:(NSNotification *)notif;
- (void)_didStartCalling:(NSNotification *)notif;
- (void)_callCleared:(NSNotification *)notif;

- (void)_displayListeningStatusFieldInformation;

@end

@interface XMManualAddressURL : XMURL <XMCallAddress>
{
	NSString *address;
}

- (id)_initWithAddress:(NSString *)address;

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
												 name:XMNotification_PreferencesDidChange 
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didEndFetchingExternalAddress:)
												 name:XMNotification_DidEndFetchingExternalAddress
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didStartSubsystemSetup:)
												 name:XMNotification_DidStartSubsystemSetup
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didEndSubsystemSetup:)
												 name:XMNotification_DidEndSubsystemSetup
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didStartCalling:)
												 name:XMNotification_DidStartCalling
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_callCleared:)
												 name:XMNotification_CallCleared
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
	NSLog(@"change");
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

- (void)_didEndFetchingExternalAddress:(NSNotification *)notif
{
	[self _displayListeningStatusFieldInformation];
}

- (void)_didStartSubsystemSetup:(NSNotification *)notif
{
	[locationsPopUp setEnabled:NO];
	[callButton setEnabled:NO];
}

- (void)_didEndSubsystemSetup:(NSNotification *)notif
{
	[locationsPopUp setEnabled:YES];
	[callButton setEnabled:YES];
	[self _displayListeningStatusFieldInformation];
}

- (void)_didStartCalling:(NSNotification *)notif
{
	id<XMCallAddress> activeCallAddress = [callAddressManager activeCallAddress];
	[callAddressField setRepresentedObject:activeCallAddress];
	[locationsPopUp setEnabled:NO];
	[callButton setTitle:NSLocalizedString(@"Hangup", @"")];
	[statusFieldOne setStringValue:NSLocalizedString(@"Calling...", @"")];
	[statusFieldTwo setStringValue:@""];
	
	isCalling = YES;
}

- (void)_callCleared:(NSNotification *)notif
{
	[locationsPopUp setEnabled:YES];
	[callButton setTitle:NSLocalizedString(@"Call", @"")];
	[self _displayListeningStatusFieldInformation];
	isCalling = NO;
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
		XMManualAddressURL *manualAddressURL = [[[XMManualAddressURL alloc] _initWithAddress:completedString] autorelease];
		return manualAddressURL;
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

@end

@implementation XMManualAddressURL

- (id)_initWithAddress:(NSString *)theAddress
{
	address = [theAddress copy];
	
	return self;
}

- (XMCallProtocol)callProtocol
{
	return XMCallProtocol_H323;
}

- (NSString *)address
{
	return address;
}

- (unsigned)port
{
	return 0;
}

- (NSString *)humanReadableRepresentation
{
	return [self address];
}

- (id<XMCallAddressProvider>)provider
{
	return nil;
}

- (XMURL *)url
{
	return self;
}

- (NSString *)displayString
{
	return [self address];
}

- (NSImage *)displayImage
{
	return nil;
}

@end
