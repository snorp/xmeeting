/*
 * $Id: XMCallInfo.m,v 1.12 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#import "XMCallInfo.h"

#import "XMPrivate.h"
#import "XMCallStatistics.h"

@implementation XMCallInfo

#pragma mark Init & Deallocation Methods

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	return nil;
}

- (id)_initWithCallToken:(NSString *)_callToken
                protocol:(XMCallProtocol)_protocol
              remoteName:(NSString *)_remoteName 
            remoteNumber:(NSString *)_remoteNumber
           remoteAddress:(NSString *)_remoteAddress
       remoteApplication:(NSString *)_remoteApplication
             callAddress:(NSString *)_callAddress
            localAddress:(NSString *)_localAddress
              callStatus:(XMCallStatus)_status;
{
	self = [super init];
	
	callToken = [_callToken copy];
	protocol = _protocol;

	remoteName = [_remoteName copy];
	remoteNumber = [_remoteNumber copy];
	remoteAddress = [_remoteAddress copy];
	remoteApplication = [_remoteApplication copy];
	callAddress = [_callAddress copy];
	localAddress = [_localAddress copy];
	localAddressInterface = nil;
	callStatus = _status;
	
	// setting the end reason to an impossible value
	callEndReason = XMCallEndReasonCount;
	
	callInitiationDate = [[NSDate alloc] init];
	callStartDate = nil;
	callEndDate = nil;
	
	incomingAudioCodec = nil;
	outgoingAudioCodec = nil;
	incomingVideoCodec = nil;
	outgoingVideoCodec = nil;
  
  isReceivingAudio = NO;
  isSendingAudio = NO;
  isReceivingVideo = NO;
  isSendingVideo = NO;
	
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
  [callToken release];
  
	[remoteName release];
	[remoteNumber release];
	[remoteAddress release];
	[remoteApplication release];
	[callAddress release];
	[localAddress release];
	
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

- (NSString *)localAddress
{
	return localAddress;
}

- (NSString *)localAddressInterface
{
	return localAddressInterface;
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
  if(callStartDate != nil) {
    if(callEndDate == nil) {
      NSDate *now = [[NSDate alloc] init];
      NSTimeInterval callDuration = [now timeIntervalSinceDate:callStartDate];
      [now release];
      return callDuration;
    } else {
      return [callEndDate timeIntervalSinceDate:callStartDate];
    }
  } else {
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

- (BOOL)isReceivingAudio
{
  return isReceivingAudio;
}

- (BOOL)isSendingAudio
{
  return isSendingAudio;
}

- (BOOL)isReceivingVideo
{
  return isReceivingVideo;
}

- (BOOL)isSendingVideo
{
  return isSendingVideo;
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

- (NSString *)_callToken
{
	return callToken;
}

- (void)_setCallToken:(NSString *)_callToken
{
  NSString *old = callToken;
  callToken = [_callToken copy];
	[old release];
}

- (void)_setRemoteName:(NSString *)_remoteName
{
	NSString *old = remoteName;
	remoteName = [_remoteName copy];
	[old release];
}

- (void)_setRemoteNumber:(NSString *)_remoteNumber
{
	NSString *old = remoteNumber;
	remoteNumber = [_remoteNumber copy];
	[old release];
}

- (void)_setRemoteAddress:(NSString *)_remoteAddress
{
	NSString *old = remoteAddress;
	remoteAddress = [_remoteAddress copy];
	[old release];
}

- (void)_setRemoteApplication:(NSString *)_remoteApplication
{
	NSString *old = remoteApplication;
	remoteApplication = [_remoteApplication copy];
	[old release];
}

- (void)_setLocalAddress:(NSString *)_localAddress
{
	NSString *old = localAddress;
	localAddress = [_localAddress copy];
	[old release];
}

- (void)_setLocalAddressInterface:(NSString *)_localAddressInterface
{
	NSString *old = localAddressInterface;
	localAddressInterface = [_localAddressInterface copy];
	[old release];
}

- (void)_setCallStatus:(XMCallStatus)status
{
  // do nothing if the status doesn't change
  if (callStatus == status) {
    return;
  }
  
	callStatus = status;

	// update the start / end times if needed
	if(status == XMCallStatus_Active) {
		callStartDate = [[NSDate alloc] init];
	} else if(status == XMCallStatus_Ended) {
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

- (void)_setIsReceivingAudio:(BOOL)flag
{
  isReceivingAudio = flag;
}

- (void)_setIsSendingAudio:(BOOL)flag
{
  isSendingAudio = flag;
}

- (void)_setIsReceivingVideo:(BOOL)flag
{
  isReceivingVideo = flag;
}

- (void)_setIsSendingVideo:(BOOL)flag
{
  isSendingVideo = flag;
}

- (void)_updateCallStatistics:(XMCallStatistics *)callStats
{
	XMCallStatisticsRecord *newStats = [callStats _callStatisticsRecord];
	
	memcpy(&callStatistics, newStats, sizeof(XMCallStatisticsRecord));
}

@end
