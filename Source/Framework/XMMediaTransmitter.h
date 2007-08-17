/*
 * $Id: XMMediaTransmitter.h,v 1.25 2007/08/17 11:36:41 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_MEDIA_TRANSMITTER_H__
#define __XM_MEDIA_TRANSMITTER_H__

#import <Cocoa/Cocoa.h>
#import <QuickTime/QuickTime.h>

#import "XMVideoInputModule.h"
#import "XMVideoModule.h"
#import "XMTypes.h"

@interface XMMediaTransmitter : NSObject <XMVideoInputManager> {
  
@private
  NSPort *receivePort;
  
  NSArray *videoInputModules;
  id<XMVideoInputModule> activeModule;
  NSString *selectedDevice;
  
  BOOL isGrabbing;
  NSTimer *frameGrabTimer;
  unsigned previewFrameGrabRate;
  unsigned frameGrabRate;
  
  BOOL isDoingVideoDisplay;
  
  BOOL isTransmitting;
  unsigned transmitFrameCounter;
  unsigned transmitFrameGrabRate;
  XMVideoSize videoSize;
  CodecType codecType;
  OSType codecManufacturer;
  unsigned codecSpecificCallFlags;
  unsigned bitrateToUse;
  unsigned keyframeInterval;
  
  BOOL isRecording;
  CodecType recordingCodec;
  XMVideoSize recordingSize;
  XMCodecQuality recordingQuality;
  unsigned recordingBitrate;
  
  BOOL needsPictureUpdate;
  
  BOOL useCompressionSessionAPI;
  ComponentInstance compressor;
  
  TimeValue previousTimeStamp;
  struct timeval firstTime;
  
  ICMCompressionSessionRef compressionSession;
  ICMCompressionFrameOptionsRef compressionFrameOptions;
  TimeValue compressionSessionPreviousTimeStamp;
  
  BOOL compressSequenceIsActive;
  ImageSequence compressSequence;
  ImageDescriptionHandle compressSequenceImageDescription;
  Ptr compressSequenceCompressedFrame;
  TimeValue compressSequencePreviousTimeStamp;
  UInt32 compressSequenceFrameNumber;
  UInt32 compressSequenceFrameCounter;
  UInt32 compressSequenceLastVideoBytesSent;
  UInt32 compressSequenceNonKeyFrameCounter;
  struct timeval dataRateUpdateTime;
  
  RTPMediaPacketizer mediaPacketizer;
  RTPMPSampleDataParams sampleData;
}

+ (void)_getDeviceList;
+ (void)_selectModule:(unsigned)moduleIndex device:(NSString *)device;

+ (void)_setFrameGrabRate:(unsigned)frameGrabRate;

+ (void)_startVideoDisplay;
+ (void)_stopVideoDisplay;

+ (void)_startTransmittingForSession:(unsigned)sessionID
						   withCodec:(XMCodecIdentifier)codecIdentifier
						   videoSize:(XMVideoSize)videoSize 
				  maxFramesPerSecond:(unsigned)maxFramesPerSecond
						  maxBitrate:(unsigned)maxBitrate
					keyframeInterval:(unsigned)keyframeInterval
							   flags:(unsigned)flags;
+ (void)_stopTransmittingForSession:(unsigned)sessionID;

+ (void)_updatePicture;
+ (void)_setMaxBitrate:(unsigned)maxBitrate;

+ (void)_setVideoBytesSent:(unsigned)videoBytesSent;

+ (void)_startRecordingWithCodec:(XMCodecIdentifier)codecIdentifier
					   videoSize:(XMVideoSize)videoSize
					codecQuality:(XMCodecQuality)codecQuality
					  maxBitrate:(unsigned)maxBitrate;
+ (void)_stopRecording;

+ (void)_sendSettings:(NSData *)settings toModule:(id<XMVideoInputModule>)module;

- (id)_init;
- (void)_close;

- (void)_setDevice:(NSString *)device;
- (BOOL)_deviceHasSettings:(NSString *)device;
- (BOOL)_requiresSettingsDialogWhenDeviceIsSelected:(NSString *)device;
- (NSView *)_settingsViewForDevice:(NSString *)device;
- (void)_setDefaultSettingsForDevice:(NSString *)device;

- (unsigned)_videoModuleCount;
- (id<XMVideoModule>)_videoModuleAtIndex:(unsigned)index;

@end

#endif // __XM_MEDIA_TRANSMITTER_H__
