/*
 * $Id: XMOpalDispatcher.m,v 1.24 2006/06/08 08:54:28 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMOpalDispatcher.h"

#import "XMPrivate.h"
#import "XMPreferences.h"
#import "XMCallStatistics.h"
#import "XMBridge.h"

typedef enum _XMOpalDispatcherMessage
{
	// General messages
	_XMOpalDispatcherMessage_Shutdown = 0x0000,
	
	// Setup messages
	_XMOpalDispatcherMessage_SetPreferences = 0x0100,
	_XMOpalDispatcherMessage_RetryEnableH323,
	_XMOpalDispatcherMessage_RetryGatekeeperRegistration,
	_XMOpalDispatcherMessage_RetryEnableSIP,
	_XMOpalDispatcherMessage_RetrySIPRegistrations,
	
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
	
	// Media stream message
	_XMOpalDispatcherMessage_AudioStreamOpened = 0x0300,
	_XMOpalDispatcherMessage_VideoStreamOpened,
	_XMOpalDispatcherMessage_AudioStreamClosed,
	_XMOpalDispatcherMessage_VideoStreamClosed,
	
	// InCall messages
	_XMOpalDispatcherMessage_SendUserInputTone = 0x400,
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

- (void)_handleInitiateCallMessage:(NSArray *)messageComponents;
- (void)_handleInitiateSpecificCallMessage:(NSArray *)messageComponents;
- (void)_handleCallIsAlertingMessage:(NSArray *)messageComponents;
- (void)_handleIncomingCallMessage:(NSArray *)messageComponents;
- (void)_handleAcceptIncomingCallMessage:(NSArray *)messageComponents;
- (void)_handleRejectIncomingCallMessage:(NSArray *)messageComponents;
- (void)_handleCallEstablishedMessage:(NSArray *)messageComponents;
- (void)_handleClearCallMessage:(NSArray *)messageComponents;
- (void)_handleCallClearedMessage:(NSArray *)messageComponents;

- (void)_handleAudioStreamOpenedMessage:(NSArray *)messageComponents;
- (void)_handleVideoStreamOpenedMessage:(NSArray *)messageComponents;
- (void)_handleAudioStreamClosedMessage:(NSArray *)messageComponents;
- (void)_handleVideoStreamClosedMessage:(NSArray *)messageComponents;

- (void)_handleSendUserInputToneMessage:(NSArray *)messageComponents;
- (void)_handleSendUserInputStringMessage:(NSArray *)messageComponents;
- (void)_handleStartCameraEventMessage:(NSArray *)messageComponents;
- (void)_handleStopCameraEventMessage:(NSArray *)messageComponents;

- (void)_doPreferencesSetup:(XMPreferences *)preferences 
			externalAddress:(NSString *)externalAddress 
					verbose:(BOOL)verbose;
- (void)_doH323Setup:(XMPreferences *)preferences verbose:(BOOL)verbose;
- (void)_doGatekeeperSetup:(XMPreferences *)preferences verbose:(BOOL)verbose;
- (void)_doSIPSetup:(XMPreferences *)preferences verbose:(BOOL)verbose;
- (void)_doRegistrarSetup:(XMPreferences *)preferences verbose:(BOOL)verbose;

- (void)_waitForSubsystemSetupCompletion:(BOOL)verbose;

- (void)_checkGatekeeperRegistration:(NSTimer *)timer;
- (void)_updateCallStatistics:(NSTimer *)timer;

- (void)_sendCallStartFailReason:(XMCallStartFailReason)reason address:(NSString *)address;

@end

@implementation XMOpalDispatcher

#pragma mark Class Methods

+ (void)_shutdown
{
	[XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_Shutdown withComponents:nil];
}

+ (void)_setPreferences:(XMPreferences *)preferences externalAddress:(NSString *)externalAddress
{
	NSData *preferencesData = [NSKeyedArchiver archivedDataWithRootObject:preferences];
	NSData *externalAddressData = [NSKeyedArchiver archivedDataWithRootObject:externalAddress];
	
	NSArray *components = [[NSArray alloc] initWithObjects:preferencesData, externalAddressData, nil];
	
	[XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_SetPreferences withComponents:components];
	
	[components release];
}

+ (void)_retryEnableH323:(XMPreferences *)preferences
{
	NSData *preferencesData = [NSKeyedArchiver archivedDataWithRootObject:preferences];
	
	NSArray *components = [[NSArray alloc] initWithObjects:preferencesData, nil];
	
	[XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_RetryEnableH323 withComponents:components];
	
	[components release];
}

+ (void)_retryGatekeeperRegistration:(XMPreferences *)preferences
{
	NSData *preferencesData = [NSKeyedArchiver archivedDataWithRootObject:preferences];
	
	NSArray *components = [[NSArray alloc] initWithObjects:preferencesData, nil];
	
	[XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_RetryGatekeeperRegistration withComponents:components];
	
	[components release];
}

+ (void)_retryEnableSIP:(XMPreferences *)preferences
{
	NSData *preferencesData = [NSKeyedArchiver archivedDataWithRootObject:preferences];
	
	NSArray *components = [[NSArray alloc] initWithObjects:preferencesData, nil];
	
	[XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_RetryEnableSIP withComponents:components];
	
	[components release];
}

+ (void)_retrySIPRegistrations:(XMPreferences *)preferences
{
	NSData *preferencesData = [NSKeyedArchiver archivedDataWithRootObject:preferences];
	
	NSArray *components = [[NSArray alloc] initWithObjects:preferencesData, nil];
	
	[XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_RetrySIPRegistrations withComponents:components];
	
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
					   externalAddress:(NSString *)externalAddress;
{
	NSData *addressData = [NSKeyedArchiver archivedDataWithRootObject:address];
	
	NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:(unsigned)protocol];
	NSData *protocolData = [NSKeyedArchiver archivedDataWithRootObject:number];
	[number release];
	
	NSData *preferencesData = [NSKeyedArchiver archivedDataWithRootObject:preferences];
	
	NSData *externalAddressData = [NSKeyedArchiver archivedDataWithRootObject:externalAddress];
	
	NSArray *components = [[NSArray alloc] initWithObjects:addressData, protocolData, preferencesData,
															externalAddressData, nil];
	
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
	
	NSArray *components = [[NSArray alloc] initWithObjects:idData, codecData, sizeData, incomingData, nil];
	
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
	if(_XMOpalDispatcherSharedInstance == nil)
	{
		NSLog(@"Attempt to send message to NIL OpalDispatcher");
		return;
	}
	
	NSPort *thePort = [_XMOpalDispatcherSharedInstance _receivePort];
	NSPortMessage *portMessage = [[NSPortMessage alloc] initWithSendPort:thePort receivePort:nil components:components];
	[portMessage setMsgid:(unsigned)message];
	if([portMessage sendBeforeDate:[NSDate date]] == NO)
	{
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

	callID = 0;
	
	gatekeeperRegistrationCheckTimer = nil;
	
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
	
	// running the run loop
	[[NSRunLoop currentRunLoop] run];
	
	[self performSelectorOnMainThread:@selector(_handleOpalDispatcherThreadDidExit) withObject:nil waitUntilDone:NO];
	
	[autoreleasePool release];
	autoreleasePool = nil;
}

- (void)handlePortMessage:(NSPortMessage *)portMessage
{
	_XMOpalDispatcherMessage message = (_XMOpalDispatcherMessage)[portMessage msgid];
	
	switch(message)
	{
		case _XMOpalDispatcherMessage_Shutdown:
			[self _handleShutdownMessage];
			break;
		case _XMOpalDispatcherMessage_SetPreferences:
			[self _handleSetPreferencesMessage:[portMessage components]];
			break;
		case _XMOpalDispatcherMessage_RetryEnableH323:
			[self _handleRetryEnableH323Message:[portMessage components]];
			break;
		case _XMOpalDispatcherMessage_RetryGatekeeperRegistration:
			[self _handleRetryGatekeeperRegistrationMessage:[portMessage components]];
			break;
		case _XMOpalDispatcherMessage_RetryEnableSIP:
			[self _handleRetryEnableSIPMessage:[portMessage components]];
			break;
		case _XMOpalDispatcherMessage_RetrySIPRegistrations:
			[self _handleRetrySIPRegistrationsMessage:[portMessage components]];
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
	if(callID != 0)
	{
		// we have to terminate the call first
		// and we wait until the call is cleared before shutting down the system entirely
		[self _handleClearCallMessage:nil];
		callID = UINT_MAX;
		return;
	}
	// By using the default XMPreferences instance,
	// we shutdown the subsystem
	XMPreferences *preferences = [[XMPreferences alloc] init];
	[self _doPreferencesSetup:preferences externalAddress:nil verbose:NO];
	[preferences release];
	
	if(gatekeeperRegistrationCheckTimer != nil)
	{
		[gatekeeperRegistrationCheckTimer invalidate];
		[gatekeeperRegistrationCheckTimer release];
		gatekeeperRegistrationCheckTimer = nil;
	}
	
	if(callStatisticsUpdateIntervalTimer != nil)
	{
		[callStatisticsUpdateIntervalTimer invalidate];
		[callStatisticsUpdateIntervalTimer release];
		callStatisticsUpdateIntervalTimer = nil;
	}
	
	// exiting from the run loop
	[[NSRunLoop currentRunLoop] removePort:receivePort forMode:NSDefaultRunLoopMode];
}

- (void)_handleSetPreferencesMessage:(NSArray *)components
{	
	NSData *preferencesData = (NSData *)[components objectAtIndex:0];
	XMPreferences *preferences = (XMPreferences *)[NSKeyedUnarchiver unarchiveObjectWithData:preferencesData];
		
	NSData *externalAddressData = (NSData *)[components objectAtIndex:1];
	NSString *externalAddress = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:externalAddressData];
	
	[self _doPreferencesSetup:preferences externalAddress:externalAddress verbose:YES];
	
	[self _waitForSubsystemSetupCompletion:YES];
	
	[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleSubsystemSetupEnd) withObject:nil waitUntilDone:NO];
}

- (void)_handleRetryEnableH323Message:(NSArray *)components
{
	NSData *preferencesData = (NSData *)[components objectAtIndex:0];
	XMPreferences *preferences = (XMPreferences *)[NSKeyedUnarchiver unarchiveObjectWithData:preferencesData];
	
	[self _doH323Setup:preferences verbose:YES];
	
	[self _waitForSubsystemSetupCompletion:NO];
	
	[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleSubsystemSetupEnd) withObject:nil waitUntilDone:NO];
}

- (void)_handleRetryGatekeeperRegistrationMessage:(NSArray *)components
{
	NSData *preferencesData = (NSData *)[components objectAtIndex:0];
	XMPreferences *preferences = (XMPreferences *)[NSKeyedUnarchiver unarchiveObjectWithData:preferencesData];
	
	[self _doGatekeeperSetup:preferences verbose:YES];
	
	[self _waitForSubsystemSetupCompletion:NO];
	
	[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleSubsystemSetupEnd)
												   withObject:nil
												waitUntilDone:NO];
}

- (void)_handleRetryEnableSIPMessage:(NSArray *)components
{
	NSData *preferencesData = (NSData *)[components objectAtIndex:0];
	XMPreferences *preferences = (XMPreferences *)[NSKeyedUnarchiver unarchiveObjectWithData:preferencesData];
	
	[self _doSIPSetup:preferences verbose:YES];
	
	[self _waitForSubsystemSetupCompletion:YES];
	
	[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleSubsystemSetupEnd)
												   withObject:nil
												waitUntilDone:NO];
}

- (void)_handleRetrySIPRegistrationsMessage:(NSArray *)components
{
	NSData *preferencesData = (NSData *)[components objectAtIndex:0];
	XMPreferences *preferences = (XMPreferences *)[NSKeyedUnarchiver unarchiveObjectWithData:preferencesData];
	
	[self _doRegistrarSetup:preferences verbose:YES];
	
	[self _waitForSubsystemSetupCompletion:YES];
	
	[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleSubsystemSetupEnd)
												   withObject:nil
												waitUntilDone:NO];
}

- (void)_handleInitiateCallMessage:(NSArray *)components
{
	NSData *addressData = (NSData *)[components objectAtIndex:0];
	NSString *address = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:addressData];
	NSData *protocolData = (NSData *)[components objectAtIndex:1];
	NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:protocolData];
	XMCallProtocol protocol = (XMCallProtocol)[number unsignedIntValue];
	
	if(callID != 0)
	{
		// This probably indicates that an incoming call arrived at exactly the same time than
		// the user tried to initiate this call. Since the incoming call arrived first,
		// we cannot call anyone at the moment
		[self _sendCallStartFailReason:XMCallStartFailReason_AlreadyInCall address:address];
		return;
	}
	
	if((protocol == XMCallProtocol_H323) && (_XMIsH323Enabled() == NO))
	{
		// Trying to make a H.323 call but H.323 isn't enabled
		[self _sendCallStartFailReason:XMCallStartFailReason_H323NotEnabled address:address];
		return;
	}
	if((protocol == XMCallProtocol_H323) && XMIsPhoneNumber(address) && (_XMIsRegisteredAtGatekeeper() == NO))
	{
		[self _sendCallStartFailReason:XMCallStartFailReason_GatekeeperRequired address:address];
		return;
	}
	if((protocol == XMCallProtocol_SIP) && (_XMIsSIPEnabled() == NO))
	{
		[self _sendCallStartFailReason:XMCallStartFailReason_SIPNotEnabled address:address];
		return;
	}
	
	const char *addressString = [address cStringUsingEncoding:NSASCIIStringEncoding];
	callID = _XMInitiateCall(protocol, addressString);
	
	if(callID == 0)
	{
		// Initiating the call failed
		[self _sendCallStartFailReason:XMCallStartFailReason_UnknownFailure address:address];
	}
	else
	{
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

- (void)_handleInitiateSpecificCallMessage:(NSArray *)messageComponents
{
	if(callID != 0)
	{
		// This probably indicates that an incoming call arrived at exactly the same time than
		// the user tried to initiate this call. Since the incoming call arrived first,
		// we cannot call anyone at the moment
		NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:(unsigned)XMCallStartFailReason_AlreadyInCall];
		[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleCallInitiationFailed:) 
													   withObject:number
													waitUntilDone:NO];
		[number release];
		
		return;
	}
	
	NSData *addressData = (NSData *)[messageComponents objectAtIndex:0];
	NSData *protocolData = (NSData *)[messageComponents objectAtIndex:1];
	NSData *preferencesData = (NSData *)[messageComponents objectAtIndex:2];
	NSData *externalAddressData = (NSData *)[messageComponents objectAtIndex:3];
	
	NSString *address = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:addressData];
	NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:protocolData];
	XMCallProtocol callProtocol = (XMCallProtocol)[number unsignedIntValue];
	XMPreferences *preferences = (XMPreferences *)[NSKeyedUnarchiver unarchiveObjectWithData:preferencesData];
	NSString *externalAddress = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:externalAddressData];
	
	[self _doPreferencesSetup:preferences externalAddress:externalAddress verbose:NO];
	
	if((callProtocol == XMCallProtocol_H323) && (_XMIsH323Enabled() == NO))
	{
		NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:(unsigned)XMCallStartFailReason_H323NotEnabled];
		[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleCallInitiationFailed:)
													   withObject:number
													waitUntilDone:NO];
		[number release];
		
		return;
	}
	
	const char *addressString = [address cStringUsingEncoding:NSASCIIStringEncoding];
	callID = _XMInitiateCall(callProtocol, addressString);
	
	if(callID == 0)
	{
		// Initiating the call failed
		NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:(unsigned)XMCallStartFailReason_UnknownFailure];
		[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleCallInitiationFailed:)
													   withObject:number
													waitUntilDone:NO];
		[number release];
	}
	else
	{
		XMCallInfo *callInfo = [[XMCallInfo alloc] _initWithCallID:callID
														  protocol:callProtocol
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

- (void)_handleCallIsAlertingMessage:(NSArray *)messageComponents
{
	NSData *idData = (NSData *)[messageComponents objectAtIndex:0];
	NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:idData];
	unsigned theCallID = [number unsignedIntValue];
	
	if((theCallID != callID) && (callID != UINT_MAX))
	{
		NSLog(@"CallID mismatch on IsAlerting: %d to currently %d", (int)theCallID, (int)callID);
		return;
	}
	
	if(callID == UINT_MAX)
	{
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
	
	if(callID != 0)
	{
		NSLog(@"have already call ongoing");
		
		if(theCallID > callID)
		{
			NSLog(@"Incoming greater than callID");
		}
		else if(theCallID < callID)
		{
			NSLog(@"INcoming less than callID");
		}
		else
		{
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
	
	if(theCallID != callID)
	{
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
	
	if(theCallID != callID)
	{
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
	
	if(theCallID != callID)
	{
		NSLog(@"callID mismatch in callEstablished: %d to current %d", (int)theCallID, (int)callID);
		return;
	}
	
	NSArray *remotePartyInformations = nil;
	
	if(isIncomingCall == NO)
	{
		const char *remoteName;
		const char *remoteNumber;
		const char *remoteAddress;
		const char *remoteApplication;
	
		_XMGetCallInformation(callID, &remoteName, &remoteNumber, &remoteAddress, &remoteApplication);
		
		NSString *remoteNameString = [[NSString alloc] initWithCString:remoteName encoding:NSASCIIStringEncoding];
		NSString *remoteNumberString = [[NSString alloc] initWithCString:remoteNumber encoding:NSASCIIStringEncoding];
		NSString *remoteAddressString = [[NSString alloc] initWithCString:remoteAddress encoding:NSASCIIStringEncoding];
		NSString *remoteApplicationString = [[NSString alloc] initWithCString:remoteApplication encoding:NSASCIIStringEncoding];
		
		remotePartyInformations = [[NSArray alloc] initWithObjects:remoteNameString, remoteNumberString, remoteAddressString,
													remoteApplicationString, localAddress, nil];
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
	if(messageComponents != nil)
	{
		NSData *idData = (NSData *)[messageComponents objectAtIndex:0];
		NSNumber *idNumber = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:idData];
		unsigned theCallID = [idNumber unsignedIntValue];
	
		if(theCallID != callID)
		{
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
	
	if((theCallID != callID) && (callID != UINT_MAX))
	{
		NSLog(@"callID mismatch in callCleared: %d to current %d", (int)theCallID, (int)callID);
		return;
	}
	
	_XMStopAudio();
	_XMResetAvailableBandwidth();
	
	NSData *callEndReasonData = (NSData *)[messageComponents objectAtIndex:1];
	NSNumber *callEndReason = [NSKeyedUnarchiver unarchiveObjectWithData:callEndReasonData];
	
	[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleCallCleared:)
												   withObject:callEndReason
												waitUntilDone:NO];
	
	if(callID == UINT_MAX)
	{
		// the framework is closing
		callID = 0;
		[self _handleShutdownMessage];
	}
	
	if(callStatisticsUpdateIntervalTimer != nil)
	{
		[callStatisticsUpdateIntervalTimer invalidate];
		[callStatisticsUpdateIntervalTimer release];
		callStatisticsUpdateIntervalTimer = nil;
	}
	
	callID = 0;
}

- (void)_handleAudioStreamOpenedMessage:(NSArray *)messageComponents
{
	NSData *idData = (NSData *)[messageComponents objectAtIndex:0];
	NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:idData];
	unsigned theCallID = [number unsignedIntValue];
	
	if(theCallID != callID)
	{
		NSLog(@"CallID mismatch on AudioStreamOpened: %d to actual %d", theCallID, callID);
		return;
	}
	
	NSData *codecData = (NSData *)[messageComponents objectAtIndex:1];
	NSString *codec = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:codecData];
	
	NSData *directionData = (NSData *)[messageComponents objectAtIndex:2];
	number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:directionData];
	BOOL isIncomingStream = [number boolValue];
	
	if(isIncomingStream == YES)
	{
		[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleIncomingAudioStreamOpened:) 
													   withObject:codec waitUntilDone:NO];
	}
	else
	{
		[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleOutgoingAudioStreamOpened:)
													   withObject:codec waitUntilDone:NO];
	}
}

- (void)_handleVideoStreamOpenedMessage:(NSArray *)messageComponents
{
	NSData *idData = (NSData *)[messageComponents objectAtIndex:0];
	NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:idData];
	unsigned theCallID = [number unsignedIntValue];
	
	if(theCallID != 0 && theCallID != callID)
	{
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
	
	NSString *sizeString = nil;
	
	switch(videoSize)
	{
		case XMVideoSize_SQCIF:
			sizeString = @"SQCIF";
			break;
		case XMVideoSize_QCIF:
			sizeString = @"QCIF";
			break;
		case XMVideoSize_CIF:
			sizeString = @"CIF";
			break;
		case XMVideoSize_320_240:
			sizeString = @"320x240";
			break;
		default:
			sizeString = @"UNKNOWN";
			break;
	}
	
	NSString *codecString = [[NSString alloc] initWithFormat:@"%@ (%@)", codec, sizeString];
	
	if(isIncomingStream == YES)
	{
		[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleIncomingVideoStreamOpened:)
													   withObject:codecString waitUntilDone:NO];
	}
	else
	{
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
	
	if((theCallID != callID) && (callID != UINT_MAX))
	{
		NSLog(@"CallID mismatch on MediaStreamClosed: %d to actual %d", theCallID, callID);
		return;
	}
	
	NSData *directionData = (NSData *)[messageComponents objectAtIndex:1];
	number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:directionData];
	BOOL isIncomingStream = [number boolValue];

	if(isIncomingStream == YES)
	{
		[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleIncomingAudioStreamClosed)
													   withObject:nil waitUntilDone:NO];
	}
	else
	{
		[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleOutgoingAudioStreamClosed)
													   withObject:nil waitUntilDone:NO];
	}
}

- (void)_handleVideoStreamClosedMessage:(NSArray *)messageComponents
{
	NSData *idData = (NSData *)[messageComponents objectAtIndex:0];
	NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:idData];
	unsigned theCallID = [number unsignedIntValue];
	
	if((theCallID != callID) && (callID != UINT_MAX))
	{
		NSLog(@"CallID mismatch on MediaStreamClosed: %d to actual %d", theCallID, callID);
		return;
	}
	
	NSData *directionData = (NSData *)[messageComponents objectAtIndex:1];
	number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:directionData];
	BOOL isIncomingStream = [number boolValue];
	
	if(isIncomingStream == YES)
	{
		[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleIncomingVideoStreamClosed)
													   withObject:nil waitUntilDone:NO];
	}
	else
	{
		[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleOutgoingVideoStreamClosed)
													   withObject:nil waitUntilDone:NO];
	}
}

- (void)_handleSendUserInputToneMessage:(NSArray *)messageComponents
{
	NSData *idData = (NSData *)[messageComponents objectAtIndex:0];
	NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:idData];
	unsigned theCallID = [number unsignedIntValue];
	
	if((theCallID != callID) && (callID != UINT_MAX))
	{
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
	
	if((theCallID != callID) && (callID != UINT_MAX))
	{
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
	
	if((theCallID != callID) && (callID != UINT_MAX))
	{
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
	
	if((theCallID != callID) && (callID != UINT_MAX))
	{
		NSLog(@"CallID mismatch on StopCameraEvent: %d to actual %d", theCallID, callID);
		return;
	}
	
	_XMStopCameraEvent(theCallID);
}

#pragma mark -
#pragma mark Setup Methods

- (void)_doPreferencesSetup:(XMPreferences *)preferences externalAddress:(NSString *)suppliedExternalAddress
					verbose:(BOOL)verbose
{
	// ***** Adjusting the general settings ***** //
	NSString *theUserName = [preferences userName];
	if(theUserName != nil)
	{
		const char *userName;
		userName = [theUserName cStringUsingEncoding:NSASCIIStringEncoding];
		_XMSetUserName(userName);
	}
	
	_XMSetBandwidthLimit([preferences bandwidthLimit]);
	
	const char *stunServer = NULL;
	if([preferences useSTUN] == YES)
	{
		NSString *server = [preferences stunServer];
		if(server != nil)
		{
			stunServer = [server cStringUsingEncoding:NSASCIIStringEncoding];
		}
	}
	_XMSetSTUNServer(stunServer);
	
	const char *translationAddress = NULL;
	if([preferences useAddressTranslation] == YES)
	{
		NSString *externalAddress = [preferences externalAddress];
		if(externalAddress == nil)
		{
			externalAddress = suppliedExternalAddress;
		}
		
		translationAddress = [externalAddress cStringUsingEncoding:NSASCIIStringEncoding];
	}
	_XMSetTranslationAddress(translationAddress);
	
	_XMSetPortRanges([preferences udpPortBase],
					 [preferences udpPortMax],
					 [preferences tcpPortBase],
					 [preferences tcpPortMax],
					 [preferences udpPortBase],
					 [preferences udpPortMax]);
	
	// ***** Adjusting the Audio Preferences ***** //
	
	_XMSetAudioBufferSize([preferences audioBufferSize]);
	
	// ***** Adjusting the Video Preferences ***** //
	BOOL enableVideo = [preferences enableVideo];
	_XMSetEnableVideo(enableVideo);
	
	if(enableVideo == YES)
	{
		[XMMediaTransmitter _setFrameGrabRate:[preferences videoFramesPerSecond]];
	}
	
	BOOL enableH264LimitedMode = [preferences enableH264LimitedMode];
	_XMSetEnableH264LimitedMode(enableH264LimitedMode);
	
	// ***** Adjusting the Codec Order/Mask ***** //
	
	unsigned audioCodecCount = [preferences audioCodecListCount];
	unsigned videoCodecCount = [preferences videoCodecListCount];
	unsigned orderedCodecsCount = 0;
	unsigned disabledCodecsCount = 0;
	unsigned i;
	
	// for simplicity, we allocate the buffers big enough to hold all codecs
	unsigned orderedCodecsBufferSize = (audioCodecCount + videoCodecCount) * sizeof(const char *);
	unsigned disabledCodecsBufferSize = (audioCodecCount + videoCodecCount) * sizeof(const char *);
	char const** orderedCodecs = (char const**)malloc(orderedCodecsBufferSize);
	char const** disabledCodecs = (char const**)malloc(disabledCodecsBufferSize);

	for(i = 0; i < audioCodecCount; i++)
	{
		XMPreferencesCodecListRecord *record = [preferences audioCodecListRecordAtIndex:i];
		XMCodecIdentifier identifier = [record identifier];
		const char *mediaFormatString = _XMMediaFormatForCodecIdentifier(identifier);
		
		if([record isEnabled])
		{
			orderedCodecs[orderedCodecsCount] = mediaFormatString;
			orderedCodecsCount++;
		}
		else
		{
			disabledCodecs[disabledCodecsCount] = mediaFormatString;
			disabledCodecsCount++;
		}
	}
	
	for(i = 0; i < videoCodecCount; i++)
	{
		XMPreferencesCodecListRecord *record = [preferences videoCodecListRecordAtIndex:i];
		XMCodecIdentifier identifier = [record identifier];
		const char *mediaFormatString = _XMMediaFormatForCodecIdentifier(identifier);
		
		if([record isEnabled])
		{
			orderedCodecs[orderedCodecsCount] = mediaFormatString;
			orderedCodecsCount++;
		}
		else
		{
			disabledCodecs[disabledCodecsCount] = mediaFormatString;
			disabledCodecsCount++;
		}
	}
	
	_XMSetCodecs(orderedCodecs, orderedCodecsCount, disabledCodecs, disabledCodecsCount);
	
	free(orderedCodecs);
	free(disabledCodecs);
	
	// ***** Adjusting the SIP Preferences **** //
	
	// this is done before H.323 GK setup as SIP Registrar registration is done
	// asynchronously. We're waiting until the SIP registration is complete at the end
	// of the setup procedure
	[self _doSIPSetup:preferences verbose:verbose];
	
	// ***** Adjusting the H.323 Preferences ***** //
	[self _doH323Setup:preferences verbose:verbose];
}

- (void)_doH323Setup:(XMPreferences *)preferences verbose:(BOOL)verbose
{
	if([preferences enableH323] == YES)
	{
		if(_XMEnableH323Listeners(YES) == YES)
		{
			//_XMSetH323Functionality([preferences enableFastStart], [preferences enableH245Tunnel]);
			// Currently, fastStart has to be disabled as long as the Capability management system is not
			// FastStart-Ready
			_XMSetH323Functionality(NO, NO);
			
			// setting up the gatekeeper
			[self _doGatekeeperSetup:preferences verbose:verbose];
		}
		else
		{
			// Enabling the h323 subsystem failed
			if(verbose == YES)
			{
				[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleH323EnablingFailure)
															   withObject:nil
															waitUntilDone:NO];
			}
		}
	} // H.323 disabled
	else
	{
		// unregistering from the gk if registered
		_XMSetGatekeeper(NULL, NULL, NULL, NULL);
		
		// disabling the H.323 Listeners 
		_XMEnableH323Listeners(NO);
	}
}

- (void)_doGatekeeperSetup:(XMPreferences *)preferences 
				   verbose:(BOOL)verbose
{
	const char *gatekeeperAddress = NULL;
	const char *gatekeeperUsername = NULL;
	const char *gatekeeperPhoneNumber = NULL;
	const char *gatekeeperPassword = NULL;
	
	NSString *address = [preferences gatekeeperAddress];
	NSString *username = [preferences gatekeeperUsername];
	NSString *phoneNumber = [preferences gatekeeperPhoneNumber];
	NSString *password = [preferences gatekeeperPassword];
	
	if(address != nil && (username != nil || phoneNumber != nil))
	{
		if(address != nil)
		{
			gatekeeperAddress = [address cStringUsingEncoding:NSASCIIStringEncoding];
		}
		if(username != nil)
		{
			gatekeeperUsername = [username cStringUsingEncoding:NSASCIIStringEncoding];
		}
		if(phoneNumber != nil)
		{
			gatekeeperPhoneNumber = [phoneNumber cStringUsingEncoding:NSASCIIStringEncoding];
		}
		if(password != nil)
		{
			gatekeeperPassword = [password cStringUsingEncoding:NSASCIIStringEncoding];
		}
		
		// inform the CallManager about the gk notification start
		// The GK Registration may be a lengthy task, especially when
		// the registration fails since there is a timeout to wait
		// before ending the registration process with failure
		if(verbose == YES)
		{
			[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleGatekeeperRegistrationProcessStart) 
														   withObject:nil
														waitUntilDone:NO];
		}
	}
	
	// the result of this operation will be informed 
	XMGatekeeperRegistrationFailReason failReason = _XMSetGatekeeper(gatekeeperAddress, 
																	 gatekeeperUsername, 
																	 gatekeeperPhoneNumber,
																	 gatekeeperPassword);
	
	if((failReason != XMGatekeeperRegistrationFailReason_NoFailure) && (verbose == YES))
	{
		NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:(unsigned)failReason];
		[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleGatekeeperRegistrationFailure:)
													   withObject:number
													waitUntilDone:NO];
		[number release];
	}
	
	if((gatekeeperAddress != NULL) && (verbose == YES))
	{
		// we did run a registration attempt. We inform the CallManager that the GK registration
		// process did end
		[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleGatekeeperRegistrationProcessEnd) 
													   withObject:nil
													waitUntilDone:NO];
	}
}

- (void)_doSIPSetup:(XMPreferences *)preferences verbose:(BOOL)verbose
{
	if([preferences enableSIP] == YES)
	{
		if(_XMEnableSIPListeners(YES) == YES)
		{
			NSString *host = [preferences sipProxyHost];
			NSString *username = [preferences sipProxyUsername];
			NSString *password = [preferences sipProxyPassword];
			
			const char *proxyHost = [host cStringUsingEncoding:NSASCIIStringEncoding];
			const char *proxyUsername = [username cStringUsingEncoding:NSASCIIStringEncoding];
			const char *proxyPassword = [password cStringUsingEncoding:NSASCIIStringEncoding];
			
			_XMSetSIPProxy(proxyHost, proxyUsername, proxyPassword);
			
			[self _doRegistrarSetup:preferences verbose:verbose];
		}
		else
		{
			if(verbose == YES)
			{
				[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleSIPEnablingFailure)
															   withObject:nil
															waitUntilDone:NO];
			}
		}
	}
	else // SIP disabled
	{
		_XMSetSIPProxy(NULL, NULL, NULL);
		
		// unregistering from any registrars if needed
		[sipRegistrationWaitLock lock]; // will be unlocked from within _XMFinishRegistrarSetup()
		_XMPrepareRegistrarSetup();
		_XMFinishRegistrarSetup();
		
		// disabling the SIP Listeners
		_XMEnableSIPListeners(NO);
	}
}

- (void)_doRegistrarSetup:(XMPreferences *)preferences verbose:(BOOL)verbose
{
	NSArray *records = [preferences registrarRecords];
	
	unsigned i;
	unsigned count = [records count];
	
	[sipRegistrationWaitLock lock];
	
	if(verbose == YES)
	{
		[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleSIPRegistrationProcessStart)
													   withObject:nil
													waitUntilDone:NO];
	}
	
	_XMPrepareRegistrarSetup();
	
	for(i = 0; i < count; i++)
	{
		XMPreferencesRegistrarRecord *record = (XMPreferencesRegistrarRecord *)[records objectAtIndex:i];
		if(![record isKindOfClass:[XMPreferencesRegistrarRecord class]])
		{
			continue;
		}
		
		const char *registrarHost = NULL;
		const char *registrarUsername = NULL;
		const char *registrarAuthorizationUsername = NULL;
		const char *registrarPassword = NULL;
		
		NSString *host = [record host];
		NSString *username = [record username];
		NSString *authorizationUsername = [record authorizationUsername];
		NSString *password = [record password];
		
		if(host != nil && username != nil)
		{
			registrarHost = [host cStringUsingEncoding:NSASCIIStringEncoding];
			registrarUsername = [username cStringUsingEncoding:NSASCIIStringEncoding];
			registrarAuthorizationUsername = [authorizationUsername cStringUsingEncoding:NSASCIIStringEncoding];
			registrarPassword = [password cStringUsingEncoding:NSASCIIStringEncoding];
			
			_XMUseRegistrar(registrarHost, registrarUsername, registrarAuthorizationUsername, registrarPassword);
		}
	}
	
	_XMFinishRegistrarSetup();
}

- (void)_waitForSubsystemSetupCompletion:(BOOL)verbose
{
	// Since the SIP Registrars are registered asynchronously,
	// we wait here until this task has completed
	[sipRegistrationWaitLock lock];
	[sipRegistrationWaitLock unlock];
	
	if(verbose == YES)
	{
		[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleSIPRegistrationProcessEnd)
													   withObject:nil
													waitUntilDone:NO];
	}
}

#pragma mark -
#pragma mark Subsystem Feedback

- (void)_handleNATType:(XMNATType)natType externalAddress:(NSString *)externalAddress
{
	NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:(unsigned)natType];
	NSArray *array = [[NSArray alloc] initWithObjects:number, externalAddress, nil];
	
	[_XMUtilsSharedInstance performSelectorOnMainThread:@selector(_handleSTUNInformation:) withObject:array waitUntilDone:NO];
	
	[array release];
	[number release];
}

- (void)_handleGatekeeperRegistration:(NSString *)gatekeeperName
{
	[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleGatekeeperRegistration:)
												   withObject:gatekeeperName
												waitUntilDone:NO];
	
	if(gatekeeperRegistrationCheckTimer == nil)
	{
		gatekeeperRegistrationCheckTimer = [[NSTimer scheduledTimerWithTimeInterval:120.0
																			 target:self
																		   selector:@selector(_checkGatekeeperRegistration:)
																		   userInfo:nil
																			repeats:YES] retain];
	}
}

- (void)_handleGatekeeperUnregistration
{
	[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleGatekeeperUnregistration)
												   withObject:nil
												waitUntilDone:NO];
	
	if(gatekeeperRegistrationCheckTimer != nil)
	{
		[gatekeeperRegistrationCheckTimer invalidate];
		[gatekeeperRegistrationCheckTimer release];
		gatekeeperRegistrationCheckTimer = nil;
	}
}

- (void)_handleSIPRegistrationForHost:(NSString *)host username:(NSString *)username
{
	NSArray *array = [[NSArray alloc] initWithObjects:host, username, nil];
	[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleSIPRegistration:)
												   withObject:array
												waitUntilDone:NO];
	[array release];
}

- (void)_handleSIPUnregistrationForHost:(NSString *)host username:(NSString *)username
{
	NSArray *array = [[NSArray alloc] initWithObjects:host, username, nil];
	[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleSIPUnregistration:)
												   withObject:array
												waitUntilDone:NO];
	[array release];
}

- (void)_handleSIPRegistrationFailureForHost:(NSString *)host username:(NSString *)username failReason:(XMSIPStatusCode)failReason
{
	NSNumber *errorNumber = [[NSNumber alloc] initWithUnsignedInt:failReason];
	NSArray *array = [[NSArray alloc] initWithObjects:host, username, errorNumber, nil];
	
	[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleSIPRegistrationFailure:)
												   withObject:array
												waitUntilDone:NO];
	
	
	[array release];
	[errorNumber release];
}

- (void)_handleRegistrarSetupCompleted
{
	[sipRegistrationWaitLock unlock];
}

#pragma mark -
#pragma mark Methods fired by Timers

- (void)_checkGatekeeperRegistration:(NSTimer *)timer
{
	_XMCheckGatekeeperRegistration();
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

@end
