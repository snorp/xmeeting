/*
 * $Id: XMMediaTransmitter.h,v 1.8 2005/11/29 18:56:29 hfriederich Exp $
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
	NSMutableArray *videoInputViews;
	id<XMVideoInputModule> activeModule;
	NSString *selectedDevice;
	
	NSTimer *frameGrabTimer;
	
	BOOL isGrabbing;
	BOOL isTransmitting;
	BOOL needsPictureUpdate;
	
	unsigned frameGrabRate;
	unsigned transmitFrameGrabRate;
	XMVideoSize videoSize;
	CodecType codecType;
	TimeScale timeScale;
	TimeValue timeOffset;
	TimeValue lastTime;
	
	ICMCompressionSessionRef compressionSession;
	ICMCompressionFrameOptionsRef compressionFrameOptions;
	RTPMediaPacketizer mediaPacketizer;
	RTPMPSampleDataParams sampleData;
}

+ (void)_getDeviceList;
+ (void)_setDevice:(NSString *)device;

+ (void)_setFrameGrabRate:(unsigned)frameGrabRate;

+ (void)_startGrabbing;
+ (void)_stopGrabbing;

+ (void)_startTransmittingWithCodec:(XMCodecIdentifier)codecIdentifier
						  videoSize:(XMVideoSize)videoSize 
				 maxFramesPerSecond:(unsigned)maxFramesPerSecond
						 maxBitrate:(unsigned)maxBitrate
							session:(unsigned)sessionID;
+ (void)_stopTransmittingForSession:(unsigned)sessionID;

+ (void)_updatePicture;

- (id)_init;
- (void)_close;

@end

#endif // __XM_MEDIA_TRANSMITTER_H__
