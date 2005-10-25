/*
 * $Id: XMCallManager.m,v 1.5 2005/10/25 21:41:35 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMTypes.h"
#import "XMStringConstants.h"
#import "XMPrivate.h"
#import "XMCallManager.h"
#import "XMOpalDispatcher.h"
#import "XMUtils.h"
#import "XMCallInfo.h"
#import "XMPreferences.h"
#import "XMPreferencesCodecListRecord.h"
#import "XMURL.h"
#import "XMBridge.h"

#define XM_H323_NOT_LISTENING 0
#define XM_H323_LISTENING 1
#define XM_H323_ERROR 2

#define XM_CALL_MANAGER_READY 0
#define XM_CALL_MANAGER_SUBSYSTEM_SETUP 1
#define XM_CALL_MANAGER_PREPARING_CALL 2
#define XM_CALL_MANAGER_IN_CALL 3

@interface XMCallManager (PrivateMethods)

- (void)_doSubsystemSetupWithPreferences:(XMPreferences *)preferences;
- (void)_didEndFetchingExternalAddress:(NSNotification *)notif;

- (void)_initiateCall:(XMURL *)url;
- (void)_initiateSpecificCall:(XMGeneralPurposeURL *)url;

- (void)_storeCall:(XMCallInfo *)callInfo;

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
	if(_XMCallManagerSharedInstance == nil)
	{
		NSLog(@"Attempt to acces XMCallManager prior to initialization");
	}
	
	return _XMCallManagerSharedInstance;
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
	
	callManagerStatus = XM_CALL_MANAGER_READY;
	
	h323ListeningStatus = XM_H323_NOT_LISTENING;
	
	activePreferences = [[XMPreferences alloc] init];
	automaticallyAcceptIncomingCalls = NO;
	
	activeCall = nil;
	needsSubsystemSetupAfterCallEnd = NO;
	callStartFailReason = XMCallStartFailReason_NoFailure;
	
	gatekeeperName = nil;
	gatekeeperRegistrationFailReason = XMGatekeeperRegistrationFailReason_NoFailure;
	
	callStatisticsUpdateInterval = 1.0;
	
	recentCalls = [[NSMutableArray alloc] initWithCapacity:10];
	
	return self;
}

- (void)_close
{
	if(activePreferences != nil)
	{
		[activePreferences release];
		activePreferences = nil;
	}
	
	if(activeCall != nil)
	{
		[activeCall release];
		activeCall = nil;
	}
	
	if(gatekeeperName != nil)
	{
		[gatekeeperName release];
		gatekeeperName = nil;
	}
	
	if(recentCalls != nil)
	{
		[recentCalls release];
		recentCalls = nil;
	}
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc
{	
	[self _close];
	
	[super dealloc];
}

#pragma mark General Configuration

- (BOOL)doesAllowModifications
{
	return (callManagerStatus == XM_CALL_MANAGER_READY);
}

- (BOOL)isH323Listening
{
	return (h323ListeningStatus == XM_H323_LISTENING);
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
	if(prefs == nil)
	{
		[NSException raise:XMException_InvalidParameter format:XMExceptionReason_InvalidParameterMustNotBeNil];
		return;
	}
	if(callManagerStatus != XM_CALL_MANAGER_READY)
	{
		[NSException raise:XMException_InvalidAction format:XMExceptionReason_CallManagerInvalidActionIfInSubsystemSetupOrInCall];
		return;
	}
	
	XMPreferences *old = activePreferences;
	activePreferences = [prefs copy];
	[old release];
	
	[self _doSubsystemSetupWithPreferences:activePreferences];
}

#pragma mark Call management methods

- (BOOL)isInCall
{
	if((callManagerStatus == XM_CALL_MANAGER_PREPARING_CALL) ||
	   (callManagerStatus == XM_CALL_MANAGER_IN_CALL))
	{
		return YES;
	}
	
	return NO;
}

- (XMCallInfo *)activeCall
{
	return activeCall;
}

- (void)callURL:(XMURL *)remotePartyURL;
{	
	// invalid action checks
	if(callManagerStatus != XM_CALL_MANAGER_READY)
	{
		[NSException raise:XMException_InvalidAction format:XMExceptionReason_CallManagerInvalidActionIfInSubsystemSetupOrInCall];
		return;
	}
	
	if([remotePartyURL isKindOfClass:[XMGeneralPurposeURL class]])
	{
		XMGeneralPurposeURL *url = (XMGeneralPurposeURL *)remotePartyURL;
		
		if([url _doesModifyPreferences:activePreferences])
		{
			[self _initiateSpecificCall:url];
		}
	}
	
	[self _initiateCall:remotePartyURL];
}

- (XMCallStartFailReason)callStartFailReason
{
	return callStartFailReason;
}

- (void)acceptIncomingCall
{
	if(activeCall == nil)
	{
		[NSException raise:XMException_InvalidAction format:XMExceptionReason_CallManagerInvalidActionIfNotInCall];
		return;
	}
	
	if([activeCall callStatus] != XMCallStatus_Incoming)
	{
		[NSException raise:XMException_InvalidAction format:XMExceptionReason_CallManagerInvalidActionIfCallStatusNotIncoming];
		return;
	}
	
	unsigned callID = [activeCall _callID];
		
	[XMOpalDispatcher _acceptIncomingCall:callID];
}

- (void)rejectIncomingCall
{
	if(activeCall == nil)
	{
		[NSException raise:XMException_InvalidAction format:XMExceptionReason_CallManagerInvalidActionIfNotInCall];
		return;
	}
	
	if([activeCall callStatus] != XMCallStatus_Incoming)
	{
		[NSException raise:XMException_InvalidAction format:XMExceptionReason_CallManagerInvalidActionIfCallStatusNotIncoming];
		return;
	}
	
	unsigned callID = [activeCall _callID];
	
	[XMOpalDispatcher _rejectIncomingCall:callID];
}

- (void)clearActiveCall
{
	if(activeCall == nil)
	{
		[NSException raise:XMException_InvalidAction format:XMExceptionReason_CallManagerInvalidActionIfNotInCall];
		return;
	}
	
	unsigned callID = [activeCall _callID];
	
	[activeCall _setCallStatus:XMCallStatus_Terminating];
	
	[XMOpalDispatcher _clearCall:callID];
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
	if(callManagerStatus == XM_CALL_MANAGER_READY &&
	   h323ListeningStatus == XM_H323_ERROR && 
	   activePreferences != nil &&
	   [activePreferences enableH323] == YES)
	{
		h323ListeningStatus = XM_H323_NOT_LISTENING;
		
		callManagerStatus = XM_CALL_MANAGER_SUBSYSTEM_SETUP;
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidStartSubsystemSetup
															object:self];
		
		[XMOpalDispatcher _retryEnableH323:activePreferences];
	}
	else
	{
		NSString *exceptionReason;
		
		if(callManagerStatus != XM_CALL_MANAGER_READY)
		{
			exceptionReason = XMExceptionReason_CallManagerInvalidActionIfInSubsystemSetupOrInCall;
		}
		else if([self isH323Listening] == YES)
		{
			exceptionReason = XMExceptionReason_CallManagerInvalidActionIfH323Listening;
		}
		else if(activePreferences == nil)
		{
			exceptionReason = XMExceptionReason_InvalidParameterMustNotBeNil;
		}
		else
		{
			exceptionReason = XMExceptionReason_CallManagerInvalidActionIfH323Disabled;
		}
		
		[NSException raise:XMException_InvalidAction format:exceptionReason];
	}
}

- (void)retryGatekeeperRegistration
{
	if(callManagerStatus == XM_CALL_MANAGER_READY &&
	   gatekeeperName == nil && 
	   activePreferences != nil &&
	   [activePreferences useGatekeeper])
	{
		callManagerStatus = XM_CALL_MANAGER_SUBSYSTEM_SETUP;
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidStartSubsystemSetup
															object:self];
		[XMOpalDispatcher _retryGatekeeperRegistration:activePreferences];
	}
	else
	{
		NSString *exceptionReason;
		
		if(callManagerStatus != XM_CALL_MANAGER_READY)
		{
			exceptionReason = XMExceptionReason_CallManagerInvalidActionIfInSubsystemSetupOrInCall;
		}
		else if(gatekeeperName != nil)
		{
			exceptionReason = XMExceptionReason_CallManagerInvalidActionIfGatekeeperRegistered;
		}
		else if(activePreferences == nil)
		{
			exceptionReason = XMExceptionReason_InvalidParameterMustNotBeNil;
		}
		else
		{
			exceptionReason = XMExceptionReason_CallManagerInvalidActionIfGatekeeperDisabled;
		}
		
		[NSException raise:XMException_InvalidAction format:exceptionReason];
	}
}

#pragma mark InCall Methods

- (NSTimeInterval)callStatisticsUpdateInterval
{
	return callStatisticsUpdateInterval;
}

- (void)setCallStatisticsUpdateInterval:(NSTimeInterval)interval
{
	callStatisticsUpdateInterval = interval;
	
	[XMOpalDispatcher _setCallStatisticsUpdateInterval:callStatisticsUpdateInterval];
}

#pragma mark Private & Framework Methods

- (void)_doSubsystemSetupWithPreferences:(XMPreferences *)preferences
{
	if(callManagerStatus == XM_CALL_MANAGER_READY)
	{
		callManagerStatus = XM_CALL_MANAGER_SUBSYSTEM_SETUP;
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidStartSubsystemSetup
															object:self];
	}
	
	automaticallyAcceptIncomingCalls = [preferences automaticallyAcceptIncomingCalls];
	
	NSString *externalAddress = nil;
	if([preferences useAddressTranslation])
	{
		if([preferences externalAddress] == nil)
		{
			externalAddress = [_XMUtilsSharedInstance externalAddress];
			if(externalAddress == nil)
			{
				if([_XMUtilsSharedInstance didSucceedFetchingExternalAddress] == YES)
				{
					// not yet fetched
					[_XMUtilsSharedInstance startFetchingExternalAddress];
					[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didEndFetchingExternalAddress:)
																 name:XMNotification_UtilsDidEndFetchingExternalAddress object:nil];
				
					// we continue this job when the external address fetch task is finished
					return;
				}
			}
		}
	}
	
	// resetting the H323 listening status if an error previously
	if(h323ListeningStatus == XM_H323_ERROR)
	{
		h323ListeningStatus = XM_H323_NOT_LISTENING;
	}
	
	// preparations complete
	[XMOpalDispatcher _setPreferences:preferences externalAddress:externalAddress];
}

- (void)_didEndFetchingExternalAddress:(NSNotification *)notif
{
	// removing the listener
	[[NSNotificationCenter defaultCenter] removeObserver:self name:XMNotification_UtilsDidEndFetchingExternalAddress object:nil];
	
	// do the subsystem setup again
	[self _doSubsystemSetupWithPreferences:activePreferences];
}

- (void)_handleSubsystemSetupEnd
{	
	BOOL enableH323 = [activePreferences enableH323];
	if((enableH323 == YES) && (h323ListeningStatus != XM_H323_ERROR))
	{
		h323ListeningStatus = XM_H323_LISTENING;
	}
	if(enableH323 == NO)
	{
		h323ListeningStatus = XM_H323_NOT_LISTENING;
	}
	
	if(needsSubsystemSetupAfterCallEnd == YES)
	{
		callManagerStatus = XM_CALL_MANAGER_READY;
		
		needsSubsystemSetupAfterCallEnd = NO;
		
		[self _storeCall:activeCall];
		
		[activeCall release];
		activeCall = nil;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidClearCall
															object:self];
	}
	else if(callManagerStatus == XM_CALL_MANAGER_SUBSYSTEM_SETUP)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidEndSubsystemSetup object:self];
		callManagerStatus = XM_CALL_MANAGER_READY;
	}
}

- (void)_handleCallInitiated:(XMCallInfo *)call
{
	if(activeCall != nil)
	{
		NSLog(@"Call initiated and active call not nil!");
		[activeCall release];
		activeCall = nil;
	}
	
	activeCall = [call retain];
	
	callManagerStatus = XM_CALL_MANAGER_IN_CALL;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidStartCalling object:self];
}

- (void)_handleCallInitiationFailed:(NSNumber *)failReason
{
	callStartFailReason = (XMCallStartFailReason)[failReason unsignedIntValue];
	
	callManagerStatus = XM_CALL_MANAGER_READY;
	
	needsSubsystemSetupAfterCallEnd = NO;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidNotStartCalling object:self];
}

- (void)_handleCallIsAlerting
{
	[activeCall _setCallStatus:XMCallStatus_Ringing];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidStartRingingAtRemoteParty
														object:self];
}

- (void)_handleIncomingCall:(XMCallInfo *)call
{
	if(activeCall != nil)
	{
		NSLog(@"incoming call with non-nil active call");
		[activeCall release];
		activeCall = nil;
	}
	
	activeCall = [call retain];
	
	callManagerStatus = XM_CALL_MANAGER_IN_CALL;
	
	if(automaticallyAcceptIncomingCalls == YES)
	{
		[XMOpalDispatcher _acceptIncomingCall:[activeCall _callID]];
	}
	else
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidReceiveIncomingCall 
														object:self];
	}
}

- (void)_handleCallEstablished:(NSArray *)remotePartyInformations
{
	[activeCall _setCallStatus:XMCallStatus_Active];
	
	if([activeCall isOutgoingCall])
	{
		NSString *remoteName = (NSString *)[remotePartyInformations objectAtIndex:0];
		NSString *remoteNumber = (NSString *)[remotePartyInformations objectAtIndex:1];
		NSString *remoteAddress = (NSString *)[remotePartyInformations objectAtIndex:2];
		NSString *remoteApplication = (NSString *)[remotePartyInformations objectAtIndex:3];
		
		[activeCall _setRemoteName:remoteName];
		[activeCall _setRemoteNumber:remoteNumber];
		[activeCall _setRemoteAddress:remoteAddress];
		[activeCall _setRemoteApplication:remoteApplication];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidEstablishCall
														object:self];
}

- (void)_handleCallCleared:(NSNumber *)callEndReason
{
	XMCallEndReason reason = (XMCallEndReason)[callEndReason unsignedIntValue];
	[activeCall _setCallStatus:XMCallStatus_Ended];
	[activeCall _setCallEndReason:reason];
	
	if(needsSubsystemSetupAfterCallEnd == YES)
	{
		[self _doSubsystemSetupWithPreferences:activePreferences];
	}
	else
	{
		[self _storeCall:activeCall];
		
		[activeCall release];
		activeCall = nil;
		
		callManagerStatus = XM_CALL_MANAGER_READY;
	
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidClearCall
															object:self];
	}
}

- (void)_handleCallStatisticsUpdate:(XMCallStatistics *)updatedStatistics
{
	[activeCall _updateCallStatistics:updatedStatistics];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidUpdateCallStatistics
														object:self];
}

- (void)_handleOutgoingAudioStreamOpened:(NSString *)codec
{
	[activeCall _setOutgoingAudioCodec:codec];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidOpenOutgoingAudioStream
														object:self];
}

- (void)_handleIncomingAudioStreamOpened:(NSString *)codec
{
	[activeCall _setIncomingAudioCodec:codec];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidOpenIncomingAudioStream
														object:self];
}

- (void)_handleOutgoingVideoStreamOpened:(NSString *)codec
{
	[activeCall _setOutgoingVideoCodec:codec];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidOpenOutgoingVideoStream
														object:self];
}

- (void)_handleIncomingVideoStreamOpened:(NSString *)codec
{
	[activeCall _setIncomingVideoCodec:codec];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidOpenIncomingVideoStream
														object:self];
}

- (void)_handleOutgoingAudioStreamClosed
{
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidCloseOutgoingAudioStream
														object:self];
}

- (void)_handleIncomingAudioStreamClosed
{
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidCloseIncomingAudioStream
														object:self];
}

- (void)_handleOutgoingVideoStreamClosed
{
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidCloseOutgoingVideoStream
														object:self];
}

- (void)_handleIncomingVideoStreamClosed
{
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidCloseIncomingVideoStream
														object:self];
}

- (void)_handleH323EnablingFailure
{
	h323ListeningStatus = XM_H323_ERROR;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidNotEnableH323
														object:self];
}

- (void)_handleGatekeeperRegistrationProcessStart
{
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidStartGatekeeperRegistrationProcess
														object:self];
}

- (void)_handleGatekeeperRegistrationProcessEnd
{
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidEndGatekeeperRegistrationProcess
														object:self];
}

- (void)_handleGatekeeperRegistration:(NSString *)theGatekeeperName
{
	if(gatekeeperName != nil)
	{
		[gatekeeperName release];
	}
	gatekeeperName = [theGatekeeperName retain];
	
	gatekeeperRegistrationFailReason = XMGatekeeperRegistrationFailReason_NoFailure;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidRegisterAtGatekeeper
														object:self];
}

- (void)_handleGatekeeperUnregistration
{
	if(gatekeeperName == nil)
	{
		return;
	}
	
	[gatekeeperName release];
	gatekeeperName = nil;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidUnregisterFromGatekeeper
														object:self];
}

- (void)_handleGatekeeperRegistrationFailure:(NSNumber *)failReason
{
	if(gatekeeperName != nil)
	{
		[gatekeeperName release];
		gatekeeperName = nil;
	}
	
	gatekeeperRegistrationFailReason = (XMGatekeeperRegistrationFailReason)[failReason unsignedIntValue];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidNotRegisterAtGatekeeper
														object:self];
}

- (void)_initiateCall:(XMURL *)url
{
	XMCallProtocol callProtocol = [url callProtocol];
	NSString *address = [url address];
	
	// checking if the protocol is enabled. It may also be that the enabling failed for some reason!
	if((callProtocol == XMCallProtocol_H323) && (h323ListeningStatus != XM_H323_LISTENING))
	{
		callStartFailReason = XMCallStartFailReason_ProtocolNotEnabled;
		
		NSNotification *notification = [NSNotification notificationWithName:XMNotification_CallManagerDidNotStartCalling
																	 object:self];
		[[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostASAP];
		
		return;
	}
	
	/* Checks completed, start calling */
	callManagerStatus = XM_CALL_MANAGER_PREPARING_CALL;
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidStartCallInitiation
														object:self];
	
	[XMOpalDispatcher _initiateCallToAddress:address protocol:callProtocol];
}

- (void)_initiateSpecificCall:(XMGeneralPurposeURL *)url
{
	// In this case, we have to modify the subsystem before continuing
	// to make the call. This is "specific calling" since the call
	// is initated with a specific set of preferences
	XMPreferences *modifiedPreferences = [activePreferences copy];
	[url _modifyPreferences:modifiedPreferences];

	XMCallProtocol callProtocol = [url callProtocol];
	NSString *address = [url address];
	
	//Detection of call start failure conditions
	if(callProtocol == XMCallProtocol_H323 && [modifiedPreferences enableH323] == NO)
	{
		callStartFailReason = XMCallStartFailReason_ProtocolNotEnabled;
		
		NSNotification *notification = [NSNotification notificationWithName:XMNotification_CallManagerDidNotStartCalling
																	 object:self];
		[[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostASAP];
			
		[modifiedPreferences release];
			
		return;
	}
	else if(callProtocol == XMCallProtocol_H323 && 
			[activePreferences useGatekeeper] == NO && 
			[modifiedPreferences useGatekeeper] == YES &&
			[url valueForKey:XMKey_PreferencesGatekeeperAddress] == nil &&
			[url valueForKey:XMKey_PreferencesGatekeeperID] == nil)
	{
		callStartFailReason = XMCallStartFailReason_GatekeeperUsedButNotSpecified;
		
		NSNotification *notification = [NSNotification notificationWithName:XMNotification_CallManagerDidNotStartCalling
																	 object:self];
		[[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostASAP];
		
		[modifiedPreferences release];
		
		return;
	}
	
	//Detection of direct call start failure conditions completed.
	callManagerStatus = XM_CALL_MANAGER_PREPARING_CALL;
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidStartCallInitiation object:self];
	
	// change the subsystem and start calling afterwards
	[XMOpalDispatcher _initiateSpecificCallToAddress:address 
											protocol:callProtocol 
										 preferences:modifiedPreferences 
									 externalAddress:[_XMUtilsSharedInstance externalAddress]];
}

- (void)_storeCall:(XMCallInfo *)call
{
	if([recentCalls count] == 100)
	{
		[recentCalls removeObjectAtIndex:99];
	}
	[recentCalls insertObject:call atIndex:0];
}

@end
