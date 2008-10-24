/*
 * $Id: XMCallStatistics.m,v 1.3 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#import "XMCallStatistics.h"

@implementation XMCallStatistics

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	return nil;
}

- (id)_init
{
	self = [super init];
	
	callStatisticsRecord.roundTripDelay = 0;
	
	callStatisticsRecord.audioPacketsSent = 0;
	callStatisticsRecord.audioBytesSent = 0;
	callStatisticsRecord.audioMinimumSendTime = 0;
	callStatisticsRecord.audioAverageSendTime = 0;
	callStatisticsRecord.audioMaximumSendTime = 0;
	callStatisticsRecord.audioPacketsReceived = 0;
	callStatisticsRecord.audioBytesReceived = 0;
	callStatisticsRecord.audioMinimumReceiveTime = 0;
	callStatisticsRecord.audioAverageReceiveTime = 0;
	callStatisticsRecord.audioMaximumReceiveTime = 0;
	callStatisticsRecord.audioPacketsLost = 0;
	callStatisticsRecord.audioPacketsOutOfOrder = 0;
	callStatisticsRecord.audioPacketsTooLate = 0;
	
	callStatisticsRecord.videoPacketsSent = 0;
	callStatisticsRecord.videoBytesSent = 0;
	callStatisticsRecord.videoMinimumSendTime = 0;
	callStatisticsRecord.videoAverageSendTime = 0;
	callStatisticsRecord.videoMaximumSendTime = 0;
	callStatisticsRecord.videoPacketsReceived = 0;
	callStatisticsRecord.videoBytesReceived = 0;
	callStatisticsRecord.videoMinimumReceiveTime = 0;
	callStatisticsRecord.videoAverageReceiveTime = 0;
	callStatisticsRecord.videoMaximumReceiveTime = 0;
	callStatisticsRecord.videoPacketsLost = 0;
	callStatisticsRecord.videoPacketsOutOfOrder = 0;
	callStatisticsRecord.videoPacketsTooLate = 0;
	
	return self;
}

- (XMCallStatisticsRecord *)_callStatisticsRecord
{
	return &callStatisticsRecord;
}

@end
