/*
 * $Id: XMCallInfo.m,v 1.5 2005/08/29 15:19:51 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMCallInfo.h"
#import "XMPrivate.h"

@implementation XMCallInfo

#pragma mark Init & Deallocation Methods

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	return nil;
}

- (id)_initWithCallID:(unsigned)theID 
			 protocol:(XMCallProtocol)theProtocol
		   remoteName:(NSString *)theRemoteName 
		 remoteNumber:(NSString *)theRemoteNumber
		remoteAddress:(NSString *)theRemoteAddress
	remoteApplication:(NSString *)theRemoteApplication
		  callAddress:(NSString *)theCallAddress
		   callStatus:(XMCallStatus)theStatus;
{
	self = [super init];
	
	callID = theID;
	protocol = theProtocol;

	remoteName = [theRemoteName copy];
	remoteNumber = [theRemoteNumber copy];
	remoteAddress = [theRemoteAddress copy];
	remoteApplication = [theRemoteApplication copy];
	callAddress = [theCallAddress copy];
	callStatus = theStatus;
	
	// setting the end reason to an impossible value
	callEndReason = XMCallEndReasonCount;
	
	callInitiationDate = [[NSDate alloc] init];
	callStartDate = nil;
	callEndDate = nil;
	
	incomingAudioCodec = nil;
	outgoingAudioCodec = nil;
	incomingVideoCodec = nil;
	outgoingVideoCodec = nil;
	
	callStatistics.roundTripDelay = 0;
	
	callStatistics.audioPacketsSent = 0;
	callStatistics.audioBytesSent = 0;
	callStatistics.audioMinimumSendTime = 0;
	callStatistics.audioAverageSendTime = 0;
	callStatistics.audioMaximumSendTime = 0;
	callStatistics.audioPacketsReceived = 0;
	callStatistics.audioBytesReceived = 0;
	callStatistics.audioMinimumReceiveTime = 0;
	callStatistics.audioAverageReceiveTime = 0;
	callStatistics.audioMaximumReceiveTime = 0;
	callStatistics.audioPacketsLost = 0;
	callStatistics.audioPacketsOutOfOrder = 0;
	callStatistics.audioPacketsTooLate = 0;
	
	callStatistics.videoPacketsSent = 0;
	callStatistics.videoBytesSent = 0;
	callStatistics.videoMinimumSendTime = 0;
	callStatistics.videoAverageSendTime = 0;
	callStatistics.videoMaximumSendTime = 0;
	callStatistics.videoPacketsReceived = 0;
	callStatistics.videoBytesReceived = 0;
	callStatistics.videoMinimumReceiveTime = 0;
	callStatistics.videoAverageReceiveTime = 0;
	callStatistics.videoMaximumReceiveTime = 0;
	callStatistics.videoPacketsLost = 0;
	callStatistics.videoPacketsOutOfOrder = 0;
	callStatistics.videoPacketsTooLate = 0;
	
	return self;
}

- (void)dealloc
{
	[remoteName release];
	[remoteNumber release];
	[remoteAddress release];
	[remoteApplication release];
	[callAddress release];
	
	[callInitiationDate release];
	[callStartDate release];
	[callEndDate release];
	
	[incomingAudioCodec release];
	[outgoingAudioCodec release];
	[incomingVideoCodec release];
	[outgoingVideoCodec release];
	
	[super dealloc];
}

#pragma mark Public Methods

- (XMCallProtocol)protocol
{
	return protocol;
}

- (BOOL)isOutgoingCall
{
	return callAddress != nil;
}

- (NSString *)remoteName
{
	return remoteName;
}

- (NSString *)remoteNumber
{
	return remoteNumber;
}

- (NSString *)remoteAddress
{
	return remoteAddress;
}

- (NSString *)remoteApplication
{
	return remoteApplication;
}

- (NSString *)callAddress
{
	return callAddress;
}

- (XMCallStatus)callStatus
{
	return callStatus;
}

- (XMCallEndReason)callEndReason
{
	return callEndReason;
}

- (NSDate *)callInitiationDate
{
	return callInitiationDate;
}

- (NSDate *)callStartDate
{
	return callStartDate;
}

- (NSDate *)callEndDate
{
	return callEndDate;
}

- (NSTimeInterval)callDuration
{
	if(callStartDate != nil)
	{
		if(callEndDate == nil)
		{
			NSDate *now = [[NSDate alloc] init];
			NSTimeInterval callDuration = [now timeIntervalSinceDate:callStartDate];
			[now release];
			return callDuration;
		}
		else
		{
			return [callEndDate timeIntervalSinceDate:callStartDate];
		}
	}
	else
	{
		return (NSTimeInterval)0.0;
	}
}

- (NSString *)incomingAudioCodec
{
	return incomingAudioCodec;
}

- (NSString *)outgoingAudioCodec
{
	return outgoingAudioCodec;
}

- (NSString *)incomingVideoCodec
{
	return incomingVideoCodec;
}

- (NSString *)outgoingVideoCodec
{
	return outgoingVideoCodec;
}

- (unsigned)roundTripDelay
{
	return callStatistics.roundTripDelay;
}

- (unsigned)audioPacketsSent
{
	return callStatistics.audioPacketsSent;
}

- (unsigned)audioBytesSent
{
	return callStatistics.audioBytesSent;
}

- (unsigned)audioMinimumSendTime
{
	return callStatistics.audioMinimumSendTime;
}

- (unsigned)audioAverageSendTime
{
	return callStatistics.audioAverageSendTime;
}

- (unsigned)audioMaximumSendTime
{
	return callStatistics.audioMaximumSendTime;
}
	
- (unsigned)audioPacketsReceived
{
	return callStatistics.audioPacketsReceived;
}

- (unsigned)audioBytesReceived
{
	return callStatistics.audioBytesReceived;
}

- (unsigned)audioMinimumReceiveTime
{
	return callStatistics.audioMinimumReceiveTime;
}

- (unsigned)audioAverageReceiveTime
{
	return callStatistics.audioAverageReceiveTime;
}

- (unsigned)audioMaximumReceiveTime
{
	return callStatistics.audioMaximumReceiveTime;
}
	
- (unsigned)audioPacketsLost
{
	return callStatistics.audioPacketsLost;
}

- (unsigned)audioPacketsOutOfOrder
{
	return callStatistics.audioPacketsOutOfOrder;
}

- (unsigned)audioPacketsTooLate
{
	return callStatistics.audioPacketsTooLate;
}
	
- (unsigned)videoPacketsSent
{
	return callStatistics.videoPacketsSent;
}

- (unsigned)videoBytesSent
{
	return callStatistics.videoBytesSent;
}

- (unsigned)videoMinimumSendTime
{
	return callStatistics.videoMinimumSendTime;
}

- (unsigned)videoAverageSendTime
{
	return callStatistics.videoAverageSendTime;
}

- (unsigned)videoMaximumSendTime
{
	return callStatistics.videoMaximumSendTime;
}
	
- (unsigned)videoPacketsReceived
{
	return callStatistics.videoPacketsReceived;
}

- (unsigned)videoBytesReceived
{
	return callStatistics.videoBytesReceived;
}

- (unsigned)videoMinimumReceiveTime
{
	return callStatistics.videoMinimumReceiveTime;
}

- (unsigned)videoAverageReceiveTime
{
	return callStatistics.videoAverageReceiveTime;
}

- (unsigned)videoMaximumReceiveTime
{
	return callStatistics.videoMaximumReceiveTime;
}
	
- (unsigned)videoPacketsLost
{
	return callStatistics.videoPacketsLost;
}

- (unsigned)videoPacketsOutOfOrder
{
	return callStatistics.videoPacketsOutOfOrder;
}

- (unsigned)videoPacketsTooLate
{
	return callStatistics.videoPacketsTooLate;
}

#pragma mark Private Methods

- (unsigned)_callID
{
	return callID;
}

- (void)_setCallID:(unsigned)theCallID
{
	callID = theCallID;
}

- (void)_setRemoteName:(NSString *)theName
{
	NSString *old = remoteName;
	remoteName = [theName copy];
	[old release];
}

- (void)_setRemoteNumber:(NSString *)theNumber
{
	NSString *old = remoteNumber;
	remoteNumber = [theNumber copy];
	[old release];
}

- (void)_setRemoteAddress:(NSString *)theAddress
{
	NSString *old = remoteAddress;
	remoteAddress = [theAddress copy];
	[old release];
}

- (void)_setRemoteApplication:(NSString *)theApplication
{
	NSString *old = remoteApplication;
	remoteApplication = [theApplication copy];
	[old release];
}

- (void)_setCallStatus:(XMCallStatus)status
{
	callStatus = status;
	
	if(status == XMCallStatus_Active)
	{
		// fetching the start time
		callStartDate = [[NSDate alloc] init];
	}
	else if(status == XMCallStatus_Ended)
	{
		callEndDate = [[NSDate alloc] init];
	}
}

- (void)_setCallEndReason:(XMCallEndReason)endReason
{
	callEndReason = endReason;
}

- (void)_setIncomingAudioCodec:(NSString *)codec
{
	NSString *old = incomingAudioCodec;
	incomingAudioCodec = [codec copy];
	[old release];
}

- (void)_setOutgoingAudioCodec:(NSString *)codec
{
	NSString *old = outgoingAudioCodec;
	outgoingAudioCodec = [codec copy];
	[old release];
}

- (void)_setIncomingVideoCodec:(NSString *)codec
{
	NSString *old = incomingVideoCodec;
	incomingVideoCodec = [codec copy];
	[old release];
}

- (void)_setOutgoingVideoCodec:(NSString *)codec
{
	NSString *old = outgoingVideoCodec;
	outgoingVideoCodec = [codec copy];
	[old release];
}

- (XMCallStatistics *)_callStatistics
{
	return &callStatistics;
}

@end
