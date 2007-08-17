/*
 * $Id: XMCallRecorderModule.h,v 1.4 2007/08/17 11:36:43 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CALL_RECORDER_MODULE_H__
#define __XM_CALL_RECORDER_MODULE_H__

#import <Cocoa/Cocoa.h>
#import "XMInspectorModule.h"

@interface XMCallRecorderModule : XMInspectorModule {

@private
  IBOutlet NSView *contentView;
  NSSize contentViewSize;
  
  IBOutlet NSButton *recordButton;
  IBOutlet NSTextField *filePathTextField;
  
  IBOutlet NSButton *recordAudioSwitch;
  IBOutlet NSButton *recordVideoSwitch;
  IBOutlet NSPopUpButton *videoModePopUp;
  IBOutlet NSMatrix *videoSourceMatrix;
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
- (IBAction)videoModeSelected:(id)sender;
- (IBAction)videoSourceSelected:(id)sender;
- (IBAction)videoCodecSelected:(id)sender;
- (IBAction)videoQualitySelected:(id)sender;
- (IBAction)toggleEnableVideoBandwidthLimit:(id)sender;
- (IBAction)toggleLowPriorityRecording:(id)sender;

@end

#endif // __XM_CALL_RECORDER_MODULE_H__
