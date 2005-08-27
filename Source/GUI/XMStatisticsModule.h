/*
 * $Id: XMStatisticsModule.h,v 1.3 2005/08/27 22:08:22 hfriederich Exp $
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
	
	NSNib *nibLoader;
	
	XMCallInfo *activeCall;
	
	BOOL isExpanded;
	
	NSDate *oldDate;
	unsigned oldAudioBytesSent;
	unsigned oldAudioBytesReceived;
	unsigned oldVideoBytesSent;
	unsigned oldVideoBytesReceived;
	
	float audioSendBitrate;
	float audioReceiveBitrate;
	float videoSendBitrate;
	float videoReceiveBitrate;
}

- (IBAction)toggleShowExtraInformation:(id)sender;

@end

#endif // __XM_STATISTICS_MODULE_H__
