/*
 * $Id: XMStatisticsModule.m,v 1.5 2005/08/27 22:08:22 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMeeting.h"
#import "XMStatisticsModule.h"
#import "XMApplicationFunctions.h"
#import "XMMainWindowController.h"

@interface XMStatisticsModule (PrivateMethods)

- (void)_callStatisticsUpdated:(NSNotification *)notif;

@end

@implementation XMStatisticsModule

- (id)init
{
	[[XMMainWindowController sharedInstance] addAdditionModule:self];
	
	nibLoader = nil;
	activeCall = nil;
	
	oldDate = nil;
	oldAudioBytesSent = 0;
	oldAudioBytesReceived = 0;
	oldVideoBytesSent = 0;
	oldVideoBytesReceived = 0;
	
	audioSendBitrate = -1.0f;
	audioReceiveBitrate = -1.0f;
	videoSendBitrate = -1.0f;
	videoReceiveBitrate = -1.0f;
}

- (void)dealloc
{
	[nibLoader release];
	
	[activeCall release];
	
	[oldDate release];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	expandedContentViewSize = [contentView frame].size;
	collapsedContentViewSize = expandedContentViewSize;
	collapsedContentViewSize.height -= 115.0;
	
	isExpanded = NO;
}

#pragma mark Protocol Methods

- (NSString *)name
{
	return @"Call Statistics";
}

- (NSImage *)image
{
	return [NSImage imageNamed:@"Statistics"];
}

- (NSView *)contentView
{
	if(nibLoader == nil)
	{
		nibLoader = [[NSNib alloc] initWithNibNamed:@"StatisticsModule" bundle:nil];
		[nibLoader instantiateNibWithOwner:self topLevelObjects:nil];
	}
	
	return contentView;
}

- (NSSize)contentViewSize
{
	// if not already done, causing the nib file to load
	[self contentView];
	
	if(isExpanded == YES)
	{
		return expandedContentViewSize;
	}
	else
	{
		return collapsedContentViewSize;
	}
}

- (void)becomeActiveModule
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(_callStatisticsUpdated:)
												 name:XMNotification_CallManagerCallStatisticsUpdated
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(_callStatisticsUpdated:)
												 name:XMNotification_CallManagerCallCleared
											   object:nil];
}

- (void)becomeInactiveModule
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark User Interface Methods

- (IBAction)toggleShowExtraInformation:(id)sender
{
	isExpanded = !isExpanded;
	
	[[XMMainWindowController sharedInstance] noteSizeValuesDidChangeOfAdditionModule:self];
}

#pragma mark TableView DataSource Methods

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return 4;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if(activeCall == nil)
	{
		return @"";
	}
	
	NSString *identifier = [aTableColumn identifier];
	
	if([identifier isEqualToString:@"Type"])
	{
		switch (rowIndex)
		{
			case 0:
				return @"Audio In";
			case 1:
				return @"Audio Out";
			case 2:
				return @"Video In";
			case 3:
				return @"Video Out";
		}
	}
	else if([identifier isEqualToString:@"Codec"])
	{
		NSString *codecString = nil;
		
		switch (rowIndex)
		{
			case 0:
				codecString = [activeCall incomingAudioCodec];
				break;
			case 1:
				codecString = [activeCall outgoingAudioCodec];
				break;
			case 2:
				codecString = [activeCall incomingVideoCodec];
				break;
			case 3:
				codecString = [activeCall outgoingVideoCodec];
				break;
			default:
				codecString = @"ERROR";
		}
		
		if(codecString == nil)
		{
			codecString = @"";
		}
		
		return codecString;
	}
	else if([identifier isEqualToString:@"Bitrate"])
	{
		float bitrate;
		
		switch (rowIndex)
		{
			case 0:
				bitrate = audioReceiveBitrate;
				break;
			case 1:
				bitrate = audioSendBitrate;
				break;
			case 2:
				bitrate = videoReceiveBitrate;
				break;
			case 3:
				bitrate = videoSendBitrate;
				break;
			default:
				bitrate = -1.0f;
		}
		
		if(bitrate < 0)
		{
			return @"";
		}
		else
		{
			return [NSString stringWithFormat:@"%6.1f kbit/s", bitrate];
		}
	}
	else if([identifier isEqualToString:@"TotalPackets"])
	{
		
		switch (rowIndex)
		{
			case 0:
				if([activeCall outgoingAudioCodec] != nil)
				{
					return [NSNumber numberWithUnsignedInt:[activeCall audioPacketsReceived]];
				}
			case 1:
				if([activeCall incomingAudioCodec] != nil)
				{
					return [NSNumber numberWithUnsignedInt:[activeCall audioPacketsSent]];
				}
			case 2:
				if([activeCall outgoingVideoCodec] != nil)
				{
					return [NSNumber numberWithUnsignedInt:[activeCall videoPacketsReceived]];
				}
			case 3:
				if([activeCall incomingVideoCodec] != nil)
				{
					return [NSNumber numberWithUnsignedInt:[activeCall videoPacketsSent]];
				}
			default:
				return @"";
		}
		
	}
	else
	{
		switch (rowIndex)
		{
			case 0:
				if([activeCall outgoingAudioCodec] != nil)
				{
					return byteString([activeCall audioBytesReceived]);
				}
			case 1:
				if([activeCall incomingAudioCodec] != nil)
				{
					return byteString([activeCall audioBytesSent]);
				}
			case 2:
				if([activeCall outgoingVideoCodec] != nil)
				{
					return byteString([activeCall videoBytesReceived]);
				}
			case 3:
				if([activeCall incomingVideoCodec] != nil)
				{
					return byteString([activeCall videoBytesSent]);
				}
			default:
				return @"";
		}
	}
	
	return @"ERROR";
}

#pragma mark Private Methods

- (void)_callStatisticsUpdated:(NSNotification *)notif
{
	XMCallInfo *newActiveCall = [[XMCallManager sharedInstance] activeCall];
	
	if(newActiveCall != nil && activeCall != newActiveCall)
	{
		[activeCall release];
		activeCall = [newActiveCall retain];
		
		oldAudioBytesSent = 0;
		oldAudioBytesReceived = 0;
		oldVideoBytesSent = 0;
		oldVideoBytesReceived = 0;
		
		if(oldDate)
		{
			[oldDate release];
			oldDate = [[activeCall callStartDate] retain];
		}
	}
	
	XMCallStatus callStatus = [activeCall callStatus];
	
	if(callStatus == XMCallStatus_Active)
	{
		NSDate *newDate = [[NSDate alloc] init];
		float denominator = (float)([newDate timeIntervalSinceDate:oldDate] * 125.0);
		
		[oldDate release];
		oldDate = newDate;
		
		unsigned newAudioBytesSent = [activeCall audioBytesSent];
		unsigned newAudioBytesReceived = [activeCall audioBytesReceived];
		unsigned newVideoBytesSent = [activeCall videoBytesSent];
		unsigned newVideoBytesReceived = [activeCall videoBytesReceived];

		// newBytes - oldBytes = diffBytes
		// diffBits = 8 * diffBytes
		// diffKBits = diffBits / 1000 == diffBytes / 125
		if(denominator != 0.0 && [activeCall outgoingAudioCodec] != nil)
		{
			audioSendBitrate = (float)(newAudioBytesSent - oldAudioBytesSent) / denominator;
		}
		else
		{
			audioSendBitrate = -1.0f;
		}
	
		if(denominator != 0.0 && [activeCall incomingAudioCodec] != nil)
		{
			audioReceiveBitrate = (float)(newAudioBytesReceived - oldAudioBytesReceived) / denominator;
		}
		else
		{
			audioReceiveBitrate = -1.0f;
		}
	
		if(denominator != 0.0 && [activeCall outgoingVideoCodec])
		{
			videoSendBitrate = (float)(newVideoBytesSent - oldVideoBytesSent) / denominator;
		}
		else
		{
			videoSendBitrate = -1.0f;
		}
	
		if(denominator != 0.0 && [activeCall incomingVideoCodec] != nil)
		{
			videoReceiveBitrate = (float)(newVideoBytesReceived - oldVideoBytesReceived) / denominator;
		}
		else
		{
			videoReceiveBitrate = -1.0f;
		}
	
		oldAudioBytesSent = newAudioBytesSent;
		oldAudioBytesReceived = newAudioBytesReceived;
		oldVideoBytesSent = newVideoBytesSent;
		oldVideoBytesReceived = newVideoBytesReceived;
	}
	else
	{
		audioSendBitrate = -1.0;
		audioReceiveBitrate = -1.0;
		videoSendBitrate = -1.0;
		videoReceiveBitrate = -1.0;
	}
	
	[roundTripDelayField setIntValue:[activeCall roundTripDelay]];
	
	[packetsLostField setIntValue:([activeCall audioPacketsLost] + [activeCall videoPacketsLost])];
	[packetsLateField setIntValue:([activeCall audioPacketsTooLate] + [activeCall videoPacketsTooLate])];
	[packetsOutOfOrderField setIntValue:([activeCall audioPacketsOutOfOrder] + [activeCall videoPacketsOutOfOrder])];
	
	unsigned audioMinSendTime = [activeCall audioMinimumSendTime];
	unsigned videoMinSendTime = [activeCall videoMinimumSendTime];
	unsigned minSendTime = ((audioMinSendTime < videoMinSendTime) ? audioMinSendTime : videoMinSendTime);
	unsigned aveSendTime = ([activeCall audioAverageSendTime] + [activeCall videoAverageSendTime]) / 2;
	unsigned audioMaxSendTime = [activeCall audioMaximumSendTime];
	unsigned videoMaxSendTime = [activeCall videoMaximumSendTime];
	unsigned maxSendTime = ((audioMaxSendTime > videoMaxSendTime) ? audioMaxSendTime : videoMaxSendTime);
	unsigned audioMinRecvTime = [activeCall audioMinimumReceiveTime];
	unsigned videoMinRecvTime = [activeCall videoMinimumReceiveTime];
	unsigned minRecvTime = ((audioMinRecvTime < videoMinRecvTime) ? audioMinRecvTime : videoMinRecvTime);
	unsigned aveRecvTime = ([activeCall audioAverageReceiveTime] + [activeCall videoAverageReceiveTime]) / 2;
	unsigned audioMaxRecvTime = [activeCall audioMaximumReceiveTime];
	unsigned videoMaxRecvTime = [activeCall videoMaximumReceiveTime];
	unsigned maxRecvTime = ((audioMaxRecvTime > videoMaxRecvTime) ? audioMaxRecvTime : videoMaxRecvTime);
	
	NSString *sendString = [[NSString alloc] initWithFormat:@"%d/%d/%d msec", minSendTime, aveSendTime, maxSendTime];
	[packetSendTimeField setStringValue:sendString];
	[sendString release];
	
	NSString *receiveString = [[NSString alloc] initWithFormat:@"%d/%d/%d msec", minRecvTime, aveRecvTime, maxRecvTime];
	[packetReceiveTimeField setStringValue:receiveString];
	[receiveString release];
	
	[codecTableView reloadData];
}

@end
