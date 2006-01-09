/*
 * $Id: XMMediaReceiver.m,v 1.12 2006/01/09 22:22:57 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMMediaReceiver.h"

#import "XMPrivate.h"
#import "XMUtils.h"
#import "XMVideoManager.h"
#import "XMCallbackBridge.h"

#define XM_PACKET_POOL_GRANULARITY 16
#define XM_CHUNK_BUFFER_SIZE 352*288*4

@interface XMMediaReceiver (PrivateMethods)

- (id)_init;
- (BOOL)_processPacketGroup;

@end

static void XMProcessDecompressedFrameProc(void *decompressionTrackingRefCon,
										   OSStatus result,
										   ICMDecompressionTrackingFlags decompressionTrackingFlags,
										   CVPixelBufferRef pixelBuffer,
										   TimeValue64 displayTime,
										   TimeValue64 displayDuration,
										   ICMValidTimeFlags validTimeFlags,
										   void *reserved,
										   void *sourceFrameRefCon);

@implementation XMMediaReceiver

#pragma mark Init & Deallocation Methods

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	return nil;
}

- (id)_init
{	
	self = [super init];
	
	videoDecompressionSession = NULL;
	videoCodecIdentifier = XMCodecIdentifier_UnknownCodec;
	videoPayloadType = 0;
	videoMediaSize = XMVideoSize_NoVideo;
	
	return self;
}

- (void)_close
{
}

- (void)dealloc
{	
	[self _close];
	[super dealloc];
}

#pragma mark Data Handling Methods

- (void)_startMediaReceivingForSession:(unsigned)sessionID withCodec:(XMCodecIdentifier)codecIdentifier 
							 videoSize:(XMVideoSize)videoSize payloadType:(unsigned)payloadType;
{
	ComponentResult err = noErr;
	
	err = EnterMoviesOnThread(kQTEnterMoviesFlagDontSetComponentsThreadMode);
	if(err != noErr)
	{
		NSLog(@"EnterMoviesOnThread failed");
	}
	
	videoCodecIdentifier = codecIdentifier;
	videoMediaSize = videoSize;
	videoPayloadType = payloadType;
	
	NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:(unsigned)videoSize];
	[_XMVideoManagerSharedInstance performSelectorOnMainThread:@selector(_handleVideoReceivingStart:)
													withObject:number waitUntilDone:NO];
	[number release];
}

- (void)_stopMediaReceivingForSession:(unsigned)sessionID
{	
	if(videoDecompressionSession != NULL)
	{
		ICMDecompressionSessionRelease(videoDecompressionSession);
		videoDecompressionSession = NULL;
	}
	
	[_XMVideoManagerSharedInstance performSelectorOnMainThread:@selector(_handleVideoReceivingEnd)
													withObject:nil waitUntilDone:NO];
	ExitMoviesOnThread();
}

- (BOOL)_decodeFrameForSession:(unsigned)sessionID data:(UInt8 *)data length:(unsigned)length
{
	ComponentResult err = noErr;
	
	if(videoDecompressionSession == NULL)
	{
		ImageDescriptionHandle imageDesc;
		
		NSSize videoDimensions;
		
		videoDimensions = XMGetVideoFrameDimensions(videoMediaSize);
		CodecType codecType;
		char *codecName;
		
		switch(videoCodecIdentifier)
		{
			case XMCodecIdentifier_H261:
				codecType = kH261CodecType;
				codecName = "H.261";
				break;
			case XMCodecIdentifier_H263:
				codecType = kH263CodecType;
				codecName = "H.263";
				break;
			case XMCodecIdentifier_H264:
				codecType =  kH264CodecType;
				codecName = "H.264";
				break;
			default:
				NSLog(@"illegal codecType");
				return NO;
		}
		
		imageDesc = (ImageDescriptionHandle)NewHandleClear(sizeof(**imageDesc)+4);
		(**imageDesc).idSize = sizeof( **imageDesc)+4;
		(**imageDesc).cType = codecType;
		(**imageDesc).resvd1 = 0;
		(**imageDesc).resvd2 = 0;
		(**imageDesc).dataRefIndex = 0;
		(**imageDesc).version = 1;
		(**imageDesc).revisionLevel = 1;
		(**imageDesc).vendor = 'XMet';
		(**imageDesc).temporalQuality = codecNormalQuality;
		(**imageDesc).spatialQuality = codecNormalQuality;
		(**imageDesc).width = (short)videoDimensions.width;
		(**imageDesc).height = (short)videoDimensions.height;
		(**imageDesc).hRes = Long2Fix(72);
		(**imageDesc).vRes = Long2Fix(72);
		(**imageDesc).dataSize = 0;
		(**imageDesc).frameCount = 1;
		CopyCStringToPascal(codecName, (**imageDesc).name);
		(**imageDesc).depth = 24;
		(**imageDesc).clutID = -1;
		
		/*
		if(codecType == kH264CodecType)
		{
			UInt32 avccLength = _XMGetAVCCAtomLength();
			if(avccLength == 0)
			{
				NSLog(@"AVCC Not yet ready");
				DisposeHandle((Handle)imageDesc);
				return;
			}
			
			Handle avccHandle = NewHandleClear(avccLength);
			Boolean result = _XMGetAVCCAtom((UInt8 *)*avccHandle);
			
			err = AddImageDescriptionExtension(imageDesc, avccHandle, 'avcC');
			if(err != noErr)
			{
				NSLog(@"Add AVCC failed");
				DisposeHandle((Handle)imageDesc);
				DisposeHandle(avccHandle);
				return;
			}
			
			DisposeHandle(avccHandle);
		}*/
		
		ICMDecompressionSessionOptionsRef sessionOptions = NULL;
		err = ICMDecompressionSessionOptionsCreate(NULL, &sessionOptions);
		if(err != noErr)
		{
			NSLog(@"DecompressionSessionOptionsCreate  failed %d", (int)err);
		}
		
		/*if(codecType == kH263CodecType)
		{
			NSLog(@"Is H.263 codec to receive");
			ComponentDescription componentDescription;
			componentDescription.componentType = 'imdc';
			componentDescription.componentSubType = 'h263';
			componentDescription.componentManufacturer = 'appl';
			componentDescription.componentFlags = 0;
			componentDescription.componentFlagsMask = 0;
			
			Component decompressorComponent = FindNextComponent(0, &componentDescription);
			if(decompressorComponent == NULL)
			{
				fprintf(stderr, "No such decompressor\n");
			}
			
			err = ICMDecompressionSessionOptionsSetProperty(sessionOptions,
															kQTPropertyClass_ICMDecompressionSessionOptions,
															kICMDecompressionSessionOptionsPropertyID_DecompressorComponent,
															sizeof(decompressorComponent),
															&decompressorComponent);
			if(err != noErr)
			{
				NSLog(@"No such codec found");
			}
		}*/
		
		ICMDecompressionTrackingCallbackRecord trackingCallbackRecord;
		
		trackingCallbackRecord.decompressionTrackingCallback = XMProcessDecompressedFrameProc;
		trackingCallbackRecord.decompressionTrackingRefCon = (void *)self;
		
		NSMutableDictionary *pixelBufferAttributes = [[NSMutableDictionary alloc] initWithCapacity:3];
		NSNumber *number;
		
		number = [[NSNumber alloc] initWithInt:(int)videoDimensions.width];
		[pixelBufferAttributes setObject:number forKey:(NSString *)kCVPixelBufferWidthKey];
		[number release];
		
		number = [[NSNumber alloc] initWithInt:(int)videoDimensions.height];
		[pixelBufferAttributes setObject:number forKey:(NSString *)kCVPixelBufferHeightKey];
		[number release];
		
		number = [[NSNumber alloc] initWithInt:k32ARGBPixelFormat];
		[pixelBufferAttributes setObject:number forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
		[number release];
		
		err = ICMDecompressionSessionCreate(NULL, imageDesc, sessionOptions,
											(CFDictionaryRef)pixelBufferAttributes,
											&trackingCallbackRecord, &videoDecompressionSession);
		if(err != noErr)
		{
			NSLog(@"Creating of the decompressionSession failed %d", (int)err);
		}
		
		[pixelBufferAttributes release];
		ICMDecompressionSessionOptionsRelease(sessionOptions);
		
		DisposeHandle((Handle)imageDesc);
	}
	err = ICMDecompressionSessionDecodeFrame(videoDecompressionSession,
											 data, length,
											 NULL, NULL,
											 (void *)self);
	if(err != noErr)
	{
		NSLog(@"Decompression of the frame failed %d", (int)err);
		return NO;
	}
	return YES;
}

@end

static void XMProcessDecompressedFrameProc(void *decompressionTrackingRefCon,
										   OSStatus result,
										   ICMDecompressionTrackingFlags decompressionTrackingFlags,
										   CVPixelBufferRef pixelBuffer,
										   TimeValue64 displayTime,
										   TimeValue64 displayDuration,
										   ICMValidTimeFlags validTimeFlags,
										   void *reserved,
										   void *sourceFrameRefCon)
{
	if((kICMDecompressionTracking_EmittingFrame & decompressionTrackingFlags) && pixelBuffer != NULL)
	{
		[_XMVideoManagerSharedInstance _handleRemoteVideoFrame:pixelBuffer];
	}
}
