/*
 * $Id: XMStatisticsModule.h,v 1.4 2005/09/01 15:18:23 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_STATISTICS_MODULE_H__
#define __XM_STATISTICS_MODULE_H__

#import <Cocoa/Cocoa.h>
#import "XMMainWindowAdditionModule.h"

@class XMCallInfo;

@interface XMStatisticsModule : NSObject <XMMainWindowAdditionModule> {
	
	IBOutlet NSView *contentView;
	NSSize collapsedContentViewSize;
	NSSize expandedContentViewSize;
	
	IBOutlet NSTableView *codecTableView;
	IBOutlet NSButton *extraInformationDisclosure;
	
	IBOutlet NSTextField *roundTripDelayField;
	IBOutlet NSTextField *packetsLostField;
	IBOutlet NSTextField *packetsLateField;
	IBOutlet NSTextField *packetsOutOfOrderField;
	IBOutlet NSTextField *packetSendTimeField;
	IBOutlet NSTextField *packetReceiveTimeField;
	
	IBOutlet NSBox *callInformationBox;
	IBOutlet NSTextField *remotePartyNameField;
	IBOutlet NSTextField *callDurationField;
	
	NSNib *nibLoader;
	
	XMCallInfo *activeCall;
	
	BOOL isExpanded;
	
	NSDate *oldDate;
	float oldAudioBytesSent;
	float oldAudioBytesReceived;
	float oldVideoBytesSent;
	float oldVideoBytesReceived;
	
	float audioSendBitrate;
	float audioReceiveBitrate;
	float videoSendBitrate;
	float videoReceiveBitrate;
	
	float avgAudioSendBitrate;
	float avgAudioReceiveBitrate;
	float avgVideoSendBitrate;
	float avgVideoReceiveBitrate;
}

- (IBAction)toggleShowExtraInformation:(id)sender;

@end

#endif // __XM_STATISTICS_MODULE_H__
