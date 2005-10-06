/*
 * $Id: XMSequenceGrabberVideoInputModule.h,v 1.1 2005/10/06 15:04:42 hfriederich Exp $
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
	BOOL didCallCallback;

}

@end

#endif // __XM_SEQUENCE_GRABBER_VIDEO_INPUT_MODULE_H__