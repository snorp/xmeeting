/*
 * $Id: XMCallRecorder.m,v 1.2 2006/09/16 16:54:47 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#import <CoreAudio/CoreAudio.h>

#import "XMCallRecorder.h"
#import "XMPrivate.h"
#import "XMStringConstants.h"

// Defining the QuickTime Movie Player's application type
#define XM_SIG_MOVIE_PLAYER 'TVOD'

// Default QT video time scale
#define XM_VIDEO_TIME_SCALE 600

// Time scale for 8kHz audio
#define XM_AUDIO_TIME_SCALE 8000

#define XM_UNKNOWN_LOCKING 0
#define XM_BLOCKING_COMPRESSION 1
#define XM_NONBLOCKING_COMPRESSION 2

#define XM_UNKNOWN_RECORDING_MODE 0
#define XM_AUDIO_ONLY_RECORDING_MODE 1
#define XM_RECOMPRESSION_RECORDING_MODE 2
#define XM_CLOSING_MODE 0xff

@interface XMCallRecorder (PrivateMethods)

- (void)_resetErrorCodes;
- (BOOL)_createMovie:(NSString *)filePath;
- (BOOL)_prepareAudioRecording:(XMCodecIdentifier)codec;
- (BOOL)_prepareVideoRecordingInRecompressionMode:(XMCodecIdentifier)codec quality:(XMCodecQuality)quality bandwidthLimit:(unsigned)bandwidthLimit;
- (void)_finishAudioRecording;
- (void)_finishVideoRecording;
- (void)_finishMovie;
- (void)_cleanupMovie;
- (void)_reportError;
- (void)_handleErrorReport;
- (void)_recompressionThreadDidEnd;
- (void)_handleLocalAudioFrames:(void *)localAudioFrames count:(unsigned)numLocalAudioFrames;
- (void)_handleRemoteAudioFrames:(void *)remoteAudioFrames count:(unsigned)numRemoteAudioFrames;
- (void)_runRecompressionThread:(NSArray *)parameters;
- (void)_recordFrames:(NSTimer *)timer;
- (OSStatus)_saveCompressedFrame:(ICMEncodedFrameRef)encodedFrame;

@end

extern unsigned char linear2ulaw(int pcm_val);
extern unsigned char linear2alaw(int pcm_val);

void _XMHandleLocalAudioFrames(void *localAudioFrames, unsigned numberOfFrames);
void _XMHandleRemoteAudioFrames(void *remoteAudioFrames, unsigned numberOfFrames);

OSStatus _XMSaveCompressedFrameProc(void* encodedFrameOutputRefCon, 
								    ICMCompressionSessionRef session, 
								    OSStatus err,
								    ICMEncodedFrameRef encodedFrame,
								    void* reserved);

void _XMCallRecorderPixelBufferReleaseCallback(void *releaseRefCon, 
											   const void *baseAddress);

inline void _XMZeroFillLocalAudio(void *buffer, unsigned frameOffset, unsigned bytesPerFrame);
inline void _XMZeroFillLocalAudio16Bit(void *buffer, unsigned frameOffset);
inline void _XMZeroFillLocalAudio8Bit(void *buffer, unsigned frameOffset);
inline void _XMZeroFillRemoteAudio(void *buffer, unsigned frameOffset, unsigned bytesPerFrame);
inline void _XMZeroFillRemoteAudio16Bit(void *buffer, unsigned frameOffset);
inline void _XMZeroFillRemoteAudio8Bit(void *buffer, unsigned frameOffset);
inline void _XMZeroAddLocalAudio(void *buffer, unsigned offset, unsigned numberOfZeros, unsigned bytesPerFrame);
inline void _XMZeroAddLocalAudio16Bit(void *buffer, unsigned offset, unsigned numberOfZeros);
inline void _XMZeroAddLocalAudio8Bit(void *buffer, unsigned offset, unsigned numberOfZeros);
inline void _XMZeroAddRemoteAudio(void *buffer, unsigned offset, unsigned numberOfZeros, unsigned bytesPerFrame);
inline void _XMZeroAddRemoteAudio16Bit(void *buffer, unsigned offset, unsigned numberOfZeros);
inline void _XMZeroAddRemoteAudio8Bit(void *buffer, unsigned offset, unsigned numberOfZeros);
inline void _XMDataAddLocalAudio(void *dstBuffer, unsigned offset, void *srcBuffer, unsigned numberOfFrames, XMCodecIdentifier codecIdentifier);
inline void _XMDataAddLocalAudioLPCM(void *dstBuffer, unsigned offset, void *srcBuffer, unsigned numberOfFrames);
inline void _XMDataAddLocalAudioULAW(void *dstBuffer, unsigned offset, void *srcBuffer, unsigned numberOfFrames);
inline void _XMDataAddLocalAudioALAW(void *dstBuffer, unsigned offset, void *srcBuffer, unsigned numberOfFrames);
inline void _XMDataAddRemoteAudio(void *dstBuffer, unsigned offset, void *srcBuffer, unsigned numberOfFrames, XMCodecIdentifier codecIdentifier);
inline void _XMDataAddRemoteAudioLPCM(void *dstBuffer, unsigned offset, void *srcBuffer, unsigned numberOfFrames);
inline void _XMDataAddRemoteAudioULAW(void *dstBuffer, unsigned offset, void *srcBuffer, unsigned numberOfFrames);
inline void _XMDataAddRemoteAudioALAW(void *dstBuffer, unsigned offset, void *srcBuffer, unsigned numberOfFrames);

@implementation XMCallRecorder

#pragma mark Class Methods

+ (XMCallRecorder *)sharedInstance
{
	if(_XMCallRecorderSharedInstance == nil)
	{
		NSLog(@"Attempt to access XMCallRecorder prior to initialization");
	}
	
	return _XMCallRecorderSharedInstance;
}

#pragma mark -
#pragma mark Init & Deallocation Methods

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	return nil;
}

- (id)_init
{	
	isRecording = NO;
	recordingMode = XM_UNKNOWN_RECORDING_MODE;
	
	movie = NULL;
	movieResRefNum = 0;
	videoTrack = NULL;
	videoMedia = NULL;
	audioTrack = NULL;
	audioMedia = NULL;
	startTime.tv_sec = 0;
	startTime.tv_usec = 0;
	
	audioLock = [[NSLock alloc] init];
	isAudioRecording = NO;
	audioCodecIdentifier = XMCodecIdentifier_UnknownCodec;
	audioTrackOffset = 0;
	audioMediaOffset = 0;
	audioBuffer1 = NULL;
	audioBuffer2 = NULL;
	numLocalAudioFrames = 0;
	numRemoteAudioFrames = 0;
	soundDesc = NULL;
	
	videoLock = [[NSLock alloc] init];
	recordTimer = nil;
	videoTrackOffset = 0;
	previousTimestamp = 0;
	lockingMode = XM_UNKNOWN_LOCKING;
	quitRecording = NO;
	frameOccupied = NO;
	frameUpdated = YES;
	
	recompressionBuffer = NULL;
	compressionSession = NULL;
	compressor = NULL;
	
	errorCode = noErr;
	locationCode = 0;
	
	return self;
}

- (void)dealloc
{
	[self _close];
	
	[audioLock release];
	[videoLock release];
	
	[super dealloc];
}

- (void)_close
{
	BOOL hasSeparateThreadRunning = NO;
	if(isRecording == YES && recordingMode == XM_RECOMPRESSION_RECORDING_MODE)
	{
		hasSeparateThreadRunning = YES;
	}
	
	[self stopRecording];
	
	if(hasSeparateThreadRunning == NO)
	{
		_XMThreadExit();
	}
	
	recordingMode = XM_CLOSING_MODE; // flag to indiate that _XMTreadExit() has to be called
}

#pragma mark -
#pragma mark Public Methods

- (BOOL)startRecordingInRecompressionModeToFile:(NSString *)filePath
						   videoCodecIdentifier:(XMCodecIdentifier)videoCodecIdentifier 
							  videoCodecQuality:(XMCodecQuality)videoCodecQuality
								  videoDataRate:(unsigned)videoDataRate
						   audioCodecIdentifier:(XMCodecIdentifier)theAudioCodecIdentifier
						   lowPriorityRecording:(BOOL)lowPriorityRecording;
{
	// some validity checks first
	if(isRecording == YES)
	{
		return NO;
	}
	
	[self _resetErrorCodes];
	
	if(videoCodecIdentifier < XMCodecIdentifier_H261)
	{
		errorCode = 1;
		locationCode = 0x0001;
		[self _handleErrorReport];
		return NO;
	}
	// at the moment, only Linear PCM is supported
	if(theAudioCodecIdentifier != XMCodecIdentifier_UnknownCodec &&
	   theAudioCodecIdentifier != XMCodecIdentifier_LinearPCM)
	{
		errorCode = 1;
		locationCode = 0x0002;
		[self _handleErrorReport];
		return NO;
	}
	
	// prepare the needed resources
	BOOL result = [self _createMovie:filePath];
	if(result == NO)
	{
		[self _cleanupMovie];
		[self _handleErrorReport];
		return NO;
	}
	
	result = [self _prepareAudioRecording:theAudioCodecIdentifier];
	if(result == NO)
	{
		[self _cleanupMovie];
		[self _handleErrorReport];
		return NO;
	}
	result = [self _prepareVideoRecordingInRecompressionMode:videoCodecIdentifier
													 quality:videoCodecQuality
											  bandwidthLimit:videoDataRate];
	if(result == NO)
	{
		[self _cleanupMovie];
		[self _handleErrorReport];
		return NO;
	}
	
	lockingMode = XM_BLOCKING_COMPRESSION;
	if(lowPriorityRecording == YES)
	{
		lockingMode = XM_NONBLOCKING_COMPRESSION;
	}
	
	videoTrackOffset = 0;
	previousTimestamp = 0;
	
	// validity checks succeded.
	isRecording = YES;
	quitRecording = NO;
	recordingMode = XM_RECOMPRESSION_RECORDING_MODE;
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallRecorderDidStartRecording object:self];
	
	// get start time
	gettimeofday(&startTime, NULL);
	
	// switch to green for audio recording
	if(theAudioCodecIdentifier != XMCodecIdentifier_UnknownCodec)
	{
		isAudioRecording = YES;
	}
	
	// Start the video thread
	[NSThread detachNewThreadSelector:@selector(_runRecompressionThread) toTarget:self withObject:nil];
	
	return TRUE;
}

- (BOOL)startRecordingInAudioOnlyModeToFile:(NSString *)file
					   audioCodecIdentifier:(XMCodecIdentifier)theAudioCodecIdentifier
{
	if(isRecording == YES)
	{
		return NO;
	}
	
	[self _resetErrorCodes];
	
	// At the moment, only Linear PCM is supported
	if(theAudioCodecIdentifier != XMCodecIdentifier_LinearPCM)
	{
		errorCode = 2;
		locationCode = 0x0001;
		[self _handleErrorReport];
		return NO;
	}
	
	// build up the needed resources
	BOOL result = [self _createMovie:file];
	if(result == NO)
	{
		[self _cleanupMovie];
		[self _handleErrorReport];
		return NO;
	}
	
	result = [self _prepareAudioRecording:theAudioCodecIdentifier];
	if(result == NO)
	{
		[self _cleanupMovie];
		[self _handleErrorReport];
		return NO;
	}
	
	// preparations complete. Post the notification
	isRecording = YES;
	recordingMode = XM_AUDIO_ONLY_RECORDING_MODE;
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallRecorderDidStartRecording object:self];
	
	// get start time
	gettimeofday(&startTime, NULL);
	
	// switch to green for audio recording
	isAudioRecording = YES;
	
	return YES;
}

- (void)stopRecording
{	
	if(isRecording == NO)
	{
		return;
	}
	
	if(recordingMode == XM_AUDIO_ONLY_RECORDING_MODE)
	{
		// aquire lock to switch back to avoid race conditions
		[audioLock lock];
		isAudioRecording = NO;
		[audioLock unlock];
		
		[self _finishAudioRecording];
		[self _finishMovie];
		[self _cleanupMovie];
	
		isRecording = NO;
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallRecorderDidEndRecording object:self];
	}
	else if(recordingMode == XM_RECOMPRESSION_RECORDING_MODE)
	{
		// the recompression thread has to finish.
		quitRecording = YES;
		
		// aquire lock to switch back to avoid race conditions
		[audioLock lock];
		isAudioRecording = NO;
		[audioLock unlock];
		
		[self _finishAudioRecording];
		
		// handling the rest once the recompression thread did finish
	}
}

- (BOOL)isRecording
{
	return isRecording;
}

- (BOOL)videoCodecSupportsDataRateControl:(XMCodecIdentifier)codecIdentifier
{
	switch(codecIdentifier)
	{
		case XMCodecIdentifier_H261:
		case XMCodecIdentifier_H263:
		case XMCodecIdentifier_H264:
		case XMCodecIdentifier_MPEG4:
			return YES;
		default:
			return NO;
	}
}

- (NSString *)getErrorDescription
{
	if(errorCode == noErr)
	{
		return @"";
	}
	
	return [NSString stringWithFormat:@"%d (%x)", errorCode, locationCode];
}

#pragma mark -
#pragma mark Private Methods

- (void)_resetErrorCodes
{
	errorCode = noErr;
	locationCode = 0x0000;
}

#define checkErr(code) \
{ \
	if(err != noErr) { \
		errorCode = err; \
		locationCode = code; \
		return NO; \
	} \
} \

- (BOOL)_createMovie:(NSString *)filePath
{
	ComponentResult err = noErr;
	const char *path = [filePath cStringUsingEncoding:NSUTF8StringEncoding];
	
	FSSpec file;
	err = NativePathNameToFSSpec(path, &file, 0); // returns fnfErr if file does not exist, but FSSpec is valid anyway
	if(err != noErr && err != fnfErr)
	{
		errorCode = err;
		locationCode = 0x0100;
		return NO;
	}
	
	long movieFileFlags = createMovieFileDeleteCurFile | createMovieFileDontCreateResFile;
	err = CreateMovieFile(&file, XM_SIG_MOVIE_PLAYER, smCurrentScript, movieFileFlags, &movieResRefNum, &movie);
	checkErr(0x0101);
	
	return YES;
}

- (BOOL)_prepareAudioRecording:(XMCodecIdentifier)theAudioCodecIdentifier
{
	ComponentResult err = noErr;
	audioCodecIdentifier = theAudioCodecIdentifier;
	
	if(audioCodecIdentifier != XMCodecIdentifier_UnknownCodec)
	{
		// The audio system uses two simple buffers, each constituting an 8KB sample to be added to the
		// movie. Once a sample is filled, it is written to the media and the two buffers are simply
		// interchanged. The most elegant solution would be to remap the VM pages to other physical
		// pages, removing the need to check for boundaries between the two buffers. But I don't know
		// whether this is feasible on the OS at all.
		// The audio system uses two simple buffers, each constituting an 8KB sample to be added to the
		// movie. Once a sample is filled, it is written to the media and the two buffers are simply
		// interchanged. The most elegant solution would be to remap the VM pages to other physical
		// pages, removing the need to check for boundaries between the two buffers. But I don't know
		// whether this is feasible on the OS at all.
		audioBuffer1 = malloc(8192);
		audioBuffer2 = malloc(8192);
		bzero(audioBuffer1, 8192);
		bzero(audioBuffer2, 8192);
		
		audioTrackOffset = 0;
		audioMediaOffset = 0;
		numLocalAudioFrames = 0;
		numRemoteAudioFrames = 0;
		
		AudioStreamBasicDescription asbd;
		asbd.mSampleRate = 8000;
		asbd.mChannelsPerFrame = 2;
		asbd.mFramesPerPacket = 1;
		
		// set correct format ID along with format flags, mBitsPerChannel
		// and mBytesPerPacket
		if(audioCodecIdentifier == XMCodecIdentifier_LinearPCM)
		{
			asbd.mFormatID = kAudioFormatLinearPCM;
			asbd.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger;
#if defined __BIG_ENDIAN__
			asbd.mFormatFlags |= kLinearPCMFormatFlagIsBigEndian;
#endif
			asbd.mBitsPerChannel = 16;
			asbd.mBytesPerFrame = 4;
			asbd.mBytesPerPacket = 4;
		}
		else if(audioCodecIdentifier == XMCodecIdentifier_G711_uLaw)
		{
			asbd.mFormatID = kAudioFormatULaw;
			asbd.mFormatFlags = 0;
			asbd.mBitsPerChannel = 8;
			asbd.mBytesPerFrame = 2;
			asbd.mBytesPerPacket = 2;
		}
		else
		{
			asbd.mFormatID = kAudioFormatALaw;
			asbd.mFormatFlags = 0;
			asbd.mBitsPerChannel = 8;
			asbd.mBytesPerFrame = 2;
			asbd.mBytesPerPacket = 2;
		}
		
		err = QTSoundDescriptionCreate(&asbd,
									   NULL, 0,
									   NULL, 0,
									   kQTSoundDescriptionKind_Movie_Version2,
									   &soundDesc);
		checkErr(0x0200);
		
		audioTrack = NewMovieTrack(movie, Long2Fix(0), Long2Fix(0), kFullVolume);
		err = GetMoviesError();
		checkErr(0x0201);
		
		audioMedia = NewTrackMedia(audioTrack, SoundMediaType, XM_AUDIO_TIME_SCALE, NULL, 0);
		err = GetMoviesError();
		checkErr(0x0202);
		
		err = BeginMediaEdits(audioMedia);
		checkErr(0x0203);
	}
	
	return YES;
}

- (BOOL)_prepareVideoRecordingInRecompressionMode:(XMCodecIdentifier)codec quality:(XMCodecQuality)quality bandwidthLimit:(unsigned)bandwidthLimit
{
	ComponentResult err = noErr;
	
	if(codec != XMCodecIdentifier_UnknownCodec)
	{
		videoTrack = NewMovieTrack(movie, Long2Fix(2*352+8), Long2Fix(288+4), 0);
		err = GetMoviesError();
		checkErr(0x0300);
	
		videoMedia = NewTrackMedia(videoTrack, VideoMediaType, XM_VIDEO_TIME_SCALE, NULL, 0);
		err = GetMoviesError();
		checkErr(0x0301);
		
		err = BeginMediaEdits(videoMedia);
		checkErr(0x0302);
			
		CodecType codecType;
		switch(codec)
		{
			case XMCodecIdentifier_H261:
				codecType = kH261CodecType;
				if(bandwidthLimit != 0 && bandwidthLimit < 80000) {
					bandwidthLimit = 80000;
				}
				break;
			case XMCodecIdentifier_H263:
				codecType = kH263CodecType;
				if(bandwidthLimit != 0 && bandwidthLimit < 64000) {
					bandwidthLimit = 64000;
				}
				break;
			case XMCodecIdentifier_H264:
				codecType = kH264CodecType;
				break;
			case XMCodecIdentifier_MPEG4:
				codecType = kMPEG4VisualCodecType;
				break;
			case XMCodecIdentifier_Motion_JPEG_A:
				codecType = kMotionJPEGACodecType;
				break;
			case XMCodecIdentifier_Motion_JPEG_B:
				codecType = kMotionJPEGBCodecType;
				break;
			default:
				// should not happen
				codecType = kMPEG4VisualCodecType;
				break;
		}
		
		ICMEncodedFrameOutputRecord encodedFrameOutputRecord = {0};
		ICMCompressionSessionOptionsRef sessionOptions = NULL;
		
		err = ICMCompressionSessionOptionsCreate(NULL, &sessionOptions);
		checkErr(0x0303);
		
		err = ICMCompressionSessionOptionsSetAllowTemporalCompression(sessionOptions, true);
		checkErr(0x0304);
		
		err = ICMCompressionSessionOptionsSetAllowFrameReordering(sessionOptions, true);
		checkErr(0x0305);
		
		err = ICMCompressionSessionOptionsSetMaxKeyFrameInterval(sessionOptions, 120);
		checkErr(0x0306);
		
		err = ICMCompressionSessionOptionsSetAllowFrameTimeChanges(sessionOptions, true);
		checkErr(0x0307);
		
		err = ICMCompressionSessionOptionsSetDurationsNeeded(sessionOptions, false);
		checkErr(0x0308);
		
		// averageDataRate is in bytes/s
		if(bandwidthLimit != 0)
		{
			SInt32 averageDataRate = bandwidthLimit/8;
			err = ICMCompressionSessionOptionsSetProperty(sessionOptions,
														  kQTPropertyClass_ICMCompressionSessionOptions,
														  kICMCompressionSessionOptionsPropertyID_AverageDataRate,
														  sizeof(averageDataRate),
														  &averageDataRate);
			checkErr(0x0309);
		}
		
		CodecQ codecQuality = (CodecQ)quality;
		err = ICMCompressionSessionOptionsSetProperty(sessionOptions,
													  kQTPropertyClass_ICMCompressionSessionOptions,
													  kICMCompressionSessionOptionsPropertyID_Quality,
													  sizeof(codecQuality),
													  &codecQuality);
		checkErr(0x030a);
		
		ComponentDescription componentDescription;
		componentDescription.componentType = FOUR_CHAR_CODE('imco');
		componentDescription.componentSubType = codecType;
		componentDescription.componentManufacturer = 0;
		componentDescription.componentFlags = 0;
		componentDescription.componentFlagsMask = 0;
		
		Component compressorComponent = FindNextComponent(0, &componentDescription);
		err = (compressorComponent == NULL);
		checkErr(0x030b);
		
		err = OpenAComponent(compressorComponent, &compressor);
		checkErr(0x030c);
		
		err = ICMCompressionSessionOptionsSetProperty(sessionOptions,
													  kQTPropertyClass_ICMCompressionSessionOptions,
													  kICMCompressionSessionOptionsPropertyID_CompressorComponent,
													  sizeof(compressor),
													  &compressor);
		checkErr(0x030d);
		
		encodedFrameOutputRecord.encodedFrameOutputCallback = _XMSaveCompressedFrameProc;
		encodedFrameOutputRecord.encodedFrameOutputRefCon = (void *)self;
		encodedFrameOutputRecord.frameDataAllocator = NULL;
		
		NSSize frameDimensions = NSMakeSize(2*352+8, 288+4);
		err = ICMCompressionSessionCreate(NULL, frameDimensions.width, frameDimensions.height,
										  codecType, (TimeScale)XM_VIDEO_TIME_SCALE, sessionOptions, NULL,
										  &encodedFrameOutputRecord, &compressionSession);
		checkErr(0x030e);
		
		ICMCompressionSessionOptionsRelease(sessionOptions);
		
		// create the recompression buffer
		// The idea is the following:
		// The two video streams get CIF size each.
		// If the remote frame is larger than CIF, the image is clipped to the CIF region
		// (not nice but efficient, should not happen at the moment, even if using H.264)
		// Smaller frames are centered within their CIF spot.
		// The frame used for compression uses a 2px border around the images.
		// Thus, the complete dimensions are 
	    //
		// width: 2px + 352px + 2px + 352px + 2px
		// height: 2px + 288px + 2px
		
		unsigned width = 2*352 + 6;
		unsigned height = 288 + 4;
		void *buffer = malloc(4*width*height);
		bzero(buffer, 4*width*height);
		
		CVReturn result = CVPixelBufferCreateWithBytes(NULL, (size_t)width, (size_t)height,
													   k32ARGBPixelFormat, buffer, 4*width,
													   _XMCallRecorderPixelBufferReleaseCallback,
													   NULL, NULL, &recompressionBuffer);
		if(result != kCVReturnSuccess)
		{
			errorCode = result;
			locationCode = 0x030f;
			return NO;
		}
	}
	
	return YES;
}

- (void)_finishAudioRecording
{
	if(audioMedia != NULL)
	{
		// complete the last sample if needed
		unsigned numberOfFramesPerBuffer = 4096;
		if(audioCodecIdentifier == XMCodecIdentifier_LinearPCM)
		{
			numberOfFramesPerBuffer = 2048;
		}
		if(numLocalAudioFrames < numberOfFramesPerBuffer)
		{
			_XMZeroFillLocalAudio(audioBuffer1, numLocalAudioFrames, numberOfFramesPerBuffer);
		}
		if(numRemoteAudioFrames < numberOfFramesPerBuffer)
		{
			_XMZeroFillRemoteAudio(audioBuffer1, numRemoteAudioFrames, numberOfFramesPerBuffer);
		}
		AddMediaSample2(audioMedia,   // insert into audio media
						audioBuffer1, // insert first buffer
						8192,	        // length of audio buffer
						1,            // normal decode duration
						0,            // no display offset (won't work anyway)
						(SampleDescriptionHandle)soundDesc,
						numberOfFramesPerBuffer, // precalculated, number of frames per sample 
						0,            // no flags
						NULL);        // not interested in decode time
		
		// end media editing and add media to the track
		EndMediaEdits(audioMedia);
		TimeValue trackStart = (TimeValue)(audioTrackOffset / 13.333333); // conversion from timebase 8000 to timebase 600
		InsertMediaIntoTrack(audioTrack, trackStart, 0, GetMediaDuration(audioMedia), fixed1);
	}
}

- (void)_finishVideoRecording
{
	if(videoMedia != NULL)
	{
		EndMediaEdits(videoMedia);
		InsertMediaIntoTrack(videoTrack, videoTrackOffset, 0, GetMediaDuration(videoMedia), fixed1);
	}
}

- (void)_finishMovie
{
	short movieResId = movieInDataForkResID;
	AddMovieResource(movie, movieResRefNum, &movieResId, NULL);
}

- (void)_cleanupMovie
{
	if(movieResRefNum != 0)
	{
		CloseMovieFile(movieResRefNum);
	}
	
	if(movie != NULL)
	{
		DisposeMovie(movie);
	}
	
	movie = NULL;
	movieResRefNum = 0;
	audioMedia = NULL;
	audioTrack = NULL;
	videoMedia = NULL;
	videoTrack = NULL;
	
	if(audioBuffer1 != NULL)
	{
		free(audioBuffer1);
		audioBuffer1 = NULL;
	}
	if(audioBuffer2 != NULL)
	{
		free(audioBuffer2);
		audioBuffer2 = NULL;
	}
	if(soundDesc != NULL)
	{
		DisposeHandle((Handle)soundDesc);
		soundDesc = NULL;
	}
	
	if(compressionSession != NULL)
	{
		ICMCompressionSessionRelease(compressionSession);
		compressionSession = NULL;
	}
	if(compressor != NULL)
	{
		CloseComponent(compressor);
		compressor = NULL;
	}
	if(recompressionBuffer != NULL)
	{
		CVPixelBufferRelease(recompressionBuffer);
		recompressionBuffer = NULL;
	}
}

- (void)_reportError
{
	// The error code handling is implemented somewhat imprecise since there
	// are potential race conditions in case multiple threads report errors
	// at the same time. However, as this case is unlikey, it is not considered
	// a real problem.
	[self performSelectorOnMainThread:@selector(_handleErrorReport) withObject:nil waitUntilDone:NO];
}

- (void)_handleErrorReport
{
	NSLog(@"Got ErrorReport: %d, %x", errorCode, locationCode);
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallRecorderDidGetError object:self];
}

- (void)_recompressionThreadDidEnd
{
	[self _finishVideoRecording];
	
	[self _finishMovie];
	[self _cleanupMovie];
	
	isRecording = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallRecorderDidEndRecording object:self];
	
	if(recordingMode == XM_CLOSING_MODE)
	{
		_XMThreadExit();
	}
}

#pragma mark -
#pragma mark Framework Methods

- (void)_handleUncompressedLocalVideoFrame:(CVPixelBufferRef)pixelBuffer
{
	if(recompressionBuffer == NULL)
	{
		return;
	}
	
	[videoLock lock];
	
	if(recompressionBuffer != NULL)
	{
		if(frameOccupied == NO)
		{
			CVPixelBufferLockBaseAddress(recompressionBuffer, 0);
		
			size_t srcBytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
			size_t srcWidth = CVPixelBufferGetWidth(pixelBuffer);
			size_t srcHeight = CVPixelBufferGetHeight(pixelBuffer);
			void *srcPtr = CVPixelBufferGetBaseAddress(pixelBuffer);
		
			size_t dstBytesPerRow = CVPixelBufferGetBytesPerRow(recompressionBuffer);
			void *dstPtr = CVPixelBufferGetBaseAddress(recompressionBuffer);
		
			// local video is displayed on the left side
			// xOffset is 2px + amount necessary to center local video
			// yOffset is 2px + amount necessary to center local video
			size_t xOffset = 2 + ((352-srcWidth)/2);
			size_t yOffset = 2 + ((288-srcHeight)/2);
			dstPtr += yOffset*dstBytesPerRow + 4*xOffset; // 32-bit samples (xOffset)!
		
			unsigned i;
			for(i = 0; i < srcHeight; i++)
			{
				memcpy(dstPtr, srcPtr, 4*srcWidth);
				srcPtr += srcBytesPerRow;
				dstPtr += dstBytesPerRow;
			}
		
			frameUpdated = YES;
		
			CVPixelBufferUnlockBaseAddress(recompressionBuffer, 0);
		}
	}
	
	[videoLock unlock];
}

- (void)_handleUncompressedRemoteVideoFrame:(CVPixelBufferRef)pixelBuffer
{
	if(recompressionBuffer == NULL)
	{
		return;
	}
	
	[videoLock lock];
	
	if(recompressionBuffer != NULL)
	{
		if(frameOccupied == NO)
		{
			CVPixelBufferLockBaseAddress(recompressionBuffer, 0);
		
			size_t srcBytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
			size_t srcWidth = CVPixelBufferGetWidth(pixelBuffer);
			size_t srcHeight = CVPixelBufferGetHeight(pixelBuffer);
			void *srcPtr = CVPixelBufferGetBaseAddress(pixelBuffer);
		
			// adjust width / height in case necessary
			if(srcWidth > 352)
			{
				srcWidth = 352;
			}
			if(srcHeight > 288)
			{
				srcHeight = 288;
			}
		
			size_t dstBytesPerRow = CVPixelBufferGetBytesPerRow(recompressionBuffer);
			void *dstPtr = CVPixelBufferGetBaseAddress(recompressionBuffer);
			
			// remote video is displayed on the right side
			// xOffset is 2px + 352px + 2px + amount necessary to center remote video
			// yOffset is 2px + amount necessary to center remote video
			size_t xOffset = 2 + 352 + 2 + ((352-srcWidth)/2);
			size_t yOffset = 2 + ((288-srcHeight)/2);
			dstPtr += yOffset*dstBytesPerRow + 4*xOffset; // 32-bit samples (xOffset)!
		
			unsigned i;
			for(i = 0; i < srcHeight; i++)
			{
				memcpy(dstPtr, srcPtr, 4*srcWidth);
				srcPtr += srcBytesPerRow;
				dstPtr += dstBytesPerRow;
			}
		
			frameUpdated = YES;
		
			CVPixelBufferUnlockBaseAddress(recompressionBuffer, 0);
		}
	}
	
	[videoLock unlock];
}

#pragma mark -
#pragma mark Audio handling Methods

#undef checkErr
#define checkErr(theCode) \
{ \
	if(err != noErr) { \
		errorCode = err; \
		locationCode = theCode; \
		[self _reportError]; \
	} \
}

/**
 * The challenge here is to implement a synchronization scheme that works in various
 * cases. Eventually, there is not remote audio stream. Eventually, the incoming audio
 * stream is muted or the *null* device is used. In these cases, this callback will not
 * be called. In contrast to video, the audio streams are assumed to be continuous and
 * one cannot adjust the timing by calculating timestamps & frame duration.
 * The solution used here is to have a large audio "jitter" buffer where the audio frames
 * are stored in the right spot. The goal is to implement this buffer without using a
 * separate reader thread
 **/
- (void)_handleLocalAudioFrames:(void *)localAudioFrames count:(unsigned)numFramesToStore
{
	OSStatus err = noErr;
	
	// don't lock if not needed
	if(isAudioRecording == NO)
	{
		return;
	}
	
	[audioLock lock];
	
	if(isAudioRecording)
	{
		// obtain the current time
		struct timeval currentTime;
		gettimeofday(&currentTime, NULL);
		
		// calculate the timestamp based on time
		int timestamp;
		timestamp = (currentTime.tv_sec - startTime.tv_sec)*8000;
		timestamp += (currentTime.tv_usec - startTime.tv_usec)/125;
		
		// adjust the track offset index for the first frames
		// to get the timstamp in sync
		if(audioTrackOffset == 0 && audioMediaOffset == 0 && numLocalAudioFrames == 0)
		{
			audioTrackOffset = timestamp;
		}
		
		// calculate the expected timestamp based on how many samples are already
		// recorded
		int expectedTimestamp = audioTrackOffset + audioMediaOffset + numLocalAudioFrames;
		
		// Depending on the chosen encoding algorithm, a frame will consist of either 8- or 16 bit.
		// Thus, the number of frames to be stored in the audio buffer may vary
		// Assuming the default to be A-Law / uLaw, 8bit.
		int numberOfFramesPerBuffer = 4096; // 8192 byte buffer size, 2 audio channels and 1 byte per frame
		int bytesPerFrame = 1;
		if(audioCodecIdentifier == XMCodecIdentifier_LinearPCM)
		{
			numberOfFramesPerBuffer = 2048;
			bytesPerFrame = 2;
		}
		
		// calculate the difference between the two timestamps. If the time based
		// timestamp is less than or not greater than 160 frames 
		// (corresponding to 20ms), accept it and put the frames into the buffer, starting at expected index.
		// Else, fill the gap with zeros. If there were multiple *empty* samples resulting, it is more efficient
		// to finish the old Media and start a new Media which will be inserted into the Track at the correct
		// offset. After this section, the buffer should be in sync again
		int tsDifference = timestamp - expectedTimestamp;
		if(tsDifference > 160)
		{
			// calculate how many frames are available in the two buffers allocated
			int availableFrames = 2*numberOfFramesPerBuffer - numLocalAudioFrames;
			
			// Check which *recovery* action to do
			if(tsDifference > availableFrames)
			{
				// There are probably multiple empty samples, since the chance is very high
				// that the user muted the recording process or chose the dummy device
				// Instead of filling x samples containing just zeros, stop the current
				// Media, insert it into the Track and start a new Track/Media.
				// The second buffer will be discarded anyway, even if there already were
				// some frames in it. No more than 160 frames (20ms) are lost in this case,
				// this goes unnoticed.
				if(numLocalAudioFrames < numberOfFramesPerBuffer)
				{
					_XMZeroFillLocalAudio(audioBuffer1, numLocalAudioFrames, bytesPerFrame);
				}
				if(numRemoteAudioFrames < numberOfFramesPerBuffer)
				{
					_XMZeroFillRemoteAudio(audioBuffer1, numRemoteAudioFrames, bytesPerFrame);
				}
				
				// add the audio buffer
				err = AddMediaSample2(audioMedia,   // insert into audio media
									  audioBuffer1, // insert first buffer
									  8192,	        // length of audio buffer
									  1,            // normal decode duration
									  0,            // no display offset (won't work anyway)
									  (SampleDescriptionHandle)soundDesc,
									  numberOfFramesPerBuffer, // precalculated, number of frames per sample 
									  0,            // no flags
									  NULL);        // not interested in decode time
				checkErr(0x0400);
				
				// end the current audio media and insert it into the track
				err = EndMediaEdits(audioMedia);
				checkErr(0x0401);
				TimeValue trackStart = (TimeValue)(audioTrackOffset / 13.33333); // conversion from timebase 8000 to timebase 600
				err = InsertMediaIntoTrack(audioTrack, trackStart, 0, GetMediaDuration(audioMedia), fixed1);
				checkErr(0x0402);
				
				// Create a new audio track & media
				audioTrack = NewMovieTrack(movie, Long2Fix(0), Long2Fix(0), kFullVolume);
				err = GetMoviesError();
				checkErr(0x0403);
				
				audioMedia = NewTrackMedia(audioTrack, SoundMediaType, XM_AUDIO_TIME_SCALE, NULL, 0);
				err = GetMoviesError();
				checkErr(0x0404);
				
				err = BeginMediaEdits(audioMedia);
				checkErr(0x0405);
				
				// move the track offset to the current timestamp
				// reset media offset and the local buffer to the empty
				audioTrackOffset = timestamp;
				audioMediaOffset = 0;
				numLocalAudioFrames = 0;
				numRemoteAudioFrames = 0;
			}
			else 
			{
				// check whether the actual sample buffer is already full. If so, write out the
				// sample and swap buffers
				if(numLocalAudioFrames >= numberOfFramesPerBuffer)
				{
					// the first sample is already completed.
					// Time to add this sample into the Media
					
					// first, check whether it's necessary to fill the remote channel
					// with zeros
					if(numRemoteAudioFrames < numberOfFramesPerBuffer)
					{
						_XMZeroFillRemoteAudio(audioBuffer1, numRemoteAudioFrames, bytesPerFrame);
						numRemoteAudioFrames = numberOfFramesPerBuffer;
					}
					
					// add the media sample
					err = AddMediaSample2(audioMedia,   // insert into audio media
										  audioBuffer1, // insert first buffer
										  8192,	        // length of audio buffer
										  1,            // normal decode duration
										  0,            // no display offset (won't work anyway)
										  (SampleDescriptionHandle)soundDesc,
										  numberOfFramesPerBuffer, // number of frames per sample 
										  0,            // no flags
										  NULL);        // not interested in decode time
					checkErr(0x0406);
					
					// swap the buffers
					void *buf = audioBuffer2;
					audioBuffer2 = audioBuffer1;
					audioBuffer1 = buf;
					
					// increase the offset within the media
					audioMediaOffset += numberOfFramesPerBuffer;
					numLocalAudioFrames -= numberOfFramesPerBuffer;
					numRemoteAudioFrames -= numberOfFramesPerBuffer;
				}
				
				// some zeros go into the first buffer, eventually also some into the second
				int availableFramesInActiveSample = numberOfFramesPerBuffer-numLocalAudioFrames;
				if(tsDifference > availableFramesInActiveSample)
				{
					// some zeros belong also into the second sample.
					// first, calculate the remaining frames to zero out in the second buffer
					// then, fill the remaining part of the first buffer with zeros
					// and start filling the second buffer with zeros
					int remainingZeros = tsDifference - availableFramesInActiveSample;
					_XMZeroFillLocalAudio(audioBuffer1, numLocalAudioFrames, bytesPerFrame);
					_XMZeroAddLocalAudio(audioBuffer2, 0, remainingZeros, bytesPerFrame);
					
					// since some samples went into the first buffer, it is not
					// necessary to save the active sample. Simply adjust the
					// numLocalAudioFrames counter
					numLocalAudioFrames += tsDifference;
				}
				else
				{
					// the whole gap of zeros fits within the first buffer
					_XMZeroAddLocalAudio(audioBuffer1, numLocalAudioFrames, tsDifference, bytesPerFrame);
					numLocalAudioFrames += tsDifference;
				}
			}
		}
		
		// Now, assuming all gaps have been filled with zeros.
		// check whether some samples belong into the first buffers
		if(numLocalAudioFrames < numberOfFramesPerBuffer)
		{
			// determine how many frames belong into the first buffer
			// and how many frames belong into the second buffer
			int availableFrames = numberOfFramesPerBuffer-numLocalAudioFrames;
			int numberOfFramesInSecondBuffer = 0;
			int copyLength = numFramesToStore;
			if(numFramesToStore > availableFrames)
			{
				copyLength = availableFrames;
				numberOfFramesInSecondBuffer = numFramesToStore-availableFrames;
			}
			
			_XMDataAddLocalAudio(audioBuffer1, numLocalAudioFrames, localAudioFrames, copyLength, audioCodecIdentifier);
			if(numberOfFramesInSecondBuffer > 0)
			{
				UInt16 *src = (UInt16 *)localAudioFrames;
				src += copyLength;
				_XMDataAddLocalAudio(audioBuffer2, 0, (void *)src, numberOfFramesInSecondBuffer, audioCodecIdentifier);
			}
		}
		else
		{
			// all frames are copied into the second buffer
			unsigned offset = numLocalAudioFrames - numberOfFramesPerBuffer;
			_XMDataAddLocalAudio(audioBuffer2, offset, localAudioFrames, numFramesToStore, audioCodecIdentifier);
		}
		
		numLocalAudioFrames += numFramesToStore;
		
		// if a buffer is full with both local and remote audio data, save it. If some part is missing yet,
		// wait until the second buffer is full. However, after more than 160 frames (20ms) have been added,
		// save the frame anyway.
		if((numLocalAudioFrames >= numberOfFramesPerBuffer && numRemoteAudioFrames >= numberOfFramesPerBuffer) ||
		   (numLocalAudioFrames >= numberOfFramesPerBuffer+160))
		{
			// If needed, zero-fill the remainder of the remote buffer
			if(numRemoteAudioFrames < numberOfFramesPerBuffer)
			{
				_XMZeroFillRemoteAudio(audioBuffer1, numRemoteAudioFrames, bytesPerFrame);
				numRemoteAudioFrames = numberOfFramesPerBuffer;
			}
			
			// save the sample
			err = AddMediaSample2(audioMedia,   // insert into audio media
								  audioBuffer1, // insert first buffer
								  8192,	        // length of audio buffer
								  1,            // normal decode duration
								  0,            // no display offset (won't work anyway)
								  (SampleDescriptionHandle)soundDesc,
								  numberOfFramesPerBuffer, // number of frames per sample 
								  0,            // no flags
								  NULL);        // not interested in decode time
			checkErr(0x0407);
			
			// swapping the buffers
			void *buf = audioBuffer2;
			audioBuffer2 = audioBuffer1;
			audioBuffer1 = buf;
			
			audioMediaOffset += numberOfFramesPerBuffer;
			numLocalAudioFrames -= numberOfFramesPerBuffer;
			numRemoteAudioFrames -= numberOfFramesPerBuffer;
		}
	}
	
	[audioLock unlock];
}

- (void)_handleRemoteAudioFrames:(void *)remoteAudioFrames count:(unsigned)numFramesToStore
{
	OSStatus err = noErr;
	
	// Basically, the same algorithm is used as in the case of the local frames.
	// Of course, the data is stored in the right channel instead of the left
	// one as in case of local audio data
	
	if(isAudioRecording == NO)
	{
		return;
	}
	
	[audioLock lock];
	
	if(isAudioRecording)
	{
		// obtain the current time
		struct timeval currentTime;
		gettimeofday(&currentTime, NULL);
		
		// calculate the timestamp based on time
		int timestamp;
		timestamp = (currentTime.tv_sec - startTime.tv_sec)*8000;
		timestamp += (currentTime.tv_usec - startTime.tv_usec)/125;
		
		// adjust the buffer index for the first local frames
		// to get calculated and used timestamps in sync
		if(audioTrackOffset == 0 && audioMediaOffset == 0 && numRemoteAudioFrames == 0)
		{
			audioTrackOffset = timestamp;
		}
		
		// calculate the expected timestamp based on how many samples are already
		// recorded
		int expectedTimestamp = audioTrackOffset + audioMediaOffset + numRemoteAudioFrames;
		
		// Depending on the chosen encoding algorithm, a frame will consist of either 8- or 16 bit.
		// Thus, the number of frames to be stored in the audio buffer may vary
		// Assuming the default to be A-Law / uLaw, 8bit.
		int numberOfFramesPerBuffer = 4096; // 8192 byte buffer size, 2 audio channels and 1 byte per frame
		int bytesPerFrame = 1;
		if(audioCodecIdentifier == XMCodecIdentifier_LinearPCM)
		{
			numberOfFramesPerBuffer = 2048;
			bytesPerFrame = 2;
		}
		
		// calculate the difference between the two timestamps. If the time based
		// timestamp is less than or not greater than 160 frames 
		// (corresponding to 20ms), accept it and put the frames into the buffer, starting at expected index.
		// Else, fill the gap with zeros. If there were multiple *empty* samples resulting, it is more efficient
		// to finish the old Media and start a new Media which will be inserted into the Track at the correct
		// offset. After this section, the buffer should be in sync again
		int tsDifference = timestamp - expectedTimestamp;
		if(tsDifference > 160)
		{
			// calculate how many frames are available in the two buffers allocated
			int availableFrames = 2*numberOfFramesPerBuffer - numRemoteAudioFrames;
			
			// Check which *recovery* action to do
			if(tsDifference > availableFrames)
			{
				// There are probably multiple empty samples, since the chance is very high
				// that the user muted the recording process or chose the dummy device
				// Instead of filling x samples containing just zeros, stop the current
				// Media, insert it into the Track and start a new Track/Media.
				// The second buffer will be discarded anyway, even if there already were
				// some frames in it. No more than 160 frames (20ms) are lost in this case,
				// this goes unnoticed.
				if(numRemoteAudioFrames < numberOfFramesPerBuffer)
				{
					_XMZeroFillRemoteAudio(audioBuffer1, numRemoteAudioFrames, bytesPerFrame);
				}
				if(numLocalAudioFrames < numberOfFramesPerBuffer)
				{
					_XMZeroFillLocalAudio(audioBuffer1, numLocalAudioFrames, bytesPerFrame);
				}
				
				// add the audio buffer
				err = AddMediaSample2(audioMedia,   // insert into audio media
									  audioBuffer1, // insert first buffer
									  8192,	        // length of audio buffer
									  1,            // normal decode duration
									  0,            // no display offset (won't work anyway)
									  (SampleDescriptionHandle)soundDesc,
									  numberOfFramesPerBuffer, // precalculated, number of frames per sample 
									  0,            // no flags
									  NULL);        // not interested in decode time
				checkErr(0x0500);
				
				// end the current audio media and insert it into the track
				err = EndMediaEdits(audioMedia);
				checkErr(0x0501);
				TimeValue trackStart = (TimeValue)(audioTrackOffset / 13.33333); // conversion from timebase 8000 to timebase 600
				err = InsertMediaIntoTrack(audioTrack, trackStart, 0, GetMediaDuration(audioMedia), fixed1);
				checkErr(0x0502);
				
				// Create a new audio track & media
				audioTrack = NewMovieTrack(movie, Long2Fix(0), Long2Fix(0), kFullVolume);
				err = GetMoviesError();
				checkErr(0x0503);
				
				audioMedia = NewTrackMedia(audioTrack, SoundMediaType, XM_AUDIO_TIME_SCALE, NULL, 0);
				err = GetMoviesError();
				checkErr(0x0504);
				
				err = BeginMediaEdits(audioMedia);
				checkErr(0x0505);
				
				// move the track offset to the current timestamp
				// reset media offset and the local buffer to the empty
				audioTrackOffset = timestamp;
				audioMediaOffset = 0;
				numLocalAudioFrames = 0;
				numRemoteAudioFrames = 0;
			}
			else 
			{
				// check whether the actual sample buffer is already full. If so, write out the
				// sample and swap buffers
				if(numRemoteAudioFrames >= numberOfFramesPerBuffer)
				{
					// the first sample is already completed.
					// Time to add this sample into the Media
					
					// first, check whether it's necessary to fill the local channel
					// with zeros
					if(numLocalAudioFrames < numberOfFramesPerBuffer)
					{
						_XMZeroFillLocalAudio(audioBuffer1, numLocalAudioFrames, bytesPerFrame);
						numLocalAudioFrames = numberOfFramesPerBuffer;
					}
					
					// add the media sample
					err = AddMediaSample2(audioMedia,   // insert into audio media
										  audioBuffer1, // insert first buffer
										  8192,	        // length of audio buffer
										  1,            // normal decode duration
										  0,            // no display offset (won't work anyway)
										  (SampleDescriptionHandle)soundDesc,
										  numberOfFramesPerBuffer, // number of frames per sample 
										  0,            // no flags
										  NULL);        // not interested in decode time
					checkErr(0x0506);
					
					// swap the buffers
					void *buf = audioBuffer2;
					audioBuffer2 = audioBuffer1;
					audioBuffer1 = buf;
					
					// increase the offset within the media
					audioMediaOffset += numberOfFramesPerBuffer;
					numLocalAudioFrames -= numberOfFramesPerBuffer;
					numRemoteAudioFrames -= numberOfFramesPerBuffer;
				}
				
				// some zeros go into the first buffer, eventually also some into the second
				int availableFramesInActiveSample = numberOfFramesPerBuffer-numRemoteAudioFrames;
				if(tsDifference > availableFramesInActiveSample)
				{
					// some zeros belong also into the second sample.
					// first, calculate the remaining frames to zero out in the second buffer
					// then, fill the remaining part of the first buffer with zeros
					// and start filling the second buffer with zeros
					int remainingZeros = tsDifference - availableFramesInActiveSample;
					_XMZeroFillRemoteAudio(audioBuffer1, numRemoteAudioFrames, bytesPerFrame);
					_XMZeroAddRemoteAudio(audioBuffer2, 0, remainingZeros, bytesPerFrame);
					
					// since some samples went into the first buffer, it is not
					// necessary to save the active sample. Simply adjust the
					// numRemoteAudioFrames counter
					numRemoteAudioFrames += tsDifference;
				}
				else
				{
					// the whole gap of zeros fits within the first buffer
					_XMZeroAddRemoteAudio(audioBuffer1, numRemoteAudioFrames, tsDifference, bytesPerFrame);
					numRemoteAudioFrames += tsDifference;
				}
			}
		}
		
		// Now, assuming all gaps have been filled with zeros.
		// check whether some samples belong into the first buffers
		if(numRemoteAudioFrames < numberOfFramesPerBuffer)
		{
			// determine how many frames belong into the first buffer
			// and how many frames belong into the second buffer
			int availableFrames = numberOfFramesPerBuffer-numRemoteAudioFrames;
			int numberOfFramesInSecondBuffer = 0;
			int copyLength = numFramesToStore;
			if(numFramesToStore > availableFrames)
			{
				copyLength = availableFrames;
				numberOfFramesInSecondBuffer = numFramesToStore-availableFrames;
			}
			
			_XMDataAddRemoteAudio(audioBuffer1, numRemoteAudioFrames, remoteAudioFrames, copyLength, audioCodecIdentifier);
			if(numberOfFramesInSecondBuffer > 0)
			{
				UInt16 *src = (UInt16 *)remoteAudioFrames;
				src += copyLength;
				_XMDataAddRemoteAudio(audioBuffer2, 0, src, numberOfFramesInSecondBuffer, audioCodecIdentifier);
			}
		}
		else
		{
			// all frames are copied into the second buffer
			unsigned offset = numRemoteAudioFrames - numberOfFramesPerBuffer;
			_XMDataAddRemoteAudio(audioBuffer2, offset, remoteAudioFrames, numFramesToStore, audioCodecIdentifier);
		}
		
		numRemoteAudioFrames += numFramesToStore;
		
		// if a buffer is full with both local and remote audio data, save it. If some part is missing yet,
		// wait until the second buffer is full. However, after more than 160 frames (20ms) have been added,
		// save the frame anyway.
		if((numLocalAudioFrames >= numberOfFramesPerBuffer && numRemoteAudioFrames >= numberOfFramesPerBuffer) ||
		   (numRemoteAudioFrames >= numberOfFramesPerBuffer+160))
		{
			// If needed, zero-fill the remainder of the remote buffer
			if(numLocalAudioFrames < numberOfFramesPerBuffer)
			{
				_XMZeroFillLocalAudio(audioBuffer1, numLocalAudioFrames, bytesPerFrame);
				numLocalAudioFrames = numberOfFramesPerBuffer;
			}
			
			// save the sample
			err = AddMediaSample2(audioMedia,   // insert into audio media
								  audioBuffer1, // insert first buffer
								  8192,	        // length of audio buffer
								  1,            // normal decode duration
								  0,            // no display offset (won't work anyway)
								  (SampleDescriptionHandle)soundDesc,
								  numberOfFramesPerBuffer, // number of frames per sample 
								  0,            // no flags
								  NULL);        // not interested in decode time
			checkErr(0x0507);
	
			// swapping the buffers
			void *buf = audioBuffer2;
			audioBuffer2 = audioBuffer1;
			audioBuffer1 = buf;
			
			audioMediaOffset += numberOfFramesPerBuffer;
			numLocalAudioFrames -= numberOfFramesPerBuffer;
			numRemoteAudioFrames -= numberOfFramesPerBuffer;
		}
	}

	[audioLock unlock];
}

#pragma mark -
#pragma mark Video Recompression Methods

- (void)_runRecompressionThread
{
	
	EnterMoviesOnThread(kQTEnterMoviesFlagDontSetComponentsThreadMode);
	
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	recordTimer = [NSTimer scheduledTimerWithTimeInterval:(1/30.0) target:self selector:@selector(_recordFrame:) userInfo:nil repeats:YES];
	[autoreleasePool release];
	
	// Running the run loop until the recording session is stopped
	[[NSRunLoop currentRunLoop] run];
	
	ExitMoviesOnThread();
	
	// inform the main thread that this thread is finished
	[self performSelectorOnMainThread:@selector(_recompressionThreadDidEnd) withObject:nil waitUntilDone:NO];
}

/**
 * QuickTime and the OS seem to *punish* this thread for its long occupance 
 * of the lock by blocking this thread inside the [lock unlock] message.
 * Between the time the thread enters and leaves the [lock unlock] message, 
 * several local video callbacks may run.
 * Thus, the expected framerate of the recorded file isn't too high, even
 * if trying to reach 30fps. Of course, running a record operation at the
 * same time XMeeting is in a call results in a huge CPU load. Therefore,
 * it makes sense to leave this as a simple best effort service.
 **/
- (void)_recordFrame:(NSTimer *)timer
{	
	if(frameUpdated == NO)
	{
		return;
	}
	
	[videoLock lock];
	
	if(lockingMode == XM_NONBLOCKING_COMPRESSION)
	{
		frameOccupied = YES;
		[videoLock unlock];
	}

	TimeValue64 timestamp;
	TimeValue64 duration;
	
	struct timeval theTime;
	gettimeofday(&theTime, NULL);
		
	// calculating the timestamp with time base 600
	int timestamp1 = (theTime.tv_sec - startTime.tv_sec)*600;
	int timestamp2 = (theTime.tv_usec - startTime.tv_usec)/1666;
	timestamp = ((TimeValue64)timestamp1 + (TimeValue64)timestamp2);
	duration = timestamp - previousTimestamp;
	
	ICMCompressionFrameOptionsRef compressionFrameOptionsRef = NULL;
	
	// if one has to abort, still compress this sample.
	// Ensure that it is a key frame to get nice looking end of the movie
	if(quitRecording == YES)
	{
		[timer invalidate];
		
		OSStatus err = ICMCompressionFrameOptionsCreate(NULL,
														compressionSession,
														&compressionFrameOptionsRef);
		if(err == noErr)
		{
			err = ICMCompressionFrameOptionsSetForceKeyFrame(compressionFrameOptionsRef, true);
			if(err != noErr)
			{
				NSLog(@"ICMCompressionFrameOptionsSetForceKeyFrame failed %d", err);
			}
		}
	}
	
	previousTimestamp = timestamp;
	
	// compressing the frame. The encoded frame is handled in the callback
	ICMCompressionSessionEncodeFrame(compressionSession,
									 recompressionBuffer,
									 timestamp,
									 duration,
									 (kICMValidTime_DisplayTimeStampIsValid | kICMValidTime_DisplayDurationIsValid),
									 compressionFrameOptionsRef, NULL, NULL);
	

	ICMCompressionFrameOptionsRelease(compressionFrameOptionsRef); // does nothing if NULL
	compressionFrameOptionsRef = NULL;
	
	if(lockingMode == XM_NONBLOCKING_COMPRESSION)
	{
		[videoLock lock];
		frameOccupied = NO;
	}
	frameUpdated = NO;
	[videoLock unlock];
}

#undef checkErr
#define checkErr(code) \
{ \
	if(err != noErr) { \
		errorCode = err; \
		locationCode = code; \
		[self _reportError]; \
	} \
}

- (OSStatus)_saveCompressedFrame:(ICMEncodedFrameRef)encodedFrame
{
	OSStatus err = noErr;
	
	/* sanity check since the last frame has duration zero! */
	TimeValue64 duration = ICMEncodedFrameGetDecodeDuration(encodedFrame);
	if(duration == 0)
	{
		err = ICMEncodedFrameSetDecodeDuration((ICMMutableEncodedFrameRef)encodedFrame, 20);
		checkErr(0x0600);
	}
	
	err = AddMediaSampleFromEncodedFrame(videoMedia, encodedFrame, NULL);
	checkErr(0x0601);
	
	return err;
}

@end

#pragma mark -
#pragma mark Callbacks & Functions

void _XMHandleLocalAudioFrames(void *localAudioFrames, unsigned numberOfFrames)
{
	[_XMCallRecorderSharedInstance _handleLocalAudioFrames:localAudioFrames count:numberOfFrames];
}

void _XMHandleRemoteAudioFrames(void *remoteAudioFrames, unsigned numberOfFrames)
{
	[_XMCallRecorderSharedInstance _handleRemoteAudioFrames:remoteAudioFrames count:numberOfFrames];
}

OSStatus _XMSaveCompressedFrameProc(void* encodedFrameOutputRefCon, 
								   ICMCompressionSessionRef session, 
								   OSStatus err,
								   ICMEncodedFrameRef encodedFrame,
								   void* reserved)
{
	if(err == noErr)
	{
		XMCallRecorder *callRecorder = (XMCallRecorder *)encodedFrameOutputRefCon;
		err = [callRecorder _saveCompressedFrame:encodedFrame];
	}
	
	return err;
}

void _XMCallRecorderPixelBufferReleaseCallback(void *releaseRefCon, 
											   const void *baseAddress)
{
	free((void *)baseAddress);
}

inline void _XMZeroFillLocalAudio(void *buffer, unsigned frameOffset, unsigned bytesPerFrame)
{
	if(bytesPerFrame == 2)
	{
		_XMZeroFillLocalAudio16Bit(buffer, frameOffset);
	}
	else
	{
		_XMZeroFillLocalAudio8Bit(buffer, frameOffset);
	}
}

inline void _XMZeroFillLocalAudio16Bit(void *buffer, unsigned frameOffset)
{
	UInt16 *buf = (UInt16 *)buffer;
	buf += (2*frameOffset); // moving to offset
	
	int remainingFrames = 2048-frameOffset;
	int i;
	for(i = 0; i < remainingFrames; i++)
	{
		buf[2*i] = 0; // only every second frame belongs to the left channel
	}
}

inline void _XMZeroFillLocalAudio8Bit(void *buffer, unsigned frameOffset)
{
	UInt8 *buf = (UInt8 *)buffer;
	buf += (2*frameOffset); // moving to offset
	
	int remainingFrames = 4096-frameOffset;
	int i;
	for(i = 0; i < remainingFrames; i++)
	{
		buf[2*i] = 0; // only every second frame belongs to the left channel;
	}
}

inline void _XMZeroFillRemoteAudio(void *buffer, unsigned frameOffset, unsigned bytesPerFrame)
{
	if(bytesPerFrame == 2)
	{
		_XMZeroFillRemoteAudio16Bit(buffer, frameOffset);
	}
	else
	{
		_XMZeroFillRemoteAudio8Bit(buffer, frameOffset);
	}
}

inline void _XMZeroFillRemoteAudio16Bit(void *buffer, unsigned frameOffset)
{
	UInt16 *buf = (UInt16 *)buffer;
	buf += (2*frameOffset) + 1; // moving to offset, moving to right channel
	
	int remainingFrames = 2048-frameOffset;
	int i;
	for(i = 0; i < remainingFrames; i++)
	{
		buf[2*i] = (UInt16)0; // only every second frame belongs to the right channel
	}
}

inline void _XMZeroFillRemoteAudio8Bit(void *buffer, unsigned frameOffset)
{
	UInt8 *buf = (UInt8 *)buffer;
	buf += (2*frameOffset) + 1; // moving to offset, moving to right channel
	
	int remainingFrames = 4096-frameOffset;
	int i;
	for(i = 0; i < remainingFrames; i++)
	{
		buf[2*i] = 0; // only every second frame belongs to the right channel;
	}
}

inline void _XMZeroAddLocalAudio(void *buffer, unsigned offset, unsigned numberOfZeros, unsigned bytesPerFrame)
{
	if(bytesPerFrame == 2)
	{
		_XMZeroAddLocalAudio16Bit(buffer, offset, numberOfZeros);
	}
	else
	{
		_XMZeroAddLocalAudio8Bit(buffer, offset, numberOfZeros);
	}
}

inline void _XMZeroAddLocalAudio16Bit(void *buffer, unsigned offset, unsigned numberOfZeros)
{
	UInt16 *buf = (UInt16 *)buffer;
	buf += (2*offset);
	int i;
	for(i < 0; i < numberOfZeros; i++)
	{
		buf[2*i] = 0;
	}
}

inline void _XMZeroAddLocalAudio8Bit(void *buffer, unsigned offset, unsigned numberOfZeros)
{
	UInt8 *buf = (UInt8 *)buffer;
	buf += (2*offset);
	int i;
	for(i = 0; i < numberOfZeros; i++)
	{
		buf[2*i] = 0;
	}
}

inline void _XMZeroAddRemoteAudio(void *buffer, unsigned offset, unsigned numberOfZeros, unsigned bytesPerFrame)
{
	if(bytesPerFrame == 2)
	{
		_XMZeroAddRemoteAudio16Bit(buffer, offset, numberOfZeros);
	}
	else
	{
		_XMZeroAddRemoteAudio8Bit(buffer, offset, numberOfZeros);
	}
}

inline void _XMZeroAddRemoteAudio16Bit(void *buffer, unsigned offset, unsigned numberOfZeros)
{
	UInt16 *buf = (UInt16 *)buffer;
	buf += (2*offset) + 1;	// switch to right channel
	int i;
	for(i = 0; i < numberOfZeros; i++)
	{
		buf[2*i] = 0;
	}
}

inline void _XMZeroAddRemoteAudio8Bit(void *buffer, unsigned offset, unsigned numberOfZeros)
{
	UInt8 *buf = (UInt8 *)buffer;
	buf += (2*offset) + 1;	// switch to right channel
	int i;
	for(i = 0; i < numberOfZeros; i++)
	{
		buf[2*i] = 0;
	}
}

inline void _XMDataAddLocalAudio(void *dstBuffer, unsigned offset, void *srcBuffer, unsigned numberOfFrames, XMCodecIdentifier codecIdentifier)
{
	if(codecIdentifier == XMCodecIdentifier_LinearPCM)
	{
		_XMDataAddLocalAudioLPCM(dstBuffer, offset, srcBuffer, numberOfFrames);
	}
	else if(codecIdentifier == XMCodecIdentifier_G711_uLaw)
	{
		_XMDataAddLocalAudioULAW(dstBuffer, offset, srcBuffer, numberOfFrames);
	}
	else
	{
		_XMDataAddLocalAudioALAW(dstBuffer, offset, srcBuffer, numberOfFrames);
	}
}

inline void _XMDataAddLocalAudioLPCM(void *dstBuffer, unsigned offset, void *srcBuffer, unsigned numberOfFrames)
{
	UInt16 *dst = (UInt16 *)dstBuffer;
	UInt16 *src = (UInt16 *)srcBuffer;
	dst += (2*offset); // moving to offset
	int i;
	for(i = 0; i < numberOfFrames; i++)
	{
		dst[2*i] = src[i];
	}
}

inline void _XMDataAddLocalAudioULAW(void *dstBuffer, unsigned offset, void *srcBuffer, unsigned numberOfFrames)
{
	UInt8 *dst = (UInt8 *)dstBuffer;
	UInt16 *src = (UInt16 *)srcBuffer;
	dst += (2*offset);	// moving to offset
	int i;
	for(i = 0; i < numberOfFrames; i++)
	{
		UInt32 value = src[i];
		dst[2*i] = (UInt8)(linear2ulaw(value));
	}
}

inline void _XMDataAddLocalAudioALAW(void *dstBuffer, unsigned offset, void *srcBuffer, unsigned numberOfFrames)
{
	UInt8 *dst = (UInt8 *)dstBuffer;
	UInt16 *src = (UInt16 *)srcBuffer;
	dst += (2*offset);	// moving to offset
	int i;
	for(i = 0; i < numberOfFrames; i++)
	{
		UInt16 value = src[i];
		dst[2*i] = linear2alaw(value);
	}
}

inline void _XMDataAddRemoteAudio(void *dstBuffer, unsigned offset, void *srcBuffer, unsigned numberOfFrames, XMCodecIdentifier codecIdentifier)
{
	if(codecIdentifier == XMCodecIdentifier_LinearPCM)
	{
		_XMDataAddRemoteAudioLPCM(dstBuffer, offset, srcBuffer, numberOfFrames);
	}
	else if(codecIdentifier == XMCodecIdentifier_G711_uLaw)
	{
		_XMDataAddRemoteAudioULAW(dstBuffer, offset, srcBuffer, numberOfFrames);
	}
	else
	{
		_XMDataAddRemoteAudioALAW(dstBuffer, offset, srcBuffer, numberOfFrames);
	}
}

inline void _XMDataAddRemoteAudioLPCM(void *dstBuffer, unsigned offset, void *srcBuffer, unsigned numberOfFrames)
{
	UInt16 *dst = (UInt16 *)dstBuffer;
	UInt16 *src = (UInt16 *)srcBuffer;
	dst += (2*offset) + 1; // moving to offset, moving to right channel
	int i;
	for(i = 0; i < numberOfFrames; i++)
	{
		dst[2*i] = src[i];
	}
}

inline void _XMDataAddRemoteAudioULAW(void *dstBuffer, unsigned offset, void *srcBuffer, unsigned numberOfFrames)
{
	UInt8 *dst = (UInt8 *)dstBuffer;
	UInt16 *src = (UInt16 *)srcBuffer;
	dst += (2*offset) + 1;	// 1 byte per frame, moving to offset, moving to right channel
	int i;
	for(i = 0; i < numberOfFrames; i++)
	{
		UInt16 value = src[i];
		dst[2*i] = linear2ulaw(value);
	}
}

inline void _XMDataAddRemoteAudioALAW(void *dstBuffer, unsigned offset, void *srcBuffer, unsigned numberOfFrames)
{
	UInt8 *dst = (UInt8 *)dstBuffer;
	UInt16 *src = (UInt16 *)srcBuffer;
	dst += (2*offset) + 1;	// 1 byte per frame, moving to offset, moving to right channel
	int i;
	for(i = 0; i < numberOfFrames; i++)
	{
		UInt16 value = src[i];
		dst[2*i] = linear2alaw(value);
	}
}