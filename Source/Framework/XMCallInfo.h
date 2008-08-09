/*
 * $Id: XMCallInfo.h,v 1.14 2008/08/09 12:32:10 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CALL_INFO_H__
#define __XM_CALL_INFO_H__

#import <Foundation/Foundation.h>

#import "XMTypes.h"

/**
 * This class encapsulates all information about a specific call,
 * whether this is a call to or from an remote endpoint.
 * Instances of this class can be queried about the remote name,
 * the protocol used (H.323 or SIP) and additional informations
 * to customise the call which can be defined in a callto: / h323:
 * or sip: url.
 **/
@interface XMCallInfo : NSObject {
	
@private
  unsigned callID;	//identifier for the call token in OPAL
  
  XMCallProtocol protocol;
  NSString *remoteName;
  NSString *remoteNumber;
  NSString *remoteAddress;
  NSString *remoteApplication;
  NSString *callAddress;
  NSString *localAddress;
  NSString *localAddressInterface;
  
  XMCallStatus callStatus;
  XMCallEndReason callEndReason;
  
  NSDate *callInitiationDate;
  NSDate *callStartDate;
  NSDate *callEndDate;
  
  NSString *incomingAudioCodec;
  NSString *outgoingAudioCodec;
  NSString *incomingVideoCodec;
  NSString *outgoingVideoCodec;
  
  BOOL isReceivingAudio;
  BOOL isSendingAudio;
  BOOL isReceivingVideo;
  BOOL isSendingVideo;
  
  XMCallStatisticsRecord callStatistics;
}

/**
 * Obtain the call protocol in use
 **/
- (XMCallProtocol)protocol;

/**
 * Returns the call direction
 **/
- (BOOL)isOutgoingCall;

/**
 * Obtain the remote party's name.
 * Returns nil if there is no remote name
 * (remote party not found)
 **/
- (NSString *)remoteName;

/**
 * Obtain the remote party's e164 number.
 * Returns nil if the remote party has no number
 **/
- (NSString *)remoteNumber;

/**
 * Obtain the remote party's address.
 * Returns nil if the remoty party has no
 * address (remote party not found)
 **/
- (NSString *)remoteAddress;

/**
 * Obtain the remote party's application.
 * Returns nil if the remote party's application
 * cannot be determined (remote party not found)
 **/
- (NSString *)remoteApplication;

/**
 * Returns the address used to call the remote party.
 * If this is an incoming call, returns nil
 **/
- (NSString *)callAddress;

/**
 * Returns the local address over which the
 * call is / was running
 **/
- (NSString *)localAddress;

/**
 * Returns the network interface about which
 * the call did run in a human readable fashion.
 * Returns "<PUBLIC>" if the local address matches
 * the public (non NATed) address at the time the call was.
 * Returns "<UNKNOWN>" if the interface isn't known.
 **/
- (NSString *)localAddressInterface;

/**
 * Returns the current state of the call
 **/
- (XMCallStatus)callStatus;

/**
 * Returns the reason why the call was ended.
 * Note that the return value is only meaningful
 * if the call is ended. Otherwise, NumCallEndReasons
 * will be returned
 **/
- (XMCallEndReason)callEndReason;

/**
 * Returns the time when the call was initiated (the time this object was created)
 **/
- (NSDate *)callInitiationDate;

/**
 * Returns the time when the call started. This marks the time when the
 * callStatus changed to XMCallStatus_Active. If the call never started,
 * returns nil
 **/
- (NSDate *)callStartDate;

/**
 * Returns the time when the call ended. If the call is still active
 * or never started, returns nil. The call is considered to have ended
 * when the callStatus changed to XMCallStatus_Ended.
 **/
- (NSDate *)callEndDate;

/**
 * Obtain the duration of the call. This information is always up-to-date.
 * If the call has ended, returns the total duration of the call.
 **/
- (NSTimeInterval)callDuration;

/**
 * Returns the audio codec used for the incoming audio stream
 **/
- (NSString *)incomingAudioCodec;

/**
 * Returns the audio codec used for the outgoing audio stream
 **/
- (NSString *)outgoingAudioCodec;

/**
 * Returns the video codec used for the incoming video stream
 **/
- (NSString *)incomingVideoCodec;

/**
 * Returns the video codec used for the outgoing video stream
 **/
- (NSString *)outgoingVideoCodec;

/**
 * Returns whether the call is currently receiving audio
 **/
- (BOOL)isReceivingAudio;

/**
 * Returns whether the call is currently sending audio
 **/
- (BOOL)isSendingAudio;

/**
 * Returns whether the call is currently receiving video
 **/
- (BOOL)isReceivingVideo;

/**
 * Returns whether the call is currently sending video
 **/
- (BOOL)isSendingVideo;

/**
 * Returns the roundTripDelay in milliseconds
 **/
- (unsigned)roundTripDelay;

/**
 * Return the respective statistics data
 **/
- (unsigned)audioPacketsSent;
- (unsigned)audioBytesSent;
- (unsigned)audioMinimumSendTime; // milliseconds
- (unsigned)audioAverageSendTime; // milliseconds
- (unsigned)audioMaximumSendTime; // milliseconds
	
- (unsigned)audioPacketsReceived;
- (unsigned)audioBytesReceived;
- (unsigned)audioMinimumReceiveTime; // milliseconds
- (unsigned)audioAverageReceiveTime; // milliseconds
- (unsigned)audioMaximumReceiveTime; // milliseconds
	
- (unsigned)audioPacketsLost;
- (unsigned)audioPacketsOutOfOrder;
- (unsigned)audioPacketsTooLate;
	
- (unsigned)videoPacketsSent;
- (unsigned)videoBytesSent;
- (unsigned)videoMinimumSendTime; // milliseconds
- (unsigned)videoAverageSendTime; // milliseconds
- (unsigned)videoMaximumSendTime; // milliseconds
	
- (unsigned)videoPacketsReceived;
- (unsigned)videoBytesReceived;
- (unsigned)videoMinimumReceiveTime; // milliseconds
- (unsigned)videoAverageReceiveTime; // milliseconds
- (unsigned)videoMaximumReceiveTime; // milliseconds
	
- (unsigned)videoPacketsLost;
- (unsigned)videoPacketsOutOfOrder;
- (unsigned)videoPacketsTooLate;

@end

#endif // __XM_CALL_INFO_H__