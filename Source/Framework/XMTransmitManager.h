/*
 * $Id: XMTransmitManager.h,v 1.1 2005/10/06 15:04:42 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_VIDEO_TRANSMIT_MANAGER_H__
#define __XM_VIDEO_TRANSMIT_MANAGER_H__

#import <Cocoa/Cocoa.h>
#import <QuickTime/QuickTime.h>
#import "XMVideoInputModule.h"

@interface XMTransmitManager : NSObject <XMVideoInputManager> {

	NSPort *receivePort;
	
	NSArray *videoInputModules;
	id<XMVideoInputModule> activeModule;
	NSString *selectedDevice;
	
	BOOL isGrabbing;
	BOOL isTransmitting;
	
	unsigned frameGrabRate;
	
	ICMCompressionSessionRef compressionSession;
	RTPMediaPacketizer mediaPacketizer;
	RTPMPSampleDataParams sampleData;
}

+ (void)_startupWithVideoInputModules:(NSArray *)videoInputModules;

+ (void)_getDeviceList;
+ (void)_setDevice:(NSString *)device;

+ (void)_setFrameGrabRate:(unsigned)frameGrabRate;

+ (void)_startGrabbing;
+ (void)_stopGrabbing;

+ (void)_shutdown;

@end

#endif // __XM_VIDEO_TRANSMIT_MANAGER_H__
