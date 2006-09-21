/*
 * $Id: XMCallRecorderModule.h,v 1.2 2006/09/21 20:14:23 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CALL_RECORDER_MODULE_H__
#define __XM_CALL_RECORDER_MODULE_H__

#import <Cocoa/Cocoa.h>
#import "XMInspectorModule.h"

@interface XMCallRecorderModule : XMInspectorModule {
	
	IBOutlet NSView *contentView;
	NSSize contentViewSize;
	
	IBOutlet NSButton *recordButton;
	IBOutlet NSTextField *filePathTextField;
	
	IBOutlet NSButton *recordAudioSwitch;
	IBOutlet NSButton *recordVideoSwitch;
	IBOutlet NSPopUpButton *videoCodecPopUp;
	IBOutlet NSSlider *videoQualitySlider;
	IBOutlet NSButton *dataRateLimitSwitch;
	IBOutlet NSTextField *dataRateLimitField;
	NSString *bwLimitString;
	IBOutlet NSButton *lowPrioritySwitch;
	
	NSWindow *recorderWindow;

}

- (IBAction)toggleRecording:(id)sender;

- (IBAction)toggleRecordAudio:(id)sender;
- (IBAction)toggleRecordVideo:(id)sender;
- (IBAction)videoCodecSelected:(id)sender;
- (IBAction)videoQualitySelected:(id)sender;
- (IBAction)toggleEnableVideoBandwidthLimit:(id)sender;
- (IBAction)toggleLowPriorityRecording:(id)sender;

@end

#endif // __XM_CALL_RECORDER_MODULE_H__
