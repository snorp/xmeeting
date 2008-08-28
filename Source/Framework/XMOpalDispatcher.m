/*
 * $Id: XMOpalDispatcher.m,v 1.53 2008/08/28 11:07:22 hfriederich Exp $
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

typedef enum _XMOpalDispatcherMessage
{
  // General messages
  _XMOpalDispatcherMessage_Shutdown = 0x0000,
  
  // Setup messages
  _XMOpalDispatcherMessage_SetPreferences = 0x0100,
  _XMOpalDispatcherMessage_HandleNetworkConfigurationChange,
  
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
- (void)_handleRetryEnableH323Message:(NSArray *)messageComponents;
- (void)_handleRetryGatekeeperRegistrationMessage:(NSArray *)messageComponents;
- (void)_handleRetryEnableSIPMessage:(NSArray *)messageComponents;
- (void)_handleRetrySIPRegistrationsMessage:(NSArray *)messageComponents;
- (void)_handleNetworkConfigurationChangeMessage;

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
       networkConfigurationChanged:(BOOL)networkConfigurationChanged
                    verbose:(BOOL)verbose;
- (void)_doH323Setup:(XMPreferences *)preferences verbose:(BOOL)verbose block:(BOOL)block;
- (void)_doGatekeeperSetup:(XMPreferences *)preferences block:(BOOL)block;
- (void)_doSIPSetup:(XMPreferences *)preferences verbose:(BOOL)verbose;
- (void)_doRegistrationSetup:(XMPreferences *)preferences verbose:(BOOL)verbose proxyChanged:(BOOL)proxyChanged;

- (void)_waitForSubsystemSetupCompletion:(BOOL)verbose;

- (void)_resyncSubsystem:(NSTimer *)timer;
- (void)_updateCallStatistics:(NSTimer *)timer;

- (void)_initiateCallToAddress:(NSString *)address protocol:(XMCallProtocol)callProtocol;
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
   networkConfigurationChanged:(BOOL)networkConfigurationChanged
{
  NSData *preferencesData = [NSKeyedArchiver archivedDataWithRootObject:preferences];
  NSData *publicAddressData = [NSKeyedArchiver archivedDataWithRootObject:publicAddress];
  NSData *networkConfigurationChangedData = [NSKeyedArchiver archivedDataWithRootObject:[NSNumber numberWithBool:networkConfigurationChanged]];
  
  NSArray *components = [[NSArray alloc] initWithObjects:preferencesData, publicAddressData, networkConfigurationChangedData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_SetPreferences withComponents:components];
  
  [components release];
}

+ (void)_handleNetworkConfigurationChange
{
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_HandleNetworkConfigurationChange withComponents:nil];
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

+ (void)_callIsAlerting:(unsigned)callID
{
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:callID];
  NSData *idData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  NSArray *components = [[NSArray alloc] initWithObjects:idData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_CallIsAlerting withComponents:components];
  
  [components release];
}

+ (void)_incomingCall:(unsigned)callID
             protocol:(XMCallProtocol)protocol
           remoteName:(NSString *)remoteName
         remoteNumber:(NSString *)remoteNumber
        remoteAddress:(NSString *)remoteAddress
    remoteApplication:(NSString *)remoteApplication
         localAddress:(NSString *)localAddress
{
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:callID];
  NSData *callData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  number = [[NSNumber alloc] initWithUnsignedInt:(unsigned)protocol];
  NSData *protocolData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  NSData *nameData = [NSKeyedArchiver archivedDataWithRootObject:remoteName];
  NSData *numberData = [NSKeyedArchiver archivedDataWithRootObject:remoteNumber];
  NSData *addressData = [NSKeyedArchiver archivedDataWithRootObject:remoteAddress];
  NSData *applicationData = [NSKeyedArchiver archivedDataWithRootObject:remoteApplication];
  NSData *localAddressData = [NSKeyedArchiver archivedDataWithRootObject:localAddress];
  
  NSArray *components = [[NSArray alloc] initWithObjects:callData, protocolData, nameData,
    numberData, addressData, applicationData, 
    localAddressData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_IncomingCall withComponents:components];
  
  [components release];
}

+ (void)_acceptIncomingCall:(unsigned)callID
{
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:callID];
  NSData *idData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  NSArray *components = [[NSArray alloc] initWithObjects:idData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_AcceptIncomingCall withComponents:components];
  
  [components release];
}

+ (void)_rejectIncomingCall:(unsigned)callID
{
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:callID];
  NSData *idData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  NSArray *components = [[NSArray alloc] initWithObjects:idData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_RejectIncomingCall withComponents:components];
  
  [components release];
}

+ (void)_callEstablished:(unsigned)callID incoming:(BOOL)isIncomingCall localAddress:(NSString *)localAddress
{
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:callID];
  NSData *idData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  number = [[NSNumber alloc] initWithBool:isIncomingCall];
  NSData *incomingData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  NSData *addressData = [NSKeyedArchiver archivedDataWithRootObject:localAddress];
  
  NSArray *components = [[NSArray alloc] initWithObjects:idData, incomingData, addressData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_CallEstablished withComponents:components];
  
  [components release];
}

+ (void)_clearCall:(unsigned)callID
{
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:callID];
  NSData *idData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  NSArray *components = [[NSArray alloc] initWithObjects:idData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_ClearCall withComponents:components];
  
  [components release];
}

+ (void)_callCleared:(unsigned)callID reason:(XMCallEndReason)callEndReason
{
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:callID];
  NSData *idData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  number = [[NSNumber alloc] initWithUnsignedInt:(unsigned)callEndReason];
  NSData *callEndReasonData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  NSArray *components = [[NSArray alloc] initWithObjects:idData, callEndReasonData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_CallCleared withComponents:components];
  
  [components release];
}

+ (void)_callReleased:(unsigned)callID localAddress:(NSString *)localAddress
{
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:callID];
  NSData *idData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  NSData *addressData = [NSKeyedArchiver archivedDataWithRootObject:localAddress];
  
  NSArray *components = [[NSArray alloc] initWithObjects:idData, addressData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_CallReleased withComponents:components];
  
  [components release];
}

+ (void)_audioStreamOpened:(unsigned)callID codec:(NSString *)codec incoming:(BOOL)isIncomingStream
{
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:callID];
  NSData *idData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  NSData *codecData = [NSKeyedArchiver archivedDataWithRootObject:codec];
  
  number = [[NSNumber alloc] initWithBool:isIncomingStream];
  NSData *incomingData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  NSArray *components = [[NSArray alloc] initWithObjects:idData, codecData, incomingData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_AudioStreamOpened withComponents:components];
  
  [components release];
}

+ (void)_videoStreamOpened:(unsigned)callID codec:(NSString *)codec size:(XMVideoSize)videoSize incoming:(BOOL)isIncomingStream
                     width:(unsigned)width height:(unsigned)height
{
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:callID];
  NSData *idData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  NSData *codecData = [NSKeyedArchiver archivedDataWithRootObject:codec];
  
  number = [[NSNumber alloc] initWithUnsignedInt:videoSize];
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
  
  NSArray *components = [[NSArray alloc] initWithObjects:idData, codecData, sizeData, incomingData, widthData, heightData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_VideoStreamOpened withComponents:components];
  
  [components release];
}

+ (void)_audioStreamClosed:(unsigned)callID incoming:(BOOL)isIncomingStream
{
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:callID];
  NSData *idData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  number = [[NSNumber alloc] initWithBool:isIncomingStream];
  NSData *incomingData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  NSArray *components = [[NSArray alloc] initWithObjects:idData, incomingData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_AudioStreamClosed withComponents:components];
  
  [components release];
}

+ (void)_videoStreamClosed:(unsigned)callID incoming:(BOOL)isIncomingStream
{
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:callID];
  NSData *idData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  number = [[NSNumber alloc] initWithBool:isIncomingStream];
  NSData *incomingData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  NSArray *components = [[NSArray alloc] initWithObjects:idData, incomingData, nil];
  
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

+ (void)_sendUserInputToneForCall:(unsigned)callID tone:(char)tone
{
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:callID];
  NSData *idData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  number = [[NSNumber alloc] initWithChar:tone];
  NSData *toneData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  NSArray *components = [[NSArray alloc] initWithObjects:idData, toneData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_SendUserInputTone withComponents:components];
  
  [components release];
}

+ (void)_sendUserInputStringForCall:(unsigned)callID string:(NSString *)string
{
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:callID];
  NSData *idData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  NSData *stringData = [NSKeyedArchiver archivedDataWithRootObject:string];
  
  NSArray *components = [[NSArray alloc] initWithObjects:idData, stringData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_SendUserInputString withComponents:components];
  
  [components release];
}

+ (void)_startCameraEventForCall:(unsigned)callID event:(XMCameraEvent)event
{
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:callID];
  NSData *idData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  number = [[NSNumber alloc] initWithUnsignedInt:event];
  NSData *eventData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  NSArray *components = [[NSArray alloc] initWithObjects:idData, eventData, nil];
  
  [XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_StartCameraEvent withComponents:components];
  
  [components release];
}

+ (void)_stopCameraEventForCall:(unsigned)callID
{
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:callID];
  NSData *idData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  
  NSArray *components = [[NSArray alloc] initWithObjects:idData, nil];
  
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
  
  callID = 0;
  
  controlTimer = nil;
  callStatisticsUpdateIntervalTimer = nil;
  
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

- (void)_runOpalDispatcherThread:(NSString *)pTracePath
{
  NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
  
  [receivePort setDelegate:self];
  [[NSRunLoop currentRunLoop] addPort:receivePort forMode:NSDefaultRunLoopMode];
  
  // Initiating the OPAL subsystem
  const char *pathString = [pTracePath cStringUsingEncoding:NSASCIIStringEncoding];
  _XMInitSubsystem(pathString);
  
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
  if (callID != 0) {
    // we have to terminate the call first
    // and we wait until the call is cleared before shutting down the system entirely
    [self _handleClearCallMessage:nil];
    callID = UINT_MAX;
    return;
  }
  
  // By using the default XMPreferences instance,
  // we shutdown the subsystem
  XMPreferences *preferences = [[XMPreferences alloc] init];
  [self _doPreferencesSetup:preferences publicAddress:nil networkConfigurationChanged:NO verbose:NO];
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
  
  NSData *networkConfigurationChangedData = (NSData *)[components objectAtIndex:2];
  BOOL networkConfigurationChanged = [(NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:networkConfigurationChangedData] boolValue];
  
  [self _doPreferencesSetup:preferences publicAddress:publicAddress networkConfigurationChanged:networkConfigurationChanged verbose:YES];
  
  [self _waitForSubsystemSetupCompletion:YES];
  
  [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleSubsystemSetupEnd) withObject:nil waitUntilDone:NO];
}

- (void)_handleNetworkConfigurationChangeMessage
{
  _XMHandleNetworkConfigurationChange();
}

- (void)_handleInitiateCallMessage:(NSArray *)components
{
  NSData *addressData = (NSData *)[components objectAtIndex:0];
  NSString *address = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:addressData];
  NSData *protocolData = (NSData *)[components objectAtIndex:1];
  NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:protocolData];
  XMCallProtocol protocol = (XMCallProtocol)[number unsignedIntValue];
  
  if (callID != 0) {
    // This probably indicates that an incoming call arrived at exactly the same time than
    // the user tried to initiate this call. Since the incoming call arrived first,
    // we cannot call anyone at the moment
    [self _sendCallStartFailReason:XMCallStartFailReason_AlreadyInCall address:address];
    return;
  }
  
  [self _initiateCallToAddress:address protocol:protocol];
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
  
  if (callID != 0) {
    // This probably indicates that an incoming call arrived at exactly the same time than
    // the user tried to initiate this call. Since the incoming call arrived first,
    // we cannot call anyone at the moment
    [self _sendCallStartFailReason:XMCallStartFailReason_AlreadyInCall address:address];
    return;
  }
  
  [self _doPreferencesSetup:preferences publicAddress:publicAddress networkConfigurationChanged:NO verbose:NO];
  
  [self _initiateCallToAddress:address protocol:callProtocol];	
}

- (void)_handleCallIsAlertingMessage:(NSArray *)messageComponents
{
  NSData *idData = (NSData *)[messageComponents objectAtIndex:0];
  NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:idData];
  unsigned theCallID = [number unsignedIntValue];
  
  if ((theCallID != callID) && (callID != UINT_MAX)) {
    NSLog(@"CallID mismatch on IsAlerting: %d to currently %d", (int)theCallID, (int)callID);
    return;
  }
  
  if (callID == UINT_MAX) {
    // we are shutting down anyway...
    return;
  }
  
  [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleCallIsAlerting)
                                                 withObject:nil
                                              waitUntilDone:NO];
}

- (void)_handleIncomingCallMessage:(NSArray *)messageComponents
{
  NSData *idData = (NSData *)[messageComponents objectAtIndex:0];
  NSData *protocolData = (NSData *)[messageComponents objectAtIndex:1];
  NSData *remoteNameData = (NSData *)[messageComponents objectAtIndex:2];
  NSData *remoteNumberData = (NSData *)[messageComponents objectAtIndex:3];
  NSData *remoteAddressData = (NSData *)[messageComponents objectAtIndex:4];
  NSData *remoteApplicationData = (NSData *)[messageComponents objectAtIndex:5];
  NSData *localAddressData = (NSData *)[messageComponents objectAtIndex:6];
  
  NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:idData];
  unsigned theCallID = [number unsignedIntValue];
  
  if (callID != 0) {
    NSLog(@"have already call ongoing");
    
    if (theCallID > callID) {
      NSLog(@"Incoming greater than callID");
    } else if (theCallID < callID) {
      NSLog(@"INcoming less than callID");
    } else {
      NSLog(@"Incoming EQUAL callID!!!!!");
    }
    return;
  }
  
  callID = theCallID;
  
  number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:protocolData];
  XMCallProtocol protocol = (XMCallProtocol)[number unsignedIntValue];
  
  NSString *remoteName = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:remoteNameData];
  NSString *remoteNumber = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:remoteNumberData];
  NSString *remoteAddress = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:remoteAddressData];
  NSString *remoteApplication = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:remoteApplicationData];
  NSString *localAddress = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:localAddressData];
  
  XMCallInfo *callInfo = [[XMCallInfo alloc] _initWithCallID:callID
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
  NSData *idData = (NSData *)[messageComponents objectAtIndex:0];
  NSNumber *idNumber = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:idData];
  unsigned theCallID = [idNumber unsignedIntValue];
  
  if (theCallID != callID) {
    NSLog(@"callID mismatch in accpetIncomingCall: %d to current %d", (int)theCallID, (int)callID);
    return;
  }
  
  _XMAcceptIncomingCall(callID);
}

- (void)_handleRejectIncomingCallMessage:(NSArray *)messageComponents
{
  NSData *idData = (NSData *)[messageComponents objectAtIndex:0];
  NSNumber *idNumber = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:idData];
  unsigned theCallID = [idNumber unsignedIntValue];
  
  if (theCallID != callID) {
    NSLog(@"callID mismatch in rejectIncomingCall: %d to current %d", (int)theCallID, (int)callID);
    return;
  }
  
  _XMRejectIncomingCall(callID);
}

- (void)_handleCallEstablishedMessage:(NSArray *)messageComponents
{
  NSData *idData = (NSData *)[messageComponents objectAtIndex:0];
  NSNumber *idNumber = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:idData];
  unsigned theCallID = [idNumber unsignedIntValue];
  
  NSData *incomingData = (NSData *)[messageComponents objectAtIndex:1];
  NSNumber *incomingNumber = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:incomingData];
  BOOL isIncomingCall = [incomingNumber boolValue];
  
  NSData *localAddressData = (NSData *)[messageComponents objectAtIndex:2];
  NSString *localAddress = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:localAddressData];
  
  if (theCallID != callID) {
    NSLog(@"callID mismatch in callEstablished: %d to current %d", (int)theCallID, (int)callID);
    return;
  }
  
  NSArray *remotePartyInformations = nil;
  
  if (isIncomingCall == NO) {
    const char *remoteName;
    const char *remoteNumber;
    const char *remoteAddress;
    const char *remoteApplication;
    
    _XMLockCallInformation();
    _XMGetCallInformation(callID, &remoteName, &remoteNumber, &remoteAddress, &remoteApplication);
    
    NSString *remoteNameString = [[NSString alloc] initWithCString:remoteName encoding:NSASCIIStringEncoding];
    NSString *remoteNumberString = [[NSString alloc] initWithCString:remoteNumber encoding:NSASCIIStringEncoding];
    NSString *remoteAddressString = [[NSString alloc] initWithCString:remoteAddress encoding:NSASCIIStringEncoding];
    NSString *remoteApplicationString = [[NSString alloc] initWithCString:remoteApplication encoding:NSASCIIStringEncoding];
    
    _XMUnlockCallInformation();
    
    remotePartyInformations = [[NSArray alloc] initWithObjects:remoteNameString, remoteNumberString, remoteAddressString,
      remoteApplicationString, localAddress, nil];
    
    [remoteNameString release];
    [remoteNumberString release];
    [remoteAddressString release];
    [remoteApplicationString release];
  }
  
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
    NSData *idData = (NSData *)[messageComponents objectAtIndex:0];
    NSNumber *idNumber = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:idData];
    unsigned theCallID = [idNumber unsignedIntValue];
    
    if (theCallID != callID) {
      NSLog(@"callID mismatch in clearCall: %d to current %d", (int)theCallID, (int)callID);
      return;
    }
  }
  
  _XMClearCall(callID);
}

- (void)_handleCallClearedMessage:(NSArray *)messageComponents
{
  NSData *idData = (NSData *)[messageComponents objectAtIndex:0];
  NSNumber *callIDNumber = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:idData];
  unsigned theCallID = [callIDNumber unsignedIntValue];
  
  // If call initiation fails, no callID is set (zero), don't log this
  if ((theCallID != callID) && (callID != UINT_MAX) && (callID != 0)) {
    NSLog(@"callID mismatch in callCleared: %d to current %d", (int)theCallID, (int)callID);
    return;
  }
  
  _XMStopAudio();
  
  NSData *callEndReasonData = (NSData *)[messageComponents objectAtIndex:1];
  NSNumber *callEndReason = [NSKeyedUnarchiver unarchiveObjectWithData:callEndReasonData];
  
  [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleCallCleared:)
                                                 withObject:callEndReason
                                              waitUntilDone:NO];
  
  if (callID == UINT_MAX) {
    // the framework is closing
    callID = 0;
    [self _handleShutdownMessage];
  }
  
  if (callStatisticsUpdateIntervalTimer != nil) {
    [callStatisticsUpdateIntervalTimer invalidate];
    [callStatisticsUpdateIntervalTimer release];
    callStatisticsUpdateIntervalTimer = nil;
  }
  
  callID = 0;
}

- (void)_handleCallReleasedMessage:(NSArray *)messageComponents
{
  NSData *idData = (NSData *)[messageComponents objectAtIndex:0];
  NSNumber *callIDNumber = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:idData];
  unsigned theCallID = [callIDNumber unsignedIntValue];
  
  if ((theCallID != callID) && (callID != UINT_MAX)) {
    NSLog(@"callID mismatch in callReleased: %d to current %d", (int)theCallID, (int)callID);
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
  NSData *idData = (NSData *)[messageComponents objectAtIndex:0];
  NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:idData];
  unsigned theCallID = [number unsignedIntValue];
  
  if (theCallID != callID) {
    NSLog(@"CallID mismatch on AudioStreamOpened: %d to actual %d", theCallID, callID);
    return;
  }
  
  NSData *codecData = (NSData *)[messageComponents objectAtIndex:1];
  NSString *codec = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:codecData];
  
  NSData *directionData = (NSData *)[messageComponents objectAtIndex:2];
  number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:directionData];
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
  NSData *idData = (NSData *)[messageComponents objectAtIndex:0];
  NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:idData];
  unsigned theCallID = [number unsignedIntValue];
  
  if (theCallID != 0 && theCallID != callID) {
    NSLog(@"CallID mismatch on VideoStreamOpened: %d to actual %d", theCallID, callID);
    return;
  }
  
  NSData *codecData = (NSData *)[messageComponents objectAtIndex:1];
  NSString *codec = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:codecData];
  
  NSData *sizeData = (NSData *)[messageComponents objectAtIndex:2];
  number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:sizeData];
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
  NSData *idData = (NSData *)[messageComponents objectAtIndex:0];
  NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:idData];
  unsigned theCallID = [number unsignedIntValue];
  
  if ((theCallID != callID) && (callID != UINT_MAX)) {
    NSLog(@"CallID mismatch on MediaStreamClosed: %d to actual %d", theCallID, callID);
    return;
  }
  
  NSData *directionData = (NSData *)[messageComponents objectAtIndex:1];
  number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:directionData];
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
  NSData *idData = (NSData *)[messageComponents objectAtIndex:0];
  NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:idData];
  unsigned theCallID = [number unsignedIntValue];
  
  if ((theCallID != callID) && (callID != UINT_MAX)) {
    NSLog(@"CallID mismatch on MediaStreamClosed: %d to actual %d", theCallID, callID);
    return;
  }
  
  NSData *directionData = (NSData *)[messageComponents objectAtIndex:1];
  number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:directionData];
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
  NSData *idData = (NSData *)[messageComponents objectAtIndex:0];
  NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:idData];
  unsigned theCallID = [number unsignedIntValue];
  
  if ((theCallID != callID) && (callID != UINT_MAX)) {
    NSLog(@"CallID mismatch on StartCameraEvent: %d to actual %d", theCallID, callID);
    return;
  }
  
  NSData *toneData = (NSData *)[messageComponents objectAtIndex:1];
  number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:toneData];
  char tone = [number charValue];
  
  _XMSendUserInputTone(theCallID, tone);
  
}

- (void)_handleSendUserInputStringMessage:(NSArray *)messageComponents
{
  NSData *idData = (NSData *)[messageComponents objectAtIndex:0];
  NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:idData];
  unsigned theCallID = [number unsignedIntValue];
  
  if ((theCallID != callID) && (callID != UINT_MAX)) {
    NSLog(@"CallID mismatch on StartCameraEvent: %d to actual %d", theCallID, callID);
    return;
  }
  
  NSData *stringData = (NSData *)[messageComponents objectAtIndex:1];
  NSString *string = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:stringData];
  
  const char *theString = [string cStringUsingEncoding:NSASCIIStringEncoding];
  
  _XMSendUserInputString(theCallID, theString);
}

- (void)_handleStartCameraEventMessage:(NSArray *)messageComponents
{
  NSData *idData = (NSData *)[messageComponents objectAtIndex:0];
  NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:idData];
  unsigned theCallID = [number unsignedIntValue];
  
  if ((theCallID != callID) && (callID != UINT_MAX)) {
    NSLog(@"CallID mismatch on StartCameraEvent: %d to actual %d", theCallID, callID);
    return;
  }
  
  NSData *eventData = (NSData *)[messageComponents objectAtIndex:1];
  number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:eventData];
  XMCameraEvent cameraEvent = (XMCameraEvent)[number unsignedIntValue];
  
  _XMStartCameraEvent(theCallID, cameraEvent);
}

- (void)_handleStopCameraEventMessage:(NSArray *)messageComponents
{
  NSData *idData = (NSData *)[messageComponents objectAtIndex:0];
  NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:idData];
  unsigned theCallID = [number unsignedIntValue];
  
  if ((theCallID != callID) && (callID != UINT_MAX)) {
    NSLog(@"CallID mismatch on StopCameraEvent: %d to actual %d", theCallID, callID);
    return;
  }
  
  _XMStopCameraEvent(theCallID);
}

#pragma mark -
#pragma mark Setup Methods

- (void)_doPreferencesSetup:(XMPreferences *)preferences publicAddress:(NSString *)suppliedExternalAddress
       networkConfigurationChanged:(BOOL)networkConfigurationChanged verbose:(BOOL)verbose
{
  // retain the preferences, used for the resync timer
  [currentPreferences release];
  currentPreferences = [preferences retain];
  
  if (networkConfigurationChanged) {
    _XMHandleNetworkConfigurationChange();
  }
  
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
    publicAddress = suppliedExternalAddress;
  }
  
  const char * translationAddress = [publicAddress cStringUsingEncoding:NSASCIIStringEncoding];
  _XMSetNATInformation(servers, numServers, translationAddress, networkConfigurationChanged);
  
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
  [self _doH323Setup:preferences verbose:verbose block:YES];
}

- (void)_doH323Setup:(XMPreferences *)preferences verbose:(BOOL)verbose block:(BOOL)block
{
  XMProtocolStatus protocolStatus;
  
  if ([preferences enableH323] == YES)
  {
    if (_XMEnableH323(YES) == YES) {
      protocolStatus = XMProtocolStatus_Enabled;
      
      _XMSetH323Functionality([preferences enableFastStart], [preferences enableH245Tunnel]);
      
      // setting up the gatekeeper
      [self _doGatekeeperSetup:preferences block:block];
    } else { // Enabling the h323 subsystem failed
      protocolStatus = XMProtocolStatus_Error;
    }
  } else { // h323 disabled
    protocolStatus = XMProtocolStatus_Disabled;
    
    // unregistering from the gk if registered
    _XMSetGatekeeper(NULL, NULL, NULL, NULL, block);
    
    // disabling the H.323 Listeners 
    _XMEnableH323(NO);
  }
  
  if (verbose == YES) {
    NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:protocolStatus];
    [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleH323ProtocolStatus:) withObject:number waitUntilDone:NO];
    [number release];
  }
}

- (void)_doGatekeeperSetup:(XMPreferences *)preferences block:(BOOL)block
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
  _XMSetGatekeeper(gatekeeperAddress, 
                   gatekeeperTerminalAlias1, 
                   gatekeeperTerminalAlias2,
                   gatekeeperPassword,
                   block);
}

- (void)_doSIPSetup:(XMPreferences *)preferences verbose:(BOOL)verbose
{
  XMProtocolStatus protocolStatus;
  
  if ([preferences enableSIP] == YES) {
    BOOL proxyInfoChanged = NO;
    
    if (_XMEnableSIP(YES) == YES) {
      protocolStatus = XMProtocolStatus_Enabled;
      
      NSString *host = [preferences sipProxyHost];
      NSString *username = [preferences sipProxyUsername];
      NSString *password = [preferences sipProxyPassword];
      
      const char *proxyHost = [host cStringUsingEncoding:NSASCIIStringEncoding];
      const char *proxyUsername = [username cStringUsingEncoding:NSASCIIStringEncoding];
      const char *proxyPassword = [password cStringUsingEncoding:NSASCIIStringEncoding];
      
      proxyInfoChanged = _XMSetSIPProxy(proxyHost, proxyUsername, proxyPassword);
      
      [self _doRegistrationSetup:preferences verbose:verbose proxyChanged:proxyInfoChanged];
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

- (void)_doRegistrationSetup:(XMPreferences *)preferences verbose:(BOOL)verbose
                proxyChanged:(BOOL)proxyInfoChanged
{
  NSArray *records = [preferences sipRegistrationRecords];
  
  unsigned i;
  unsigned count = [records count];
  
  [sipRegistrationWaitLock lock];
  
  if (verbose == YES) {
    [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleSIPRegistrationProcessStart)
                                                   withObject:nil
                                                waitUntilDone:NO];
  }
  
  _XMPrepareRegistrationSetup(proxyInfoChanged);
  
  for (i = 0; i < count; i++) {
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

- (void)_waitForSubsystemSetupCompletion:(BOOL)verbose
{
  // Since the SIP Registration performs asynchronously,
  // we wait here until this task has completed
  [sipRegistrationWaitLock lock];
  [sipRegistrationWaitLock unlock];
  
  if (verbose == YES) {
    [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleSIPRegistrationProcessEnd)
                                                   withObject:nil
                                                waitUntilDone:NO];
  }
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
  [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleGatekeeperUnregistration)
                                                 withObject:nil
                                              waitUntilDone:NO];
}

- (void)_handleSIPRegistration:(NSString *)registration
{
  [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleSIPRegistration:)
                                                 withObject:registration
                                              waitUntilDone:NO];
}

- (void)_handleSIPUnregistration:(NSString *)registration
{
  [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleSIPUnregistration:)
                                                 withObject:registration
                                              waitUntilDone:NO];
}

- (void)_handleSIPRegistrationFailure:(NSString *)registration failReason:(XMSIPStatusCode)failReason
{
  NSNumber *errorNumber = [[NSNumber alloc] initWithUnsignedInt:failReason];
  NSArray *array = [[NSArray alloc] initWithObjects:registration, errorNumber, nil];
  
  [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleSIPRegistrationFailure:)
                                                 withObject:array
                                              waitUntilDone:NO];
  
  
  [array release];
  [errorNumber release];
}

- (void)_handleRegistrationSetupCompleted
{
  [sipRegistrationWaitLock unlock];
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
  BOOL useGatekeeper = ([currentPreferences gatekeeperTerminalAlias1] != nil);
  
  // retry to enable H.323 if it previously failed
  if (enableH323 && _XMIsH323Enabled() == NO) {
    [self _doH323Setup:currentPreferences verbose:YES block:NO];
  }
  // retry to register at the gatekeeper if it previously failed
  else if (enableH323 && useGatekeeper && _XMIsRegisteredAtGatekeeper() == NO) {
    [self _doGatekeeperSetup:currentPreferences block:NO];
  }
  
  // retry to enable SIP if it previously failed
  if (enableSIP && _XMIsSIPEnabled() == NO) {
    [self _doSIPSetup:currentPreferences verbose:YES]; 
  }
}

- (void)_updateCallStatistics:(NSTimer *)timer
{
  XMCallStatistics *callStatistics = [[XMCallStatistics alloc] _init];
  
  _XMGetCallStatistics(callID, [callStatistics _callStatisticsRecord]);
  
  [XMMediaTransmitter _setVideoBytesSent:[callStatistics _callStatisticsRecord]->videoBytesSent];
  
  [_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleCallStatisticsUpdate:)
                                                 withObject:callStatistics
                                              waitUntilDone:NO];
  
  [callStatistics release];
}

#pragma mark -
#pragma mark Private Helper Methods

- (void)_initiateCallToAddress:(NSString *)address protocol:(XMCallProtocol)protocol
{
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
  XMCallEndReason endReason;
  callID = _XMInitiateCall(protocol, addressString, origAddressString, &endReason);
  
  if (callID == 0) {
    XMCallStartFailReason failReason = XMCallStartFailReason_UnknownFailure;
    if (endReason == XMCallEndReason_EndedByTransportFail) {
      failReason = XMCallStartFailReason_TransportFail;
    }
    if (endReason == XMCallEndReason_EndedByNoNetworkInterfaces) {
      failReason = XMCallStartFailReason_NoNetworkInterfaces;
    }
    
    // Initiating the call failed
    [self _sendCallStartFailReason:failReason address:address];
  } else {
    XMCallInfo *callInfo = [[XMCallInfo alloc] _initWithCallID:callID
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
