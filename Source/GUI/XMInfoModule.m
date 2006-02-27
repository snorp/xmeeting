/*
 * $Id: XMInfoModule.m,v 1.2 2006/02/27 14:38:18 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Ivan Guajana. All rights reserved.
 */

#import "XMeeting.h"
#import "XMInfoModule.h"
#import "XMApplicationFunctions.h"
#import "XMMainWindowController.h"
#import "XMInspectorController.h"
#import "XMPreferencesManager.h"


@interface XMInfoModule (PrivateMethods)

- (void)_didUpdateCallStatistics:(NSNotification *)notif;
- (void)_displayListeningStatusFieldInformation;
- (void)_preferencesDidChange:(NSNotification *)notif;
- (void)_didStartCalling:(NSNotification *)notif;
- (void)_didReceiveIncomingCall:(NSNotification *)notif;
- (void)_gatekeeperRegistrationDidChange:(NSNotification *)notif;
@end

@implementation XMInfoModule

- (id)init
{
	[[XMMainWindowController sharedInstance] addAdditionModule:self];
	
	nibLoader = nil;
	
	return self;
}

- (void)dealloc
{
	[nibLoader release];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	contentViewSize = [contentView frame].size;
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

	[notificationCenter addObserver:self selector:@selector(_preferencesDidChange:)
							   name:XMNotification_PreferencesDidChange 
							 object:nil];
	[notificationCenter addObserver:self selector:@selector(_displayListeningStatusFieldInformation)
							   name:XMNotification_UtilsDidEndFetchingExternalAddress
							 object:nil];
	[notificationCenter addObserver:self selector:@selector(_displayListeningStatusFieldInformation)
							   name:XMNotification_CallManagerDidStartSubsystemSetup
							 object:nil];
	[notificationCenter addObserver:self selector:@selector(_displayListeningStatusFieldInformation)
							   name:XMNotification_CallManagerDidEndSubsystemSetup
							 object:nil];
	[notificationCenter addObserver:self selector:@selector(_displayListeningStatusFieldInformation)
							   name:XMNotification_CallManagerDidStartCallInitiation
							 object:nil];
	[notificationCenter addObserver:self selector:@selector(_didStartCalling:)
							   name:XMNotification_CallManagerDidStartCalling
							 object:nil];
	[notificationCenter addObserver:self selector:@selector(_displayListeningStatusFieldInformation)
							   name:XMNotification_CallManagerDidNotStartCalling
							 object:nil];
	[notificationCenter addObserver:self selector:@selector(_didReceiveIncomingCall:)
							   name:XMNotification_CallManagerDidReceiveIncomingCall
							 object:nil];
	[notificationCenter addObserver:self selector:@selector(_displayListeningStatusFieldInformation)
							   name:XMNotification_CallManagerDidClearCall
							 object:nil];
	[notificationCenter addObserver:self selector:@selector(_gatekeeperRegistrationDidChange:)
							   name:XMNotification_CallManagerDidRegisterAtGatekeeper
							 object:nil];
	[notificationCenter addObserver:self selector:@selector(_gatekeeperRegistrationDidChange:)
							   name:XMNotification_CallManagerDidUnregisterFromGatekeeper
							 object:nil];

	[self _preferencesDidChange:nil];
	[self _displayListeningStatusFieldInformation];
	[self _gatekeeperRegistrationDidChange:nil];
}

#pragma mark Protocol Methods

- (NSString *)name
{
	return @"Info";
}

- (NSImage *)image
{
	return [NSImage imageNamed:@"Inspect_small"];
}

- (NSView *)contentView
{
	if(nibLoader == nil)
	{
		nibLoader = [[NSNib alloc] initWithNibNamed:@"Info" bundle:nil];
		[nibLoader instantiateNibWithOwner:self topLevelObjects:nil];
	}
	
	return contentView;
}

- (NSSize)contentViewSize
{
	// if not already done, causing the nib file to load
	[self contentView];
	
	return contentViewSize;
}

- (void)becomeActiveModule
{

}

- (void)becomeInactiveModule
{

}


#pragma mark Private Methods
- (void)_displayListeningStatusFieldInformation
{
	XMCallManager *callManager = [XMCallManager sharedInstance];
	XMUtils *utils = [XMUtils sharedInstance];
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	
	BOOL isH323Listening = [callManager isH323Listening];
	
	if(!isH323Listening)
	{
		[statusFld setStringValue:NSLocalizedString(@"Offline", @"")];
		[ipFld setStringValue:@""];
		[ipFld setStringValue:@""];
		return;
	}

	NSString *externalAddress = [utils externalAddress];
	NSArray *localAddresses = [utils localAddresses];
	unsigned localAddressCount = [localAddresses count];
	
	if(localAddressCount == 0)
	{
		[statusFld setStringValue:NSLocalizedString(@"Offline (No Network Address)", @"")];
		[ipFld setStringValue:@""];
		[ipFld setToolTip:@""];
		return;
	}
	
	[statusFld setStringValue:NSLocalizedString(@"Idle", @"")];
	
	NSMutableString *ipAddressString = [[NSMutableString alloc] initWithCapacity:30];
	unsigned i;
	
	for(i = 0; i < (localAddressCount-1); i++)
	{
		[ipAddressString appendString:[localAddresses objectAtIndex:i]];
		[ipAddressString appendString:@", "];
	}
	[ipAddressString appendString:[localAddresses objectAtIndex:(localAddressCount-1)]];
	
	BOOL useAddressTranslation = [[preferencesManager activeLocation] useAddressTranslation];
	
	if(useAddressTranslation == YES && externalAddress != nil && ![localAddresses containsObject:externalAddress])
	{
		[ipAddressString appendString:@", "];
		[ipAddressString appendString:externalAddress];
		[ipAddressString appendString: @" (External)"];
	}
	
	[ipFld setStringValue:ipAddressString];
	[ipFld setToolTip:ipAddressString];
	[ipAddressString release];
}

- (void)_gatekeeperRegistrationDidChange:(NSNotification *)notif
{
	NSString *gatekeeperName = [[XMCallManager sharedInstance] gatekeeperName];
	
	if(gatekeeperName != nil)
	{
		NSString *gatekeeperFormat = NSLocalizedString(@"%@", @"");
		NSString *gatekeeperString = [[NSString alloc] initWithFormat:gatekeeperFormat, gatekeeperName];
		[gkFld setStringValue:gatekeeperString];
		[gatekeeperString release];
		
		[gdsFld setTextColor:[NSColor controlTextColor]];
	}
	else
	{
		[gkFld setStringValue:@""];
		[gdsFld setTextColor:[NSColor disabledControlTextColor]];
	}
}


- (void)_preferencesDidChange:(NSNotification *)notif
{
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	XMLocation *activeLocation = [preferencesManager activeLocation];
	
	if([activeLocation useGatekeeper] == YES)
	{
		NSString* phone = [activeLocation gatekeeperPhoneNumber]; 
		[gdsFld setStringValue:phone];
	}
	else
	{
		[gdsFld setStringValue:@""];
	}
}

- (void)_didReceiveIncomingCall:(NSNotification *)notif
{
	[statusFld setStringValue:NSLocalizedString(@"Incoming Call", @"")];
}

- (void)_didStartCalling:(NSNotification *)notif
{
	[statusFld setStringValue:NSLocalizedString(@"In call", @"")];
}

- (BOOL)isResizableWhenInSeparateWindow{
	return NO;
}

@end
