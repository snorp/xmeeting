/*
 * $Id: XMMediaTransmitter.h,v 1.2 2005/10/12 21:07:40 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_MEDIA_TRANSMITTER_H__
#define __XM_MEDIA_TRANSMITTER_H__

#import <Cocoa/Cocoa.h>
#import <QuickTime/QuickTime.h>

#import "XMVideoInputModule.h"
#import "XMTypes.h"

@interface XMMediaTransmitter : NSObject <XMVideoInputManager> {

	NSPort *receivePort;
	
	NSArray *videoInputModules;
	id<XMVideoInputModule> activeModule;
	NSString *selectedDevice;
	
	BOOL isGrabbing;
	BOOL isTransmitting;
	
	unsigned frameGrabRate;
	XMVideoSize videoSize;
	CodecType codecType;
	TimeScale timeScale;
	TimeValue timeOffset;
	TimeValue lastTime;
	
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

+ (void)_startTransmittingWithCodec:(unsigned)codecType videoSize:(XMVideoSize)videoSize session:(unsigned)sessionID;
+ (void)_stopTransmittingForSession:(unsigned)sessionID;

+ (void)_shutdown;

@end

#endif // __XM_MEDIA_TRANSMITTER_H__
