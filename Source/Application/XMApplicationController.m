/*
 * $Id: XMApplicationController.m,v 1.22 2006/03/16 14:13:57 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMApplicationController.h"

#import "XMeeting.h"
#import "XMPreferencesManager.h"
#import "XMAddressBookCallAddressProvider.h"
#import "XMCallHistoryCallAddressProvider.h"

#import "XMMainWindowController.h"
#import "XMPreferencesWindowController.h"
#import "XMNoCallModule.h"
#import "XMInCallModule.h"
#import "XMBusyModule.h"
#import "XMLocalAudioVideoModule.h"
#import "XMAddressBookModule.h"
#import "XMZeroConfModule.h"
#import "XMDialPadModule.h"
#import "XMTextChatModule.h"
#import "XMStatisticsModule.h"
#import "XMCallHistoryModule.h"
#import "XMInspectorController.h"

#import "XMSetupAssistantManager.h"

@interface XMApplicationController (PrivateMethods)

- (void)_didStartSubsystemSetup:(NSNotification *)notif;
- (void)_didEndSubsystemSetup:(NSNotification *)notif;
- (void)_didReceiveIncomingCall:(NSNotification *)notif;
- (void)_didEstablishCall:(NSNotification *)notif;
- (void)_didClearCall:(NSNotification *)notif;

// handle errors
- (void)_didNotStartCalling:(NSNotification *)notif;
- (void)_didNotEnableH323:(NSNotification *)notif;
- (void)_didNotRegisterAtGatekeeper:(NSNotification *)notif;

// terminating the application
- (void)_frameworkClosed:(NSNotification *)notif;

// displaying dialogs
- (void)_displayIncomingCall;
- (void)_displayCallStartFailed;
- (void)_displayEnablingH323FailedAlert;
- (void)_displayGatekeeperRegistrationFailedAlert;

// validating menu items
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem;

- (void)_showSetupAssistant;
- (void)_setupApplication:(NSArray *)locations;

@end

@implementation XMApplicationController

#pragma mark Init & Deallocation Methods

- (id)init
{
	self = [super init];
	
	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notif
{
	// Initialize the framework
	XMInitFramework();
	
	// registering for notifications
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	[notificationCenter addObserver:self selector:@selector(_didStartSubsystemSetup:)
							   name:XMNotification_CallManagerDidStartSubsystemSetup object:nil];
	[notificationCenter addObserver:self selector:@selector(_didEndSubsystemSetup:)
							   name:XMNotification_CallManagerDidEndSubsystemSetup object:nil];
	[notificationCenter addObserver:self selector:@selector(_didReceiveIncomingCall:)
							   name:XMNotification_CallManagerDidReceiveIncomingCall object:nil];
	[notificationCenter addObserver:self selector:@selector(_didEstablishCall:)
							   name:XMNotification_CallManagerDidEstablishCall object:nil];
	[notificationCenter addObserver:self selector:@selector(_didClearCall:)
							   name:XMNotification_CallManagerDidClearCall object:nil];
	[notificationCenter addObserver:self selector:@selector(_didNotStartCalling:)
							   name:XMNotification_CallManagerDidNotStartCalling object:nil];
	[notificationCenter addObserver:self selector:@selector(_didNotEnableH323:)
							   name:XMNotification_CallManagerDidNotEnableH323 object:nil];
	[notificationCenter addObserver:self selector:@selector(_didNotRegisterAtGatekeeper:)
							   name:XMNotification_CallManagerDidNotRegisterAtGatekeeper object:nil];
	[notificationCenter addObserver:self selector:@selector(_frameworkDidClose:)
							   name:XMNotification_FrameworkDidClose object:nil];
		
	if([XMPreferencesManager doesHavePreferences] == YES)
	{
		[self performSelector:@selector(_setupApplication:) withObject:nil afterDelay:0.0];
	}
	else
	{
		[self performSelector:@selector(_showSetupAssistant) withObject:nil afterDelay:0.0];
	}
}

- (void)dealloc
{
	[noCallModule release];
	[inCallModule release];
	[busyModule release];
	[localAudioVideoModule release];
	[addressBookModule release];
	//[zeroConfModule release];
	//[dialPadModule release];
	//[textChatModule release];
	[infoModule release];
	[statisticsModule release];
	[callHistoryModule release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

#pragma mark Action Methods


- (IBAction)showInspector:(id)sender{
	static XMInspectorController *instance;
	if (!instance){
		instance = [XMInspectorController instanceWithModules:[NSArray arrayWithObjects:infoModule, statisticsModule, callHistoryModule, nil] andName:@"Inspector"];
		[NSBundle loadNibNamed:@"XMInspector" owner:[instance retain]];
	}
	else
	{
		[instance show];
	}
}

- (IBAction)showTools:(id)sender{
	static XMInspectorController *instance;
	if (!instance){
		instance = [XMInspectorController instanceWithModules:[NSArray arrayWithObjects:localAudioVideoModule, dialPadModule, nil] andName:@"Tools"];
		[NSBundle loadNibNamed:@"XMInspector" owner:[instance retain]];
	}
	else
	{
		[instance show];
	}
}


- (IBAction)showPreferences:(id)sender
{
	[[XMPreferencesWindowController sharedInstance] showPreferencesWindow];
}

- (IBAction)updateDeviceLists:(id)sender
{
	[[XMVideoManager sharedInstance] updateInputDeviceList];
}

- (IBAction)retryGatekeeperRegistration:(id)sender
{
	[[XMCallManager sharedInstance] retryGatekeeperRegistration];
}

#pragma mark -
#pragma mark Get&Set
- (XMAddressBookModule*)addressBookModule{
	return addressBookModule;
}


#pragma mark -
#pragma mark NSApplication delegate methods

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	XMCloseFramework();
	
	[[XMPreferencesManager sharedInstance] synchronize];
	// wait for the FrameworkDidClose notification before terminating.
	return NSTerminateLater;
}

#pragma mark Notification Methods

- (void)_didStartSubsystemSetup:(NSNotification *)notif
{
	[[XMMainWindowController sharedInstance] showModule:busyModule];
}

- (void)_didEndSubsystemSetup:(NSNotification *)notif
{
	[[XMMainWindowController sharedInstance] showModule:noCallModule];
}

- (void)_didReceiveIncomingCall:(NSNotification *)notif
{
	
	[self performSelector:@selector(_displayIncomingCall) withObject:nil afterDelay:0.0];
}

- (void)_didEstablishCall:(NSNotification *)notif
{
	[[XMMainWindowController sharedInstance] showModule:inCallModule];
}

- (void)_didClearCall:(NSNotification *)notif
{	
	if(incomingCallAlert != nil)
	{
		[NSApp abortModal];
	}
	[[XMMainWindowController sharedInstance] showModule:noCallModule];
}

- (void)_didNotStartCalling:(NSNotification *)notif
{
	// by delaying the display of the callStartFailed message on screen, we allow
	// that all observers of this notification have received the notification
	[self performSelector:@selector(_displayCallStartFailed) withObject:nil afterDelay:0.0];
}

- (void)_didNotEnableH323:(NSNotification *)notif
{
	[self performSelector:@selector(_displayEnableH323FailedAlert) withObject:nil afterDelay:0.0];
}

- (void)_didNotRegisterAtGatekeeper:(NSNotification *)notif
{
	[self performSelector:@selector(_displayGatekeeperRegistrationFailedAlert) withObject:nil afterDelay:0.0];
}

- (void)_frameworkDidClose:(NSNotification *)notif
{
	// Now it's time to terminate the application
	[NSApp replyToApplicationShouldTerminate:YES];
}

#pragma mark Displaying Alerts

- (void)_displayIncomingCall
{
	incomingCallAlert = [[NSAlert alloc] init];
	
	[incomingCallAlert setMessageText:NSLocalizedString(@"Incoming Call", @"")];
	
	NSString *informativeTextFormat = NSLocalizedString(@"Incoming call from \"%@\"\nTake call or not?", @"");
	XMCallInfo *activeCall = [[XMCallManager sharedInstance] activeCall];
	NSString *remoteName = [activeCall remoteName];
	
	NSString *informativeText = [[NSString alloc] initWithFormat:informativeTextFormat, remoteName];
	[incomingCallAlert setInformativeText:informativeText];
	[informativeText release];
	
	[incomingCallAlert setAlertStyle:NSInformationalAlertStyle];
	[incomingCallAlert addButtonWithTitle:NSLocalizedString(@"Yes", @"")];
	[incomingCallAlert addButtonWithTitle:NSLocalizedString(@"No", @"")];
	
	int result = [incomingCallAlert runModal];
	
	if(result == NSAlertFirstButtonReturn)
	{
		[[XMCallManager sharedInstance] acceptIncomingCall];
	}
	else if(result == NSAlertSecondButtonReturn)
	{
		[[XMCallManager sharedInstance] rejectIncomingCall];
	}
	
	[incomingCallAlert release];
	incomingCallAlert = nil;
	

}

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
	
	[alert release];
}

- (void)_displayEnableH323FailedAlert
{
	NSAlert *alert = [[NSAlert alloc] init];
	
	[alert setMessageText:NSLocalizedString(@"Enabling H.323 Failed", @"")];
	[alert setInformativeText:NSLocalizedString(@"Unable to enable the H.323 subsystem.\nThere is probably another H.323 application running.\nYou will not be able to make H.323 calls", @"")];
	
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
		/*case XMGatekeeperRegistrationFailReason_NoGatekeeperSpecified:
			reasonText = NSLocalizedString(@"no gatekeeper specified", @"");
			suggestionText = NSLocalizedString(@"Please specify a gatekeeper in preferences.", @"");
			break;*/
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

#pragma mark Private Methods

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if([menuItem tag] == 101)
	{
		XMCallManager *callManager = [XMCallManager sharedInstance];
		
		if([callManager gatekeeperRegistrationFailReason] != XMGatekeeperRegistrationFailReason_NoFailure)
		{
			return YES;
		}
		return NO;
	}
	
	return YES;
}

- (void)_showSetupAssistant
{
	[[XMSetupAssistantManager sharedInstance] runFirstApplicationLaunchAssistantWithDelegate:self
																			  didEndSelector:@selector(_setupApplication:)];
}

- (void)_setupApplication:(NSArray *)locations
{		
	// registering the call address providers
	[[XMCallHistoryCallAddressProvider sharedInstance] setActiveCallAddressProvider:YES];
	[[XMAddressBookCallAddressProvider sharedInstance] setActiveCallAddressProvider:YES];
	
	noCallModule = [[XMNoCallModule alloc] init];
	inCallModule = [[XMInCallModule alloc] init];
	busyModule = [[XMBusyModule alloc] init];
	
	localAudioVideoModule = [[XMLocalAudioVideoModule alloc] init];
	
	infoModule = [[XMInfoModule alloc] init];
	addressBookModule = [[XMAddressBookModule alloc] init];
	//zeroConfModule = [[XMZeroConfModule alloc] init];
	//dialPadModule = [[XMDialPadModule alloc] init];
	//textChatModule = [[XMTextChatModule alloc] init];
	statisticsModule = [[XMStatisticsModule alloc] init];
	callHistoryModule = [[XMCallHistoryModule alloc] init];
	
	// show the main window
	[[XMMainWindowController sharedInstance] showMainWindow];
	
	// start fetching the external address
	XMUtils *utils = [XMUtils sharedInstance];
	[utils startFetchingExternalAddress];
	
	// causing the PreferencesManager to activate the active location
	// by calling XMCallManager -setActivePreferences:
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	[preferencesManager setLocations:locations];
	if([locations count] != 0)
	{
		[preferencesManager synchronizeAndNotify];
	}
	
	// start grabbing from the video sources
	[[XMVideoManager sharedInstance] startGrabbing];
	
	incomingCallAlert = nil;
}

@end
