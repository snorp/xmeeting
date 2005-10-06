/*
 * $Id: XMApplicationController.m,v 1.10 2005/10/06 15:04:42 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMeeting.h"
#import "XMApplicationController.h"
#import "XMAddressBookCallAddressProvider.h"
#import "XMCallHistoryCallAddressProvider.h"

#import "XMMainWindowController.h"
#import "XMPreferencesWindowController.h"
#import "XMNoCallModule.h"
#import "XMInCallModule.h"
#import "XMLocalAudioVideoModule.h"
#import "XMAddressBookModule.h"
#import "XMZeroConfModule.h"
#import "XMDialPadModule.h"
#import "XMTextChatModule.h"
#import "XMStatisticsModule.h"
#import "XMCallHistoryModule.h"

@interface XMApplicationController (PrivateMethods)

- (void)_didGoOffline:(NSNotification *)notif;
- (void)_callStartFailed:(NSNotification *)notif;
- (void)_callEstablished:(NSNotification *)notif;
- (void)_callCleared:(NSNotification *)notif;
- (void)_enablingH323Failed:(NSNotification *)notif;
- (void)_gatekeeperRegistrationFailed:(NSNotification *)notif;

- (void)_displayCallStartFailed;
- (void)_displayEnablingH323FailedAlert;
- (void)_displayGatekeeperRegistrationFailedAlert;

@end

@implementation XMApplicationController

#pragma mark Init & Deallocation Methods

- (void)applicationDidFinishLaunching:(NSNotification *)notif
{
	// First step to do!
	InitXMeetingFramework();
	
	// registering the call address providers
	[[XMAddressBookCallAddressProvider sharedInstance] setActiveCallAddressProvider:YES];
	[[XMCallHistoryCallAddressProvider sharedInstance] setActiveCallAddressProvider:YES];
	
	noCallModule = [[XMNoCallModule alloc] init];
	inCallModule = [[XMInCallModule alloc] init];
	
	localAudioVideoModule = [[XMLocalAudioVideoModule alloc] init];
	
	addressBookModule = [[XMAddressBookModule alloc] init];
	zeroConfModule = [[XMZeroConfModule alloc] init];
	dialPadModule = [[XMDialPadModule alloc] init];
	textChatModule = [[XMTextChatModule alloc] init];
	statisticsModule = [[XMStatisticsModule alloc] init];
	callHistoryModule = [[XMCallHistoryModule alloc] init];
	
	// show the main window
	[[XMMainWindowController sharedInstance] showMainWindow];
	
	// start fetching the external address
	XMUtils *utils = [XMUtils sharedInstance];
	[utils localAddress];
	[utils startFetchingExternalAddress];
	
	// registering for notifications
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	[notificationCenter addObserver:self selector:@selector(_didGoOffline:)
							   name:XMNotification_CallManagerDidGoOffline object:nil];
	[notificationCenter addObserver:self selector:@selector(_callStartFailed:)
							   name:XMNotification_CallManagerCallStartFailed object:nil];
	[notificationCenter addObserver:self selector:@selector(_callEstablished:)
							   name:XMNotification_CallManagerCallEstablished object:nil];
	[notificationCenter addObserver:self selector:@selector(_callCleared:)
							   name:XMNotification_CallManagerCallCleared object:nil];
	[notificationCenter addObserver:self selector:@selector(_enablingH323Failed:)
							   name:XMNotification_CallManagerEnablingH323Failed object:nil];
	[notificationCenter addObserver:self selector:@selector(_gatekeeperRegistrationFailed:)
							   name:XMNotification_CallManagerGatekeeperRegistrationFailed object:nil];
	
	// last but not least, go online
	[[XMCallManager sharedInstance] setOnline:YES];
	[[XMVideoManager sharedInstance] startGrabbing];
}

- (void)dealloc
{
	[noCallModule release];
	[inCallModule release];
	[localAudioVideoModule release];
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

- (IBAction)updateDeviceLists:(id)sender
{
	[[XMVideoManager sharedInstance] updateInputDeviceList];
}

#pragma mark NSApplication delegate methods

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	[[XMCallManager sharedInstance] setOnline:NO];
	appShouldTerminate = YES;
	
	// wait for the DidGoOffline notification before terminating.
	return NSTerminateLater;
}

#pragma mark Notification Methods

- (void)_didGoOffline:(NSNotification *)notif
{
	if(appShouldTerminate == YES)
	{
		[NSApp replyToApplicationShouldTerminate:YES];
	}
}

- (void)_callStartFailed:(NSNotification *)notif
{
	[self performSelector:@selector(_displayCallStartFailed) withObject:nil afterDelay:0.0];
}

- (void)_callEstablished:(NSNotification *)notif
{
	[[XMMainWindowController sharedInstance] showMainModule:inCallModule];
}

- (void)_callCleared:(NSNotification *)notif
{	
	[[XMMainWindowController sharedInstance] showMainModule:noCallModule];
}

- (void)_enablingH323Failed:(NSNotification *)notif
{
	[self performSelector:@selector(_displayEnableH323FailedAlert) withObject:nil afterDelay:0.0];
}

- (void)_gatekeeperRegistrationFailed:(NSNotification *)notif
{
	[self performSelector:@selector(_displayGatekeeperRegistrationFailedAlert) withObject:nil afterDelay:0.0];
}

#pragma mark Displaying Alerts

- (void)_displayCallStartFailed
{
	NSAlert *alert = [[NSAlert alloc] init];
	
	[alert setMessageText:NSLocalizedString(@"Call failed", @"")];
	
	NSString *informativeTextFormat = NSLocalizedString(@"Unable to call ADDRESS. (%@)", @"");
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
	
	NSString *informativeText = [[NSString alloc] initWithFormat:informativeTextFormat, failReasonText];
	[alert setInformativeText:informativeText];
	[informativeText release];
	
	[alert setAlertStyle:NSInformationalAlertStyle];
	[alert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
	
	[alert runModal];
}

- (void)_displayEnableH323FailedAlert
{
	NSAlert *alert = [[NSAlert alloc] init];
	
	[alert setMessageText:NSLocalizedString(@"Enabling H.323 Failed", @"")];
	[alert setInformativeText:NSLocalizedString(@"Unable to enable the H.323 subsystem (REASON) \
	You will not be able to make H.323 calls", @"")];
	
	[alert setAlertStyle:NSInformationalAlertStyle];
	[alert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
	[alert addButtonWithTitle:NSLocalizedString(@"Retry", @"")];
	
	int result = [alert runModal];
	
	if(result == NSAlertSecondButtonReturn)
	{
		[[XMCallManager sharedInstance] retryEnableH323];
	}
	
	[alert release];
}

- (void)_displayGatekeeperRegistrationFailedAlert
{
	NSAlert *alert = [[NSAlert alloc] init];
	
	XMCallManager *callManager = [XMCallManager sharedInstance];
	XMGatekeeperRegistrationFailReason failReason = [callManager gatekeeperRegistrationFailReason];
	NSString *reasonText;
	NSString *suggestionText;
	
	switch(failReason)
	{
		case XMGatekeeperRegistrationFailReason_NoGatekeeperSpecified:
			reasonText = NSLocalizedString(@"no gatekeeper specified", @"");
			suggestionText = NSLocalizedString(@"Please specify a gatekeeper in preferences.", @"");
			break;
		case XMGatekeeperRegistrationFailReason_GatekeeperNotFound:
			reasonText = NSLocalizedString(@"gatekeeper not found", @"");
			suggestionText = NSLocalizedString(@"Please check your internet connection.", @"");
			break;
		case XMGatekeeperRegistrationFailReason_RegistrationReject:
			reasonText = NSLocalizedString(@"gatekeeper rejected registration", @"");
			suggestionText = NSLocalizedString(@"Please check your gatekeeper settings.", @"");
			break;
		default:
			reasonText = NSLocalizedString(@"unknown failure", @"");
			suggestionText = @"";
			break;
	}
	
	[alert setMessageText:NSLocalizedString(@"Gatekeeper Registration Failed", @"")];
	NSString *informativeTextFormat = NSLocalizedString(@"Unable to register at gatekeeper. (%@) You will not be able \
	to use phone numbers when making a call. %@", @"");
	

	NSString *informativeText = [[NSString alloc] initWithFormat:informativeTextFormat, reasonText, suggestionText];
	[alert setInformativeText:informativeText];
	[informativeText release];
	
	[alert setAlertStyle:NSInformationalAlertStyle];
	[alert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
	[alert addButtonWithTitle:NSLocalizedString(@"Retry", @"")];
	
	int result = [alert runModal];
	
	if(result == NSAlertSecondButtonReturn)
	{
		[[XMCallManager sharedInstance] retryGatekeeperRegistration];
	}
	
	[alert release];
}

@end
