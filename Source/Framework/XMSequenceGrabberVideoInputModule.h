/*
 * $Id: XMSequenceGrabberVideoInputModule.h,v 1.6 2006/06/07 10:10:15 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_SEQUENCE_GRABBER_VIDEO_INPUT_MODULE_H__
#define __XM_SEQUENCE_GRABBER_VIDEO_INPUT_MODULE_H__

#import <Cocoa/Cocoa.h>
#import <QuickTime/QuickTime.h>
#import "XMVideoInputModule.h"


@interface XMSequenceGrabberVideoInputModule : NSObject <XMVideoInputModule> {
	
	id<XMVideoInputManager> inputManager;
	
	SGDeviceList deviceList;
	NSArray *deviceNames;
	NSArray *deviceNameIndexes;
	NSString *selectedDevice;
	
	SeqGrabComponent sequenceGrabber;
	SGChannel videoChannel;
	SGDataUPP dataGrabUPP;
	ICMDecompressionSessionRef grabDecompressionSession;
	TimeValue lastTime;
	TimeValue timeScale;
	TimeValue desiredFrameDuration;
	
	NSSize frameSize;
	unsigned framesPerSecond;
	
	BOOL isGrabbing;
	unsigned callbackMissCounter;
	unsigned callbackStatus;
	
	unsigned short brightness;
	unsigned short hue;
	unsigned short saturation;
	unsigned short contrast;
	unsigned short sharpness;
	
	IBOutlet NSView *settingsView;
	
	IBOutlet NSSlider *brightnessSlider;
	IBOutlet NSTextField *brightnessField;
	IBOutlet NSSlider *hueSlider;
	IBOutlet NSTextField *hueField;
	IBOutlet NSSlider *saturationSlider;
	IBOutlet NSTextField *saturationField;
	IBOutlet NSSlider *contrastSlider;
	IBOutlet NSTextField *contrastField;
	IBOutlet NSSlider *sharpnessSlider;
	IBOutlet NSTextField *sharpnessField;
}

- (id)_init;

- (void)_setVideoValues:(NSArray *)values;

- (IBAction)_sliderValueChanged:(id)sender;

@end

#endif // __XM_SEQUENCE_GRABBER_VIDEO_INPUT_MODULE_H__