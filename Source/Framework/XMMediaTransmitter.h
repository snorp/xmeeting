/*
 * $Id: XMMediaTransmitter.h,v 1.10 2006/01/14 13:25:59 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
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
	
	unsigned flags;
	ICMCompressionSessionRef compressionSession;
	ICMCompressionFrameOptionsRef compressionFrameOptions;
	ComponentInstance compressor;
	RTPMediaPacketizer mediaPacketizer;
	RTPMPSampleDataParams sampleData;
}

+ (void)_getDeviceList;
+ (void)_setDevice:(NSString *)device;

+ (void)_setFrameGrabRate:(unsigned)frameGrabRate;

+ (void)_startGrabbing;
+ (void)_stopGrabbing;

+ (void)_startTransmittingForSession:(unsigned)sessionID
						   withCodec:(XMCodecIdentifier)codecIdentifier
						   videoSize:(XMVideoSize)videoSize 
				  maxFramesPerSecond:(unsigned)maxFramesPerSecond
						  maxBitrate:(unsigned)maxBitrate
							   flags:(unsigned)flags;
+ (void)_stopTransmittingForSession:(unsigned)sessionID;

+ (void)_updatePicture;

- (id)_init;
- (void)_close;

@end

#endif // __XM_MEDIA_TRANSMITTER_H__
