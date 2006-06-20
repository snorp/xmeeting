/*
 * $Id: XMApplicationController.m,v 1.39 2006/06/20 13:33:58 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMApplicationController.h"

#import "XMeeting.h"

#import "XMAddressBookCallAddressProvider.h"
#import "XMCallHistoryCallAddressProvider.h"
#import "XMPreferencesManager.h"
#import "XMH323Account.h"
#import "XMSIPAccount.h"
#import "XMLocation.h"
#import "XMApplicationFunctions.h"

#import "XMMainWindowController.h"
#import "XMNoCallModule.h"
#import "XMInCallModule.h"

#import "XMInspectorController.h"

#import "XMInfoModule.h"
#import "XMStatisticsModule.h"
#import "XMCallHistoryModule.h"

#import "XMLocalAudioVideoModule.h"
#import "XMDialPadModule.h"

#import "XMAddressBookModule.h"

//#import "XMZeroConfModule.h"
//#import "XMTextChatModule.h"

#import "XMPreferencesWindowController.h"

#import "XMSetupAssistantManager.h"

@interface XMApplicationController (PrivateMethods)

// preferences management
- (void)_activeLocationDidChange:(NSNotification *)notif;
- (void)_preferencesDidChange:(NSNotification *)notif;

// Call management
- (void)_didReceiveIncomingCall:(NSNotification *)notif;
- (void)_didEstablishCall:(NSNotification *)notif;
- (void)_didClearCall:(NSNotification *)notif;

// handle errors
- (void)_didNotStartCalling:(NSNotification *)notif;
- (void)_didNotEnableH323:(NSNotification *)notif;
- (void)_didNotRegisterAtGatekeeper:(NSNotification *)notif;
- (void)_didNotEnableSIP:(NSNotification *)notif;
- (void)_didNotRegisterAtSIPRegistrar:(NSNotification *)notif;

// terminating the application
- (void)_frameworkClosed:(NSNotification *)notif;

// displaying dialogs
- (void)_displayIncomingCallAlert;
- (void)_displayCallStartFailedAlert:(NSString *)address;
- (void)_displayEnablingH323FailedAlert;
- (void)_displayGatekeeperRegistrationFailedAlert;
- (void)_displayEnablingSIPFailedAlert;
- (void)_displaySIPRegistrationFailedAlert;

// validating menu items
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem;

- (void)_showSetupAssistant;
- (void)_setupApplication;
- (void)_setupApplicationWithLocations:(NSArray *)locations 
						  h323Accounts:(NSArray *)h323Accounts
						   sipAccounts:(NSArray *)sipAccounts;

@end

@implementation XMApplicationController

#pragma mark Init & Deallocation Methods

- (id)init
{
	self = [super init];
	
	// all setup is done in -applicationDidFinishLaunching
	// in order to avoid problems with the XMeeting framework's runtime
	// engine
	
	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notif
{
	// Initialize the framework
	BOOL enablePTrace = [XMPreferencesManager enablePTrace];
	NSString *pTracePath = nil;
	if(enablePTrace == YES)
	{
		pTracePath = [XMPreferencesManager pTraceFilePath];
	}
	XMInitFramework(pTracePath);
	
	// registering for notifications
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	[notificationCenter addObserver:self selector:@selector(_activeLocationDidChange:)
							   name:XMNotification_PreferencesManagerDidChangeActiveLocation object:nil];
	[notificationCenter addObserver:self selector:@selector(_preferencesDidChange:)
							   name:XMNotification_PreferencesManagerDidChangePreferences object:nil];
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
	[notificationCenter addObserver:self selector:@selector(_didNotEnableSIP:)
							   name:XMNotification_CallManagerDidNotEnableSIP object:nil];
	[notificationCenter addObserver:self selector:@selector(_didNotRegisterAtSIPRegistrar:)
							   name:XMNotification_CallManagerDidNotRegisterAtSIPRegistrar object:nil];
	[notificationCenter addObserver:self selector:@selector(_frameworkDidClose:)
							   name:XMNotification_FrameworkDidClose object:nil];
	
	// depending on wheter preferences are in the system, the setup assistant is shown or not.
	if([XMPreferencesManager doesHavePreferences] == YES)
	{
		[self performSelector:@selector(_setupApplication) withObject:nil afterDelay:0.0];
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
	
	[infoModule release];
	[statisticsModule release];
	[callHistoryModule release];
	
	[localAudioVideoModule release];
	
	[addressBookModule release];
	
	//[zeroConfModule release];
	//[dialPadModule release];
	//[textChatModule release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
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

- (IBAction)retryEnableH323:(id)sender
{
	[[XMCallManager sharedInstance] retryEnableH323];
}

- (IBAction)retryGatekeeperRegistration:(id)sender
{
	[[XMCallManager sharedInstance] retryGatekeeperRegistration];
}

- (IBAction)retryEnableSIP:(id)sender
{
	[[XMCallManager sharedInstance] retryEnableSIP];
}

- (IBAction)retrySIPRegistration:(id)sender
{
	[[XMCallManager sharedInstance] retrySIPRegistrations];
}

- (IBAction)updateNetworkInformation:(id)sender
{
	XMUtils *utils = [XMUtils sharedInstance];
	
	[utils startFetchingCheckipExternalAddress];
	[utils updateSTUNInformation];
	

	[[XMMainWindowController sharedInstance] showMainWindow];
}

- (IBAction)showMainWindow:(id)sender
{
	[[XMMainWindowController sharedInstance] showMainWindow];
}

- (IBAction)showInspector:(id)sender
{
	[[XMInspectorController inspectorWithTag:XMInspectorControllerTag_Inspector] show];
}

- (IBAction)showTools:(id)sender
{
	[[XMInspectorController inspectorWithTag:XMInspectorControllerTag_Tools] show];
}

- (IBAction)showContacts:(id)sender
{
	[[XMInspectorController inspectorWithTag:XMInspectorControllerTag_Contacts] show];
}

- (IBAction)enterFullScreen:(id)sender
{
	XMMainWindowController *mainWindowController = [XMMainWindowController sharedInstance];
	
	if([mainWindowController isFullScreen])
	{
		return;
	}
	[XMInspectorController setFullScreen:YES];
	[mainWindowController beginFullScreen];
}

#pragma mark -
#pragma mark Public Methods

- (void)exitFullScreen
{
	XMMainWindowController *mainWindowController = [XMMainWindowController sharedInstance];
	
	if([mainWindowController isFullScreen] == NO)
	{
		return;
	}
	
	[XMInspectorController setFullScreen:NO];
	[mainWindowController endFullScreen];
}

- (BOOL)isFullScreen
{
	return [[XMMainWindowController sharedInstance] isFullScreen];
}

- (void)showInfoInspector
{
	[[XMInspectorController inspectorWithTag:XMInspectorControllerTag_Inspector] showModule:infoModule];
}

- (void)showStatisticsInspector
{
	[[XMInspectorController inspectorWithTag:XMInspectorControllerTag_Inspector] showModule:statisticsModule];
}

- (void)showCallHistoryInspector
{
	[[XMInspectorController inspectorWithTag:XMInspectorControllerTag_Inspector] showModule:callHistoryModule];
}

#pragma mark -
#pragma mark NSApplication delegate methods

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
	[[XMMainWindowController sharedInstance] showMainWindow];
	return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	// Close the preferences window in a proper fashion
	[[XMPreferencesWindowController sharedInstance] closePreferencesWindow];
	
	// Store unsaved changes
	[[XMPreferencesManager sharedInstance] storeVideoManagerSettings];
	
	XMCloseFramework();
	
	[[XMPreferencesManager sharedInstance] synchronize];
	
	// wait for the FrameworkDidClose notification before terminating.
	return NSTerminateLater;
}

#pragma mark -
#pragma mark Notification Methods

- (void)_activeLocationDidChange:(NSNotification *)notif
{
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	XMVideoManager *videoManager = [XMVideoManager sharedInstance];
	
	if([[preferencesManager activeLocation] enableVideo] == YES)
	{
		[videoManager startGrabbing];
	}
	else
	{
		[videoManager stopGrabbing];
	}
}

- (void)_preferencesDidChange:(NSNotification *)notif
{
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	
	if([preferencesManager searchAddressBookDatabase] == YES)
	{
		[[XMAddressBookCallAddressProvider sharedInstance] setActiveCallAddressProvider:YES];
	}
	else
	{
		[[XMAddressBookCallAddressProvider sharedInstance] setActiveCallAddressProvider:NO];
	}
}

- (void)_didReceiveIncomingCall:(NSNotification *)notif
{
	// ensure that the propagation of the notification doesn't get blocked
	[self performSelector:@selector(_displayIncomingCallAlert) withObject:nil afterDelay:0.0];
}

- (void)_didEstablishCall:(NSNotification *)notif
{
	BOOL enterFullScreen = NO;
	
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	if([[preferencesManager activeLocation] enableVideo] == YES &&
	   [preferencesManager automaticallyEnterFullScreen] == YES)
	{
		enterFullScreen = YES;
	}

	[[XMMainWindowController sharedInstance] showModule:inCallModule fullScreen:enterFullScreen];
}

- (void)_didClearCall:(NSNotification *)notif
{	
	if(incomingCallAlert != nil)
	{
		[NSApp abortModal];
	}
	[[XMMainWindowController sharedInstance] showModule:noCallModule fullScreen:NO];
}

- (void)_didNotStartCalling:(NSNotification *)notif
{
	NSDictionary *dict = [notif userInfo];
	NSString *address = [dict objectForKey:@"Address"];
	
	// by delaying the display of the callStartFailed message on screen, we allow
	// that all observers of this notification have received the notification
	[self performSelector:@selector(_displayCallStartFailedAlert:) withObject:address afterDelay:0.0];
}

- (void)_didNotEnableH323:(NSNotification *)notif
{
	// same as _didNotStartCalling
	[self performSelector:@selector(_displayEnableH323FailedAlert) withObject:nil afterDelay:0.0];
}

- (void)_didNotRegisterAtGatekeeper:(NSNotification *)notif
{
	// same as _didNotStartCalling
	[self performSelector:@selector(_displayGatekeeperRegistrationFailedAlert) withObject:nil afterDelay:0.0];
}

- (void)_didNotEnableSIP:(NSNotification *)notif
{
	// same as _didNotStartCalling
	[self performSelector:@selector(_displayEnableSIPFailedAlert) withObject:nil afterDelay:0.0];
}

- (void)_didNotRegisterAtSIPRegistrar:(NSNotification *)notif
{
	// same as _didNotStartCalling
	[self performSelector:@selector(_displaySIPRegistrationFailedAlert) withObject:nil afterDelay:0.0];
}

- (void)_frameworkDidClose:(NSNotification *)notif
{
	// Now it's time to terminate the application
	[NSApp replyToApplicationShouldTerminate:YES];
}

#pragma mark Displaying Alerts

- (void)_displayIncomingCallAlert
{
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	
	// show main window on call
	[[XMMainWindowController sharedInstance] showMainWindow];
	
	incomingCallAlert = [[NSAlert alloc] init];
	
	if([preferencesManager alertIncomingCalls] == YES)
	{
		alertType = [preferencesManager incomingCallAlertType];
		
		switch(alertType)
		{
			case XMIncomingCallAlertType_Ringing:
			case XMIncomingCallAlertType_RingOnce:
				incomingCallSound = [[NSSound soundNamed:@"Ringer.aiff"] retain];
				[incomingCallSound setDelegate:self];
				[incomingCallSound play];
				break;
			case XMIncomingCallAlertType_Beep:
				NSBeep();
				break;
			default:
				break;
		}
	}
	
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
	[incomingCallSound stop];
	[incomingCallSound release];
	incomingCallSound = nil;
}

- (void)_displayCallStartFailedAlert:(NSString *)address
{
	NSAlert *alert = [[NSAlert alloc] init];
	
	[alert setMessageText:NSLocalizedString(@"XM_CALL_FAILED_MESSAGE", @"")];
	
	NSString *informativeTextFormat = NSLocalizedString(@"XM_CALL_FAILED_INFO_TEXT", @"");
	NSString *failReasonText;
	
	XMCallStartFailReason failReason = [[XMCallManager sharedInstance] callStartFailReason];
	
	switch(failReason)
	{
		case XMCallStartFailReason_H323NotEnabled:
			failReasonText = NSLocalizedString(@"XM_CALL_FAILED_H323_NOT_ENABLED", @"");
			break;
		case XMCallStartFailReason_GatekeeperRequired:
			failReasonText = NSLocalizedString(@"XM_CALL_FAILED_GK_REQUIRED", @"");
			break;
		case XMCallStartFailReason_SIPNotEnabled:
			failReasonText = NSLocalizedString(@"XM_CALL_FAILED_SIP_NOT_ENABLED", @"");
			break;
		case XMCallStartFailReason_AlreadyInCall:
			failReasonText = NSLocalizedString(@"XM_CALL_FAILED_ALREADY_IN_CALL", @"");
			break;
		default:
			failReasonText = NSLocalizedString(@"XM_UNKNOWN_REASON", @"");
			break;
	}
	
	NSString *informativeText = [[NSString alloc] initWithFormat:informativeTextFormat, address, failReasonText];
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
	
	[alert setMessageText:NSLocalizedString(@"XM_ENABLE_H323_FAILED_MESSAGE", @"")];
	[alert setInformativeText:NSLocalizedString(@"XM_ENABLE_H323_FAILED_INFO_TEXT", @"")];
	
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
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	XMLocation *activeLocation = [preferencesManager activeLocation];
	unsigned h323AccountTag = [activeLocation h323AccountTag];
	XMH323Account *h323Account = [preferencesManager h323AccountWithTag:h323AccountTag];
	NSString *host = [h323Account gatekeeper];
	
	XMGatekeeperRegistrationFailReason failReason = [callManager gatekeeperRegistrationFailReason];
	NSString *reasonText = XMGatekeeperRegistrationFailReasonString(failReason);
	NSString *suggestionText;
	
	switch(failReason)
	{
		case XMGatekeeperRegistrationFailReason_GatekeeperNotFound:
			suggestionText = NSLocalizedString(@"XM_GK_NOT_FOUND_SUGGESTION", @"");
			break;
		case XMGatekeeperRegistrationFailReason_RegistrationReject:
			suggestionText = NSLocalizedString(@"XM_GK_REG_REJECT_SUGGESTION", @"");
			break;
		default:
			suggestionText = @"";
			break;
	}
	
	[alert setMessageText:NSLocalizedString(@"XM_GK_REG_FAILED_MESSAGE", @"")];
	NSString *informativeTextFormat = NSLocalizedString(@"XM_GK_REG_FAILED_INFO_TEXT", @"");

	NSString *informativeText = [[NSString alloc] initWithFormat:informativeTextFormat, host, reasonText, suggestionText];
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

- (void)_displayEnableSIPFailedAlert
{
	NSAlert *alert = [[NSAlert alloc] init];
	
	[alert setMessageText:NSLocalizedString(@"XM_ENABLE_SIP_FAILED_MESSAGE", @"")];
	[alert setInformativeText:NSLocalizedString(@"XM_ENABLE_SIP_FAILED_INFO_TEXT", @"")];
	
	[alert setAlertStyle:NSInformationalAlertStyle];
	[alert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
	[alert addButtonWithTitle:NSLocalizedString(@"Retry", @"")];
	
	int result = [alert runModal];
	
	if(result == NSAlertSecondButtonReturn)
	{
		[[XMCallManager sharedInstance] retryEnableSIP];
	}
	
	[alert release];	
}

- (void)_displaySIPRegistrationFailedAlert
{
	NSAlert *alert = [[NSAlert alloc] init];
	
	XMCallManager *callManager = [XMCallManager sharedInstance];
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	XMLocation *activeLocation = [preferencesManager activeLocation];
	unsigned sipAccountTag = [activeLocation sipAccountTag];
	XMSIPAccount *sipAccount = [preferencesManager sipAccountWithTag:sipAccountTag];
	NSString *host = [sipAccount registrar];
	XMSIPStatusCode failReason = [callManager sipRegistrationFailReasonAtIndex:0];
	
	NSString *reasonText = XMSIPStatusCodeString(failReason);
	
	NSString *suggestionText;
	
	switch(failReason)
	{
		case XMSIPStatusCode_Failure_UnAuthorized:
			suggestionText = NSLocalizedString(@"XM_SIP_UN_AUTHORIZED_SUGGESTION", @"");
			break;
		case XMSIPStatusCode_Failure_NotAcceptable:
			suggestionText = NSLocalizedString(@"XM_SIP_NOT_ACCEPTABLE_SUGGESTION", @"");
			break;
		case XMSIPStatusCode_Failure_BadGateway:
			suggestionText = NSLocalizedString(@"XM_SIP_BAD_GATEWAY_SUGGESTION", @"");
			break;
		default:
			suggestionText = @"";
			break;
	}
	
	[alert setMessageText:NSLocalizedString(@"XM_SIP_REG_FAILED_MESSAGE", @"")];
	NSString *informativeTextFormat = NSLocalizedString(@"XM_SIP_REG_FAILED_INFO_TEXT", @"");
	
	NSString *informativeText = [[NSString alloc] initWithFormat:informativeTextFormat, host, reasonText, suggestionText];
	[alert setInformativeText:informativeText];
	[informativeText release];
	
	[alert setAlertStyle:NSInformationalAlertStyle];
	[alert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
	[alert addButtonWithTitle:NSLocalizedString(@"Retry", @"")];
	
	int result = [alert runModal];
	
	if(result == NSAlertSecondButtonReturn)
	{
		[[XMCallManager sharedInstance] retrySIPRegistrations];
	}
	
	[alert release];
}

- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)didFinish
{
	if(didFinish == YES && alertType == XMIncomingCallAlertType_Ringing)
	{
		[sound play];
	}
}
#pragma mark -
#pragma mark Menu Validation

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	int tag = [menuItem tag];
	XMCallManager *callManager = [XMCallManager sharedInstance];
	BOOL doesAllowModifications = [callManager doesAllowModifications];
	
	if(tag == 310) // retry enable H.323
	{
		if(doesAllowModifications == YES &&
		   [callManager isH323Listening] == NO &&
		   [[[XMPreferencesManager sharedInstance] activeLocation] enableH323] == YES)
		{
			return YES;
		}
		return NO;
	}
	else if(tag == 311) // retry GK Registration
	{
		if(doesAllowModifications == YES &&
		   [callManager gatekeeperRegistrationFailReason] != XMGatekeeperRegistrationFailReason_NoFailure)
		{
			return YES;
		}
		return NO;
	}
	else if(tag == 320) // retry Enable SIP
	{
		if(doesAllowModifications == YES &&
		   [callManager isSIPListening] == NO &&
		   [[[XMPreferencesManager sharedInstance] activeLocation] enableSIP] == YES)
		{
			return YES;
		}
		return NO;
	}
	else if(tag == 321) // retry SIP registration
	{
		if(doesAllowModifications == YES &&
		   [callManager sipRegistrationFailReasonCount] > 0 &&
		   [callManager isRegisteredAtAllRegistrars] == NO)
		{
			return YES;
		}
		return NO;
	}
	else if(tag == 430)
	{
		if([callManager isInCall] &&
		   [[[XMPreferencesManager sharedInstance] activeLocation] enableVideo] == YES)
		{
			return YES;
		}
		
		return NO;
	}
	
	return YES;
}

#pragma mark -
#pragma mark Private Methods

- (void)_showSetupAssistant
{
	[[XMSetupAssistantManager sharedInstance] runFirstApplicationLaunchAssistantWithDelegate:self
			didEndSelector:@selector(_setupApplicationWithLocations:h323Accounts:sipAccounts:)];
}

- (void)_setupApplication
{
	NSArray *array = [NSArray array];
	[self _setupApplicationWithLocations:array
							h323Accounts:nil
							 sipAccounts:nil];
}

- (void)_setupApplicationWithLocations:(NSArray *)locations
						  h323Accounts:(NSArray *)h323Accounts
						   sipAccounts:(NSArray *)sipAccounts
{		
	// registering the call address providers
	[[XMCallHistoryCallAddressProvider sharedInstance] setActiveCallAddressProvider:YES];
	
	[self _preferencesDidChange:nil];
	//[[XMAddressBookCallAddressProvider sharedInstance] setActiveCallAddressProvider:YES];
	
	noCallModule = [[XMNoCallModule alloc] init];
	inCallModule = [[XMInCallModule alloc] init];
	NSArray *mainWindowModules = [[NSArray alloc] initWithObjects:noCallModule, inCallModule, nil];
	[[XMMainWindowController sharedInstance] setModules:mainWindowModules];
	[mainWindowModules release];
	
	infoModule = [[XMInfoModule alloc] init];
	[infoModule setTag:XMInspectorControllerTag_Inspector];
	statisticsModule = [[XMStatisticsModule alloc] init];
	[statisticsModule setTag:XMInspectorControllerTag_Inspector];
	callHistoryModule = [[XMCallHistoryModule alloc] init];
	[callHistoryModule setTag:XMInspectorControllerTag_Inspector];
	NSArray *inspectorModules = [[NSArray alloc] initWithObjects:infoModule, statisticsModule, callHistoryModule, nil];
	[[XMInspectorController inspectorWithTag:XMInspectorControllerTag_Inspector] setModules:inspectorModules];
	[inspectorModules release];
	
	localAudioVideoModule = [[XMLocalAudioVideoModule alloc] init];
	[localAudioVideoModule setTag:XMInspectorControllerTag_Tools];
	dialPadModule = [[XMDialPadModule alloc] init];
	[dialPadModule setTag:XMInspectorControllerTag_Tools];
	NSArray *toolsModules = [[NSArray alloc] initWithObjects:localAudioVideoModule, dialPadModule, nil];
	[[XMInspectorController inspectorWithTag:XMInspectorControllerTag_Tools] setModules:toolsModules];
	[toolsModules release];
	
	addressBookModule = [[XMAddressBookModule alloc] init];
	[addressBookModule setTag:XMInspectorControllerTag_Contacts];
	NSArray *contactsModules = [[NSArray alloc] initWithObjects:addressBookModule, nil];
	[[XMInspectorController inspectorWithTag:XMInspectorControllerTag_Contacts] setModules:contactsModules];
	[contactsModules release];
	
	// start fetching the external address
	XMUtils *utils = [XMUtils sharedInstance];
	[utils startFetchingCheckipExternalAddress];
	
	// causing the PreferencesManager to activate the active location
	// by calling XMCallManager -setActivePreferences:
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	[preferencesManager setH323Accounts:h323Accounts];
	[preferencesManager setSIPAccounts:sipAccounts];
	[preferencesManager setLocations:locations];
	
	if([locations count] != 0)
	{
		[preferencesManager synchronizeAndNotify];
	}
	
	// show the main window
	[[XMMainWindowController sharedInstance] showMainWindow];
	
	// start grabbing from the video sources if needed
	[self _activeLocationDidChange:nil];
	
	incomingCallAlert = nil;
	incomingCallSound = nil;
}

@end
