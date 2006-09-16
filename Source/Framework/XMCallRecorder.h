/*
 * $Id: XMCallRecorder.h,v 1.2 2006/09/16 16:54:47 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CALL_RECORDER_H__
#define __XM_CALL_RECORDER_H__

#import <Cocoa/Cocoa.h>
#import <QuickTime/QuickTime.h>

#import "XMTypes.h"

@interface XMCallRecorder : NSObject {

	BOOL isRecording;
	int recordingMode;
	
	Movie movie;
	short movieResRefNum;
	Track videoTrack;
	Media videoMedia;
	Track audioTrack;
	Media audioMedia;
	struct timeval startTime;
	
	NSLock *audioLock;
	BOOL isAudioRecording;
	XMCodecIdentifier audioCodecIdentifier;
	unsigned audioTrackOffset;
	unsigned audioMediaOffset;
	void *audioBuffer1;
	void *audioBuffer2;
	unsigned numLocalAudioFrames;
	unsigned numRemoteAudioFrames;
	SoundDescriptionHandle soundDesc;
	
	NSLock *videoLock;
	NSTimer *recordTimer;
	unsigned videoTrackOffset;
	TimeValue64 previousTimestamp;
	int lockingMode;
	BOOL quitRecording;
	BOOL frameOccupied;
	BOOL frameUpdated;
	
	CVPixelBufferRef recompressionBuffer;
	ICMCompressionSessionRef compressionSession;
	ComponentInstance compressor;
	
	OSStatus errorCode;
	unsigned locationCode;
}

+ (XMCallRecorder *)sharedInstance;

/**
 * Starts a recording session, recording to the specified file using the codecs specified.
 * Note that not all video codecs support active bandwidth control. Therefore, always
 * use the videoCodecQuality constant to express how good the quality of video will be.
 * If lowPriorityRecording is set, the transmit/receive frame pipelines are blocked for an as short time as possible,
 * resulting in a maximum throughput videoDevice->codec->packetizer->network and network->reassembler->codec->display
 * However, the framerate of the recorded video may be significantly lower than is the flag is not set.
 **/
- (BOOL)startRecordingInRecompressionModeToFile:(NSString *)file videoCodecIdentifier:(XMCodecIdentifier)videoCodecIdentifier 
							  videoCodecQuality:(XMCodecQuality)videoCodecQuality videoDataRate:(unsigned)videoDataRate
						   audioCodecIdentifier:(XMCodecIdentifier)audioCodecIdentifier
						   lowPriorityRecording:(BOOL)lowPriorityRecording;

/**
 * Starts an audio only recording session. Currently, only XMCodecIdentifier_LinearPCM is supported
 **/
- (BOOL)startRecordingInAudioOnlyModeToFile:(NSString *)file audioCodecIdentifier:(XMCodecIdentifier)audioCodecIdentifier;

- (void)stopRecording;

- (BOOL)isRecording;

/**
 * Returns which codecs can control the data rate to compress. the videoBandwidthLimit parameter
 * has only an effect if using these codecs
 **/
- (BOOL)videoCodecSupportsDataRateControl:(XMCodecIdentifier)codecIdentifier;

/**
 * Returns an error description if the recoring failed somehow
 **/
- (NSString *)getErrorDescription;

@end

#endif // __XM_CALL_RECORDER_H__
