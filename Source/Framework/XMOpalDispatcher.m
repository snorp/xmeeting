/*
 * $Id: XMOpalDispatcher.m,v 1.9 2005/11/24 21:13:02 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
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
	_XMOpalDispatcherMessage_SetCallStatisticsUpdateInterval,
	
	// Media stream message
	_XMOpalDispatcherMessage_MediaStreamOpened = 0x0300,
	_XMOpalDispatcherMessage_MediaStreamClosed
	
} _XMOpalDispatcherMessage;

@interface XMOpalDispatcher (PrivateMethods)

+ (void)_sendMessage:(_XMOpalDispatcherMessage)message withComponents:(NSArray *)components;

- (NSPort *)_receivePort;
- (void)_handleOpalDispatcherThreadDidExit;

- (void)_runOpalDispatcherThread;
- (void)handlePortMessage:(NSPortMessage *)portMessage;

- (void)_handleShutdownMessage;
- (void)_handleSetPreferencesMessage:(NSArray *)messageComponents;
- (void)_handleRetryEnableH323Message:(NSArray *)messageComponents;
- (void)_handleRetryGatekeeperRegistrationMessage:(NSArray *)messageComponents;

- (void)_handleInitiateCallMessage:(NSArray *)messageComponents;
- (void)_handleInitiateSpecificCallMessage:(NSArray *)messageComponents;
- (void)_handleCallIsAlertingMessage:(NSArray *)messageComponents;
- (void)_handleIncomingCallMessage:(NSArray *)messageComponents;
- (void)_handleAcceptIncomingCallMessage:(NSArray *)messageComponents;
- (void)_handleRejectIncomingCallMessage:(NSArray *)messageComponents;
- (void)_handleCallEstablishedMessage:(NSArray *)messageComponents;
- (void)_handleClearCallMessage:(NSArray *)messageComponents;
- (void)_handleCallClearedMessage:(NSArray *)messageComponents;
- (void)_handleSetCallStatisticsUpdateIntervalMessage:(NSArray *)messageComponents;

- (void)_handleMediaStreamOpenedMessage:(NSArray *)messageComponents;
- (void)_handleMediaStreamClosedMessage:(NSArray *)messageComponents;

- (void)_doPreferencesSetup:(XMPreferences *)preferences 
				withAddress:(NSString *)externalAddress 
		 gatekeeperPassword:(NSString *)gatekeeperPassword
					verbose:(BOOL)verbose;
- (void)_doH323Setup:(XMPreferences *)preferences gatekeeperPassword:(NSString *)gatekeeperPassword
			 verbose:(BOOL)verbose;
- (void)_doGatekeeperSetup:(XMPreferences *)preferences
				  password:(NSString *)password
				   verbose:(BOOL)verbose;

- (void)_checkGatekeeperRegistration:(NSTimer *)timer;
- (void)_updateCallStatistics:(NSTimer *)timer;

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
	
	// since the password data isn't directly contained within the preferences instance,
	// we need to get the password string on this thread
	NSString *gatekeeperPassword = nil;
	if([preferences useGatekeeper] == YES)
	{
		gatekeeperPassword = [preferences gatekeeperPassword];
	}
	NSData *gatekeeperPasswordData = [NSKeyedArchiver archivedDataWithRootObject:gatekeeperPassword];
	
	NSArray *components = [[NSArray alloc] initWithObjects:preferencesData, externalAddressData, gatekeeperPasswordData, nil];
	
	[XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_SetPreferences withComponents:components];
	
	[components release];
}

+ (void)_retryEnableH323:(XMPreferences *)preferences
{
	NSData *preferencesData = [NSKeyedArchiver archivedDataWithRootObject:preferences];
	
	NSString *gatekeeperPassword = nil;
	if([preferences useGatekeeper] == YES)
	{
		gatekeeperPassword = [preferences gatekeeperPassword];
	}
	NSData *gatekeeperPasswordData = [NSKeyedArchiver archivedDataWithRootObject:gatekeeperPassword];
	
	NSArray *components = [[NSArray alloc] initWithObjects:preferencesData, gatekeeperPasswordData, nil];
	
	[XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_RetryEnableH323 withComponents:components];
	
	[components release];
}

+ (void)_retryGatekeeperRegistration:(XMPreferences *)preferences
{
	NSData *preferencesData = [NSKeyedArchiver archivedDataWithRootObject:preferences];
	
	NSString *gatekeeperPassword = nil;
	if([preferences useGatekeeper] == YES)
	{
		gatekeeperPassword = [preferences gatekeeperPassword];
	}
	NSData *gatekeeperPasswordData = [NSKeyedArchiver archivedDataWithRootObject:gatekeeperPassword];
	
	NSArray *components = [[NSArray alloc] initWithObjects:preferencesData, gatekeeperPasswordData, nil];
	
	[XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_RetryGatekeeperRegistration withComponents:components];
	
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
	
	NSString *gatekeeperPassword = nil;
	if([preferences useGatekeeper] == YES)
	{
		gatekeeperPassword = [preferences gatekeeperPassword];
	}
	NSData *gatekeeperPasswordData = [NSKeyedArchiver archivedDataWithRootObject:gatekeeperPassword];
	
	NSArray *components = [[NSArray alloc] initWithObjects:addressData, protocolData, preferencesData,
															externalAddressData, gatekeeperPasswordData, nil];
	
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
	
	NSArray *components = [[NSArray alloc] initWithObjects:callData, protocolData, nameData,
												numberData, addressData, applicationData, nil];
	
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

+ (void)_callEstablished:(unsigned)callID incoming:(BOOL)isIncomingCall
{
	NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:callID];
	NSData *idData = [NSKeyedArchiver archivedDataWithRootObject:number];
	[number release];
	
	number = [[NSNumber alloc] initWithBool:isIncomingCall];
	NSData *incomingData = [NSKeyedArchiver archivedDataWithRootObject:number];
	[number release];
	
	NSArray *components = [[NSArray alloc] initWithObjects:idData, incomingData, nil];
	
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

+ (void)_setCallStatisticsUpdateInterval:(NSTimeInterval)timeInterval
{
	NSNumber *number = [[NSNumber alloc] initWithDouble:(double)timeInterval];
	NSData *timeIntervalData = [NSKeyedArchiver archivedDataWithRootObject:number];
	[number release];
	NSArray *components = [[NSArray alloc] initWithObjects:timeIntervalData, nil];
	
	[XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_SetCallStatisticsUpdateInterval withComponents:components];
	
	[components release];
}

+ (void)_mediaStreamOpened:(unsigned)callID codec:(NSString *)codec incoming:(BOOL)isIncomingStream
{
	NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:callID];
	NSData *idData = [NSKeyedArchiver archivedDataWithRootObject:number];
	[number release];
	
	NSData *codecData = [NSKeyedArchiver archivedDataWithRootObject:codec];
	
	number = [[NSNumber alloc] initWithBool:isIncomingStream];
	NSData *incomingData = [NSKeyedArchiver archivedDataWithRootObject:number];
	[number release];
	
	NSArray *components = [[NSArray alloc] initWithObjects:idData, codecData, incomingData, nil];
	
	[XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_MediaStreamOpened withComponents:components];
	
	[components release];
}

+ (void)_mediaStreamClosed:(unsigned)callID codec:(NSString *)codec incoming:(BOOL)isIncomingStream
{
	NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:callID];
	NSData *idData = [NSKeyedArchiver archivedDataWithRootObject:number];
	[number release];
	
	NSData *codecData = [NSKeyedArchiver archivedDataWithRootObject:codec];
	
	number = [[NSNumber alloc] initWithBool:isIncomingStream];
	NSData *incomingData = [NSKeyedArchiver archivedDataWithRootObject:number];
	[number release];
	
	NSArray *components = [[NSArray alloc] initWithObjects:idData, codecData, incomingData, nil];
	
	[XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_MediaStreamClosed withComponents:components];
	
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
	callStatisticsUpdateInterval = 1;
	
	return self;
}

- (void)_close
{
	[XMOpalDispatcher _sendMessage:_XMOpalDispatcherMessage_Shutdown withComponents:nil];
}

- (void)dealloc
{
	[receivePort release];

	[super dealloc];
}

#pragma mark MainThread Methods

- (NSPort *)_receivePort
{
	return receivePort;
}

- (void)_handleOpalDispatcherThreadDidExit
{
	_XMThreadExit();
}

#pragma mark OpalDispatcherThread Methods

- (void)_runOpalDispatcherThread
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	[receivePort setDelegate:self];
	[[NSRunLoop currentRunLoop] addPort:receivePort forMode:NSDefaultRunLoopMode];
	
	// Initiating the OPAL subsystem
	_XMInitSubsystem();
	
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
		case _XMOpalDispatcherMessage_SetCallStatisticsUpdateInterval:
			[self _handleSetCallStatisticsUpdateIntervalMessage:[portMessage components]];
			break;
		case _XMOpalDispatcherMessage_MediaStreamOpened:
			[self _handleMediaStreamOpenedMessage:[portMessage components]];
			break;
		case _XMOpalDispatcherMessage_MediaStreamClosed:
			[self _handleMediaStreamClosedMessage:[portMessage components]];
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
	[self _doPreferencesSetup:preferences withAddress:nil gatekeeperPassword:nil verbose:NO];
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
	// The Strings returned from NSString's -cStringWithEncoding:
	// don't have to be freed explicitely since the NSString
	// class takes care of them
	
	NSData *preferencesData = (NSData *)[components objectAtIndex:0];
	XMPreferences *preferences = (XMPreferences *)[NSKeyedUnarchiver unarchiveObjectWithData:preferencesData];
		
	NSData *externalAddressData = (NSData *)[components objectAtIndex:1];
	NSString *externalAddress = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:externalAddressData];
	
	NSData *gatekeeperPasswordData = (NSData *)[components objectAtIndex:2];
	NSString *gatekeeperPassword = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:gatekeeperPasswordData];
	
	[self _doPreferencesSetup:preferences withAddress:externalAddress gatekeeperPassword:gatekeeperPassword verbose:YES];
	
	[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleSubsystemSetupEnd) withObject:nil waitUntilDone:NO];
}

- (void)_handleRetryEnableH323Message:(NSArray *)components
{
	NSData *preferencesData = (NSData *)[components objectAtIndex:0];
	XMPreferences *preferences = (XMPreferences *)[NSKeyedUnarchiver unarchiveObjectWithData:preferencesData];
	
	NSData *gatekeeperPasswordData = (NSData *)[components objectAtIndex:1];
	NSString *gatekeeperPassword = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:gatekeeperPasswordData];
	
	[self _doH323Setup:preferences gatekeeperPassword:gatekeeperPassword verbose:YES];
	
	[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleSubsystemSetupEnd) withObject:nil waitUntilDone:NO];
}

- (void)_handleRetryGatekeeperRegistrationMessage:(NSArray *)components
{
	NSData *preferencesData = (NSData *)[components objectAtIndex:0];
	XMPreferences *preferences = (XMPreferences *)[NSKeyedUnarchiver unarchiveObjectWithData:preferencesData];
	
	NSData *gatekeeperPasswordData = (NSData *)[components objectAtIndex:1];
	NSString *gatekeeperPassword = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:gatekeeperPasswordData];
	
	[self _doGatekeeperSetup:preferences password:gatekeeperPassword verbose:YES];
	
	[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleSubsystemSetupEnd)
												   withObject:nil
												waitUntilDone:NO];
}

- (void)_handleInitiateCallMessage:(NSArray *)components
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
	
	NSData *addressData = (NSData *)[components objectAtIndex:0];
	NSString *address = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:addressData];
	NSData *protocolData = (NSData *)[components objectAtIndex:1];
	NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:protocolData];
	XMCallProtocol protocol = (XMCallProtocol)[number unsignedIntValue];
	
	if((protocol == XMCallProtocol_H323) && (_XMIsH323Enabled() == NO))
	{
		// Trying to make a H.323 call but H.323 isn't enabled
		NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:(unsigned)XMCallStartFailReason_ProtocolNotEnabled];
		[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleCallInitiationFailed:)
													   withObject:number
													waitUntilDone:NO];
		[number release];
		return;
	}
	
	const char *addressString = [address cStringUsingEncoding:NSASCIIStringEncoding];
	callID = _XMInitiateCall(protocol, addressString);
	
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
														  protocol:protocol
														remoteName:nil
													  remoteNumber:nil
													 remoteAddress:nil
												 remoteApplication:nil
													   callAddress:address
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
	NSData *gatekeeperPasswordData = (NSData *)[messageComponents objectAtIndex:4];
	
	NSString *address = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:addressData];
	NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:protocolData];
	XMCallProtocol callProtocol = (XMCallProtocol)[number unsignedIntValue];
	XMPreferences *preferences = (XMPreferences *)[NSKeyedUnarchiver unarchiveObjectWithData:preferencesData];
	NSString *externalAddress = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:externalAddressData];
	NSString *gatekeeperPassword = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:gatekeeperPasswordData];
	
	[self _doPreferencesSetup:preferences withAddress:externalAddress gatekeeperPassword:gatekeeperPassword verbose:NO];
	
	if((callProtocol == XMCallProtocol_H323) && (_XMIsH323Enabled() == NO))
	{
		NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:(unsigned)XMCallStartFailReason_ProtocolNotEnabled];
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
	
	XMCallInfo *callInfo = [[XMCallInfo alloc] _initWithCallID:callID
													  protocol:protocol
													remoteName:remoteName
												  remoteNumber:remoteNumber
												 remoteAddress:remoteAddress
											 remoteApplication:remoteApplication
												   callAddress:nil
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
													remoteApplicationString, nil];
	}
	
	[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleCallEstablished:)
												   withObject:remotePartyInformations
												waitUntilDone:NO];
	
	if(callStatisticsUpdateInterval != 0)
	{
		callStatisticsUpdateIntervalTimer = [[NSTimer scheduledTimerWithTimeInterval:callStatisticsUpdateInterval 
																			  target:self
																			selector:@selector(_updateCallStatistics:)
																			userInfo:nil
																			 repeats:YES] retain];
	}
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

- (void)_handleSetCallStatisticsUpdateIntervalMessage:(NSArray *)components
{
	NSData *intervalData = (NSData *)[components objectAtIndex:0];
	NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:intervalData];
	callStatisticsUpdateInterval = (NSTimeInterval)[number doubleValue];
	
	if(callStatisticsUpdateIntervalTimer != nil)
	{
		if([callStatisticsUpdateIntervalTimer timeInterval] == callStatisticsUpdateInterval)
		{
			return;
		}
		else
		{
			[callStatisticsUpdateIntervalTimer invalidate];
			[callStatisticsUpdateIntervalTimer release];
			callStatisticsUpdateIntervalTimer = nil;
		}
	}
	
	if(callStatisticsUpdateInterval != 0.0)
	{
		callStatisticsUpdateIntervalTimer = [[NSTimer scheduledTimerWithTimeInterval:callStatisticsUpdateInterval
																			  target:self
																			selector:@selector(_updateCallStatistics:)
																			userInfo:nil
																			 repeats:YES] retain];
	}
}

- (void)_handleMediaStreamOpenedMessage:(NSArray *)messageComponents
{
	NSData *idData = (NSData *)[messageComponents objectAtIndex:0];
	NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:idData];
	unsigned theCallID = [number unsignedIntValue];
	
	if(theCallID != callID)
	{
		NSLog(@"CallID mismatch on MediaStreamOpened: %d to actual %d", theCallID, callID);
		return;
	}
	
	NSData *codecData = (NSData *)[messageComponents objectAtIndex:1];
	NSString *codec = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:codecData];
	
	NSData *directionData = (NSData *)[messageComponents objectAtIndex:2];
	number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:directionData];
	BOOL isIncomingStream = [number boolValue];
	
	NSRange range = [codec rangeOfString:@"H.261"];
	if(range.location == NSNotFound)
	{
		if(isIncomingStream == YES)
		{
			[_XMCallManagerSharedInstance _handleIncomingAudioStreamOpened:codec];
		}
		else
		{
			[_XMCallManagerSharedInstance _handleOutgoingAudioStreamOpened:codec];
		}
	}
	else
	{
		if(isIncomingStream == YES)
		{
			[_XMCallManagerSharedInstance _handleIncomingVideoStreamOpened:codec];
		}
		else
		{
			[_XMCallManagerSharedInstance _handleOutgoingVideoStreamOpened:codec];
		}
	}
}

- (void)_handleMediaStreamClosedMessage:(NSArray *)messageComponents
{
	NSData *idData = (NSData *)[messageComponents objectAtIndex:0];
	NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:idData];
	unsigned theCallID = [number unsignedIntValue];
	
	if((theCallID != callID) && (callID != UINT_MAX))
	{
		NSLog(@"CallID mismatch on MediaStreamClosed: %d to actual %d", theCallID, callID);
		return;
	}
	
	NSData *codecData = (NSData *)[messageComponents objectAtIndex:1];
	NSString *codec = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:codecData];
	
	NSData *directionData = (NSData *)[messageComponents objectAtIndex:2];
	number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:directionData];
	BOOL isIncomingStream = [number boolValue];
	
	NSRange range = [codec rangeOfString:@"H.261"];
	if(range.location == NSNotFound)
	{
		if(isIncomingStream == YES)
		{
			[_XMCallManagerSharedInstance _handleIncomingAudioStreamClosed];
		}
		else
		{
			[_XMCallManagerSharedInstance _handleOutgoingAudioStreamClosed];
		}
	}
	else
	{
		if(isIncomingStream == YES)
		{
			[_XMCallManagerSharedInstance _handleIncomingVideoStreamClosed];
		}
		else
		{
			[_XMCallManagerSharedInstance _handleOutgoingVideoStreamClosed];
		}
	}
}

- (void)_doPreferencesSetup:(XMPreferences *)preferences withAddress:(NSString *)suppliedExternalAddress
		 gatekeeperPassword:(NSString *)gatekeeperPassword
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
	
	// ***** Adjusting the Codec Order/Mask ***** //
	
	unsigned audioCodecCount = [preferences audioCodecListCount];
	unsigned videoCodecCount = [preferences videoCodecListCount];
	unsigned orderedCodecsCount = 0;
	unsigned disabledCodecsCount = 0;
	unsigned i;
	
	// for simplicity, we allocate the buffers big enough to hold all codecs
	unsigned orderedCodecsBufferSize = (audioCodecCount + videoCodecCount) * _XMMaxMediaFormatsPerCodecIdentifier() * sizeof(const char *);
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
	
		if([record isEnabled])
		{
			XMVideoSize size = [preferences preferredVideoSize];
			
			const char *mediaFormatString = _XMMediaFormatForCodecIdentifierWithVideoSize(identifier, size);
			if(mediaFormatString != NULL)
			{
				orderedCodecs[orderedCodecsCount] = mediaFormatString;
				orderedCodecsCount++;
			}
			
			if(size == XMVideoSize_QCIF)
			{
				size = XMVideoSize_CIF;
			}
			else
			{
				size = XMVideoSize_QCIF;
			}
			
			mediaFormatString = _XMMediaFormatForCodecIdentifierWithVideoSize(identifier, size);
			if(mediaFormatString != NULL)
			{
				orderedCodecs[orderedCodecsCount] = mediaFormatString;
				orderedCodecsCount++;
			}
		}
		else
		{
			const char *mediaFormatString = _XMMediaFormatForCodecIdentifier(identifier);
			disabledCodecs[disabledCodecsCount] = mediaFormatString;
			disabledCodecsCount++;
		}
	}
	
	_XMSetCodecs(orderedCodecs, orderedCodecsCount, disabledCodecs, disabledCodecsCount);
	
	free(orderedCodecs);
	free(disabledCodecs);
	
	// ***** Adjusting the H.323 Preferences ***** //
	[self _doH323Setup:preferences gatekeeperPassword:gatekeeperPassword verbose:verbose];
}

- (void)_doH323Setup:(XMPreferences *)preferences gatekeeperPassword:(NSString *)gatekeeperPassword
			 verbose:(BOOL)verbose
{
	if([preferences enableH323] == YES)
	{
		if(_XMEnableH323Listeners(YES) == YES)
		{
			_XMSetH323Functionality([preferences enableFastStart], [preferences enableH245Tunnel]);
			
			// setting up the gatekeeper
			[self _doGatekeeperSetup:preferences password:gatekeeperPassword verbose:verbose];
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
		_XMSetGatekeeper(NULL, NULL, NULL, NULL, NULL);
		
		// disabling the H.323 Listeners 
		_XMEnableH323Listeners(NO);
	}
}

- (void)_doGatekeeperSetup:(XMPreferences *)preferences 
				  password:(NSString *)password
				   verbose:(BOOL)verbose
{
	const char *gatekeeperAddress = NULL;
	const char *gatekeeperID = NULL;
	const char *gatekeeperUsername = NULL;
	const char *gatekeeperPhoneNumber = NULL;
	const char *gatekeeperPassword = NULL;
	
	if([preferences useGatekeeper] == YES)
	{
		NSString *gkAddress = [preferences gatekeeperAddress];
		NSString *gkID = [preferences gatekeeperID];
		NSString *gkUsername = [preferences gatekeeperUsername];
		NSString *gkPhoneNumber = [preferences gatekeeperPhoneNumber];
		
		// if no gkAddress and no gkID specified, gk registration will
		// not work. The call manager has already taken care of
		if(gkAddress != nil || gkID != nil)
		{
			if(gkAddress != nil)
			{
				gatekeeperAddress = [gkAddress cStringUsingEncoding:NSASCIIStringEncoding];
			}
			if(gkID != nil)
			{
				gatekeeperID = [gkID cStringUsingEncoding:NSASCIIStringEncoding];
			}
			if(gkUsername != nil)
			{
				gatekeeperUsername = [gkUsername cStringUsingEncoding:NSASCIIStringEncoding];
			}
			if(gkPhoneNumber != nil)
			{
				gatekeeperPhoneNumber = [gkPhoneNumber cStringUsingEncoding:NSASCIIStringEncoding];
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
	}
	
	// the result of this operation will be informed 
	XMGatekeeperRegistrationFailReason failReason = _XMSetGatekeeper(gatekeeperAddress, 
																	 gatekeeperID, 
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
	
	if((gatekeeperAddress != NULL || gatekeeperID != NULL) && (verbose == YES))
	{
		// we did run a registration attempt. We inform the CallManager that the GK registration
		// process did end
		[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleGatekeeperRegistrationProcessEnd) 
													   withObject:nil
													waitUntilDone:NO];
	}
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

- (void)_checkGatekeeperRegistration:(NSTimer *)timer
{
	_XMCheckGatekeeperRegistration();
}

- (void)_updateCallStatistics:(NSTimer *)timer
{
	XMCallStatistics *callStatistics = [[XMCallStatistics alloc] _init];
	
	_XMGetCallStatistics(callID, [callStatistics _callStatisticsRecord]);
	
	[_XMCallManagerSharedInstance performSelectorOnMainThread:@selector(_handleCallStatisticsUpdate:)
												   withObject:callStatistics
												waitUntilDone:NO];
	
	[callStatistics release];
}

@end
