/*
 * $Id: XMMediaTransmitter.h,v 1.11 2006/02/06 19:38:07 hfriederich Exp $
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
	id<XMVideoInputModule> activeModule;
	NSString *selectedDevice;
	
	NSTimer *frameGrabTimer;
	
	BOOL isGrabbing;
	unsigned frameGrabRate;
	TimeScale timeScale;
	TimeValue timeOffset;
	TimeValue lastTime;
	
	BOOL isTransmitting;
	unsigned transmitFrameGrabRate;
	XMVideoSize videoSize;
	CodecType codecType;
	OSType codecManufacturer;
	unsigned codecSpecificCallFlags;
	unsigned bitrateToUse;
	
	BOOL needsPictureUpdate;

	BOOL useCompressionSessionAPI;
	ComponentInstance compressor;
	
	ICMCompressionSessionRef compressionSession;
	ICMCompressionFrameOptionsRef compressionFrameOptions;
	
	BOOL compressSequenceIsActive;
	ImageSequence compressSequence;
	ImageDescriptionHandle compressSequenceImageDescription;
	Ptr compressSequenceCompressedFrame;
	TimeValue compressSequencePreviousTimeStamp;
	UInt32 compressSequenceFrameNumber;
	UInt32 compressSequenceFrameCounter;
	UInt32 compressSequenceLastVideoBytesSent;
	UInt32 compressSequenceNonKeyFrameCounter;
	
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

+ (void)_setVideoBytesSent:(unsigned)videoBytesSent;

- (id)_init;
- (void)_close;

@end

#endif // __XM_MEDIA_TRANSMITTER_H__
