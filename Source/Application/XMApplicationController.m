/*
 * $Id: XMApplicationController.m,v 1.61 2008/08/14 19:57:05 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
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
#import "XMURICommand.h"

#import "XMMainWindowController.h"
#import "XMNoCallModule.h"
#import "XMInCallModule.h"

#import "XMInspectorController.h"

#import "XMInfoModule.h"
#import "XMStatisticsModule.h"
#import "XMCallHistoryModule.h"

#import "XMLocalAudioVideoModule.h"
#import "XMDialPadModule.h"
#import "XMCallRecorderModule.h"

#import "XMAddressBookModule.h"

//#import "XMZeroConfModule.h"
//#import "XMTextChatModule.h"

#import "XMPreferencesWindowController.h"

#import "XMSetupAssistantManager.h"

#import "XMIncomingCallAlert.h"

@interface XMApplicationController (PrivateMethods)

// preferences management
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
- (void)_sipRegistrationDidFail:(NSNotification *)notif;
- (void)_didStartSubsystemSetup:(NSNotification *)notif;
- (void)_videoManagerDidGetError:(NSNotification *)notif;
- (void)_callRecorderDidGetError:(NSNotification *)notif;

  // terminating the application
- (void)_frameworkClosed:(NSNotification *)notif;

  // displaying dialogs
- (void)_displayIncomingCallAlert;
- (void)_displayCallStartFailedAlert:(NSString *)address;
- (void)_displayEnablingH323FailedAlert;
- (void)_displayGatekeeperRegistrationFailedAlert;
- (void)_displayEnablingSIPFailedAlert;
- (void)_displaySIPRegistrationFailedAlert:(NSNumber *)index;
- (void)_displayVideoManagerErrorAlert;
- (void)_displayCallRecorderErrorAlert;

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
  
  // Initialize the framework
  BOOL enablePTrace = [XMPreferencesManager enablePTrace];
  NSString *pTracePath = nil;
  if(enablePTrace == YES)
  {
    pTracePath = [XMPreferencesManager pTraceFilePath];
  }
  XMInitFramework(pTracePath);
  
  return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notif
{  
  // Ensure that the STUN servers are read, to avoid race conditions
  XMDefaultSTUNServers();
  
  // registering for notifications
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  
  [notificationCenter addObserver:self selector:@selector(_preferencesDidChange:)
                             name:XMNotification_PreferencesManagerDidChangePreferences object:nil];
  [notificationCenter addObserver:self selector:@selector(_didStartSubsystemSetup:)
                             name:XMNotification_CallManagerDidStartSubsystemSetup object:nil];
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
  [notificationCenter addObserver:self selector:@selector(_sipRegistrationDidFail:)
                             name:XMNotification_CallManagerDidNotSIPRegister object:nil];
  [notificationCenter addObserver:self selector:@selector(_frameworkDidClose:)
                             name:XMNotification_FrameworkDidClose object:nil];
  [notificationCenter addObserver:self selector:@selector(_videoManagerDidGetError:)
                             name:XMNotification_VideoManagerDidGetError object:nil];
  [notificationCenter addObserver:self selector:@selector(_callRecorderDidGetError:)
                             name:XMNotification_CallRecorderDidGetError object:nil];
  
  // depending on wheter preferences are in the system, the setup assistant is shown or not.
  if([XMPreferencesManager doesHavePreferences] == YES)
  {
    [self performSelector:@selector(_setupApplication) withObject:nil afterDelay:0.0];
  }
  else
  {
    [self performSelector:@selector(_showSetupAssistant) withObject:nil afterDelay:0.0];
  }
  
  // ensuring that the address book manager is initialized
  [XMAddressBookManager sharedInstance];
}

- (void)dealloc
{
  [noCallModule release];
  [inCallModule release];
  
  [infoModule release];
  [statisticsModule release];
  [callHistoryModule release];
  
  [localAudioVideoModule release];
  [dialPadModule release];
  [callRecorderModule release];
  
  [addressBookModule release];
  
  //[zeroConfModule release];
  //[textChatModule release];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [super dealloc];
}

#pragma mark -
#pragma mark Action Methods

- (IBAction)showPreferences:(id)sender
{
  [[XMPreferencesWindowController sharedInstance] showPreferencesWindow];
}

- (IBAction)updateDeviceLists:(id)sender
{
  [[XMAudioManager sharedInstance] updateDeviceLists];
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
  [utils updateNetworkInformation];
  
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
  XMSetupAssistantManager *manager = [XMSetupAssistantManager sharedInstance];
  
  if (![manager isWindowLoaded] || ![[manager window] isVisible])
  {
    [[XMMainWindowController sharedInstance] showMainWindow];
  }
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
  
  // Prevents the Application from waiting infinitely if the framework hangs somewhere
  NSTimer *timer = [NSTimer timerWithTimeInterval:10.0 target:self selector:@selector(_frameworkDidClose:)
                                         userInfo:nil repeats:NO];
  // need to use this run loop mode since at the moment this method is called, the application
  // is no longer in the default run loop mode
  [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSModalPanelRunLoopMode];
  
  // wait for the FrameworkDidClose notification before terminating.
  return NSTerminateLater;
}

#pragma mark -
#pragma mark Services implementation

- (void)handleServicesString:(NSPasteboard *)pboard
                    userData:(NSString *)userData
                       error:(NSString **)error
{
  NSArray *types;
  NSString *pboardString;
  
  types = [pboard types];
  if(![types containsObject:NSStringPboardType])
  {
    *error = @"No pboard string";
    return;
  }
  pboardString = [pboard stringForType:NSStringPboardType];
  if(!pboardString)
  {
    *error = @"No pboard string";
    return;
  }
  
  *error = [XMURICommand tryToCallAddress:pboardString];
}

#pragma mark -
#pragma mark Notification Methods

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
  if(activeAlert != nil)
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

- (void)_sipRegistrationDidFail:(NSNotification *)notif
{
  // same as _didNotStartCalling
  [self performSelector:@selector(_displaySIPRegistrationFailedAlert:) withObject:[notif object] afterDelay:0.0];
}

- (void)_didStartSubsystemSetup:(NSNotification *)notif
{
  if(activeAlert != nil)
  {
    [NSApp abortModal];
  }
}

- (void)_frameworkDidClose:(NSNotification *)notif
{
  // Now it's time to terminate the application
  [NSApp replyToApplicationShouldTerminate:YES];
}

- (void)_videoManagerDidGetError:(NSNotification *)notif
{
  // same as _didNotStartCalling
  [self performSelector:@selector(_displayVideoManagerErrorAlert) withObject:nil afterDelay:0.0];
}

- (void)_callRecorderDidGetError:(NSNotification *)notif
{
  // same as _didNotStartCalling
  [self performSelector:@selector(_displayCallRecorderErrorAlert) withObject:nil afterDelay:0.0];
}

#pragma mark -
#pragma mark Displaying Alerts

- (void)_displayIncomingCallAlert
{
  XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
  
  // show main window on call
  [[XMMainWindowController sharedInstance] showMainWindow];
  
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
  
  XMCallInfo *activeCall = [[XMCallManager sharedInstance] activeCall];
  
  // make sure no other alerts are present
  if(activeAlert != nil)
  {
    [NSApp abortModal];
  }
  
  activeAlert = [[XMIncomingCallAlert alloc] initWithCallInfo:activeCall];
  
  int result = [(XMIncomingCallAlert *)activeAlert runModal];
  
  if(result == NSAlertFirstButtonReturn)
  {
    [[XMCallManager sharedInstance] acceptIncomingCall];
  }
  else if(result == NSAlertSecondButtonReturn)
  {
    [[XMCallManager sharedInstance] rejectIncomingCall];
  }
  
  [activeAlert release];
  activeAlert = nil;
  [incomingCallSound stop];
  [incomingCallSound release];
  incomingCallSound = nil;
}

- (void)_displayCallStartFailedAlert:(NSString *)address
{
  activeAlert = [[NSAlert alloc] init];
  
  [(NSAlert *)activeAlert setMessageText:NSLocalizedString(@"XM_CALL_FAILED_MESSAGE", @"")];
  
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
    case XMCallStartFailReason_SIPRegistrationRequired:
      failReasonText = NSLocalizedString(@"XM_CALL_FAILED_SIP_REGISTRATION_REQUIRED", @"");
      break;
    case XMCallStartFailReason_AlreadyInCall:
      failReasonText = NSLocalizedString(@"XM_CALL_FAILED_ALREADY_IN_CALL", @"");
      break;
    case XMCallStartFailReason_TransportFail:
      failReasonText = NSLocalizedString(@"XM_CALL_FAILED_TRANSPORT_FAIL", @"");
      break;
    case XMCallStartFailReason_NoNetworkInterfaces:
      failReasonText = NSLocalizedString(@"XM_NO_NETWORK_INTERFACES", @"");
      break;
    default:
      failReasonText = [NSString stringWithFormat:NSLocalizedString(@"XM_UNKNOWN_REASON", @""), failReason];
      break;
  }
  
  NSString *informativeText = [[NSString alloc] initWithFormat:informativeTextFormat, address, failReasonText];
  [(NSAlert *)activeAlert setInformativeText:informativeText];
  [informativeText release];
  
  [(NSAlert *)activeAlert setAlertStyle:NSInformationalAlertStyle];
  [(NSAlert *)activeAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
  
  [(NSAlert *)activeAlert runModal];
  
  [activeAlert release];
  activeAlert = nil;
}

- (void)_displayEnableH323FailedAlert
{
  activeAlert = [[NSAlert alloc] init];
  
  [(NSAlert *)activeAlert setMessageText:NSLocalizedString(@"XM_ENABLE_H323_FAILED_MESSAGE", @"")];
  [(NSAlert *)activeAlert setInformativeText:NSLocalizedString(@"XM_ENABLE_H323_FAILED_INFO_TEXT", @"")];
  
  [(NSAlert *)activeAlert setAlertStyle:NSInformationalAlertStyle];
  [(NSAlert *)activeAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
  [(NSAlert *)activeAlert addButtonWithTitle:NSLocalizedString(@"Retry", @"")];
  
  int result = [(NSAlert *)activeAlert runModal];
  
  if(result == NSAlertSecondButtonReturn)
  {
    [[XMCallManager sharedInstance] retryEnableH323];
  }
  
  [activeAlert release];
  activeAlert = nil;
}

- (void)_displayGatekeeperRegistrationFailedAlert
{
  activeAlert = [[NSAlert alloc] init];
  
  XMCallManager *callManager = [XMCallManager sharedInstance];
  XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
  XMLocation *activeLocation = [preferencesManager activeLocation];
  unsigned h323AccountTag = [activeLocation h323AccountTag];
  XMH323Account *h323Account = [preferencesManager h323AccountWithTag:h323AccountTag];
  NSString *host = [h323Account gatekeeperHost];
  
  XMGatekeeperRegistrationFailReason failReason = [callManager gatekeeperRegistrationFailReason];
  NSString *reasonText = XMGatekeeperRegistrationFailReasonString(failReason);
  NSString *suggestionText;
  
  switch(failReason)
  {
    case XMGatekeeperRegistrationFailReason_GatekeeperNotFound:
      suggestionText = NSLocalizedString(@"XM_GK_NOT_FOUND_SUGGESTION", @"");
      break;
    case XMGatekeeperRegistrationFailReason_DuplicateAlias:
      suggestionText = NSLocalizedString(@"XM_GK_DUPLICATE_ALIAS_SUGGESTION", @"");
      break;
    case XMGatekeeperRegistrationFailReason_SecurityDenied:
      suggestionText = NSLocalizedString(@"XM_GK_SECURITY_DENIED_SUGGESTION", @"");
      break;
    case XMGatekeeperRegistrationFailReason_UnregisteredByGatekeeper:
      suggestionText = NSLocalizedString(@"XM_GK_UNREG_BY_GK_SUGGESTION", @"");
      break;
    default:
      suggestionText = @"";
      break;
  }
  
  [(NSAlert *)activeAlert setMessageText:NSLocalizedString(@"XM_GK_REG_FAILED_MESSAGE", @"")];
  NSString *informativeTextFormat = NSLocalizedString(@"XM_GK_REG_FAILED_INFO_TEXT", @"");
  
  NSString *informativeText = [[NSString alloc] initWithFormat:informativeTextFormat, host, reasonText, suggestionText];
  [(NSAlert *)activeAlert setInformativeText:informativeText];
  [informativeText release];
  
  [(NSAlert *)activeAlert setAlertStyle:NSInformationalAlertStyle];
  [(NSAlert *)activeAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
  [(NSAlert *)activeAlert addButtonWithTitle:NSLocalizedString(@"Retry", @"")];
  
  int result = [(NSAlert *)activeAlert runModal];
  
  if(result == NSAlertSecondButtonReturn)
  {
    [[XMCallManager sharedInstance] retryGatekeeperRegistration];
  }
  
  [activeAlert release];
  activeAlert = nil;
}

- (void)_displayEnableSIPFailedAlert
{
  activeAlert = [[NSAlert alloc] init];
  
  [(NSAlert *)activeAlert setMessageText:NSLocalizedString(@"XM_ENABLE_SIP_FAILED_MESSAGE", @"")];
  [(NSAlert *)activeAlert setInformativeText:NSLocalizedString(@"XM_ENABLE_SIP_FAILED_INFO_TEXT", @"")];
  
  [(NSAlert *)activeAlert setAlertStyle:NSInformationalAlertStyle];
  [(NSAlert *)activeAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
  [(NSAlert *)activeAlert addButtonWithTitle:NSLocalizedString(@"Retry", @"")];
  
  int result = [(NSAlert *)activeAlert runModal];
  
  if(result == NSAlertSecondButtonReturn)
  {
    [[XMCallManager sharedInstance] retryEnableSIP];
  }
  
  [activeAlert release];
  activeAlert = nil;
}

- (void)_displaySIPRegistrationFailedAlert:(NSNumber *)indexNumber
{
  activeAlert = [[NSAlert alloc] init];
  
  XMCallManager *callManager = [XMCallManager sharedInstance];
  XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
  XMLocation *activeLocation = [preferencesManager activeLocation];
  unsigned index = [indexNumber unsignedIntValue];
  unsigned sipAccountTag = [(NSNumber *)[[activeLocation sipAccountTags] objectAtIndex:index] unsignedIntValue];
  XMSIPAccount *sipAccount = [preferencesManager sipAccountWithTag:sipAccountTag];
  NSString *domain = [sipAccount domain];
  XMSIPStatusCode failReason = [callManager sipRegistrationFailReasonAtIndex:index];
  
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
  
  [(NSAlert *)activeAlert setMessageText:NSLocalizedString(@"XM_SIP_REG_FAILED_MESSAGE", @"")];
  NSString *informativeTextFormat = NSLocalizedString(@"XM_SIP_REG_FAILED_INFO_TEXT", @"");
  
  NSString *informativeText = [[NSString alloc] initWithFormat:informativeTextFormat, domain, reasonText, suggestionText];
  [(NSAlert *)activeAlert setInformativeText:informativeText];
  [informativeText release];
  
  [(NSAlert *)activeAlert setAlertStyle:NSInformationalAlertStyle];
  [(NSAlert *)activeAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
  [(NSAlert *)activeAlert addButtonWithTitle:NSLocalizedString(@"Retry", @"")];
  
  int result = [(NSAlert *)activeAlert runModal];
  
  if(result == NSAlertSecondButtonReturn)
  {
    [[XMCallManager sharedInstance] retrySIPRegistrations];
  }
  
  [activeAlert release];
  activeAlert = nil;
}

- (void)_displayVideoManagerErrorAlert
{
  NSString *errorDescription = [[XMVideoManager sharedInstance] errorDescription];
  if (errorDescription == nil)
  {
    errorDescription = @"";
  }
  
  activeAlert = [[NSAlert alloc] init];
  
  [(NSAlert *)activeAlert setMessageText:NSLocalizedString(@"XM_VIDEO_DEVICE_PROBLEM_MESSAGE", @"")];
  [(NSAlert *)activeAlert setInformativeText:errorDescription];
  
  [(NSAlert *)activeAlert setAlertStyle:NSInformationalAlertStyle];
  [(NSAlert *)activeAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
  
  [(NSAlert *)activeAlert runModal];
  
  [activeAlert release];
  activeAlert = nil;
}

- (void)_displayCallRecorderErrorAlert
{
  activeAlert = [[NSAlert alloc] init];
  NSString *errorDescription = [[XMCallRecorder sharedInstance] errorDescription];
  
  [(NSAlert *)activeAlert setMessageText:NSLocalizedString(@"XM_CALL_RECORDER_ERROR_MESSAGE", @"")];
  NSString *infoTextFormat = NSLocalizedString(@"XM_CALL_RECORDER_ERROR_INFO_TEXT", @"");
  NSString *infoText = [[NSString alloc] initWithFormat:infoTextFormat, errorDescription];
  [(NSAlert *)activeAlert setInformativeText:infoText];
  [infoText release];
  
  [(NSAlert *)activeAlert setAlertStyle:NSInformationalAlertStyle];
  [(NSAlert *)activeAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
  
  [(NSAlert *)activeAlert runModal];
  
  [activeAlert release];
  activeAlert = nil;
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
       [callManager isCompletelySIPRegistered] == NO)
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
  [self _preferencesDidChange:nil];
  [[XMCallHistoryCallAddressProvider sharedInstance] setActiveCallAddressProvider:YES];
  
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
  callRecorderModule = [[XMCallRecorderModule alloc] init];
  [callRecorderModule setTag:XMInspectorControllerTag_Tools];
  NSArray *toolsModules = [[NSArray alloc] initWithObjects:localAudioVideoModule, dialPadModule, callRecorderModule, nil];
  [[XMInspectorController inspectorWithTag:XMInspectorControllerTag_Tools] setModules:toolsModules];
  [toolsModules release];
  
  addressBookModule = [[XMAddressBookModule alloc] init];
  [addressBookModule setTag:XMInspectorControllerTag_Contacts];
  NSArray *contactsModules = [[NSArray alloc] initWithObjects:addressBookModule, nil];
  [[XMInspectorController inspectorWithTag:XMInspectorControllerTag_Contacts] setModules:contactsModules];
  [contactsModules release];
  
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
  [[XMMainWindowController sharedInstance] showModule:noCallModule fullScreen:NO];
  
  activeAlert = nil;
  incomingCallSound = nil;
  
  // Enable the services menu
  [NSApp setServicesProvider:self];
}

@end
