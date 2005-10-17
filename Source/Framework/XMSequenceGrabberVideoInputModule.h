/*
 * $Id: XMSequenceGrabberVideoInputModule.h,v 1.3 2005/10/17 12:57:53 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
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

}

- (id)_init;

@end

#endif // __XM_SEQUENCE_GRABBER_VIDEO_INPUT_MODULE_H__