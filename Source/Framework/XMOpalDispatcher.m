/*
 * $Id: XMOpalDispatcher.m,v 1.60 2008/09/24 06:52:42 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#import "XMOpalDispatcher.h"

#import "XMPrivate.h"
#import "XMPreferences.h"
#import "XMCallStatistics.h"
#import "XMBridge.h"

#import <unistd.h>

NSString *SHUTDOWN_CALL_TOKEN = @"<Shutdown>";

typedef enum _XMOpalDispatcherMessage
{
  // General messages
  _XMOpalDispatcherMessage_Shutdown = 0x0000,
  
  // Setup messages
  _XMOpalDispatcherMessage_SetPreferences = 0x0100,
  _XMOpalDispatcherMessage_HandleNetworkConfigurationChange,
  _XMOpalDispatcherMessage_HandlePublicAddressUpdate,
  
  // Call Management messages
  _XMOpalDispatcherMessage_InitiateCall = 0x0200,
  _XMOpalDispatcherMessage_InitiateSpecificCall,
  _XMOpalDispatcherMessage_CallIsAlerting,
  _XMOpalDispatcherMessage_IncomingCall,
  _XMOpalDispatcherMessage_AcceptIncomingCall,
  _XMOpalDispatcherMessage_RejectIncomingCall,
  _XMOpalDispatcherMessage_CallEstablished,
  _XMOpalDispatcherMessage_ClearCall,
  _XMOpalDispatcherMessage_CallCleared,
  _XMOpalDispatcherMessage_CallReleased,
  
  // Media callback messages
  _XMOpalDispatcherMessage_AudioStreamOpened = 0x0300,
  _XMOpalDispatcherMessage_VideoStreamOpened,
  _XMOpalDispatcherMessage_AudioStreamClosed,
  _XMOpalDispatcherMessage_VideoStreamClosed,
  _XMOpalDispatcherMessage_FECCChannelOpened,
  
  // InCall messages
  _XMOpalDispatcherMessage_SetUserInputMode = 0x400,
  _XMOpalDispatcherMessage_SendUserInputTone,
  _XMOpalDispatcherMessage_SendUserInputString,
  _XMOpalDispatcherMessage_StartCameraEvent,
  _XMOpalDispatcherMessage_StopCameraEvent
  
} _XMOpalDispatcherMessage;

@interface XMOpalDispatcher (PrivateMethods)

+ (void)_sendMessage:(_XMOpalDispatcherMessage)message withComponents:(NSArray *)components;

- (NSPort *)_receivePort;
- (void)_handleOpalDispatcherThreadDidExit;

- (void)handlePortMessage:(NSPortMessage *)portMessage;

- (void)_handleShutdownMessage;
- (void)_handleSetPreferencesMessage:(NSArray *)messageComponents;
- (void)_handleNetworkConfigurationChangeMessage;
- (void)_handlePublicAddressUpdateMessage:(NSArray *)messageComponents;

- (void)_handleInitiateCallMessage:(NSArray *)messageComponents;
- (void)_handleInitiateSpecificCallMessage:(NSArray *)messageComponents;
- (void)_handleCallIsAlertingMessage:(NSArray *)messageComponents;
- (void)_handleIncomingCallMessage:(NSArray *)messageComponents;
- (void)_handleAcceptIncomingCallMessage:(NSArray *)messageComponents;
- (void)_handleRejectIncomingCallMessage:(NSArray *)messageComponents;
- (void)_handleCallEstablishedMessage:(NSArray *)messageComponents;
- (void)_handleClearCallMessage:(NSArray *)messageComponents;
- (void)_handleCallClearedMessage:(NSArray *)messageComponents;
- (void)_handleCallReleasedMessage:(NSArray *)messageComponents;

- (void)_handleAudioStreamOpenedMessage:(NSArray *)messageComponents;
- (void)_handleVideoStreamOpenedMessage:(NSArray *)messageComponents;
- (void)_handleAudioStreamClosedMessage:(NSArray *)messageComponents;
- (void)_handleVideoStreamClosedMessage:(NSArray *)messageComponents;
- (void)_handleFECCChannelOpenedMessage;

- (void)_handleSetUserInputModeMessage:(NSArray *)messageComponents;
- (void)_handleSendUserInputToneMessage:(NSArray *)messageComponents;
- (void)_handleSendUserInputStringMessage:(NSArray *)messageComponents;
- (void)_handleStartCameraEventMessage:(NSArray *)messageComponents;
- (void)_handleStopCameraEventMessage:(NSArray *)messageComponents;

- (void)_doPreferencesSetup:(XMPreferences *)preferences 
              publicAddress:(NSString *)publicAddress
                    verbose:(BOOL)verbose;
- (void)_doH323Setup:(XMPreferences *)preferences verbose:(BOOL)verbose;
- (void)_doGatekeeperSetup:(XMPreferences *)preferences;
- (void)_doSIPSetup:(XMPreferences *)preferences verbose:(BOOL)verbose;
- (void)_doRegistrationSetup:(XMPreferences *)preferences proxyChanged:(BOOL)proxyChanged;

- (void)_waitForSubsystemSetupCompletion;

- (void)_resyncSubsystem:(NSTimer *)timer;
- (void)_updateCallStatistics:(NSTimer *)timer;

- (void)_doInitiateCallToAddress:(NSString *)address protocol:(XMCallProtocol)callProtocol;
- (void)_sendCallStartFailReason:(XMCallStartFailReason)reason address:(NSString *)address;
- (NSString *)_adjustedAddress:(NSString *)address protocol:(XMCallProtocol)callProtocol;
- (void)_runGatekeeperSetup:(XMPreferences *)preferences;

@end

@implementation XMOpalDispatcher

#pragma mark Class Methods

+ (void)_shutdown
{
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_Shutdown withComponents:nil];
}

+ (void)_setPreferences:(XMPreferences *)preferences publicAddress:(NSString *)publicAddress
{
  NSData *preferencesData = [NSKeyedArchiver archivedDataWithRootObject:preferences];
  NSData *publicAddressData = [NSKeyedArchiver archivedDataWithRootObject:publicAddress];
  
  NSArray *components = [[NSArray alloc] initWithObjects:preferencesData, publicAddressData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_SetPreferences withComponents:components];
  
  [components release];
}

+ (void)_handleNetworkConfigurationChange
{
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_HandleNetworkConfigurationChange withComponents:nil];
}

+ (void)_handlePublicAddressUpdate:(NSString *)publicAddress
{
  NSData *publicAddressData = [NSKeyedArchiver archivedDataWithRootObject:publicAddress];
  NSArray *components = [[NSArray alloc] initWithObjects:publicAddressData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_HandlePublicAddressUpdate withComponents:components];
  
  [components release];
}

+ (void)_initiateCallToAddress:(NSString *)address protocol:(XMCallProtocol)protocol
{
  NSData *addressData = [NSKeyedArchiver archivedDataWithRootObject:address];
  
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:(unsigned)protocol];
  NSData *protocolData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  NSArray *components = [[NSArray alloc] initWithObjects:addressData, protocolData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_InitiateCall withComponents:components];
  
  [components release];
}

+ (void)_initiateSpecificCallToAddress:(NSString *)address
                              protocol:(XMCallProtocol)protocol
                           preferences:(XMPreferences *)preferences
                       publicAddress:(NSString *)publicAddress;
{
  NSData *addressData = [NSKeyedArchiver archivedDataWithRootObject:address];
  
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:(unsigned)protocol];
  NSData *protocolData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  NSData *preferencesData = [NSKeyedArchiver archivedDataWithRootObject:preferences];
  
  NSData *publicAddressData = [NSKeyedArchiver archivedDataWithRootObject:publicAddress];
  
  NSArray *components = [[NSArray alloc] initWithObjects:addressData, protocolData, preferencesData,
    publicAddressData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_InitiateSpecificCall withComponents:components];
  
  [components release];
}

+ (void)_callIsAlerting:(NSString *)callToken
{
  NSData *tokenData = [NSKeyedArchiver archivedDataWithRootObject:callToken];
  NSArray *components = [[NSArray alloc] initWithObjects:tokenData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_CallIsAlerting withComponents:components];
  
  [components release];
}

+ (void)_incomingCall:(NSString *)callToken
             protocol:(XMCallProtocol)protocol
           remoteName:(NSString *)remoteName
         remoteNumber:(NSString *)remoteNumber
        remoteAddress:(NSString *)remoteAddress
    remoteApplication:(NSString *)remoteApplication
         localAddress:(NSString *)localAddress
{
  NSData *callData = [NSKeyedArchiver archivedDataWithRootObject:callToken];
  
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:(unsigned)protocol];
  NSData *protocolData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  NSData *nameData = [NSKeyedArchiver archivedDataWithRootObject:remoteName];
  NSData *numberData = [NSKeyedArchiver archivedDataWithRootObject:remoteNumber];
  NSData *addressData = [NSKeyedArchiver archivedDataWithRootObject:remoteAddress];
  NSData *applicationData = [NSKeyedArchiver archivedDataWithRootObject:remoteApplication];
  NSData *localAddressData = [NSKeyedArchiver archivedDataWithRootObject:localAddress];
  
  NSArray *components = [[NSArray alloc] initWithObjects:callData, protocolData, nameData,
    numberData, addressData, applicationData, localAddressData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_IncomingCall withComponents:components];
  
  [components release];
}

+ (void)_acceptIncomingCall:(NSString *)callToken
{
  NSData *tokenData = [NSKeyedArchiver archivedDataWithRootObject:callToken];
  
  NSArray *components = [[NSArray alloc] initWithObjects:tokenData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_AcceptIncomingCall withComponents:components];
  
  [components release];
}

+ (void)_rejectIncomingCall:(NSString *)callToken
{
  NSData *tokenData = [NSKeyedArchiver archivedDataWithRootObject:callToken];
  
  NSArray *components = [[NSArray alloc] initWithObjects:tokenData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_RejectIncomingCall withComponents:components];
  
  [components release];
}

+ (void)_callEstablished:(NSString *)callToken 
              remoteName:(NSString *)remoteName
            remoteNumber:(NSString *)remoteNumber
           remoteAddress:(NSString *)remoteAddress
       remoteApplication:(NSString *)remoteApplication
            localAddress:(NSString *)localAddress
{
  NSData *tokenData = [NSKeyedArchiver archivedDataWithRootObject:callToken];
  NSData *remoteNameData = [NSKeyedArchiver archivedDataWithRootObject:remoteName];
  NSData *remoteNumberData = [NSKeyedArchiver archivedDataWithRootObject:remoteNumber];
  NSData *remoteAddressData = [NSKeyedArchiver archivedDataWithRootObject:remoteAddress];
  NSData *remoteApplicationData = [NSKeyedArchiver archivedDataWithRootObject:remoteApplication];
  NSData *localAddressData = [NSKeyedArchiver archivedDataWithRootObject:localAddress];
  
  NSArray *components = [[NSArray alloc] initWithObjects:tokenData, remoteNameData, remoteNumberData, 
    remoteAddressData, remoteApplicationData, localAddressData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_CallEstablished withComponents:components];
  
  [components release];
}

+ (void)_clearCall:(NSString *)callToken
{
  NSData *tokenData = [NSKeyedArchiver archivedDataWithRootObject:callToken];
  
  NSArray *components = [[NSArray alloc] initWithObjects:tokenData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_ClearCall withComponents:components];
  
  [components release];
}

+ (void)_callCleared:(NSString *)callToken reason:(XMCallEndReason)callEndReason
{
  NSData *tokenData = [NSKeyedArchiver archivedDataWithRootObject:callToken];
  
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:(unsigned)callEndReason];
  NSData *callEndReasonData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  NSArray *components = [[NSArray alloc] initWithObjects:tokenData, callEndReasonData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_CallCleared withComponents:components];
  
  [components release];
}

+ (void)_callReleased:(NSString *)callToken localAddress:(NSString *)localAddress
{
  NSData *tokenData = [NSKeyedArchiver archivedDataWithRootObject:callToken];
  
  NSData *addressData = [NSKeyedArchiver archivedDataWithRootObject:localAddress];
  
  NSArray *components = [[NSArray alloc] initWithObjects:tokenData, addressData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_CallReleased withComponents:components];
  
  [components release];
}

+ (void)_audioStreamOpened:(NSString *)callToken codec:(NSString *)codec incoming:(BOOL)isIncomingStream
{
  NSData *tokenData = [NSKeyedArchiver archivedDataWithRootObject:callToken];
  
  NSData *codecData = [NSKeyedArchiver archivedDataWithRootObject:codec];
  
  NSNumber *number = [[NSNumber alloc] initWithBool:isIncomingStream];
  NSData *incomingData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  NSArray *components = [[NSArray alloc] initWithObjects:tokenData, codecData, incomingData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_AudioStreamOpened withComponents:components];
  
  [components release];
}

+ (void)_videoStreamOpened:(NSString *)callToken codec:(NSString *)codec size:(XMVideoSize)videoSize incoming:(BOOL)isIncomingStream
                     width:(unsigned)width height:(unsigned)height
{
  NSData *tokenData = [NSKeyedArchiver archivedDataWithRootObject:callToken];
  
  NSData *codecData = [NSKeyedArchiver archivedDataWithRootObject:codec];
  
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:videoSize];
  NSData *sizeData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  number = [[NSNumber alloc] initWithBool:isIncomingStream];
  NSData *incomingData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  number = [[NSNumber alloc] initWithUnsignedInt:width];
  NSData *widthData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  number = [[NSNumber alloc] initWithUnsignedInt:height];
  NSData *heightData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  NSArray *components = [[NSArray alloc] initWithObjects:tokenData, codecData, sizeData, incomingData, widthData, heightData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_VideoStreamOpened withComponents:components];
  
  [components release];
}

+ (void)_audioStreamClosed:(NSString *)callToken incoming:(BOOL)isIncomingStream
{
  NSData *tokenData = [NSKeyedArchiver archivedDataWithRootObject:callToken];
  
  NSNumber *number = [[NSNumber alloc] initWithBool:isIncomingStream];
  NSData *incomingData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  NSArray *components = [[NSArray alloc] initWithObjects:tokenData, incomingData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_AudioStreamClosed withComponents:components];
  
  [components release];
}

+ (void)_videoStreamClosed:(NSString *)callToken incoming:(BOOL)isIncomingStream
{
  NSData *tokenData = [NSKeyedArchiver archivedDataWithRootObject:callToken];
  
  NSNumber *number = [[NSNumber alloc] initWithBool:isIncomingStream];
  NSData *incomingData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  NSArray *components = [[NSArray alloc] initWithObjects:tokenData, incomingData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_VideoStreamClosed withComponents:components];
  
  [components release];
}

+ (void)_feccChannelOpened
{
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_FECCChannelOpened withComponents:nil];
}

+ (void)_setUserInputMode:(XMUserInputMode)userInputMode
{
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:userInputMode];
  NSData *modeData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  NSArray *components = [[NSArray alloc] initWithObjects:modeData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_SetUserInputMode withComponents:components];
  
  [components release];
}

+ (void)_sendUserInputToneForCall:(NSString *)callToken tone:(char)tone
{
  NSData *tokenData = [NSKeyedArchiver archivedDataWithRootObject:callToken];
  
  NSNumber *number = [[NSNumber alloc] initWithChar:tone];
  NSData *toneData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  NSArray *components = [[NSArray alloc] initWithObjects:tokenData, toneData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_SendUserInputTone withComponents:components];
  
  [components release];
}

+ (void)_sendUserInputStringForCall:(NSString *)callToken string:(NSString *)string
{
  NSData *tokenData = [NSKeyedArchiver archivedDataWithRootObject:callToken];
  
  NSData *stringData = [NSKeyedArchiver archivedDataWithRootObject:string];
  
  NSArray *components = [[NSArray alloc] initWithObjects:tokenData, stringData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_SendUserInputString withComponents:components];
  
  [components release];
}

+ (void)_startCameraEventForCall:(NSString *)callToken event:(XMCameraEvent)event
{
  NSData *tokenData = [NSKeyedArchiver archivedDataWithRootObject:callToken];
  
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:event];
  NSData *eventData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  NSArray *components = [[NSArray alloc] initWithObjects:tokenData, eventData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_StartCameraEvent withComponents:components];
  
  [components release];
}

+ (void)_stopCameraEventForCall:(NSString *)callToken
{
  NSData *tokenData = [NSKeyedArchiver archivedDataWithRootObject:callToken];
  
  NSArray *components = [[NSArray alloc] initWithObjects:tokenData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_StopCameraEvent withComponents:components];
  
  [components release];
}

+ (void)_sendMessage:(_XMOpalDispatcherMessage)message withComponents:(NSArray *)components
{
  if (_XMOpalDispatcherSharedInstance == nil) {
    NSLog(@"Attempt to send message to NIL OpalDispatcher");
    return;
  }
  
  NSPort *thePort = [_XMOpalDispatcherSharedInstance _receivePort];
  NSPortMessage *portMessage = [[NSPortMessage alloc] initWithSendPort:thePort receivePort:nil components:components];
  [portMessage setMsgid:(unsigned)message];
  if ([portMessage sendBeforeDate:[NSDate date]] == NO) {
    NSLog(@"Sending the message failed (Dispatcher) %x", message);
  }
  [portMessage release];
}

#pragma mark -
#pragma mark Init & Deallocation Methods

- (id)init
{
  [self doesNotRecognizeSelector:_cmd];
  [self release];
  return nil;
}

- (id)_init
{
  self = [super init];
  
  receivePort = [[NSPort port] retain];
  currentPreferences = nil;
  
  callToken = nil;
  
  controlTimer = nil;
  callStatisticsUpdateIntervalTimer = nil;
  
  gatekeeperRegistrationWaitLock = [[NSLock alloc] init];
  sipRegistrationWaitLock = [[NSLock alloc] init];
  
  return self;
}

- (void)_close
{
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_Shutdown withComponents:nil];
}

- (void)dealloc
{
  [receivePort release];
  [currentPreferences release];
  
  [controlTimer release];
  [callStatisticsUpdateIntervalTimer release];
  
  [gatekeeperRegistrationWaitLock release];
  [sipRegistrationWaitLock release];
  
  [super dealloc];
}

#pragma mark -
#pragma mark MainThread Methods

- (NSPort *)_receivePort
{
  return receivePort;
}

- (void)_handleOpalDispatcherThreadDidExit
{
  _XMThreadExit();
}

#pragma mark -
#pragma mark OpalDispatcherThread Methods

- (void)_setLogCallStatistics:(BOOL)_logCallStatistics
{
  logCallStatistics = _logCallStatistics;
}

- (void)_runOpalDispatcherThread:(NSString *)pTracePath
{
  NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
  
  [receivePort setDelegate:self];
  [[NSRunLoop currentRunLoop] addPort:receivePort forMode:NSDefaultRunLoopMode];
  
  // Initiating the OPAL subsystem
  const char *pathString = [pTracePath cStringUsingEncoding:NSASCIIStringEncoding];
  _XMInitSubsystem(pathString, logCallStatistics);
  
  // Signaling that the subsystem has initialized
  _XMSubsystemInitialized();
  
  // start the control timer. The timer is invalidated/released within -handleShutdownMessage
  controlTimer = [[NSTimer scheduledTimerWithTimeInterval:20.0 target:self selector:@selector(_resyncSubsystem:) userInfo:nil repeats:YES] retain];
  
  // running the run loop
  [[NSRunLoop currentRunLoop] run];
  
  _XMCloseSubsystem();
  
  [self performSelectorOnMainThread:@selector(_handleOpalDispatcherThreadDidExit) withObject:nil waitUntilDone:NO];
  
  [autoreleasePool release];
  autoreleasePool = nil;
}

- (void)handlePortMessage:(NSPortMessage *)portMessage
{
  _XMOpalDispatcherMessage message = (_XMOpalDispatcherMessage)[portMessage msgid];
  
  switch (message) {
    case _XMOpalDispatcherMessage_Shutdown:
      [self _handleShutdownMessage];
      break;
    case _XMOpalDispatcherMessage_SetPreferences:
      [self _handleSetPreferencesMessage:[portMessage components]];
      break;
    case _XMOpalDispatcherMessage_HandleNetworkConfigurationChange:
      [self _handleNetworkConfigurationChangeMessage];
      break;
    case _XMOpalDispatcherMessage_HandlePublicAddressUpdate:
      [self _handlePublicAddressUpdateMessage:[portMessage components]];
      break;
    case _XMOpalDispatcherMessage_InitiateCall:
      [self _handleInitiateCallMessage:[portMessage components]];
      break;
    case _XMOpalDispatcherMessage_InitiateSpecificCall:
      [self _handleInitiateSpecificCallMessage:[portMessage components]];
      break;
    case _XMOpalDispatcherMessage_CallIsAlerting:
      [self _handleCallIsAlertingMessage:[portMessage components]];
      break;
    case _XMOpalDispatcherMessage_IncomingCall:
      [self _handleIncomingCallMessage:[portMessage components]];
      break;
    case _XMOpalDispatcherMessage_AcceptIncomingCall:
      [self _handleAcceptIncomingCallMessage:[portMessage components]];
      break;
    case _XMOpalDispatcherMessage_RejectIncomingCall:
      [self _handleRejectIncomingCallMessage:[portMessage components]];
      break;
    case _XMOpalDispatcherMessage_CallEstablished:
      [self _handleCallEstablishedMessage:[portMessage components]];
      break;
    case _XMOpalDispatcherMessage_ClearCall:
      [self _handleClearCallMessage:[portMessage components]];
      break;
    case _XMOpalDispatcherMessage_CallCleared:
      [self _handleCallClearedMessage:[portMessage components]];
      break;
    case _XMOpalDispatcherMessage_CallReleased:
      [self _handleCallReleasedMessage:[portMessage components]];
      break;
    case _XMOpalDispatcherMessage_AudioStreamOpened:
      [self _handleAudioStreamOpenedMessage:[portMessage components]];
      break;
    case _XMOpalDispatcherMessage_VideoStreamOpened:
      [self _handleVideoStreamOpenedMessage:[portMessage components]];
      break;
    case _XMOpalDispatcherMessage_AudioStreamClosed:
      [self _handleAudioStreamClosedMessage:[portMessage components]];
      break;
    case _XMOpalDispatcherMessage_VideoStreamClosed:
      [self _handleVideoStreamClosedMessage:[portMessage components]];
      break;
    case _XMOpalDispatcherMessage_FECCChannelOpened:
      [self _handleFECCChannelOpenedMessage];
      break;
    case _XMOpalDispatcherMessage_SetUserInputMode:
      [self _handleSetUserInputModeMessage:[portMessage components]];
      break;
    case _XMOpalDispatcherMessage_SendUserInputTone:
      [self _handleSendUserInputToneMessage:[portMessage components]];
      break;
    case _XMOpalDispatcherMessage_SendUserInputString:
      [self _handleSendUserInputStringMessage:[portMessage components]];
      break;
    case _XMOpalDispatcherMessage_StartCameraEvent:
      [self _handleStartCameraEventMessage:[portMessage components]];
      break;
    case _XMOpalDispatcherMessage_StopCameraEvent:
      [self _handleStopCameraEventMessage:[portMessage components]];
      break;
    default:
      break;
  }
}

- (void)_handleShutdownMessage
{
  if (callToken != nil) {
    // we have to terminate the call first
    // and we wait until the call is cleared before shutting down the system entirely
    [self _handleClearCallMessage:nil];
    callToken = SHUTDOWN_CALL_TOKEN;
    return;
  }
  
  // By using the default XMPreferences instance,
  // we shutdown the subsystem
  XMPreferences *preferences = [[XMPreferences alloc] init];
  [self _doPreferencesSetup:preferences publicAddress:nil verbose:NO];
  [preferences release];
  
  // remove all timers
  [controlTimer invalidate];
  [controlTimer release];
  controlTimer = nil;
  [callStatisticsUpdateIntervalTimer invalidate];
  [callStatisticsUpdateIntervalTimer release];
  callStatisticsUpdateIntervalTimer = nil;
  
  // exiting from the run loop
  [[NSRunLoop currentRunLoop] removePort:receivePort forMode:NSDefaultRunLoopMode];
  
  // Give one s time to cleanup
  usleep(1000*1000);
}

- (void)_handleSetPreferencesMessage:(NSArray *)components
{	
  NSData *preferencesData = (NSData *)[components objectAtIndex:0];
  XMPreferences *preferences = (XMPreferences *)[NSKeyedUnarchiver unarchiveObjectWithData:preferencesData];
		
  NSData *publicAddressData = (NSData *)[components objectAtIndex:1];
  NSString *publicAddress = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:publicAddressData];
  
  [self _doPreferencesSetup:preferences publicAddress:publicAddress verbose:YES];
  
  [self _waitForSubsystemSetupCompletion];
  
  [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleSubsystemSetupEnd) withObject:nil waitUntilDone:NO];
}

- (void)_handleNetworkConfigurationChangeMessage
{
  _XMHandleNetworkConfigurationChange();
}

- (void)_handlePublicAddressUpdateMessage:(NSArray *)components
{
  NSData *publicAddressData = (NSData *)[components objectAtIndex:0];
  NSString *publicAddress = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:publicAddressData];
  
  _XMHandlePublicAddressUpdate([publicAddress cStringUsingEncoding:NSASCIIStringEncoding]);
}

- (void)_handleInitiateCallMessage:(NSArray *)components
{
  NSData *addressData = (NSData *)[components objectAtIndex:0];
  NSString *address = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:addressData];
  NSData *protocolData = (NSData *)[components objectAtIndex:1];
  NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:protocolData];
  XMCallProtocol protocol = (XMCallProtocol)[number unsignedIntValue];
  
  if (callToken != nil) {
    // This probably indicates that an incoming call arrived at exactly the same time than
    // the user tried to initiate this call. Since the incoming call arrived first,
    // we cannot call anyone at the moment
    [self _sendCallStartFailReason:XMCallStartFailReason_AlreadyInCall address:address];
    return;
  }
  
  [self _doInitiateCallToAddress:address protocol:protocol];
}

- (void)_handleInitiateSpecificCallMessage:(NSArray *)messageComponents
{	
  NSData *addressData = (NSData *)[messageComponents objectAtIndex:0];
  NSData *protocolData = (NSData *)[messageComponents objectAtIndex:1];
  NSData *preferencesData = (NSData *)[messageComponents objectAtIndex:2];
  NSData *publicAddressData = (NSData *)[messageComponents objectAtIndex:3];
  
  NSString *address = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:addressData];
  NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:protocolData];
  XMCallProtocol callProtocol = (XMCallProtocol)[number unsignedIntValue];
  XMPreferences *preferences = (XMPreferences *)[NSKeyedUnarchiver unarchiveObjectWithData:preferencesData];
  NSString *publicAddress = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:publicAddressData];
  
  if (callToken != nil) {
    // This probably indicates that an incoming call arrived at exactly the same time than
    // the user tried to initiate this call. Since the incoming call arrived first,
    // we cannot call anyone at the moment
    [self _sendCallStartFailReason:XMCallStartFailReason_AlreadyInCall address:address];
    return;
  }
  
  [self _doPreferencesSetup:preferences publicAddress:publicAddress verbose:NO];
  [self _waitForSubsystemSetupCompletion];
  
  [self _doInitiateCallToAddress:address protocol:callProtocol];	
}

- (void)_handleCallIsAlertingMessage:(NSArray *)messageComponents
{
  if (callToken == SHUTDOWN_CALL_TOKEN) {
    return; // shutting down anyway...
  }
  
  NSData *tokenData = (NSData *)[messageComponents objectAtIndex:0];
  NSString *_callToken = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
  
  if (![callToken isEqualToString:_callToken]) {
    NSLog(@"call token mismatch on IsAlerting: %@ to currently %@", _callToken, callToken);
    return;
  }
  
  [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleCallIsAlerting)
                                                 withObject:nil
                                              waitUntilDone:NO];
}

- (void)_handleIncomingCallMessage:(NSArray *)messageComponents
{
  NSData *tokenData = (NSData *)[messageComponents objectAtIndex:0];
  NSData *protocolData = (NSData *)[messageComponents objectAtIndex:1];
  NSData *remoteNameData = (NSData *)[messageComponents objectAtIndex:2];
  NSData *remoteNumberData = (NSData *)[messageComponents objectAtIndex:3];
  NSData *remoteAddressData = (NSData *)[messageComponents objectAtIndex:4];
  NSData *remoteApplicationData = (NSData *)[messageComponents objectAtIndex:5];
  NSData *localAddressData = (NSData *)[messageComponents objectAtIndex:6];
  
  NSString *_callToken = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
  
  if (callToken != nil) {
    _XMLogMessage("Incoming call while already in call");
    _XMRejectIncomingCall([_callToken cStringUsingEncoding:NSASCIIStringEncoding], true);
    return;
  }
  
  [callToken release];
  callToken = [_callToken copy];
  
  NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:protocolData];
  XMCallProtocol protocol = (XMCallProtocol)[number unsignedIntValue];
  
  NSString *remoteName = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:remoteNameData];
  NSString *remoteNumber = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:remoteNumberData];
  NSString *remoteAddress = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:remoteAddressData];
  NSString *remoteApplication = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:remoteApplicationData];
  NSString *localAddress = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:localAddressData];
  
  XMCallInfo *callInfo = [[XMCallInfo alloc] _initWithCallToken:callToken
                                                       protocol:protocol
                                                     remoteName:remoteName
                                                   remoteNumber:remoteNumber
                                                  remoteAddress:remoteAddress
                                              remoteApplication:remoteApplication
                                                    callAddress:nil
                                                   localAddress:localAddress
                                                     callStatus:XMCallStatus_Incoming];
  
  [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleIncomingCall:)
                                                 withObject:callInfo
                                              waitUntilDone:NO];
  
  [callInfo release];
}

- (void)_handleAcceptIncomingCallMessage:(NSArray *)messageComponents
{
  if (callToken == SHUTDOWN_CALL_TOKEN) {
    return; // shutting down anyway...
  }
  
  NSData *tokenData = (NSData *)[messageComponents objectAtIndex:0];
  NSString *_callToken = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
  
  if (![callToken isEqualToString:_callToken]) {
    NSLog(@"call token mismatch in accpetIncomingCall: %@ to current %@", _callToken, callToken);
    return;
  }
  
  _XMAcceptIncomingCall([callToken cStringUsingEncoding:NSASCIIStringEncoding]);
}

- (void)_handleRejectIncomingCallMessage:(NSArray *)messageComponents
{
  if (callToken == SHUTDOWN_CALL_TOKEN) {
    return; // shutting down anyway...
  }
  
  NSData *tokenData = (NSData *)[messageComponents objectAtIndex:0];
  NSString *_callToken = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
  
  if (![callToken isEqualToString:_callToken]) {
    NSLog(@"call token mismatch in rejectIncomingCall: %@ to current %@", _callToken, callToken);
    return;
  }
  
  _XMRejectIncomingCall([callToken cStringUsingEncoding:NSASCIIStringEncoding], false);
}

- (void)_handleCallEstablishedMessage:(NSArray *)messageComponents
{
  if (callToken == SHUTDOWN_CALL_TOKEN) {
    return; // shutting down anyway...
  }
  
  NSData *tokenData = (NSData *)[messageComponents objectAtIndex:0];
  NSString *_callToken = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
  
  NSData *remoteNameData = (NSData *)[messageComponents objectAtIndex:1];
  NSString *remoteName = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:remoteNameData];
  
  NSData *remoteNumberData = (NSData *)[messageComponents objectAtIndex:2];
  NSString *remoteNumber = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:remoteNumberData];
  
  NSData *remoteAddressData = (NSData *)[messageComponents objectAtIndex:3];
  NSString *remoteAddress = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:remoteAddressData];
  
  NSData *remoteApplicationData = (NSData *)[messageComponents objectAtIndex:4];
  NSString *remoteApplication = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:remoteApplicationData];
  
  NSData *localAddressData = (NSData *)[messageComponents objectAtIndex:5];
  NSString *localAddress = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:localAddressData];
  
  if (![callToken isEqualToString:_callToken]) {
    NSLog(@"call token mismatch in callEstablished: %@ to current %@", _callToken, callToken);
    return;
  }
  
  NSArray *remotePartyInformations = [[NSArray alloc] initWithObjects:remoteName, remoteNumber, remoteAddress, remoteApplication, localAddress, nil];
  
  [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleCallEstablished:)
                                                 withObject:remotePartyInformations
                                              waitUntilDone:NO];
  
  [remotePartyInformations release];
  
  callStatisticsUpdateIntervalTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0
                                                                        target:self
                                                                      selector:@selector(_updateCallStatistics:)
                                                                      userInfo:nil
                                                                       repeats:YES] retain];
}

- (void)_handleClearCallMessage:(NSArray *)messageComponents
{
  if (messageComponents != nil) {
    if (callToken == SHUTDOWN_CALL_TOKEN) {
      return; // shutting down anyway...
    }
    
    NSData *tokenData = (NSData *)[messageComponents objectAtIndex:0];
    NSString *_callToken = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
    
    if (![callToken isEqualToString:_callToken]) {
      NSLog(@"call token mismatch in clearCall: %@ to current %@", _callToken, callToken);
      return;
    }
  }
  
  _XMClearCall([callToken cStringUsingEncoding:NSASCIIStringEncoding]);
}

- (void)_handleCallClearedMessage:(NSArray *)messageComponents
{
  NSData *tokenData = (NSData *)[messageComponents objectAtIndex:0];
  NSString *_callToken = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
  
  // If call initiation fails, no call token is set (nil), don't log this
  if (callToken != nil && callToken != SHUTDOWN_CALL_TOKEN && ![callToken isEqualToString:_callToken]) {
    // might happen if an incoming call arrives during an ongoing call
    return;
  }
  
  _XMStopAudio();
  
  NSData *callEndReasonData = (NSData *)[messageComponents objectAtIndex:1];
  NSNumber *callEndReasonNumber = [NSKeyedUnarchiver unarchiveObjectWithData:callEndReasonData];
  
  [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleCallCleared:)
                                                 withObject:callEndReasonNumber
                                              waitUntilDone:NO];
  
  if (callToken == SHUTDOWN_CALL_TOKEN) {
    // the framework is closing
    callToken = nil;
    [self _handleShutdownMessage];
  }
  
  if (callStatisticsUpdateIntervalTimer != nil) {
    [callStatisticsUpdateIntervalTimer invalidate];
    [callStatisticsUpdateIntervalTimer release];
    callStatisticsUpdateIntervalTimer = nil;
  }
  
  callToken = nil;
}

- (void)_handleCallReleasedMessage:(NSArray *)messageComponents
{
  if (callToken == SHUTDOWN_CALL_TOKEN) {
    return; // shutting down anyway...
  }
  
  NSData *tokenData = (NSData *)[messageComponents objectAtIndex:0];
  NSString *_callToken = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
  
  if (![callToken isEqualToString:_callToken]) { // might happen if incoming calls arrive during an ongoing call
    return;
  }
  
  NSData *localAddressData = (NSData *)[messageComponents objectAtIndex:1];
  NSString *localAddress = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:localAddressData];
  
  [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleLocalAddress:)
                                                 withObject:localAddress
                                              waitUntilDone:NO];
}

- (void)_handleAudioStreamOpenedMessage:(NSArray *)messageComponents
{
  if (callToken == SHUTDOWN_CALL_TOKEN) {
    return; // shutting down anyway...
  }
  
  NSData *tokenData = (NSData *)[messageComponents objectAtIndex:0];
  NSString *_callToken = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
  
  if (![callToken isEqualToString:_callToken]) {
    NSLog(@"call token mismatch on AudioStreamOpened: %@ to actual %@", _callToken, callToken);
    return;
  }
  
  NSData *codecData = (NSData *)[messageComponents objectAtIndex:1];
  NSString *codec = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:codecData];
  
  NSData *directionData = (NSData *)[messageComponents objectAtIndex:2];
  NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:directionData];
  BOOL isIncomingStream = [number boolValue];
  
  if (isIncomingStream == YES) {
    [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleIncomingAudioStreamOpened:) 
                                                   withObject:codec waitUntilDone:NO];
  } else {
    [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleOutgoingAudioStreamOpened:)
                                                   withObject:codec waitUntilDone:NO];
  }
}

- (void)_handleVideoStreamOpenedMessage:(NSArray *)messageComponents
{
  if (callToken == SHUTDOWN_CALL_TOKEN) {
    return; // shutting down anyway...
  }
  
  NSData *tokenData = (NSData *)[messageComponents objectAtIndex:0];
  NSString *_callToken = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
  
  if (callToken != nil && callToken != SHUTDOWN_CALL_TOKEN && ![callToken isEqualToString:_callToken]) {
    NSLog(@"call token mismatch on VideoStreamOpened: %@ to actual %@", _callToken, callToken);
    return;
  }
  
  NSData *codecData = (NSData *)[messageComponents objectAtIndex:1];
  NSString *codec = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:codecData];
  
  NSData *sizeData = (NSData *)[messageComponents objectAtIndex:2];
  NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:sizeData];
  XMVideoSize videoSize = (XMVideoSize)[number unsignedIntValue];
  
  NSData *directionData = (NSData *)[messageComponents objectAtIndex:3];
  number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:directionData];
  BOOL isIncomingStream = [number boolValue];
  
  NSData *widthData = (NSData *)[messageComponents objectAtIndex:4];
  number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:widthData];
  unsigned width = [number unsignedIntValue];
  
  NSData *heightData = (NSData *)[messageComponents objectAtIndex:5];
  number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:heightData];
  unsigned height = [number unsignedIntValue];
  
  NSString *sizeString = nil;
  
  switch(videoSize) {
    case XMVideoSize_SQCIF:
      sizeString = @" (SQCIF)";
      break;
    case XMVideoSize_QCIF:
      sizeString = @" (QCIF)";
      break;
    case XMVideoSize_CIF:
      sizeString = @" (CIF)";
      break;
    case XMVideoSize_Custom:
      sizeString = [NSString stringWithFormat:@" (%dx%d)", width, height];
      break;
    default:
      sizeString = @" <unknown>";
      break;
  }
  
  NSString *codecString = [[NSString alloc] initWithFormat:@"%@%@", codec, sizeString];
  
  if (isIncomingStream == YES) {
    [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleIncomingVideoStreamOpened:)
                                                   withObject:codecString waitUntilDone:NO];
  } else {
    [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleOutgoingVideoStreamOpened:)
                                                   withObject:codecString waitUntilDone:NO];
  }
  
  [codecString release];
}

- (void)_handleAudioStreamClosedMessage:(NSArray *)messageComponents
{
  if (callToken == SHUTDOWN_CALL_TOKEN) {
    return; // shutting down anyway...
  }
  
  NSData *tokenData = (NSData *)[messageComponents objectAtIndex:0];
  NSString *_callToken = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
  
  if (![callToken isEqualToString:_callToken]) {
    NSLog(@"call token mismatch on MediaStreamClosed: %@ to actual %@", _callToken, callToken);
    return;
  }
  
  NSData *directionData = (NSData *)[messageComponents objectAtIndex:1];
  NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:directionData];
  BOOL isIncomingStream = [number boolValue];
  
  if (isIncomingStream == YES) {
    [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleIncomingAudioStreamClosed)
                                                   withObject:nil waitUntilDone:NO];
  } else {
    [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleOutgoingAudioStreamClosed)
                                                   withObject:nil waitUntilDone:NO];
  }
}

- (void)_handleVideoStreamClosedMessage:(NSArray *)messageComponents
{
  if (callToken == SHUTDOWN_CALL_TOKEN) {
    return; // shutting down anyway...
  }
  
  NSData *tokenData = (NSData *)[messageComponents objectAtIndex:0];
  NSString *_callToken = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
  
  if (![callToken isEqualToString:_callToken]) {
    NSLog(@"call token mismatch on MediaStreamClosed: %@ to actual %@", _callToken, callToken);
    return;
  }
  
  NSData *directionData = (NSData *)[messageComponents objectAtIndex:1];
  NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:directionData];
  BOOL isIncomingStream = [number boolValue];
  
  if (isIncomingStream == YES) {
    [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleIncomingVideoStreamClosed)
                                                   withObject:nil waitUntilDone:NO];
  } else {
    [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleOutgoingVideoStreamClosed)
                                                   withObject:nil waitUntilDone:NO];
  }
}

- (void)_handleFECCChannelOpenedMessage
{
  [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleFECCChannelOpened)
                                                 withObject:nil waitUntilDone:NO];
}

- (void)_handleSetUserInputModeMessage:(NSArray *)messageComponents
{
  NSData *modeData = (NSData *)[messageComponents objectAtIndex:0];
  NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:modeData];
  XMUserInputMode mode = (XMUserInputMode)[number unsignedIntValue];
  
  _XMSetUserInputMode(mode);
}

- (void)_handleSendUserInputToneMessage:(NSArray *)messageComponents
{
  if (callToken == SHUTDOWN_CALL_TOKEN) {
    return; // shutting down anyway...
  }
  
  NSData *tokenData = (NSData *)[messageComponents objectAtIndex:0];
  NSString *_callToken = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
  
  if (![callToken isEqualToString:_callToken]) {
    NSLog(@"call token mismatch on SendUserInputTone: %@ to actual %@", _callToken, callToken);
    return;
  }
  
  NSData *toneData = (NSData *)[messageComponents objectAtIndex:1];
  NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:toneData];
  char tone = [number charValue];
  
  _XMSendUserInputTone([callToken cStringUsingEncoding:NSASCIIStringEncoding], tone);
  
}

- (void)_handleSendUserInputStringMessage:(NSArray *)messageComponents
{
  if (callToken == SHUTDOWN_CALL_TOKEN) {
    return; // shutting down anyway...
  }
  
  NSData *tokenData = (NSData *)[messageComponents objectAtIndex:0];
  NSString *_callToken = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
  
  if (![callToken isEqualToString:_callToken]) {
    NSLog(@"call token mismatch on SendUserInputString: %@ to actual %@", _callToken, callToken);
    return;
  }
  
  NSData *stringData = (NSData *)[messageComponents objectAtIndex:1];
  NSString *string = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:stringData];
  
  _XMSendUserInputString([callToken cStringUsingEncoding:NSASCIIStringEncoding], [string cStringUsingEncoding:NSASCIIStringEncoding]);
}

- (void)_handleStartCameraEventMessage:(NSArray *)messageComponents
{
  if (callToken == SHUTDOWN_CALL_TOKEN) {
    return; // shutting down anyway...
  }
  
  NSData *tokenData = (NSData *)[messageComponents objectAtIndex:0];
  NSString *_callToken = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
  
  if (![callToken isEqualToString:_callToken]) {
    NSLog(@"call token mismatch on StartCameraEvent: %@ to actual %@", _callToken, callToken);
    return;
  }
  
  NSData *eventData = (NSData *)[messageComponents objectAtIndex:1];
  NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:eventData];
  XMCameraEvent cameraEvent = (XMCameraEvent)[number unsignedIntValue];
  
  _XMStartCameraEvent([callToken cStringUsingEncoding:NSASCIIStringEncoding], cameraEvent);
}

- (void)_handleStopCameraEventMessage:(NSArray *)messageComponents
{
  if (callToken == SHUTDOWN_CALL_TOKEN) {
    return; // shutting down anyway...
  }
  
  NSData *tokenData = (NSData *)[messageComponents objectAtIndex:0];
  NSString *_callToken = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
  
  if (![callToken isEqualToString:_callToken]) {
    NSLog(@"call token mismatch on StopCameraEvent: %@ to actual %@", _callToken, callToken);
    return;
  }
  
  _XMStopCameraEvent([callToken cStringUsingEncoding:NSASCIIStringEncoding]);
}

#pragma mark -
#pragma mark Setup Methods

- (void)_doPreferencesSetup:(XMPreferences *)preferences publicAddress:(NSString *)_publicAddress verbose:(BOOL)verbose
{
  // retain the preferences, used for the resync timer
  [currentPreferences release];
  currentPreferences = [preferences retain];
  
  // ***** Adjusting the general settings ***** //
  NSString *theUserName = [preferences userName];
  if (theUserName != nil) {
    const char *userName;
    userName = [theUserName cStringUsingEncoding:NSASCIIStringEncoding];
    _XMSetUserName(userName);
  }
  
  // Set bandwidth information
  _XMSetBandwidthLimit([preferences bandwidthLimit]);
  
  // Set which ports to use. Note that this has to be done
  // before setting the STUN information, or STUN would
  // use a different port range than the desired one
  // when launching the first time
  _XMSetPortRanges([preferences udpPortBase],
                   [preferences udpPortMax],
                   [preferences tcpPortBase],
                   [preferences tcpPortMax],
                   [preferences udpPortBase],
                   [preferences udpPortMax]);
  
  NSArray *stunServers = [preferences stunServers];
  unsigned numServers = [stunServers count];
  char const** servers = (char const**)malloc(numServers * sizeof(const char *));
  for (unsigned i = 0; i < numServers; i++) {
    NSString *serverName = [stunServers objectAtIndex:i];
    const char *serverString = [serverName cStringUsingEncoding:NSASCIIStringEncoding];
    servers[i] = serverString;
  }
  
  NSString *publicAddress = [preferences publicAddress];
  if (publicAddress == nil) {
    publicAddress = _publicAddress;
  }
  
  const char * thePublicAddress = [publicAddress cStringUsingEncoding:NSASCIIStringEncoding];
  _XMSetNATInformation(servers, numServers, thePublicAddress);
  
  free(servers);
  
  // ***** Adjusting the Audio Preferences ***** //
  
  _XMSetAudioFunctionality([preferences enableSilenceSuppression],
                           [preferences enableEchoCancellation],
                           [preferences audioPacketTime]);
  
  // ***** Adjusting the Video Preferences ***** //
  BOOL enableVideo = [preferences enableVideo];
  _XMSetEnableVideo(enableVideo);
  
  if (enableVideo == YES) {
    [XMMediaTransmitter _setFrameGrabRate:[preferences videoFramesPerSecond]];
  }
  
  BOOL enableH264LimitedMode = [preferences enableH264LimitedMode];
  _XMSetEnableH264LimitedMode(enableH264LimitedMode);
  
  // ***** Adjusting the Codec Order/Mask ***** //
  
  unsigned audioCodecCount = [preferences audioCodecListCount];
  unsigned videoCodecCount = [preferences videoCodecListCount];
  unsigned orderedCodecsCount = 0;
  unsigned disabledCodecsCount = 0;
  
  // for simplicity, we allocate the buffers big enough to hold all codecs
  unsigned orderedCodecsBufferSize = (audioCodecCount + videoCodecCount) * sizeof(const char *);
  unsigned disabledCodecsBufferSize = (audioCodecCount + videoCodecCount) * sizeof(const char *);
  char const** orderedCodecs = (char const**)malloc(orderedCodecsBufferSize);
  char const** disabledCodecs = (char const**)malloc(disabledCodecsBufferSize);
  
  for (unsigned i = 0; i < audioCodecCount; i++) {
    XMPreferencesCodecListRecord *record = [preferences audioCodecListRecordAtIndex:i];
    XMCodecIdentifier identifier = [record identifier];
    const char *mediaFormatString = _XMMediaFormatForCodecIdentifier(identifier);
    
    if ([record isEnabled]) {
      orderedCodecs[orderedCodecsCount] = mediaFormatString;
      orderedCodecsCount++;
    } else {
      disabledCodecs[disabledCodecsCount] = mediaFormatString;
      disabledCodecsCount++;
    }
  }
  
  for (unsigned i = 0; i < videoCodecCount; i++) {
    XMPreferencesCodecListRecord *record = [preferences videoCodecListRecordAtIndex:i];
    XMCodecIdentifier identifier = [record identifier];
    const char *mediaFormatString = _XMMediaFormatForCodecIdentifier(identifier);
    
    if ([record isEnabled]) {
      orderedCodecs[orderedCodecsCount] = mediaFormatString;
      orderedCodecsCount++;
    } else {
      disabledCodecs[disabledCodecsCount] = mediaFormatString;
      disabledCodecsCount++;
    }
  }
  
  _XMSetCodecs(orderedCodecs, orderedCodecsCount, disabledCodecs, disabledCodecsCount);
  
  free(orderedCodecs);
  free(disabledCodecs);
  
  // ***** Adjusting the SIP Preferences **** //
  
  // this is done before H.323 GK setup as SIP registration is done
  // asynchronously. We're waiting until the SIP registration is complete at the end
  // of the setup procedure
  [self _doSIPSetup:preferences verbose:verbose];
  
  // ***** Adjusting the H.323 Preferences ***** //
  [self _doH323Setup:preferences verbose:verbose];
}

- (void)_doH323Setup:(XMPreferences *)preferences verbose:(BOOL)verbose
{
  XMProtocolStatus protocolStatus;
  
  if ([preferences enableH323] == YES)
  {
    if (_XMEnableH323(YES) == YES) {
      protocolStatus = XMProtocolStatus_Enabled;
      
      _XMSetH323Functionality([preferences enableFastStart], [preferences enableH245Tunnel]);
      
      // setting up the gatekeeper
      [self _doGatekeeperSetup:preferences];
    } else { // Enabling the h323 subsystem failed
      protocolStatus = XMProtocolStatus_Error;
    }
  } else { // h323 disabled
    protocolStatus = XMProtocolStatus_Disabled;
    
    // unregistering from the gk if registered
    [gatekeeperRegistrationWaitLock lock]; // will be unlocked from another thread
    _XMSetGatekeeper(NULL, NULL, NULL, NULL);
    
    // disabling the H.323 Listeners 
    _XMEnableH323(NO);
  }
  
  if (verbose == YES) {
    NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:protocolStatus];
    [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleH323ProtocolStatus:) withObject:number waitUntilDone:NO];
    [number release];
  }
}

- (void)_doGatekeeperSetup:(XMPreferences *)preferences
{
  const char *gatekeeperAddress = "";
  const char *gatekeeperTerminalAlias1 = "";
  const char *gatekeeperTerminalAlias2 = "";
  const char *gatekeeperPassword = "";
  
  NSString *address = [preferences gatekeeperAddress];
  NSString *terminalAlias1 = [preferences gatekeeperTerminalAlias1];
  NSString *terminalAlias2 = [preferences gatekeeperTerminalAlias2];
  NSString *password = [preferences gatekeeperPassword];
  
  if (address != nil) {
    gatekeeperAddress = [address cStringUsingEncoding:NSASCIIStringEncoding];
  }
  if (terminalAlias1 != nil) {
    gatekeeperTerminalAlias1 = [terminalAlias1 cStringUsingEncoding:NSASCIIStringEncoding];
  }
  if (terminalAlias2 != nil) {
    gatekeeperTerminalAlias2 = [terminalAlias2 cStringUsingEncoding:NSASCIIStringEncoding];
  }
  if (password != nil) {
    gatekeeperPassword = [password cStringUsingEncoding:NSASCIIStringEncoding];
  }
  
  // the result of this operation will be handled through callbacks
  [gatekeeperRegistrationWaitLock lock]; // will be unlocked from another thread
  _XMSetGatekeeper(gatekeeperAddress, 
                   gatekeeperTerminalAlias1, 
                   gatekeeperTerminalAlias2,
                   gatekeeperPassword);
}

- (void)_doSIPSetup:(XMPreferences *)preferences verbose:(BOOL)verbose
{
  XMProtocolStatus protocolStatus;
  
  if ([preferences enableSIP] == YES) {
    BOOL proxyInfoChanged = NO;
    
    if (_XMEnableSIP(YES) == YES) {
      protocolStatus = XMProtocolStatus_Enabled;
      
      // Update the proxy information
      NSString *host = [preferences sipProxyHost];
      NSString *username = [preferences sipProxyUsername];
      NSString *password = [preferences sipProxyPassword];
      const char *proxyHost = [host cStringUsingEncoding:NSASCIIStringEncoding];
      const char *proxyUsername = [username cStringUsingEncoding:NSASCIIStringEncoding];
      const char *proxyPassword = [password cStringUsingEncoding:NSASCIIStringEncoding];
      proxyInfoChanged = _XMSetSIPProxy(proxyHost, proxyUsername, proxyPassword);
      
      [self _doRegistrationSetup:preferences proxyChanged:proxyInfoChanged];
    } else {
      protocolStatus = XMProtocolStatus_Error;
    }
  } else { // SIP disabled
    protocolStatus = XMProtocolStatus_Disabled;
    
    _XMSetSIPProxy(NULL, NULL, NULL);
    
    // unregistering if needed
    [sipRegistrationWaitLock lock]; // will be unlocked from within _XMFinishRegistrationSetup()
    _XMPrepareRegistrationSetup(NO);
    _XMFinishRegistrationSetup(NO);
    
    // disabling the SIP Listeners
    _XMEnableSIP(NO);
  }
  
  if (verbose == YES) {
    NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:protocolStatus];
    [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleSIPProtocolStatus:) withObject:number waitUntilDone:NO];
    [number release];
  }
}

- (void)_doRegistrationSetup:(XMPreferences *)preferences proxyChanged:(BOOL)proxyInfoChanged
{
  NSArray *records = [preferences sipRegistrationRecords];
  unsigned count = [records count];
  
  [sipRegistrationWaitLock lock]; // will be unlocked from within -_handleSIPRegistrationSetupComplete
  
  _XMPrepareRegistrationSetup(proxyInfoChanged);
  
  for (unsigned i = 0; i < count; i++) {
    XMPreferencesRegistrationRecord *record = (XMPreferencesRegistrationRecord *)[records objectAtIndex:i];
    if (![record isKindOfClass:[XMPreferencesRegistrationRecord class]]) {
      continue;
    }
    
    const char *registrationDomain = NULL;
    const char *registrationUsername = NULL;
    const char *registrationAuthorizationUsername = NULL;
    const char *registrationPassword = NULL;
    
    NSString *domain = [record domain];
    NSString *username = [record username];
    NSString *authorizationUsername = [record authorizationUsername];
    NSString *password = [record password];
    
    if (username != nil) {
      registrationDomain = [domain cStringUsingEncoding:NSASCIIStringEncoding];
      registrationUsername = [username cStringUsingEncoding:NSASCIIStringEncoding];
      registrationAuthorizationUsername = [authorizationUsername cStringUsingEncoding:NSASCIIStringEncoding];
      registrationPassword = [password cStringUsingEncoding:NSASCIIStringEncoding];
      
      _XMUseRegistration(registrationDomain, registrationUsername, registrationAuthorizationUsername, registrationPassword, proxyInfoChanged);
    }
  }
  
  _XMFinishRegistrationSetup(proxyInfoChanged);
}

- (void)_waitForSubsystemSetupCompletion
{
  // Since the registrations perform asynchronously,
  // we wait here until this task has completed
  [gatekeeperRegistrationWaitLock lock];
  [gatekeeperRegistrationWaitLock unlock];
  [sipRegistrationWaitLock lock];
  [sipRegistrationWaitLock unlock];
}

#pragma mark -
#pragma mark Subsystem Feedback

- (void)_handleNATType:(XMNATType)natType publicAddress:(NSString *)publicAddress
{
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:(unsigned)natType];
  NSArray *array = [[NSArray alloc] initWithObjects:number, publicAddress, nil];
  
  [_XMUtilsSharedInstance performSelectorOnMainThread:@selector(_handleSTUNInformation:) withObject:array waitUntilDone:NO];
  
  [array release];
  [number release];
}

- (void)_handleGatekeeperRegistration:(NSString *)gatekeeperName aliases:(NSArray *)aliases
{
  NSArray *arr = [[NSArray alloc] initWithObjects:gatekeeperName, aliases, nil];
  [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleGatekeeperRegistration:)
                                                 withObject:arr
                                              waitUntilDone:NO];
  [arr release];
}

- (void)_handleGatekeeperRegistrationFailure:(XMGatekeeperRegistrationStatus)failReason
{
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:(unsigned)failReason];
  [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleGatekeeperRegistrationFailure:)
                                                 withObject:number
                                              waitUntilDone:NO];
  [number release];
}

- (void)_handleGatekeeperUnregistration
{
  [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleGatekeeperUnregistration) withObject:nil waitUntilDone:NO];
}

- (void)_handleSIPRegistration:(NSString *)aor
{
  [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleSIPRegistration:) withObject:aor waitUntilDone:NO];
}

- (void)_handleSIPUnregistration:(NSString *)aor
{
  [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleSIPUnregistration:) withObject:aor waitUntilDone:NO];
}

- (void)_handleSIPRegistrationFailure:(NSString *)aor failReason:(XMSIPStatusCode)failReason
{
  NSNumber *errorNumber = [[NSNumber alloc] initWithUnsignedInt:failReason];
  NSArray *array = [[NSArray alloc] initWithObjects:aor, errorNumber, nil];
  
  [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleSIPRegistrationFailure:)
                                                 withObject:array
                                              waitUntilDone:NO];
  
  
  [array release];
  [errorNumber release];
}

- (void)_handleGatekeeperRegistrationComplete
{
  [gatekeeperRegistrationWaitLock unlock];
}

- (void)_handleSIPRegistrationComplete
{
  [sipRegistrationWaitLock unlock];
}

- (void)_handleCallStartToken:(NSString *)_callToken callEndReason:(XMCallEndReason)_callEndReason
{
  // call token must be nil
  callToken = [_callToken copy];
  callEndReason = _callEndReason;
}

#pragma mark -
#pragma mark Methods fired by Timers

- (void)_resyncSubsystem:(NSTimer *)timer
{
  if (currentPreferences == nil) {
    return;
  }
  
  BOOL enableH323 = [currentPreferences enableH323];
  BOOL enableSIP = [currentPreferences enableSIP];
  
  // retry to enable H.323 if it previously failed
  if (enableH323 && _XMIsH323Enabled() == NO) {
    [self _doH323Setup:currentPreferences verbose:YES];
  }
  // if the gatekeeper registration fails, the OPAL gatekeeper code will automatically try
  // to re-register
  
  // retry to enable SIP if it previously failed
  if (enableSIP && _XMIsSIPEnabled() == NO) {
    [self _doSIPSetup:currentPreferences verbose:YES]; 
  }
}

- (void)_updateCallStatistics:(NSTimer *)timer
{
  XMCallStatistics *callStatistics = [[XMCallStatistics alloc] _init];
  
  _XMGetCallStatistics([callToken cStringUsingEncoding:NSASCIIStringEncoding], [callStatistics _callStatisticsRecord]);
  
  [XMMediaTransmitter _setVideoBytesSent:[callStatistics _callStatisticsRecord]->videoBytesSent];
  
  [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleCallStatisticsUpdate:)
                                                 withObject:callStatistics
                                              waitUntilDone:NO];
  
  [callStatistics release];
}

#pragma mark -
#pragma mark Private Helper Methods

- (void)_doInitiateCallToAddress:(NSString *)address protocol:(XMCallProtocol)protocol
{
  // sanity checks. They are done here since the exact subsystem status is known only here
  if ((protocol == XMCallProtocol_H323) && (_XMIsH323Enabled() == NO)) {
    // Trying to make a H.323 call but H.323 isn't enabled
    [self _sendCallStartFailReason:XMCallStartFailReason_H323NotEnabled address:address];
    return;
  }
  if ((protocol == XMCallProtocol_H323) && XMIsPhoneNumber(address) && (_XMIsRegisteredAtGatekeeper() == NO)) {
    [self _sendCallStartFailReason:XMCallStartFailReason_GatekeeperRequired address:address];
    return;
  }
  if ((protocol == XMCallProtocol_SIP) && (_XMIsSIPEnabled() == NO)) {
    [self _sendCallStartFailReason:XMCallStartFailReason_SIPNotEnabled address:address];
    return;
  }
  if ((protocol == XMCallProtocol_SIP) && XMIsPhoneNumber(address) && (_XMIsSIPRegistered() == NO)) {
    [self _sendCallStartFailReason:XMCallStartFailReason_SIPRegistrationRequired address:address];
    return;
  }
  
  // adjust address if needed
  NSString *adjustedAddress = [self _adjustedAddress:address protocol:protocol];
  
  const char *addressString = [adjustedAddress cStringUsingEncoding:NSASCIIStringEncoding];
  const char *origAddressString = [address cStringUsingEncoding:NSASCIIStringEncoding];
  
  _XMInitiateCall(protocol, addressString, origAddressString); // will set the call token through a callback
  
  if (callToken == nil) {
    XMCallStartFailReason failReason = XMCallStartFailReason_UnknownFailure;
    if (callEndReason == XMCallEndReason_EndedByTransportFail) {
      failReason = XMCallStartFailReason_TransportFail;
    } else if (callEndReason == XMCallEndReason_EndedByNoNetworkInterfaces) {
      failReason = XMCallStartFailReason_NoNetworkInterfaces;
    }
    
    // Initiating the call failed
    [self _sendCallStartFailReason:failReason address:address];
  } else {
    // the missing information is added later on, when the remote party details are known
    XMCallInfo *callInfo = [[XMCallInfo alloc] _initWithCallToken:callToken
                                                         protocol:protocol
                                                       remoteName:nil
                                                     remoteNumber:nil
                                                    remoteAddress:nil
                                                remoteApplication:nil
                                                      callAddress:address
                                                     localAddress:nil
                                                       callStatus:XMCallStatus_Calling];
    
    [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleCallInitiated:)
                                                   withObject:callInfo
                                                waitUntilDone:nil];
    
    [callInfo release];
  }
}

- (void)_sendCallStartFailReason:(XMCallStartFailReason)reason address:(NSString *)address
{
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:(unsigned)reason];
  NSArray *info = [[NSArray alloc] initWithObjects:number, address, nil];
  [number release];
  
  [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleCallInitiationFailed:)
                                                 withObject:info
                                              waitUntilDone:NO];
  [info release];
}

- (NSString *)_adjustedAddress:(NSString *)address protocol:(XMCallProtocol)callProtocol
{
  if (callProtocol == XMCallProtocol_H323 && _XMIsRegisteredAtGatekeeper() == YES) {
    // Try to do DNS lookups. This is needed to workaround problems with
    // DNS addresses and Gatekeepers in recent versions of OPAL
    NSHost *host = [NSHost hostWithName:address];
    NSArray *addresses = [host addresses];
    unsigned count = [addresses count];
    unsigned i;
    for (i = 0; i < count; i++) {
      NSString *resolvedAddress = [addresses objectAtIndex:i];
      // at the moment only IPv4 addresses are accepted
      if (XMIsIPAddress(resolvedAddress)) {
        return resolvedAddress;
      }
    }
  }
  
  return address;
}

@end
