/*
 * $Id: XMCallManager.m,v 1.54 2008/08/29 11:32:29 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#import <AppKit/AppKit.h>

#import "XMTypes.h"
#import "XMStringConstants.h"
#import "XMPrivate.h"
#import "XMCallManager.h"
#import "XMOpalDispatcher.h"
#import "XMUtils.h"
#import "XMCallInfo.h"
#import "XMPreferences.h"
#import "XMPreferencesCodecListRecord.h"
#import "XMPreferencesRegistrationRecord.h"
#import "XMAddressResource.h"
#import "XMBridge.h"

// Call Manager State
enum {
  Ready,
  SubsystemSetup,
  PreparingCall,
  InCall,
  TerminatingCall,
  WaitingForCheckipAddress,
};

// System Sleep State
enum {
  Awake = 0,
  EnterSleep,
  Asleep,
};

@interface XMCallManager (PrivateMethods)

- (void)_doSubsystemSetupWithPreferences:(XMPreferences *)preferences;
- (void)_didEndFetchingExternalAddress:(NSNotification *)notif;

- (void)_initiateCall:(XMAddressResource *)addressResource;
- (void)_initiateSpecificCall:(XMGeneralPurposeAddressResource *)addressResource;

- (NSString *)_prepareCallInitiation:(XMAddressResource *)addressResource;

- (void)_storeCall:(XMCallInfo *)callInfo;

- (void)_didFinishLaunching:(NSNotification *)notif;
- (void)_willSleep:(NSNotification *)notif;
- (void)_didWakeup:(NSNotification *)notif;

+ (void)_updateLocalAddressInterfaceForCall:(XMCallInfo *)callInfo;

@end

@implementation XMCallManager

/**
* This code uses the following policy to ensure
 * data consistency:
 * all changes in the callInfo instance activeCall
 * happen on the main thread.
 **/

#pragma mark Class Methods

+ (XMCallManager *)sharedInstance
{	
  if (_XMCallManagerSharedInstance == nil)
  {
    NSLog(@"Attempt to acces XMCallManager prior to initialization");
  }
  
  return _XMCallManagerSharedInstance;
}

#pragma mark -
#pragma mark Init & Deallocation Methods

- (id)init
{
  [self doesNotRecognizeSelector:_cmd];
  [self release];
  
  return nil;
}

- (id)_initWithPTracePath:(NSString *)path
{
  self = [super init];
  
  state = Ready;
  
  activePreferences = [[XMPreferences alloc] init];
  automaticallyAcceptIncomingCalls = NO;
  
  activeCall = nil;
  needsSubsystemSetupAfterCallEnd = NO;
  callStartFailReason = XMCallStartFailReason_NoFailure;
  canSendCameraEvents = NO;
  
  gatekeeperName = nil;
  terminalAliases = nil;
  gatekeeperRegistrationStatus = XMGatekeeperRegistrationStatus_NotRegistered;
  
  sipRegistrations = [[NSMutableArray alloc] initWithCapacity:1];
  sipRegistrationStates = [[NSMutableArray alloc] initWithCapacity:1];
  
  recentCalls = [[NSMutableArray alloc] initWithCapacity:10];
  
  networkConfigurationChanged = YES;
  systemSleepStatus = Awake;
  h323ProtocolStatus = XMProtocolStatus_Disabled;
  sipProtocolStatus = XMProtocolStatus_Disabled;
  
  pTracePath = [path copy];
  
  // Registering notifications
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  [notificationCenter addObserver:self selector:@selector(_didFinishLaunching:)
                             name:NSApplicationDidFinishLaunchingNotification object:nil];
  
  // track when the system is going to sleep
  // Use NSWorkspace's notification center for these notifications
  notificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
  [notificationCenter addObserver:self selector:@selector(_willSleep:)
                             name:NSWorkspaceWillSleepNotification object:nil];
  [notificationCenter addObserver:self selector:@selector(_didWake:)
                             name:NSWorkspaceDidWakeNotification object:nil];
  
  return self;
}

- (void)_close
{
  [activePreferences release];
  activePreferences = nil;
  
  [activeCall release];
  activeCall = nil;
  
  [gatekeeperName release];
  gatekeeperName = nil;
  
  [terminalAliases release];
  terminalAliases = nil;
  
  [sipRegistrations release];
  sipRegistrations = nil;
  
  [sipRegistrationStates release];
  sipRegistrationStates = nil;

  [recentCalls release];
  recentCalls = nil;
  
  [pTracePath release];
  pTracePath = nil;
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
}

- (void)dealloc
{	
  [self _close];
  
  [super dealloc];
}

#pragma mark -
#pragma mark General Configuration

- (BOOL)doesAllowModifications
{
  return (state == Ready);
}

- (BOOL)isH323Enabled
{
  return (h323ProtocolStatus == XMProtocolStatus_Enabled);
}

- (XMProtocolStatus)h323ProtocolStatus
{
  return h323ProtocolStatus;
}

- (BOOL)isSIPEnabled
{
  return (sipProtocolStatus == XMProtocolStatus_Enabled);
}

- (XMProtocolStatus)sipProtocolStatus
{
  return sipProtocolStatus;
}

- (XMPreferences *)activePreferences
{
  return [[activePreferences copy] autorelease];
}

- (void)setActivePreferences:(XMPreferences *)prefs
{	
  if (prefs == nil) {
    [NSException raise:XMException_InvalidParameter format:XMExceptionReason_InvalidParameterMustNotBeNil];
    return;
  }
  if (state != Ready) {
    [NSException raise:XMException_InvalidAction format:XMExceptionReason_CallManagerInvalidActionIfInSubsystemSetupOrInCall];
    return;
  }
  
  XMPreferences *old = activePreferences;
  activePreferences = [prefs copy];
  [old release];
  
  [self _doSubsystemSetupWithPreferences:activePreferences];
}

#pragma mark -
#pragma mark Call management methods

- (BOOL)isInCall
{
  switch (state) {
    case PreparingCall:
    case InCall:
    case TerminatingCall:
      return YES;
    default:
      return NO;
  }
}

- (XMCallInfo *)activeCall
{
  return activeCall;
}

- (void)makeCall:(XMAddressResource *)addressResource;
{	
  // invalid action checks
  if (state != Ready) {
    [NSException raise:XMException_InvalidAction format:XMExceptionReason_CallManagerInvalidActionIfInSubsystemSetupOrInCall];
    return;
  }
  
  // special check for preference-modifying address resources
  if ([addressResource isKindOfClass:[XMGeneralPurposeAddressResource class]]) {
    XMGeneralPurposeAddressResource *resource = (XMGeneralPurposeAddressResource *)addressResource;
    
    if ([resource _doesModifyPreferences:activePreferences]) {
      [self _initiateSpecificCall:resource];
      return;
    }
  }
  
  [self _initiateCall:addressResource];
}

- (XMCallStartFailReason)callStartFailReason
{
  return callStartFailReason;
}

- (void)acceptIncomingCall
{
  if (activeCall == nil) {
    [NSException raise:XMException_InvalidAction format:XMExceptionReason_CallManagerInvalidActionIfNotInCall];
    return;
  }
  
  if ([activeCall callStatus] != XMCallStatus_Incoming) {
    [NSException raise:XMException_InvalidAction format:XMExceptionReason_CallManagerInvalidActionIfCallStatusNotIncoming];
    return;
  }
  
  unsigned callID = [activeCall _callID];
  [XMOpalDispatcher _acceptIncomingCall:callID];
}

- (void)rejectIncomingCall
{
  if (activeCall == nil) {
    [NSException raise:XMException_InvalidAction format:XMExceptionReason_CallManagerInvalidActionIfNotInCall];
    return;
  }
  
  if ([activeCall callStatus] != XMCallStatus_Incoming) {
    [NSException raise:XMException_InvalidAction format:XMExceptionReason_CallManagerInvalidActionIfCallStatusNotIncoming];
    return;
  }
  
  unsigned callID = [activeCall _callID];
  [XMOpalDispatcher _rejectIncomingCall:callID];
}

- (void)clearActiveCall
{
  if (activeCall == nil) {
    [NSException raise:XMException_InvalidAction format:XMExceptionReason_CallManagerInvalidActionIfNotInCall];
    return;
  }
  
  if (state == TerminatingCall) { // already terminating the call, no need to do anything
    return;
  }
  
  state = TerminatingCall;
  
  unsigned callID = [activeCall _callID];
  [activeCall _setCallStatus:XMCallStatus_Terminating];
  [XMOpalDispatcher _clearCall:callID];
}

- (unsigned)recentCallsCount
{
  return [recentCalls count];
}

- (XMCallInfo *)recentCallAtIndex:(unsigned)index
{
  return (XMCallInfo *)[recentCalls objectAtIndex:index];
}

- (NSArray *)recentCalls
{
  NSArray *recentCallsCopy = [recentCalls copy];
  return [recentCallsCopy autorelease];
}

#pragma mark -
#pragma mark H.323-specific Methods

- (BOOL)isGatekeeperRegistered
{
  return gatekeeperName != nil;
}

- (NSString *)gatekeeperName
{
  return gatekeeperName;
}

- (NSArray *)terminalAliases
{
  return terminalAliases;
}

- (XMGatekeeperRegistrationStatus)gatekeeperRegistrationStatus
{
  return gatekeeperRegistrationStatus;
}

#pragma mark -
#pragma mark SIP specific Methods

- (BOOL)isCompletelySIPRegistered
{
  unsigned count = [sipRegistrationStates count];
  if (count == 0) { // no registrations at all
    return NO;
  }
  
  BOOL didRegisterAll = YES;
  for (unsigned i = 0; i < count; i++) {
    NSNumber *number = (NSNumber *)[sipRegistrationStates objectAtIndex:i];
    XMSIPStatusCode failReason = (XMSIPStatusCode)[number unsignedIntValue];
    if (failReason != XMSIPStatusCode_Successful_OK) {
      didRegisterAll = NO;
      break;
    }
  }
  
  return didRegisterAll;
}

- (unsigned)sipRegistrationCount
{
  return [sipRegistrations count];
}

- (NSString *)sipRegistrationAtIndex:(unsigned)index
{
  return (NSString *)[sipRegistrations objectAtIndex:index];
}

- (NSArray *)sipRegistrations
{
  NSArray *sipRegistrationsCopy = [sipRegistrations copy];
  return [sipRegistrationsCopy autorelease];
}

- (unsigned)sipRegistrationStatusCount
{
  return [sipRegistrationStates count];
}

- (XMSIPStatusCode)sipRegistrationStatusAtIndex:(unsigned)index
{
  NSNumber *number = (NSNumber *)[sipRegistrationStates objectAtIndex:index];
  return (XMSIPStatusCode)[number unsignedIntValue];
}

- (NSArray *)sipRegistrationStates
{
  NSArray *copy = [sipRegistrationStates copy];
  return [copy autorelease];
}

#pragma mark -
#pragma mark InCall Methods

- (void)setUserInputMode:(XMUserInputMode) userInputMode
{
  [XMOpalDispatcher _setUserInputMode:userInputMode];
}

- (void)sendUserInputTone:(char)tone
{
  if (state != InCall) {
    [NSException raise:XMException_InvalidAction format:XMExceptionReason_CallManagerInvalidActionIfNotInCall];
    return;
  }
  
  unsigned callID = [activeCall _callID];
  [XMOpalDispatcher _sendUserInputToneForCall:callID tone:tone];
}

- (void)sendUserInputString:(NSString *)string
{
  if (state != InCall) {
    [NSException raise:XMException_InvalidAction format:XMExceptionReason_CallManagerInvalidActionIfNotInCall];
    return;
  }
  
  unsigned callID = [activeCall _callID];
  [XMOpalDispatcher _sendUserInputStringForCall:callID string:string];
}

- (BOOL)canSendCameraEvents
{
  return canSendCameraEvents;
}

- (void)startCameraEvent:(XMCameraEvent)cameraEvent
{
  if (state != InCall) {
    [NSException raise:XMException_InvalidAction format:XMExceptionReason_CallManagerInvalidActionIfNotInCall];
    return;
  }
  
  unsigned callID = [activeCall _callID];
  [XMOpalDispatcher _startCameraEventForCall:callID event:cameraEvent];
}

- (void)stopCameraEvent
{
  if (state != InCall) {
    [NSException raise:XMException_InvalidAction format:XMExceptionReason_CallManagerInvalidActionIfNotInCall];
    return;
  }
  
  unsigned callID = [activeCall _callID];
  [XMOpalDispatcher _stopCameraEventForCall:callID];
}

#pragma mark -
#pragma mark Framework Methods

- (void)_handleSubsystemSetupEnd
{
  // if the subsystem setup was done right after a call
  // ended, it's time to go back into the Ready state
  if (needsSubsystemSetupAfterCallEnd == YES) {
    state = Ready;
    
    needsSubsystemSetupAfterCallEnd = NO;
    
    [self _storeCall:activeCall];
    [activeCall release];
    activeCall = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidClearCall object:self];
    
  } else if (state == SubsystemSetup) { // protect against multiple invocations
    state = Ready;
    [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidEndSubsystemSetup object:self];
  }
  
  // if the gatekeeper registration status did not change, but remains in an error state, still post a notification.
  // parameters may have changed, but registration was still not successful
  if (gatekeeperRegistrationStatus == gatekeeperRegistrationStatusBeforeSubsystemSetup &&
      gatekeeperRegistrationStatus != XMGatekeeperRegistrationStatus_NotRegistered &&
      gatekeeperRegistrationStatus != XMGatekeeperRegistrationStatus_SuccessfullyRegistered) {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter postNotificationName:XMNotification_CallManagerDidNotRegisterAtGatekeeper object:self];
    [notificationCenter postNotificationName:XMNotification_CallManagerDidChangeGatekeeperRegistrationStatus object:self];
  }
  
  // if system is going to sleep, tell that it is okay
  if (systemSleepStatus == EnterSleep) {
    systemSleepStatus = Asleep;
  }
}

- (void)_handleCallInitiated:(XMCallInfo *)call
{
  if (activeCall != nil) { // logic inconsistency
    NSLog(@"Call initiated while active call not nil!");
    [activeCall release];
    activeCall = nil;
  }
  activeCall = [call retain];
  
  state = InCall;
  [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidStartCalling object:self];
}

- (void)_handleCallInitiationFailed:(NSArray *)info
{
  NSNumber *number = (NSNumber *)[info objectAtIndex:0];
  callStartFailReason = (XMCallStartFailReason)[number unsignedIntValue];
  
  NSString *address = (NSString *)[info objectAtIndex:1];
  
  state = Ready;
  needsSubsystemSetupAfterCallEnd = NO; // call initiation fails before the subsystem state is modified
  
  NSDictionary *infoDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:address, @"Address", nil];
  [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidNotStartCalling object:self userInfo:infoDictionary];
  [infoDictionary release];
}

- (void)_handleCallIsAlerting
{
  [activeCall _setCallStatus:XMCallStatus_Ringing];
  [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidStartRingingAtRemoteParty object:self];
}

- (void)_handleIncomingCall:(XMCallInfo *)call
{
  if (activeCall != nil) { // logic inconsistency
    NSLog(@"incoming call with non-nil active call");
    [activeCall release];
    activeCall = nil;
  }
  activeCall = [call retain];
  
  [XMCallManager _updateLocalAddressInterfaceForCall:activeCall];
  
  state = InCall;
  
  if (automaticallyAcceptIncomingCalls == YES) {
    [XMOpalDispatcher _acceptIncomingCall:[activeCall _callID]];
  } else {
    [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidReceiveIncomingCall object:self];
  }
}

- (void)_handleCallEstablished:(NSArray *)remotePartyInformations
{
  [activeCall _setCallStatus:XMCallStatus_Active];
  
  // the remote party information is not known before if there is an outgoing call:
  // update the information here
  if ([activeCall isOutgoingCall]) {
    NSString *remoteName = (NSString *)[remotePartyInformations objectAtIndex:0];
    NSString *remoteNumber = (NSString *)[remotePartyInformations objectAtIndex:1];
    NSString *remoteAddress = (NSString *)[remotePartyInformations objectAtIndex:2];
    NSString *remoteApplication = (NSString *)[remotePartyInformations objectAtIndex:3];
    NSString *localAddress = (NSString *)[remotePartyInformations objectAtIndex:4];
    
    [activeCall _setRemoteName:remoteName];
    [activeCall _setRemoteNumber:remoteNumber];
    [activeCall _setRemoteAddress:remoteAddress];
    [activeCall _setRemoteApplication:remoteApplication];
    [activeCall _setLocalAddress:localAddress];
    
    [XMCallManager _updateLocalAddressInterfaceForCall:activeCall];
  }
  
  [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidEstablishCall
                                                      object:self];
}

+ (void)_updateLocalAddressInterfaceForCall:(XMCallInfo *)call
{
  NSString *localAddress = [call localAddress];
  NSString *localAddressInterface;
  
  if (localAddress == nil) {
    return;
  }
  
  NSArray *networkInterfaces = [_XMUtilsSharedInstance networkInterfaces];
  unsigned count = [networkInterfaces count];
  BOOL found = NO;
  for (unsigned i = 0; i < count; i++) {
    XMNetworkInterface *networkInterface = (XMNetworkInterface *)[networkInterfaces objectAtIndex:i];
    if ([[networkInterface ipAddress] isEqualToString:localAddress]) {
      localAddressInterface = [networkInterface name];
      found = YES;
      break;
    }
  }
  if (found == NO) {
    NSString *publicAddress = [_XMUtilsSharedInstance publicAddress];
    
    if ([localAddress isEqualToString:publicAddress]) {
      localAddressInterface = XMPublicInterface;
    } else {
      localAddressInterface = XMUnknownInterface;
    }
  }
  [call _setLocalAddressInterface:localAddressInterface];
}

- (void)_handleCallCleared:(NSNumber *)callEndReason
{
  canSendCameraEvents = NO;
  
  XMCallEndReason reason = (XMCallEndReason)[callEndReason unsignedIntValue];
  [activeCall _setCallStatus:XMCallStatus_Ended];
  
  // Adjust some misleading call end reason values
  if (reason == XMCallEndReason_EndedByConnectFail && [activeCall protocol] == XMCallProtocol_SIP) {
    reason = XMCallEndReason_EndedByUnreachable;
  }
  
  [activeCall _setCallEndReason:reason];
  
  if (needsSubsystemSetupAfterCallEnd == YES) {
    [self _doSubsystemSetupWithPreferences:activePreferences];
  } else {
    [self _storeCall:activeCall];
    [activeCall release];
    activeCall = nil;
    
    state = Ready;
    [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidClearCall
                                                        object:self];
  }
}

- (void)_handleLocalAddress:(NSString *)address
{
  if ([activeCall localAddress] == nil)
  {
    [activeCall _setLocalAddress:address];
    
    [XMCallManager _updateLocalAddressInterfaceForCall:activeCall];
  }
}

- (void)_handleCallStatisticsUpdate:(XMCallStatistics *)updatedStatistics
{
  [activeCall _updateCallStatistics:updatedStatistics];
  [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidUpdateCallStatistics object:self];
}

- (void)_handleOutgoingAudioStreamOpened:(NSString *)codec
{
  if ([activeCall isSendingAudio]) { // protection if the callback is called multiple times
    return;
  }
  
  [activeCall _setOutgoingAudioCodec:codec];
  [activeCall _setIsSendingAudio:YES];
  [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidOpenOutgoingAudioStream object:self];
}

- (void)_handleIncomingAudioStreamOpened:(NSString *)codec
{
  if ([activeCall isReceivingAudio]) { // protection if the callback is called multiple times
    return;
  }
  
  [activeCall _setIncomingAudioCodec:codec];
  [activeCall _setIsReceivingAudio:YES];
  [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidOpenIncomingAudioStream object:self];
}

- (void)_handleOutgoingVideoStreamOpened:(NSString *)codec
{
  if ([activeCall isSendingVideo]) { // protection if the callback is called multiple times
    return;
  }
  
  [activeCall _setOutgoingVideoCodec:codec];
  [activeCall _setIsSendingVideo:YES];
  [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidOpenOutgoingVideoStream object:self];
}

- (void)_handleIncomingVideoStreamOpened:(NSString *)codec
{
  if ([activeCall isReceivingVideo]) { // protection if the callback is called multiple times
    return;
  }
  
  [activeCall _setIncomingVideoCodec:codec];
  [activeCall _setIsReceivingVideo:YES];
  [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidOpenIncomingVideoStream object:self];
}

- (void)_handleOutgoingAudioStreamClosed
{
  [activeCall _setIsSendingAudio:NO];
  [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidCloseOutgoingAudioStream object:self];
}

- (void)_handleIncomingAudioStreamClosed
{
  [activeCall _setIsReceivingAudio:NO];
  [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidCloseIncomingAudioStream object:self];
}

- (void)_handleOutgoingVideoStreamClosed
{
  [activeCall _setIsSendingVideo:NO];
  [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidCloseOutgoingVideoStream object:self];
}

- (void)_handleIncomingVideoStreamClosed
{
  [activeCall _setIsReceivingVideo:NO];
  [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidCloseIncomingVideoStream object:self];
}

- (void)_handleFECCChannelOpened
{
  if (canSendCameraEvents == NO) { // protection against calling this multiple times
    canSendCameraEvents = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidOpenFECCChannel object:self];
  }
}

- (void)_handleFECCChannelClosed
{
  if (canSendCameraEvents == YES) {
    canSendCameraEvents = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidCloseFECCChannel object:self];
  }
}

- (void)_handleH323ProtocolStatus:(NSNumber *)number;
{
  XMProtocolStatus protocolStatus = (XMProtocolStatus)[number unsignedIntValue];
  
  if (h323ProtocolStatus != protocolStatus) {
    h323ProtocolStatus = protocolStatus;
    
    NSString *notification = nil;
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    switch (h323ProtocolStatus) {
      case XMProtocolStatus_Enabled:
        notification = XMNotification_CallManagerDidEnableH323;
        break;
      case XMProtocolStatus_Disabled:
        notification = XMNotification_CallManagerDidDisableH323;
        break;
      case XMProtocolStatus_Error:
        notification = XMNotification_CallManagerDidNotEnableH323;
        break;
    }
    
    [notificationCenter postNotificationName:notification object:self];
    [notificationCenter postNotificationName:XMNotification_CallManagerDidChangeH323Status object:self];
  }
}

- (void)_handleGatekeeperRegistration:(NSArray *)objects
{
  NSString *theGatekeeperName = (NSString *)[objects objectAtIndex:0];
  NSArray *aliases = (NSArray *)[objects objectAtIndex:1];
  
  // Only send a notification if the registration status or the terminalAliases changed
  if (gatekeeperName == nil || ![gatekeeperName isEqualToString:theGatekeeperName] || ![aliases isEqualToArray:terminalAliases]) {
    [gatekeeperName release];
    gatekeeperName = [theGatekeeperName copy];
    
    [terminalAliases release];
    terminalAliases = [aliases copy];
  
    gatekeeperRegistrationStatus = XMGatekeeperRegistrationStatus_SuccessfullyRegistered;
  
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter postNotificationName:XMNotification_CallManagerDidRegisterAtGatekeeper object:self];
    [notificationCenter postNotificationName:XMNotification_CallManagerDidChangeGatekeeperRegistrationStatus object:self];
  }
}

- (void)_handleGatekeeperUnregistration
{
  if (gatekeeperName == nil) { // not registered
    return;
  }
  
  [gatekeeperName release];
  gatekeeperName = nil;
  
  [terminalAliases release];
  terminalAliases = nil;
  
  gatekeeperRegistrationStatus = XMGatekeeperRegistrationStatus_NotRegistered;
  
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  [notificationCenter postNotificationName:XMNotification_CallManagerDidUnregisterFromGatekeeper object:self];
  [notificationCenter postNotificationName:XMNotification_CallManagerDidChangeGatekeeperRegistrationStatus object:self];
}

- (void)_handleGatekeeperRegistrationFailure:(NSNumber *)failReason
{
  [gatekeeperName release];
  gatekeeperName = nil;
  
  XMGatekeeperRegistrationStatus theGatekeeperRegistrationStatus = (XMGatekeeperRegistrationStatus)[failReason unsignedIntValue];
  
  if (gatekeeperRegistrationStatus != theGatekeeperRegistrationStatus) {
    if (gatekeeperRegistrationStatus == XMGatekeeperRegistrationStatus_UnregisteredByGatekeeper &&
        theGatekeeperRegistrationStatus == XMGatekeeperRegistrationStatus_GatekeeperNotFound) {
      // Special case: GK unregistered first, went offline afterwards. Don't post a notification for the second time
      gatekeeperRegistrationStatus = theGatekeeperRegistrationStatus;
      return;
    }
    
    gatekeeperRegistrationStatus = theGatekeeperRegistrationStatus;
  
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter postNotificationName:XMNotification_CallManagerDidNotRegisterAtGatekeeper object:self];
    [notificationCenter postNotificationName:XMNotification_CallManagerDidChangeGatekeeperRegistrationStatus object:self];
  }
}

- (void)_handleSIPProtocolStatus:(NSNumber *)number
{
  XMProtocolStatus protocolStatus = (XMProtocolStatus)[number unsignedIntValue];
  
  if (sipProtocolStatus != protocolStatus) {
    sipProtocolStatus = protocolStatus;
    NSString *notification = nil;
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    switch (h323ProtocolStatus) {
      case XMProtocolStatus_Enabled:
        notification = XMNotification_CallManagerDidEnableSIP;
        break;
      case XMProtocolStatus_Disabled:
        notification = XMNotification_CallManagerDidDisableSIP;
        break;
      case XMProtocolStatus_Error:
        notification = XMNotification_CallManagerDidNotEnableSIP;
        break;
    }
    
    [notificationCenter postNotificationName:notification object:self];
    [notificationCenter postNotificationName:XMNotification_CallManagerDidChangeSIPStatus object:self];
  }
}

- (void)_handleSIPRegistration:(NSString *)addressOfRecord
{	
  NSArray *registrationRecords = [activePreferences sipRegistrationRecords];
  unsigned searchIndex = NSNotFound;
  unsigned count = [registrationRecords count];
  for (unsigned i = 0; i < count; i++) {
    XMPreferencesRegistrationRecord *record = (XMPreferencesRegistrationRecord *)[registrationRecords objectAtIndex:i];
    if (![record isKindOfClass:[XMPreferencesRegistrationRecord class]]) { // protect against illegal classes
      continue;
    }
    
    NSString *aor = [record addressOfRecord];
    
    if ([aor isEqualToString:addressOfRecord]) {
      searchIndex = i;
      break;
    }
  }
  
  if (searchIndex == NSNotFound) {
    NSLog(@"REGISTRATION NOT FOUND IN REGISTRATIONS (HANDLE REGISTRATION)");
    return;
  }
  
  count = [sipRegistrations count];
  [sipRegistrations addObject:addressOfRecord];
  
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:XMSIPStatusCode_Successful_OK];
  [sipRegistrationStates replaceObjectAtIndex:searchIndex withObject:number];
  [number release];
  
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  [notificationCenter postNotificationName:XMNotification_CallManagerDidSIPRegister object:[NSNumber numberWithUnsignedInt:count]];
  [notificationCenter postNotificationName:XMNotification_CallManagerDidChangeSIPRegistrationStatus object:self];
}

- (void)_handleSIPUnregistration:(NSString *)addressOfRecord
{	
  unsigned index = [sipRegistrations indexOfObject:addressOfRecord];
  if (index == NSNotFound) {
    NSLog(@"REGISTRATION NOT FOUND WHEN HANDLING UNREGISTRATION");
    return;
  }
  
  [sipRegistrations removeObjectAtIndex:index];
  
  // There is no corresponding record in the sipRegistrationStates array
  
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  [notificationCenter postNotificationName:XMNotification_CallManagerDidSIPUnregister object:addressOfRecord];
  [notificationCenter postNotificationName:XMNotification_CallManagerDidChangeSIPRegistrationStatus object:self];
}

- (void)_handleSIPRegistrationFailure:(NSArray *)info
{
  // extracting information from the array
  NSString *addressOfRecord = (NSString *)[info objectAtIndex:0];
  NSNumber *failReason = (NSNumber *)[info objectAtIndex:1];
  
  NSArray *records = [activePreferences sipRegistrationRecords];
  unsigned searchIndex = NSNotFound;
  unsigned count = [records count];
  for (unsigned i = 0; i < count; i++) {
    XMPreferencesRegistrationRecord *record = (XMPreferencesRegistrationRecord *)[records objectAtIndex:i];
    if (![record isKindOfClass:[XMPreferencesRegistrationRecord class]]) { // protect against illegal classes
      continue;
    }
    
    NSString *aor = [record addressOfRecord];
    
    if ([aor isEqualToString:addressOfRecord]) {
      searchIndex = i;
      break;
    }
  }
  
  if (searchIndex == NSNotFound) {
    NSLog(@"REGISTRATION NOT FOUND IN REGISTRATIONS (HANDLE REGISTRATION FAILURE)");
    return;
  }
  
  // only post the notification if the registration status changes
  NSNumber *currentFailReason = (NSNumber *)[sipRegistrationStates objectAtIndex:searchIndex];
  if (![currentFailReason isEqual:failReason]) {
    [sipRegistrationStates replaceObjectAtIndex:searchIndex withObject:failReason];
  
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter postNotificationName:XMNotification_CallManagerDidNotSIPRegister object:[NSNumber numberWithUnsignedInt:searchIndex]];
    [notificationCenter postNotificationName:XMNotification_CallManagerDidChangeSIPRegistrationStatus object:self];
  }
}

- (void)_networkConfigurationChanged
{
  if (systemSleepStatus == Awake) {
    networkConfigurationChanged = YES;
    [XMOpalDispatcher _handleNetworkConfigurationChange];
  }
}

- (void)_checkipAddressUpdated
{
  if (state == WaitingForCheckipAddress) {
    state = SubsystemSetup;
    [self _doSubsystemSetupWithPreferences:activePreferences];
  }
}

#pragma mark -
#pragma mark Private Methods

- (void)_doSubsystemSetupWithPreferences:(XMPreferences *)preferences
{
  if (state == Ready) { // only post the notification once
    state = SubsystemSetup;
    [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidStartSubsystemSetup object:self];
  }
  
  // reset any error states
  if (h323ProtocolStatus == XMProtocolStatus_Error) {
    h323ProtocolStatus = XMProtocolStatus_Disabled;
  }
  if (sipProtocolStatus == XMProtocolStatus_Error) {
    sipProtocolStatus = XMProtocolStatus_Disabled;
  }
  
  // store the current GK registration status. The status may be updated at any time, but a notification is only sent when the
  // status actually changes. However, each subsystem setup should trigger a notification.
  gatekeeperRegistrationStatusBeforeSubsystemSetup = gatekeeperRegistrationStatus;

  [sipRegistrationStates removeAllObjects];
  unsigned count = [[preferences sipRegistrationRecords] count];
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:(unsigned)XMSIPStatusCode_Successful_OK];
  for (unsigned i = 0; i < count; i++) {
    [sipRegistrationStates addObject:number];
  }
  [number release];
  
  if ([_XMUtilsSharedInstance _doesUpdateCheckipInformation]) {
    // not yet fetched
    state = WaitingForCheckipAddress;
      
    // we continue this job when the public address fetch task is finished
    return;
  }
  
  automaticallyAcceptIncomingCalls = [preferences automaticallyAcceptIncomingCalls];
  
  NSString *publicAddress = nil;
  publicAddress = [_XMUtilsSharedInstance _checkipPublicAddress];
  
  // preparations complete
  [XMOpalDispatcher _setPreferences:preferences publicAddress:publicAddress networkConfigurationChanged:networkConfigurationChanged];
  networkConfigurationChanged = NO;
}

- (void)_initiateCall:(XMAddressResource *)addressResource
{
  NSString *address = [self _prepareCallInitiation:addressResource];
  XMCallProtocol callProtocol = [addressResource callProtocol];
  
  [XMOpalDispatcher _initiateCallToAddress:address protocol:callProtocol];
}

- (void)_initiateSpecificCall:(XMGeneralPurposeAddressResource *)addressResource
{
  // In this case, we have to modify the subsystem before continuing
  // to make the call. This is "specific calling" since the call
  // is initated with a specific set of preferences
  XMPreferences *modifiedPreferences = [activePreferences copy];
  [addressResource _modifyPreferences:modifiedPreferences];
  
  NSString *address = [self _prepareCallInitiation:addressResource];
  XMCallProtocol callProtocol = [addressResource callProtocol];
  
  // change the subsystem and start calling afterwards
  [XMOpalDispatcher _initiateSpecificCallToAddress:address
                                          protocol:callProtocol 
                                       preferences:modifiedPreferences 
                                   publicAddress:[_XMUtilsSharedInstance publicAddress]];
  
  [modifiedPreferences release];
}

- (NSString *)_prepareCallInitiation:(XMAddressResource *)addressResource
{
  XMCallProtocol callProtocol = [addressResource callProtocol];
  
  NSString *address = [addressResource address];
  
  // clean phone numbers
  if (XMIsPhoneNumber(address)) {
    // remove any white spaces and '(', ')' in the address, replace any preceding + with the international prefix
    NSMutableString *processedAddress = [[NSMutableString alloc] initWithCapacity:[address length]];
    [processedAddress setString:address];
    [processedAddress replaceOccurrencesOfString:@" " withString:@"" options:0 range:NSMakeRange(0, [processedAddress length])];
    [processedAddress replaceOccurrencesOfString:@"(" withString:@"" options:0 range:NSMakeRange(0, [processedAddress length])];
    [processedAddress replaceOccurrencesOfString:@")" withString:@"" options:0 range:NSMakeRange(0, [processedAddress length])];
    if ([processedAddress length] > 1) {
      if ([processedAddress characterAtIndex:0] == '+') {
        [processedAddress replaceCharactersInRange:NSMakeRange(0, 1) withString:[activePreferences internationalDialingPrefix]];
      }
    }
    address = [processedAddress autorelease];
    
  }
  if (callProtocol == XMCallProtocol_SIP) {
    // if using SIP and the address is a phone number,
    // the address must have the form xxx@registrar.net
    // In case the suffix @registrar.net is missing, 
    // the suffix is added from the information of the
    // default registration domain
    if (XMIsPhoneNumber(address) && [[activePreferences sipRegistrationRecords] count] != 0) {
      XMPreferencesRegistrationRecord *record = (XMPreferencesRegistrationRecord *)[[activePreferences sipRegistrationRecords] objectAtIndex:0];
      NSString *registrationDomain = [record domain];
      address = [NSString stringWithFormat:@"%@@%@", address, registrationDomain];
    }
  }
  
  // validity check is done within XMOpalDispatcher
  
  state = PreparingCall;
  [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidStartCallInitiation object:self];
  
  // Stop the audio test if needed
  [_XMAudioManagerSharedInstance stopAudioTest];
  
  return address;
}

- (void)_storeCall:(XMCallInfo *)call
{
  if ([recentCalls count] == 100) { // only store 100 calls at maximum
    [recentCalls removeObjectAtIndex:99];
  }
  [recentCalls insertObject:call atIndex:0];
}

- (void)_didFinishLaunching:(NSNotification *)notif
{
  // Now it's time to launch the framework
  _XMLaunchFramework(pTracePath);
}

- (void)_willSleep:(NSNotification *)notif
{
  // System wants to go to sleep:
  // Cleanup the network part (unregister, etc), 
  // before actually going to sleep
  systemSleepStatus = EnterSleep;
  
  XMPreferences *prefs = [[XMPreferences alloc] init];
  [self _doSubsystemSetupWithPreferences:prefs];
  [prefs release];
  
  // Sleeping is suspended until this method returns
  // (or until 30s have elapsed) Thus, run the run
  // loop here until the subsystem setup has completed
  BOOL isRunning;
  do {
    NSDate *next = [NSDate dateWithTimeIntervalSinceNow:1.0];
    isRunning = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:next];
  } while(isRunning && systemSleepStatus != Asleep);
}

- (void)_didWake:(NSNotification *)notif
{
  // System is awake again
  systemSleepStatus = Awake;

  // update the network information and re-register
  networkConfigurationChanged = YES;
  [self _doSubsystemSetupWithPreferences:activePreferences];
}

@end
