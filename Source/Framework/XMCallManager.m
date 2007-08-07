/*
 * $Id: XMCallManager.m,v 1.38 2007/08/07 14:55:03 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
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
#import "XMPreferencesRegistrationRecord.h"
#import "XMAddressResource.h"
#import "XMBridge.h"

#define XM_H323_NOT_LISTENING 0
#define XM_H323_LISTENING 1
#define XM_H323_ERROR 2

#define XM_SIP_NOT_LISTENING 0
#define XM_SIP_LISTENING 1
#define XM_SIP_ERROR 2

#define XM_CALL_MANAGER_READY 0
#define XM_CALL_MANAGER_SUBSYSTEM_SETUP 1
#define XM_CALL_MANAGER_PREPARING_CALL 2
#define XM_CALL_MANAGER_IN_CALL 3
#define XM_CALL_MANAGER_TERMINATING_CALL 4

@interface XMCallManager (PrivateMethods)

- (void)_doSubsystemSetupWithPreferences:(XMPreferences *)preferences;
- (void)_didEndFetchingExternalAddress:(NSNotification *)notif;

- (void)_initiateCall:(XMAddressResource *)addressResource;
- (void)_initiateSpecificCall:(XMGeneralPurposeAddressResource *)addressResource;

- (NSString *)_prepareCallInitiation:(XMAddressResource *)addressResource;

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
	
	callManagerStatus = XM_CALL_MANAGER_READY;
	
	h323ListeningStatus = XM_H323_NOT_LISTENING;
	sipListeningStatus = XM_SIP_NOT_LISTENING;
	
	activePreferences = [[XMPreferences alloc] init];
	automaticallyAcceptIncomingCalls = NO;
	
	activeCall = nil;
	needsSubsystemSetupAfterCallEnd = NO;
	callStartFailReason = XMCallStartFailReason_NoFailure;
	
	canSendCameraEvents = NO;
	
	gatekeeperName = nil;
	gatekeeperRegistrationFailReason = XMGatekeeperRegistrationFailReason_NoFailure;
	
	registrations = [[NSMutableArray alloc] initWithCapacity:1];
	sipRegistrationFailReasons = [[NSMutableArray alloc] initWithCapacity:1];
	
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
	
	if(registrations != nil)
	{
		[registrations release];
		registrations = nil;
	}
	
	if(sipRegistrationFailReasons != nil)
	{
		[sipRegistrationFailReasons release];
		sipRegistrationFailReasons = nil;
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

#pragma mark -
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
	return (sipListeningStatus == XM_SIP_LISTENING);
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

#pragma mark -
#pragma mark Call management methods

- (BOOL)isInCall
{
	if((callManagerStatus == XM_CALL_MANAGER_PREPARING_CALL) ||
	   (callManagerStatus == XM_CALL_MANAGER_IN_CALL) ||
	   (callManagerStatus == XM_CALL_MANAGER_TERMINATING_CALL))
	{
		return YES;
	}
	
	return NO;
}

- (XMCallInfo *)activeCall
{
	return activeCall;
}

- (void)makeCall:(XMAddressResource *)addressResource;
{	
	// invalid action checks
	if(callManagerStatus != XM_CALL_MANAGER_READY)
	{
		[NSException raise:XMException_InvalidAction format:XMExceptionReason_CallManagerInvalidActionIfInSubsystemSetupOrInCall];
		return;
	}
	
	if([addressResource isKindOfClass:[XMGeneralPurposeAddressResource class]])
	{
		XMGeneralPurposeAddressResource *resource = (XMGeneralPurposeAddressResource *)addressResource;
		
		if([resource _doesModifyPreferences:activePreferences])
		{
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
	
	if(callManagerStatus == XM_CALL_MANAGER_TERMINATING_CALL)
	{
		return;
	}
	
	callManagerStatus = XM_CALL_MANAGER_TERMINATING_CALL;
	
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
	   [activePreferences gatekeeperAddress] != nil &&
	   [activePreferences gatekeeperUsername] != nil)
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

#pragma mark -
#pragma mark SIP specific Methods

- (BOOL)isCompletelyRegistered
{
	unsigned count = [sipRegistrationFailReasons count];
	if(count == 0)
	{
		return NO;
	}
	
	BOOL didRegisterAll = YES;
	
	unsigned i;
	for(i = 0; i < count; i++)
	{
		NSNumber *number = (NSNumber *)[sipRegistrationFailReasons objectAtIndex:i];
		XMSIPStatusCode failReason = (XMSIPStatusCode)[number unsignedIntValue];
		if(failReason != XMSIPStatusCode_NoFailure)
		{
			didRegisterAll = NO;
			break;
		}
	}
	
	return didRegisterAll;
}

- (unsigned)registrationCount
{
	return [registrations count];
}

- (NSString *)registrationAtIndex:(unsigned)index
{
	return (NSString *)[registrations objectAtIndex:index];
}

- (NSArray *)registrations
{
	NSArray *registrationsCopy = [registrations copy];
	return [registrationsCopy autorelease];
}

- (unsigned)sipRegistrationFailReasonCount
{
	return [sipRegistrationFailReasons count];
}

- (XMSIPStatusCode)sipRegistrationFailReasonAtIndex:(unsigned)index
{
	NSNumber *number = (NSNumber *)[sipRegistrationFailReasons objectAtIndex:index];
	
	return (XMSIPStatusCode)[number unsignedIntValue];
}

- (NSArray *)sipRegistrationFailReasons
{
	NSArray *copy = [sipRegistrationFailReasons copy];
	return [copy autorelease];
}

- (void)retryEnableSIP
{
	if(callManagerStatus == XM_CALL_MANAGER_READY &&
	   sipListeningStatus == XM_SIP_ERROR && 
	   activePreferences != nil &&
	   [activePreferences enableSIP] == YES)
	{
		sipListeningStatus = XM_SIP_NOT_LISTENING;
		
		callManagerStatus = XM_CALL_MANAGER_SUBSYSTEM_SETUP;
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidStartSubsystemSetup
															object:self];
		
		[XMOpalDispatcher _retryEnableSIP:activePreferences];
	}
	else
	{
		NSString *exceptionReason;
		
		if(callManagerStatus != XM_CALL_MANAGER_READY)
		{
			exceptionReason = XMExceptionReason_CallManagerInvalidActionIfInSubsystemSetupOrInCall;
		}
		else if([self isSIPListening] == YES)
		{
			exceptionReason = XMExceptionReason_CallManagerInvalidActionIfSIPListening;
		}
		else if(activePreferences == nil)
		{
			exceptionReason = XMExceptionReason_InvalidParameterMustNotBeNil;
		}
		else
		{
			exceptionReason = XMExceptionReason_CallManagerInvalidActionIfSIPDisabled;
		}
		
		[NSException raise:XMException_InvalidAction format:exceptionReason];
	}
}

- (void)retrySIPRegistrations
{
	if(callManagerStatus == XM_CALL_MANAGER_READY &&
	   [self isCompletelyRegistered] == NO && 
	   activePreferences != nil &&
	   [[activePreferences sipRegistrationRecords] count] != 0)
	{
		callManagerStatus = XM_CALL_MANAGER_SUBSYSTEM_SETUP;
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidStartSubsystemSetup
															object:self];
		[XMOpalDispatcher _retrySIPRegistrations:activePreferences];
	}
	else
	{
		NSString *exceptionReason;
		
		if(callManagerStatus != XM_CALL_MANAGER_READY)
		{
			exceptionReason = XMExceptionReason_CallManagerInvalidActionIfInSubsystemSetupOrInCall;
		}
		else if([self isCompletelyRegistered] == YES)
		{
			exceptionReason = XMExceptionReason_CallManagerInvalidActionIfCompletelySIPRegistered;
		}
		else if(activePreferences == nil)
		{
			exceptionReason = XMExceptionReason_InvalidParameterMustNotBeNil;
		}
		else
		{
			exceptionReason = XMExceptionReason_CallManagerInvalidActionIfSIPDisabled;
		}
		
		[NSException raise:XMException_InvalidAction format:exceptionReason];
	}
}

#pragma mark -
#pragma mark InCall Methods

- (void)setUserInputMode:(XMUserInputMode) userInputMode
{
	[XMOpalDispatcher _setUserInputMode:userInputMode];
}

- (void)sendUserInputTone:(char)tone
{
	if(callManagerStatus != XM_CALL_MANAGER_IN_CALL)
	{
		[NSException raise:XMException_InvalidAction format:XMExceptionReason_CallManagerInvalidActionIfNotInCall];
		return;
	}
	
	unsigned callID = [activeCall _callID];
	
	[XMOpalDispatcher _sendUserInputToneForCall:callID tone:tone];
}

- (void)sendUserInputString:(NSString *)string
{
	if(callManagerStatus != XM_CALL_MANAGER_IN_CALL)
	{
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
	if(callManagerStatus != XM_CALL_MANAGER_IN_CALL)
	{
		[NSException raise:XMException_InvalidAction format:XMExceptionReason_CallManagerInvalidActionIfNotInCall];
		return;
	}
	
	unsigned callID = [activeCall _callID];
	
	[XMOpalDispatcher _startCameraEventForCall:callID event:cameraEvent];
}

- (void)stopCameraEvent
{
	if(callManagerStatus != XM_CALL_MANAGER_IN_CALL)
	{
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
	BOOL enableH323 = [activePreferences enableH323];
	if((enableH323 == YES) && (h323ListeningStatus != XM_H323_ERROR))
	{
		h323ListeningStatus = XM_H323_LISTENING;
	}
	else if(enableH323 == NO)
	{
		h323ListeningStatus = XM_H323_NOT_LISTENING;
	}
	
	BOOL enableSIP = [activePreferences enableSIP];
	if((enableSIP == YES) && (sipListeningStatus != XM_SIP_ERROR))
	{
		sipListeningStatus = XM_SIP_LISTENING;
	}
	else if(enableSIP == NO)
	{
		sipListeningStatus = XM_SIP_NOT_LISTENING;
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
		callManagerStatus = XM_CALL_MANAGER_READY;
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidEndSubsystemSetup object:self];
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

- (void)_handleCallInitiationFailed:(NSArray *)info
{
	NSNumber *number = (NSNumber *)[info objectAtIndex:0];
	NSString *address = (NSString *)[info objectAtIndex:1];
	
	callStartFailReason = (XMCallStartFailReason)[number unsignedIntValue];
	
	callManagerStatus = XM_CALL_MANAGER_READY;
	
	needsSubsystemSetupAfterCallEnd = NO;
	
	NSDictionary *infoDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:address, @"Address", nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidNotStartCalling object:self userInfo:infoDictionary];
	
	[infoDictionary release];
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
	
	NSArray *localAddresses = [_XMUtilsSharedInstance localAddresses];
	NSArray *localAddressInterfaces = [_XMUtilsSharedInstance localAddressInterfaces];
	
	NSString *localAddress = [call localAddress];
	NSString *localAddressInterface;
	unsigned index = [localAddresses indexOfObject:localAddress];
	if(index != NSNotFound)
	{
		localAddressInterface = (NSString *)[localAddressInterfaces objectAtIndex:index];
	}
	else
	{
		NSString *externalAddress = [_XMUtilsSharedInstance stunExternalAddress];
		if(externalAddress == nil)
		{
			externalAddress = [_XMUtilsSharedInstance checkipExternalAddress];
		}
		
		if([localAddress isEqualToString:externalAddress])
		{
			localAddressInterface = @"<EXT>";
		}
		else
		{
			localAddressInterface = @"<UNK>";
		}
	}	
	
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
		NSString *localAddress = (NSString *)[remotePartyInformations objectAtIndex:4];
		
		[activeCall _setRemoteName:remoteName];
		[activeCall _setRemoteNumber:remoteNumber];
		[activeCall _setRemoteAddress:remoteAddress];
		[activeCall _setRemoteApplication:remoteApplication];
		[activeCall _setLocalAddress:localAddress];
		
		NSArray *localAddresses = [_XMUtilsSharedInstance localAddresses];
		NSArray *localAddressInterfaces = [_XMUtilsSharedInstance localAddressInterfaces];
		
		unsigned index = [localAddresses indexOfObject:localAddress];
		NSString *localAddressInterface;
		if(index != NSNotFound)
		{
			localAddressInterface = (NSString *)[localAddressInterfaces objectAtIndex:index];
		}
		else
		{
			NSString *externalAddress = [_XMUtilsSharedInstance stunExternalAddress];
			if(externalAddress == nil)
			{
				externalAddress = [_XMUtilsSharedInstance checkipExternalAddress];
			}
			
			if([localAddress isEqualToString:externalAddress])
			{
				localAddressInterface = @"<EXT>";
			}
			else
			{
				localAddressInterface = @"<UNK>";
			}
		}
		[activeCall _setLocalAddressInterface:localAddressInterface];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidEstablishCall
														object:self];
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

- (void)_handleLocalAddress:(NSString *)address
{
	if([activeCall localAddress] == nil)
	{
		[activeCall _setLocalAddress:address];
		
		NSArray *localAddresses = [_XMUtilsSharedInstance localAddresses];
		NSArray *localAddressInterfaces = [_XMUtilsSharedInstance localAddressInterfaces];
		
		unsigned index = [localAddresses indexOfObject:address];
		NSString *localAddressInterface;
		if(index != NSNotFound)
		{
			localAddressInterface = (NSString *)[localAddressInterfaces objectAtIndex:index];
		}
		else
		{
			NSString *externalAddress = [_XMUtilsSharedInstance stunExternalAddress];
			if(externalAddress == nil)
			{
				externalAddress = [_XMUtilsSharedInstance checkipExternalAddress];
			}
			
			if([address isEqualToString:externalAddress])
			{
				localAddressInterface = @"<EXT>";
			}
			else
			{
				localAddressInterface = @"<UNK>";
			}
		}
		[activeCall _setLocalAddressInterface:localAddressInterface];
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
	if([activeCall incomingVideoCodec] != nil)
	{
		return;
	}
	
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

- (void)_handleFECCChannelOpened
{
	canSendCameraEvents = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidOpenFECCChannel
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

- (void)_handleSIPEnablingFailure
{
	sipListeningStatus = XM_SIP_ERROR;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidNotEnableSIP
														object:self];
}

- (void)_handleSIPRegistrationProcessStart
{
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidStartSIPRegistrationProcess
														object:self];
}

- (void)_handleSIPRegistrationProcessEnd
{
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidEndSIPRegistrationProcess
														object:self];
}

- (void)_handleSIPRegistration:(NSString *)registration
{	
	NSArray *registrationRecords = [activePreferences sipRegistrationRecords];
	
	unsigned searchIndex = NSNotFound;
	unsigned count = [registrationRecords count];
	unsigned i;
	for(i = 0; i < count; i++)
	{
		XMPreferencesRegistrationRecord *record = (XMPreferencesRegistrationRecord *)[registrationRecords objectAtIndex:i];
		if(![record isKindOfClass:[XMPreferencesRegistrationRecord class]])
		{
			continue;
		}
        
        NSString *reg = [record registration];
        
		if([reg isEqualToString:registration])
		{
			searchIndex = i;
			break;
		}
	}
	
	if(searchIndex == NSNotFound)
	{
		NSLog(@"REGISTRATION NOT FOUND IN REGISTRATIONS");
		return;
	}
	
	[registrations addObject:registration];
	
	NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:XMSIPStatusCode_NoFailure];
	[sipRegistrationFailReasons replaceObjectAtIndex:searchIndex withObject:number];
	[number release];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidSIPRegister
														object:self];
}

- (void)_handleSIPUnregistration:(NSString *)registration
{	
	unsigned index = [registrations indexOfObject:registration];
	
	if(index == NSNotFound)
	{
		return;
	}
	[registrations removeObjectAtIndex:index];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidSIPUnregister
														object:self];
}

- (void)_handleSIPRegistrationFailure:(NSArray *)info
{
	// extracting information from the array
	NSString *registration = (NSString *)[info objectAtIndex:0];
	NSNumber *failReason = (NSNumber *)[info objectAtIndex:1];
	
	NSArray *records = [activePreferences sipRegistrationRecords];
	unsigned searchIndex = NSNotFound;
	unsigned count = [records count];
	unsigned i;
	
	for(i = 0; i < count; i++)
	{
		XMPreferencesRegistrationRecord *record = (XMPreferencesRegistrationRecord *)[records objectAtIndex:i];
		if(![record isKindOfClass:[XMPreferencesRegistrationRecord class]])
		{
			continue;
		}
        
        NSString *reg = [record registration];
        
		if([reg isEqualToString:registration])
		{
			searchIndex = i;
			break;
		}
	}
	
	if(searchIndex == NSNotFound)
	{
		NSLog(@"OBJECT NOT FOUND ON SIP REGISTRATION FAILURE");
	}
	
	[sipRegistrationFailReasons replaceObjectAtIndex:searchIndex withObject:failReason];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidNotSIPRegister
														object:self];
}

- (void)_updateSTUNInformation
{
	[self _doSubsystemSetupWithPreferences:activePreferences];
}

#pragma mark -
#pragma mark Private Methods

- (void)_doSubsystemSetupWithPreferences:(XMPreferences *)preferences
{
	if(callManagerStatus == XM_CALL_MANAGER_READY)
	{
		callManagerStatus = XM_CALL_MANAGER_SUBSYSTEM_SETUP;
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidStartSubsystemSetup
															object:self];
	}
	
	automaticallyAcceptIncomingCalls = [preferences automaticallyAcceptIncomingCalls];
	
	gatekeeperRegistrationFailReason = XMGatekeeperRegistrationFailReason_NoFailure;
	
	[sipRegistrationFailReasons removeAllObjects];
	
	unsigned count = [[preferences sipRegistrationRecords] count];
	unsigned i;
	NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:(unsigned)XMSIPStatusCode_NoFailure];
	for(i = 0; i < count; i++)
	{
		[sipRegistrationFailReasons addObject:number];
	}
	[number release];
	
	NSString *externalAddress = nil;
	externalAddress = [_XMUtilsSharedInstance checkipExternalAddress];
	if(externalAddress == nil)
	{
		if([_XMUtilsSharedInstance didSucceedFetchingCheckipExternalAddress] == YES)
		{
			// not yet fetched
			[_XMUtilsSharedInstance startFetchingCheckipExternalAddress];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didEndFetchingExternalAddress:)
														 name:XMNotification_UtilsDidEndFetchingCheckipExternalAddress object:nil];
					
			// we continue this job when the external address fetch task is finished
			return;
		}
	}
	
	// resetting the H323 listening status if an error previously
	if(h323ListeningStatus == XM_H323_ERROR)
	{
		h323ListeningStatus = XM_H323_NOT_LISTENING;
	}
	
	if(sipListeningStatus == XM_SIP_ERROR)
	{
		sipListeningStatus = XM_SIP_NOT_LISTENING;
	}
	
	// preparations complete
	[XMOpalDispatcher _setPreferences:preferences externalAddress:externalAddress];
}

- (void)_didEndFetchingExternalAddress:(NSNotification *)notif
{
	// removing the listener
	[[NSNotificationCenter defaultCenter] removeObserver:self name:XMNotification_UtilsDidEndFetchingCheckipExternalAddress object:nil];
	
	// do the subsystem setup again
	[self _doSubsystemSetupWithPreferences:activePreferences];
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
									 externalAddress:[_XMUtilsSharedInstance checkipExternalAddress]];
	
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
        if([processedAddress length] > 1)
        {
            if([processedAddress characterAtIndex:0] == '+')
            {
                [processedAddress replaceCharactersInRange:NSMakeRange(0, 1) withString:@"00"];
            }
        }
        address = [processedAddress autorelease];
                
    }
	if(callProtocol == XMCallProtocol_SIP)
	{
        // if using SIP and the address is a phone number,
        // the address must have the form xxx@registrar.net
        // In case the suffix @registrar.net is missing, 
        // the suffix is added from the information of the
        // registration domain
        if(XMIsPhoneNumber(address) && [registrations count] != 0)
        {
            NSRange atRange = [address rangeOfString:@"@"];
            
            if(atRange.location == NSNotFound)
            {
                NSString *registration = (NSString *)[registrations objectAtIndex:0];
                NSRange range = [registration rangeOfString:@"@"];
                NSString *domain = [registration substringFromIndex:(range.location + 1)];
                
                address = [NSString stringWithFormat:@"%@@%@", address, domain];
            }
        }
	}
	
	// validity check is done within XMOpalDispatcher
	
	callManagerStatus = XM_CALL_MANAGER_PREPARING_CALL;
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallManagerDidStartCallInitiation
														object:self];
	
	// Stop the audio test if needed
	[_XMAudioManagerSharedInstance stopAudioTest];
	
	return address;
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
