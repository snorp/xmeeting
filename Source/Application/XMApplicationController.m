/*
 * $Id: XMApplicationController.m,v 1.5 2005/06/23 12:35:56 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMeeting.h"
#import "XMApplicationController.h"
#import "XMAddressBookCallAddressProvider.h"

#import "XMMainWindowController.h"
#import "XMPreferencesWindowController.h"
#import "XMNoCallModule.h"
#import "XMInCallModule.h"
#import "XMAddressBookModule.h"
#import "XMZeroConfModule.h"
#import "XMDialPadModule.h"
#import "XMTextChatModule.h"
#import "XMStatisticsModule.h"
#import "XMCallHistoryModule.h"

@interface XMApplicationController (PrivateMethods)

- (void)_didGoOffline:(NSNotification *)notif;
- (void)_callEstablished:(NSNotification *)notif;
- (void)_callCleared:(NSNotification *)notif;

@end

@implementation XMApplicationController

#pragma mark Init & Deallocation Methods

- (void)awakeFromNib
{
	// First step to do!
	InitXMeetingFramework();
	
	// registering the call address providers
	[[XMAddressBookCallAddressProvider sharedInstance] setActiveCallAddressProvider:YES];
	
	noCallModule = [[XMNoCallModule alloc] init];
	inCallModule = [[XMInCallModule alloc] init];
	
	addressBookModule = [[XMAddressBookModule alloc] init];
	zeroConfModule = [[XMZeroConfModule alloc] init];
	dialPadModule = [[XMDialPadModule alloc] init];
	textChatModule = [[XMTextChatModule alloc] init];
	statisticsModule = [[XMStatisticsModule alloc] init];
	callHistoryModule = [[XMCallHistoryModule alloc] init];
	
	// show the main window
	[[XMMainWindowController sharedInstance] showMainWindow];
	
	// start fetching the external address
	[[XMUtils sharedInstance] localAddress];
	[[XMUtils sharedInstance] startFetchingExternalAddress];
	
	// registering for notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didGoOffline:)
												 name:XMNotification_DidGoOffline object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_callEstablished:)
												 name:XMNotification_CallEstablished object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_callCleared:)
												 name:XMNotification_CallCleared object:nil];
	
	// last but not least, go online
	[[XMCallManager sharedInstance] setOnline:YES];
}

- (void)dealloc
{
	[noCallModule release];
	[inCallModule release];
	[addressBookModule release];
	[zeroConfModule release];
	[dialPadModule release];
	[textChatModule release];
	[statisticsModule release];
	[callHistoryModule release];
	
	[super dealloc];
}

#pragma mark Action Methods

- (IBAction)showPreferences:(id)sender
{
	[[XMPreferencesWindowController sharedInstance] showPreferencesWindow];
}

#pragma mark NSApplication delegate methods

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	[[XMCallManager sharedInstance] setOnline:NO];
	appShouldTerminate = YES;
	
	// wait for the DidGoOffline notification before terminating.
	return NSTerminateLater;
}

#pragma mark Private Methods

- (void)_didGoOffline:(NSNotification *)notif
{
	if(appShouldTerminate == YES)
	{
		[NSApp replyToApplicationShouldTerminate:YES];
	}
}

- (void)_callEstablished:(NSNotification *)notif
{
	[[XMMainWindowController sharedInstance] showMainModule:inCallModule];
}

- (void)_callCleared:(NSNotification *)notif
{	
	[[XMMainWindowController sharedInstance] showMainModule:noCallModule];
}

@end
