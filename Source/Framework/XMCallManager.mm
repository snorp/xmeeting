/*
 * $Id: XMCallManager.mm,v 1.12 2005/08/29 15:19:51 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMTypes.h"
#import "XMStringConstants.h"
#import "XMPrivate.h"
#import "XMCallManager.h"
#import "XMUtils.h"
#import "XMCallInfo.h"
#import "XMPreferences.h"
#import "XMPreferencesCodecListRecord.h"
#import "XMURL.h"
#import "XMBridge.h"

@interface XMCallManager (PrivateMethods)

- (id)_init;

- (void)_prepareSubsystemSetup;
- (void)_initiateSubsystemSetupWithPreferences:(XMPreferences *)preferencesToUse;
	// called on a separate thread
- (void)_doSubsystemSetupWithPreferences:(XMPreferences *)preferencesToUse;
- (void)_shutdownSubsystem;
- (void)_mainThreadHandleSubsystemSetupDidEnd;

- (BOOL)_startIndirectCalling;
- (void)_mainThreadHandleIncomingCall:(XMCallInfo *)callInfo;
- (void)_mainThreadHandleCallEstablished:(NSArray *)infoArray;
- (void)_mainThreadHandleCallCleared:(NSArray *)infoArray;
- (void)_mainThreadHandleMediaStreamOpened:(NSArray *)infoArray;
- (void)_didEndFetchingExternalAddress:(NSNotification *)notif;

- (void)_mainThreadHandleH323Failure;
- (void)_mainThreadHandleGatekeeperRegistrationStart;
- (void)_mainThreadHandleGatekeeperRegistration;
- (void)_mainThreadHandleGatekeeperUnregistration;
- (void)_mainThreadHandleGatekeeperRegistrationFailure:(NSNumber *)reason;
- (void)_checkGatekeeperRegistration:(NSTimer *)timer;

- (void)_updateCallStatistics:(NSTimer *)timer;

- (void)_storeCall:(XMCallInfo *)call;

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
	static XMCallManager *sharedInstance = nil;
	
	if(!sharedInstance)
	{
		sharedInstance = [[XMCallManager alloc] _init];
	}
	
	return sharedInstance;
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
	//initializing the underlying OPAL system
	initOPAL();
	
	self = [super init];
	
	delegate = nil;
	
	isOnline = NO;
	doesSubsystemSetup = NO;
	needsSubsystemSetupAfterCallEnd = NO;
	needsSubsystemShutdownAfterSubsystemSetup = NO;
	postSubsystemSetupFailureNotifications = YES;
	
	activePreferences = [[XMPreferences alloc] init];
	autoAnswerCalls = NO;
	
	activeCall = nil;
	callStartFailReason = XMCallStartFailReason_NoFailure;
	
	gatekeeperName = nil;
	gatekeeperRegistrationFailReason = XMGatekeeperRegistrationFailReason_NoFailure;
	gatekeeperRegistrationCheckTimer = nil;
	
	statisticsUpdateInterval = 1.0;
	
	recentCalls = [[NSMutableArray alloc] initWithCapacity:10];
	
	return self;
}

- (void)dealloc
{
	[self setDelegate:nil];
	
	[activePreferences release];
	[activeCall release];
	
	[gatekeeperName release];
	[gatekeeperRegistrationCheckTimer invalidate];
	[gatekeeperRegistrationCheckTimer release];
	
	[recentCalls release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[self setOnline:NO];
	
	[super dealloc];
}

#pragma mark General Configuration

- (id)delegate
{
	return delegate;
}

- (void)setDelegate:(id)theDelegate
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	delegate = theDelegate;
}

- (BOOL)isOnline
{
	return isOnline;
}

- (void)setOnline:(BOOL)flag
{
	if(isOnline != flag)
	{
		isOnline = flag;
		
		if(isOnline)
		{
			[self _prepareSubsystemSetup];
			
			NSNotification *notif = [NSNotification notificationWithName:XMNotification_CallManagerDidGoOnline object:self];
			[[NSNotificationQueue defaultQueue] enqueueNotification:notif postingStyle:NSPostASAP];
		}
		else 
		{
			// just for the case...
			needsSubsystemSetupAfterCallEnd = NO;
			
			if(doesSubsystemSetup)
			{
				needsSubsystemShutdownAfterSubsystemSetup = YES;
			}
			else if([self isInCall])
			{
				// the subsystem shutdown is initiated after the call has ended
				[self clearActiveCall];
			}
			else
			{
				[self _shutdownSubsystem];
			}
		}
	}
}

- (BOOL)isH323Listening
{
	return isH323Listening();
}

- (BOOL)isSIPListening
{
	return NO;
}

- (XMPreferences *)activePreferences
{
	return [[activePreferences copy] autorelease];
}

- (void)setActivePreferences:(XMPreferences *)prefs
{
	if(doesSubsystemSetup == YES)
	{
		[NSException raise:XMException_InvalidAction format:XMExceptionReason_CallManagerInvalidActionWhileSubsystemSetup];
		return;
	}
	if(prefs == nil)
	{
		[NSException raise:XMException_InvalidParameter format:XMExceptionReason_InvalidParameterMustNotBeNil];
		return;
	}
	
	XMPreferences *old = activePreferences;
	activePreferences = [prefs copy];
	[old release];
	activeSetupPreferences = [activePreferences retain];
	
	if([self isInCall])
	{
		needsSubsystemSetupAfterCallEnd = YES;
		return;
	}
	
	// we only modify the subsystem if we really are online
	if(isOnline == YES)
	{
		[self _prepareSubsystemSetup];
	}
}

- (BOOL)doesSubsystemSetup
{
	return doesSubsystemSetup;
}

#pragma mark Call management methods

- (BOOL)isInCall
{
	if(activeCall == nil)
	{
		return NO;
	}
	return YES;
}

- (XMCallInfo *)activeCall
{
	return activeCall;
}

- (BOOL)callURL:(XMURL *)remotePartyURL;
{
	// invalid action checks
	
	if(!isOnline)
	{
		[NSException raise:XMException_InvalidAction format:XMExceptionReason_CallManagerInvalidActionWhileOffline];
		return NO;
	}
	else if(doesSubsystemSetup)
	{
		[NSException raise:XMException_InvalidAction format:XMExceptionReason_CallManagerInvalidActionWhileSubsystemSetup];
		return NO;
	}
	else if([self isInCall])
	{
		[NSException raise:XMException_InvalidAction format:XMExceptionReason_CallManagerInvalidActionWhileInCall];
		return NO;
	}
	
	XMCallProtocol callProtocol = [remotePartyURL callProtocol];
	NSString *address = [remotePartyURL address];
	
	if([remotePartyURL isKindOfClass:[XMGeneralPurposeURL class]])
	{
		XMGeneralPurposeURL *url = (XMGeneralPurposeURL *)remotePartyURL;
		
		if([url _doesModifyPreferences:activePreferences])
		{
			/*
			 * In this case, we have to modify the subsystem before continuing
			 * to make the call. This is "indirect calling" since startCall()
			 * is called some run loop cycles later.
			 */
			XMPreferences *modifiedPreferences = [activePreferences copy];
			[url _modifyPreferences:modifiedPreferences];
			
			/* Detection of call start failure conditions */
			if(callProtocol == XMCallProtocol_H323 && [modifiedPreferences enableH323] == NO)
			{
				callStartFailReason = XMCallStartFailReason_ProtocolNotEnabled;
				
				NSNotification *notification = [NSNotification notificationWithName:XMNotification_CallManagerCallStartFailed
																			 object:self];
				[[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostASAP];
				
				[modifiedPreferences release];
				
				return NO;
			}
			if(callProtocol == XMCallProtocol_H323 && 
			   [activePreferences useGatekeeper] == NO && 
			   [modifiedPreferences useGatekeeper] == YES &&
			   [url valueForKey:XMKey_PreferencesGatekeeperAddress] == nil &&
			   [url valueForKey:XMKey_PreferencesGatekeeperID] == nil)
			{
				callStartFailReason = XMCallStartFailReason_GatekeeperUsedButNotSpecified;
				
				NSNotification *notification = [NSNotification notificationWithName:XMNotification_CallManagerCallStartFailed
																			 object:self];
				[[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostASAP];
				
				[modifiedPreferences release];
				
				return NO;
			}
			
			/*
			 * Detection of direct call start failure conditions completed.
			 * Now, let's start calling
			 */
			NSNotification *notification = [NSNotification notificationWithName:XMNotification_CallManagerDidStartCalling 
																		 object:self];
			[[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostASAP];
			
			[activeSetupPreferences release];
			activeSetupPreferences = modifiedPreferences;
			
			activeCall = [[XMCallInfo alloc] _initWithCallID:0
													protocol:callProtocol
												  remoteName:nil
												remoteNumber:nil
											   remoteAddress:nil
										   remoteApplication:nil
												 callAddress:address
												  callStatus:XMCallStatus_Calling];
			
			addressToCall = [address retain];
			protocolToUse = callProtocol;
			
			postSubsystemSetupFailureNotifications = NO;
			
			[self _prepareSubsystemSetup];
			return YES;
		}
	}
	
	/* Direct calling. Detection of call start failure conditions */
	
	// checking if the protocol is enabled. It may also be that the enabling failed for some reason!
	if(callProtocol == XMCallProtocol_H323 && [self isH323Listening] == NO)
	{
		callStartFailReason = XMCallStartFailReason_ProtocolNotEnabled;
		
		NSNotification *notification = [NSNotification notificationWithName:XMNotification_CallManagerCallStartFailed
																	 object:self];
		[[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostASAP];
		return NO;
	}
	
	/* Checks completed, start calling */
	
	unsigned callID = startCall(callProtocol, [address cString]);
	
	if(callID != 0)
	{
		activeCall = [[XMCallInfo alloc] _initWithCallID:callID
												protocol:callProtocol
											  remoteName:nil
											remoteNumber:nil
										   remoteAddress:nil
									   remoteApplication:nil
											 callAddress:address
											  callStatus:XMCallStatus_Calling];
			
		NSNotification *notification = [NSNotification notificationWithName:XMNotification_CallManagerDidStartCalling 
																		 object:self];
		[[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostASAP];
		
		return YES;
	}
	else
	{
		// do some more fine-grain detection of the call start fail reason
		// (e.g. no address entered)
		callStartFailReason = XMCallStartFailReason_UnknownFailure;
		return NO;
	}
}

- (XMCallStartFailReason)callStartFailReason
{
	return callStartFailReason;
}

- (void)acceptIncomingCall:(BOOL)acceptFlag
{
	if(activeCall == nil)
	{
		[NSException raise:XMException_InvalidAction format:XMExceptionReason_CallManagerInvalidActionWhileNotInCall];
		return;
	}
	
	unsigned callID = [activeCall _callID];
		
	setAcceptIncomingCall(callID, acceptFlag);
}

- (void)clearActiveCall
{
	if(activeCall == nil)
	{
		[NSException raise:XMException_InvalidAction format:XMExceptionReason_CallManagerInvalidActionWhileNotInCall];
		return;
	}
	
	clearCall([activeCall _callID]);
}

- (NSArray *)recentCalls
{
	NSArray *recentCallsCopy = [recentCalls copy];
	return [recentCallsCopy autorelease];
}

#pragma mark H.323-specific Methods

- (BOOL)isGatekeeperRegistered
{
	return gatekeeperName != nil;
}

- (NSString *)gatekeeperName
{
	return gatekeeperName;
}

- (XMGatekeeperRegistrationFailReason)gatekeeperRegistrationFailReason
{
	return gatekeeperRegistrationFailReason;
}

- (void)retryEnableH323
{
	if(doesSubsystemSetup == NO && [self isH323Listening] == NO && [activePreferences enableH323])
	{
		[self _prepareSubsystemSetup];
	}
	else
	{
		NSString *exceptionReason;
		
		if(doesSubsystemSetup == YES)
		{
			exceptionReason = XMExceptionReason_CallManagerInvalidActionWhileSubsystemSetup;
		}
		else if([self isH323Listening] == YES)
		{
			exceptionReason = XMExceptionReason_CallManagerInvalidActionWhileH323Listening;
		}
		else
		{
			exceptionReason = XMExceptionReason_CallManagerInvalidActionWhileH323Disabled;
		}
		
		[NSException raise:XMException_InvalidAction format:exceptionReason];
	}
}

- (void)retryGatekeeperRegistration
{
	if(doesSubsystemSetup == NO && gatekeeperName == nil && [activePreferences useGatekeeper])
	{
		[self _prepareSubsystemSetup];
	}
	else
	{
		NSString *exceptionReason;
		
		if(doesSubsystemSetup == YES)
		{
			exceptionReason = XMExceptionReason_CallManagerInvalidActionWhileSubsystemSetup;
		}
		else if(gatekeeperName != nil)
		{
			exceptionReason = XMExceptionReason_CallManagerInvalidActionWhileGatekeeperRegistered;
		}
		else
		{
			exceptionReason = XMExceptionReason_CallManagerInvalidActionWhileGatekeeperDisabled;
		}
		
		[NSException raise:XMException_InvalidAction format:exceptionReason];
	}
}

#pragma mark InCall Methods

- (NSTimeInterval)statisticsUpdateInterval
{
	return statisticsUpdateInterval;
}

- (void)setStatisticsUpdateInterval:(NSTimeInterval)interval
{
	statisticsUpdateInterval = interval;
}

#pragma mark Private Methods

- (void)_prepareSubsystemSetup
{
	// "freeze" any modifications
	doesSubsystemSetup = YES;
	
	NSNotification *notification = [NSNotification notificationWithName:XMNotification_CallManagerDidStartSubsystemSetup object:self];
	
	[[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostASAP];
	
	// set the autoAnswerCall flag
	autoAnswerCalls = [activePreferences autoAnswerCalls];
	
	// we check whether we have to use the external address
	// from XMUtils and if this is not yet available, we wait
	// until this address gets available
	if([activePreferences useAddressTranslation])
	{
		if([activePreferences externalAddress] == nil)
		{
			XMUtils *utils = [XMUtils sharedInstance];
			if([utils externalAddress] == nil)
			{
				// address fetch failure or not yet fetched?
				if([utils didSucceedFetchingExternalAddress])
				{
					// not yet fetched
					[utils startFetchingExternalAddress];
					[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didEndFetchingExternalAddress:)
																 name:XMNotification_UtilsDidEndFetchingExternalAddress object:nil];
					return;
				}
			}
		}
	}
	
	// preparations complete...
	// We use a copy to avoid possible multithreading problems, even if
	// the chances for them are really small...
	[self _initiateSubsystemSetupWithPreferences:[activeSetupPreferences copy]];
}

- (void)_initiateSubsystemSetupWithPreferences:(XMPreferences *)preferences
{
	// Calling the OPAL world to create a new thread and call
	// _doSubsystemSetupWithPreferences on this new thread
	initiateSubsystemSetup((void *)preferences);
}

- (void)_doSubsystemSetupWithPreferences:(XMPreferences *)preferences
{
	// just to be sure...
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	// setting the general settings
	const char *userName = NULL;
	NSString *theUserName = [preferences userName];
	if(theUserName != nil)
	{
		userName = [theUserName cString];
	}
	
	// setting the network preferences
	setBandwidthLimit([preferences bandwidthLimit]);
	
	const char *translationAddress = NULL;
	if([preferences useAddressTranslation])
	{
		NSString *externalAddress = [preferences externalAddress];
		if(externalAddress == nil)
		{
			// we have to query XMUtils for the external address
			XMUtils *utils = [XMUtils sharedInstance];
			externalAddress = [utils externalAddress];
			if(externalAddress != nil)
			{
				translationAddress = [externalAddress cString];
			}
		}
		else
		{
			translationAddress = [externalAddress cString];
		}
	}
	setTranslationAddress(translationAddress);
	
	setPortRanges([preferences udpPortBase],
				  [preferences udpPortMax],
				  [preferences tcpPortBase],
				  [preferences tcpPortMax],
				  [preferences udpPortBase],
				  [preferences udpPortMax]);
	
	// setting the audio preferences
	setAudioBufferSize([preferences audioBufferSize]);
	
	// setting the video preferences (currently disabled)
	setVideoFunctionality(NO, NO);
	
	// for the codec order, we have to create a buffer and fill it with c strings.
	unsigned audioCodecCount = [preferences audioCodecListCount];
	unsigned videoCodecCount = [preferences videoCodecListCount];
	unsigned i;
	unsigned disabledCodecCount = 0;
	unsigned orderedCodecCount = 0;
	char const** disabledCodecs = (char const**)malloc((audioCodecCount + videoCodecCount + 1) * sizeof(char *));
	char const** orderedCodecs = (char const**)malloc((audioCodecCount + videoCodecCount + 1) * sizeof(char *));
	for(i = 0; i < audioCodecCount; i++)
	{
		XMPreferencesCodecListRecord *record = [preferences audioCodecListRecordAtIndex:i];
		const char *identifier = [[record identifier] cString];
		if([record isEnabled])
		{
			orderedCodecs[orderedCodecCount] = identifier;
			orderedCodecCount++;
		}
		else
		{
			disabledCodecs[disabledCodecCount] = identifier;
			disabledCodecCount++;
		}
	}
	for(i = 0; i < videoCodecCount; i++)
	{
		XMPreferencesCodecListRecord *record = [preferences videoCodecListRecordAtIndex:i];
		const char *identifier = [[record identifier] cString];
		if([record isEnabled])
		{
			orderedCodecs[orderedCodecCount] = identifier;
			orderedCodecCount++;
		}
		else
		{
			disabledCodecs[disabledCodecCount] = identifier;
			disabledCodecCount++;
		}
	}
	orderedCodecs[orderedCodecCount] = NULL;
	disabledCodecs[disabledCodecCount] = NULL;
	setDisabledCodecs(disabledCodecs, disabledCodecCount);
	setCodecOrder(orderedCodecs, orderedCodecCount);
	free(orderedCodecs);
	free(disabledCodecs);
	
	// setting the H.323 preferences
	if([preferences enableH323])
	{
		if(enableH323Listeners(YES))
		{
			setH323Functionality([preferences enableFastStart], [preferences enableH245Tunnel]);
		
			const char *gatekeeperAddress = NULL;
			const char *gatekeeperID = NULL;
			const char *gatekeeperUsername = NULL;
			const char *gatekeeperPhoneNumber = NULL;
			
			
			if([preferences useGatekeeper])
			{
				NSString *gkAddress = [preferences gatekeeperAddress];
				NSString *gkID = [preferences gatekeeperID];
				NSString *gkUsername = [preferences gatekeeperUsername];
				NSString *gkPhoneNumber = [preferences gatekeeperPhoneNumber];
				
				if(gkAddress != nil || gkID != nil)
				{
					if(gkAddress != nil)
					{
						gatekeeperAddress = [gkAddress cString];
					}
					if(gkID != nil)
					{
						gatekeeperID = [gkID cString];
					}
					if(gkUsername != nil)
					{
						gatekeeperUsername = [gkUsername cString];
					}
					if(gkPhoneNumber != nil)
					{
						gatekeeperPhoneNumber = [gkPhoneNumber cString];
					}
					
					// inform the rest through notifications since this might be a lengthy task
					[self performSelectorOnMainThread:@selector(_mainThreadHandleGatekeeperRegistrationStart) 
										   withObject:nil waitUntilDone:NO];
				}
				else
				{
					// the flag indicates gatekeeper usage but we have no valid gatekeeper address or ID
					[self _handleGatekeeperRegistrationFailure:XMGatekeeperRegistrationFailReason_NoGatekeeperSpecified];
				}
			}
			
			setGatekeeper(gatekeeperAddress, gatekeeperID, gatekeeperUsername, gatekeeperPhoneNumber);
		}
		else
		{
			// enabling the H.323 listeners failed
			[self performSelectorOnMainThread:@selector(_mainThreadHandleH323Failure) withObject:nil waitUntilDone:NO];
		}
	}
	else
	{
		// unregistering the gatekeeper (if any)
		setGatekeeper(NULL, NULL, NULL, NULL);
		
		// stopping the H.323 listening
		enableH323Listeners(NO);
	}
	
	[self performSelectorOnMainThread:@selector(_mainThreadHandleSubsystemSetupDidEnd) withObject:nil waitUntilDone:NO];
	
	// cleaning up
	[preferences release];
	[autoreleasePool release];
}

- (void)_shutdownSubsystem
{
	[self _doSubsystemSetupWithPreferences:[[XMPreferences alloc] init]];
	
	[gatekeeperRegistrationCheckTimer invalidate];
	[gatekeeperRegistrationCheckTimer release];
	gatekeeperRegistrationCheckTimer = nil;
}

- (void)_mainThreadHandleSubsystemSetupDidEnd
{	
	if(needsSubsystemShutdownAfterSubsystemSetup == YES)
	{
		// we just need to change the subsystem, thus we use new
		// XMPreferences instance
		needsSubsystemShutdownAfterSubsystemSetup = NO;
		[self _doSubsystemSetupWithPreferences:[[XMPreferences alloc] init]];
	}
	else
	{
		if([self isInCall])
		{
			BOOL result = [self _startIndirectCalling];
			
			if(result == YES)
			{
				needsSubsystemSetupAfterCallEnd = YES;
			}
			else
			{
				[activeSetupPreferences release];
				activeSetupPreferences = [activePreferences retain];
				[self _initiateSubsystemSetupWithPreferences:[activePreferences copy]];
				return;
			}
		}
		
		postSubsystemSetupFailureNotifications = YES;
		doesSubsystemSetup = NO;
	
			// post the notification
		NSNotification *notification = [NSNotification notificationWithName:XMNotification_CallManagerDidEndSubsystemSetup object:self];
		
		[[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostASAP];
		
		// in case we just went offline, we post the appropriate notification here
		if(isOnline == NO)
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidGoOffline object:self];
		}
	}
}

- (BOOL)_startIndirectCalling
{
	/* checking some call fail conditions */
	if((protocolToUse != XMCallProtocol_H323 || [self isH323Listening] == YES) &&
	   ([activePreferences useGatekeeper] == NO || gatekeeperName != nil))
	{
	
		unsigned callID = startCall(protocolToUse, [addressToCall cString]);
	
		[addressToCall release];
		addressToCall = nil;
		protocolToUse = XMCallProtocol_UnknownProtocol;
	
		if(callID != 0)
		{
			[activeCall _setCallID:callID];
			return YES;
		}
	}
	
	[activeCall _setCallStatus:XMCallStatus_Ended];
	[activeCall _setCallEndReason:XMCallEndReason_EndedByConnectFail];
			
	[self _storeCall:activeCall];
			
	[activeCall release];
	activeCall = nil;
			
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerCallCleared
															object:self];
	return NO;
}

- (void)_handleIncomingCall:(unsigned)callID 
				   protocol:(XMCallProtocol)protocol
				 remoteName:(NSString *)remoteName
			   remoteNumber:(NSString *)remoteNumber
			  remoteAddress:(NSString *)remoteAddress
		  remoteApplication:(NSString *)remoteApplication
{
	XMCallInfo *info = [[XMCallInfo alloc] _initWithCallID:callID
												  protocol:protocol
												remoteName:remoteName
											  remoteNumber:remoteNumber
											 remoteAddress:remoteAddress
										 remoteApplication:remoteApplication
											   callAddress:nil
												 callStatus:XMCallStatus_Incoming];
	
	[self performSelectorOnMainThread:@selector(_mainThreadHandleIncomingCall:)
						   withObject:info
						waitUntilDone:NO];
	
	[info release];
}

- (void)_mainThreadHandleIncomingCall:(XMCallInfo *)callInfo
{
	if(activeCall != nil)
	{
		// This is the very rare situation that we have started a call
		// roughly the same time as someone called us. I have serious
		// doubts that this situation is even possible, but nevertheless
		// it is better to threat this situation appropriate
		[activeCall _setCallStatus:XMCallStatus_Ended];
		[activeCall _setCallEndReason:XMCallEndReason_EndedByLocalBusy];
		[self _storeCall:activeCall];
		
		// add call archive here
		[activeCall release];
	}
	
	activeCall = [callInfo retain];
	
	if(autoAnswerCalls)
	{
		// we do not post any notification here since this will be posted on call established
		setAcceptIncomingCall([callInfo _callID], true);
	}
	else
	{
		// post the appropriate notification
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerIncomingCall
															object:self];
	}
}

-(void)_handleCallEstablished:(unsigned)callID
{	
	
	NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:callID];
	NSString *remoteNameString;
	NSString *remoteNumberString;
	NSString *remoteAddressString;
	NSString *remoteApplicationString;
	
	// we need to get additional information.
	const char *remoteName;
	const char *remoteNumber;
	const char *remoteAddress;
	const char *remoteApplication;
	
	getCallInformation([activeCall _callID], &remoteName, &remoteNumber, &remoteAddress, &remoteApplication);
	
	remoteNameString = [[NSString alloc] initWithCString:remoteName];
	remoteNumberString = [[NSString alloc] initWithCString:remoteNumber];
	remoteAddressString = [[NSString alloc] initWithCString:remoteAddress];
	remoteApplicationString = [[NSString alloc] initWithCString:remoteApplication];
	
	NSArray *informationArray = [[NSArray alloc] initWithObjects:number, remoteNameString, remoteNumberString,
															remoteAddressString, remoteApplicationString, nil];
	
	[number release];
	[remoteNameString release];
	[remoteNumberString release];
	[remoteAddressString release];
	[remoteApplicationString release];
	
	[self performSelectorOnMainThread:@selector(_mainThreadHandleCallEstablished:) withObject:informationArray
						waitUntilDone:NO];
	
	[informationArray release];
}

- (void)_mainThreadHandleCallEstablished:(NSArray *)infoArray
{
	if(activeCall == nil)
	{
		[NSException raise:XMException_InternalConsistencyFailure 
					format:XMExceptionReason_CallManagerInternalConsistencyFailureOnCallEstablished];
		return;
	}
	
	NSNumber *callIDNumber = (NSNumber *)[infoArray objectAtIndex:0];
	
	unsigned callID = [callIDNumber unsignedIntValue];
	if([activeCall _callID] != callID)
	{
		return;
	}
	
	XMCallStatus status = [activeCall callStatus];
	
	if(status != XMCallStatus_Calling && status != XMCallStatus_Incoming)
	{
		// this should actually not happen
		return;
	}

	[activeCall _setCallStatus:XMCallStatus_Active];
	
	if([activeCall remoteName] == nil)
	{
		NSString *remoteName = (NSString *)[infoArray objectAtIndex:1];
		NSString *remoteNumber = (NSString *)[infoArray objectAtIndex:2];
		NSString *remoteAddress = (NSString *)[infoArray objectAtIndex:3];
		NSString *remoteApplication = (NSString *)[infoArray objectAtIndex:4];
		
		[activeCall _setRemoteName:remoteName];
		[activeCall _setRemoteNumber:remoteNumber];
		[activeCall _setRemoteAddress:remoteAddress];
		[activeCall _setRemoteApplication:remoteApplication];
	}
	
	// starting the statistics timer
	if(statisticsUpdateInterval != 0.0)
	{
		[NSTimer scheduledTimerWithTimeInterval:statisticsUpdateInterval
										 target:self
									   selector:@selector(_updateCallStatistics:)
									   userInfo:nil
										repeats:YES];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerCallEstablished
														object:self];
}

- (void)_handleCallCleared:(unsigned)callID withCallEndReason:(XMCallEndReason)callEndReason
{	
	NSNumber *callIDNumber = [[NSNumber alloc] initWithUnsignedInt:callID];
	NSNumber *callEndReasonNumber = [[NSNumber alloc] initWithUnsignedInt:callEndReason];
	NSArray *infoArray = [[NSArray alloc] initWithObjects:callIDNumber, callEndReasonNumber, nil];
	
	[self performSelectorOnMainThread:@selector(_mainThreadHandleCallCleared:) withObject:infoArray
						waitUntilDone:NO];
	[callIDNumber release];
	[callEndReasonNumber release];
	[infoArray release];
}

- (void)_mainThreadHandleCallCleared:(NSArray *)infoArray
{
	if(activeCall == nil)
	{
		// In some cases, this callback is called multiple times,
		// therefore we return if the active call is already nil
		return;
	}
	
	NSNumber *callIDNumber = (NSNumber *)[infoArray objectAtIndex:0];
	NSNumber *callEndReasonNumber = (NSNumber *)[infoArray objectAtIndex:1];
	unsigned callID = [callIDNumber unsignedIntValue];
	XMCallEndReason callEndReason = (XMCallEndReason)[callEndReasonNumber unsignedIntValue];
	
	if([activeCall _callID] != callID)
	{
		NSLog(@"callID mismatch on call cleared!");
		return;
	}
	
	[activeCall _setCallStatus:XMCallStatus_Ended];
	[activeCall _setCallEndReason:callEndReason];
	
	[self _storeCall:activeCall];
	
	[activeCall release];
	activeCall = nil;
	
	NSNotification *notification = [NSNotification notificationWithName:XMNotification_CallManagerCallCleared object:self];
	
	[[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostASAP];
	
	// In some cases, we need to change some settings in the subsystem
	// since this cannot be done during a call, it's now time to initiate
	// this task.
	if(needsSubsystemSetupAfterCallEnd)
	{
		needsSubsystemSetupAfterCallEnd = NO;
		
		[activeSetupPreferences release];
		activeSetupPreferences = [activePreferences retain];
		[self _prepareSubsystemSetup];
	}
	
	// if we just went offline and therefore terminated the call, it's
	// time to finish the subsystem shutdown
	if(isOnline == NO)
	{
		[self _shutdownSubsystem];
	}
}

- (void)_handleMediaStreamOpened:(unsigned)callID 
				   isInputStream:(BOOL)isInputStream 
					 mediaFormat:(NSString *)mediaFormat
{	
	NSNumber *callIDNumber = [[NSNumber alloc] initWithUnsignedInt:callID];
	NSNumber *isInputStreamNumber = [[NSNumber alloc] initWithBool:isInputStream];
	NSArray *infoArray = [[NSArray alloc] initWithObjects:callIDNumber, isInputStreamNumber, mediaFormat, nil];
	
	[self performSelectorOnMainThread:@selector(_mainThreadHandleMediaStreamOpened:) withObject:infoArray
						waitUntilDone:NO];
	
	[callIDNumber release];
	[isInputStreamNumber release];
	[infoArray release];
}

- (void)_mainThreadHandleMediaStreamOpened:(NSArray *)infoArray
{
	NSNumber *callIDNumber = (NSNumber *)[infoArray objectAtIndex:0];
	NSNumber *isInputStreamNumber = (NSNumber *)[infoArray objectAtIndex:1];
	NSString *codecString = (NSString *)[infoArray objectAtIndex:2];
	unsigned callID = [callIDNumber unsignedIntValue];
	BOOL isInputStream = [isInputStreamNumber boolValue];
	
	NSLog(@"media stream opened: %@ (%d)", codecString, (int)isInputStream);
	
	if([activeCall _callID] != callID)
	{
		NSLog(@"callID mismatch on MediaStreamOpened");
		return;
	}
	
	if([codecString rangeOfString:@"261"].location != NSNotFound ||
	   [codecString rangeOfString:@"263"].location != NSNotFound)
	{
		// we have a video codec.
		if(isInputStream)
		{
			[activeCall _setOutgoingVideoCodec:codecString];
		}
		else
		{
			[activeCall _setIncomingAudioCodec:codecString];
		}
	}
	else
	{
		// we have an audio codec.
		if(isInputStream)
		{
			[activeCall _setOutgoingAudioCodec:codecString];
		}
		else
		{
			[activeCall _setIncomingAudioCodec:codecString];
		}
	}
}

- (void)_didEndFetchingExternalAddress:(NSNotification *)notif
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:XMNotification_UtilsDidEndFetchingExternalAddress object:nil];
	[self _initiateSubsystemSetupWithPreferences:[activePreferences copy]];
}

- (void)_updateCallStatistics:(NSTimer *)timer
{
	if(activeCall == nil || [activeCall callStatus] != XMCallStatus_Active)
	{
		[timer invalidate];
	}
	else
	{
		XMCallStatistics *callStatistics = [activeCall _callStatistics];
		unsigned callID = [activeCall _callID];
		
		getCallStatistics(callID, callStatistics);
		
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerCallStatisticsUpdated object:self];
	}
}

- (void)_storeCall:(XMCallInfo *)call
{
	if([recentCalls count] == 100)
	{
		[recentCalls removeObjectAtIndex:99];
	}
	[recentCalls insertObject:call atIndex:0];
}
	
#pragma mark H.323 private methods

- (void)_mainThreadHandleH323Failure
{
	if(postSubsystemSetupFailureNotifications == YES)
	{
		NSNotification *notification = [NSNotification notificationWithName:XMNotification_CallManagerEnablingH323Failed object:self];
		
		[[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostASAP];
	}
}

- (void)_mainThreadHandleGatekeeperRegistrationStart
{
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidStartGatekeeperRegistration object:self];
}

- (void)_handleGatekeeperRegistration:(NSString *)theGatekeeperName
{
	[self performSelectorOnMainThread:@selector(_mainThreadHandleGatekeeperRegistration:)
						   withObject:theGatekeeperName waitUntilDone:NO];
}

- (void)_mainThreadHandleGatekeeperRegistration:(NSString *)theGatekeeperName
{
	[gatekeeperName release];
	gatekeeperName = [theGatekeeperName retain];
	
	gatekeeperRegistrationFailReason = XMGatekeeperRegistrationFailReason_NoFailure;
	
	// check every two minutes for gatekeeper registration
	[gatekeeperRegistrationCheckTimer invalidate];
	[gatekeeperRegistrationCheckTimer release];
	gatekeeperRegistrationCheckTimer = [[NSTimer scheduledTimerWithTimeInterval:120.0 target:self 
																	   selector:@selector(_checkGatekeeperRegistration:)
																	   userInfo:nil repeats:YES] retain];
	
	NSNotification *notification = [NSNotification notificationWithName:XMNotification_CallManagerGatekeeperRegistration object:self];
	
	[[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostASAP];
}

- (void)_handleGatekeeperUnregistration
{
	[self performSelectorOnMainThread:@selector(_mainThreadHandleGatekeeperUnregistration)
						   withObject:nil waitUntilDone:NO];
}

- (void)_mainThreadHandleGatekeeperUnregistration
{	
	[gatekeeperRegistrationCheckTimer invalidate];
	[gatekeeperRegistrationCheckTimer release];
	gatekeeperRegistrationCheckTimer = nil;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerGatekeeperUnregistration object:self];
	
	[gatekeeperName release];
	gatekeeperName = nil;
}

- (void)_handleGatekeeperRegistrationFailure:(XMGatekeeperRegistrationFailReason)reason
{
	NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:reason];
	[self performSelectorOnMainThread:@selector(_mainThreadHandleGatekeeperRegistrationFailure:) withObject:number
						waitUntilDone:NO];
	[number release];
}

- (void)_mainThreadHandleGatekeeperRegistrationFailure:(NSNumber *)reason
{
	[gatekeeperName release];
	gatekeeperName = nil;
	
	gatekeeperRegistrationFailReason = (XMGatekeeperRegistrationFailReason)[reason unsignedIntValue];
	
	[gatekeeperRegistrationCheckTimer invalidate];
	[gatekeeperRegistrationCheckTimer release];
	gatekeeperRegistrationCheckTimer = nil;
	
	if(postSubsystemSetupFailureNotifications == YES)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerGatekeeperRegistrationFailed object:self];
	}
}

- (void)_checkGatekeeperRegistration:(NSTimer *)timer
{
	if(!doesSubsystemSetup)
	{
		checkGatekeeperRegistration();
	}
}

@end
