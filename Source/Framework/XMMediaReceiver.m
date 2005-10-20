/*
 * $Id: XMMediaReceiver.m,v 1.5 2005/10/20 19:21:06 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMMediaReceiver.h"

#import "XMPrivate.h"
#import "XMVideoManager.h"
#import "XMPacketReassembler.h"
#import "XMCallbackBridge.h"
#import "XMUtils.h"

@interface XMMediaReceiver (PrivateMethods)

- (id)_init;
- (void)_processFrame:(const UInt8 *)data length:(unsigned)length session:(unsigned)session;

@end

void XMProcessFrame(const UInt8* data, unsigned length, unsigned sessionID);

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
	
	XMRegisterPacketReassembler();
	
	videoPacketReassembler = NULL;
	videoDecompressionSession = NULL;
	videoCodecType = 0;
	videoPayloadType = 0;
	videoMediaSize = XMVideoSize_NoVideo;
	
	didSucceedDecodingFrame = YES;
	
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

- (void)_startMediaReceivingWithCodec:(unsigned)codecType payloadType:(unsigned)payloadType
								 videoSize:(XMVideoSize)videoSize session:(unsigned)sessionID
{
	ComponentResult err = noErr;
	
	err = EnterMoviesOnThread(kQTEnterMoviesFlagDontSetComponentsThreadMode);
	if(err != noErr)
	{
		NSLog(@"EnterMoviesOnThread failed");
	}
	
	videoCodecType = codecType;
	videoPayloadType = payloadType;
	videoMediaSize = videoSize;
	
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
	if(videoPacketReassembler != NULL)
	{
		CloseComponent(videoPacketReassembler);
		videoPacketReassembler = NULL;
	}
	
	[_XMVideoManagerSharedInstance performSelectorOnMainThread:@selector(_handleVideoReceivingEnd)
													withObject:nil waitUntilDone:NO];
	
	ExitMoviesOnThread();
}

- (BOOL)_processPacket:(UInt8*)data length:(unsigned)length session:(unsigned)sessionID
{
	ComponentResult err = noErr;
	
	if(videoPacketReassembler == NULL)
	{
		ComponentDescription componentDescription;
		
		if(XMGetPacketReassemblerComponentDescription(&componentDescription) == false)
		{
			NSLog(@"Obtaining PacketReassembler CompDesc failed");
			return NO;
		}
		
		Component reassemblerComponent = FindNextComponent(0, &componentDescription);
		if(reassemblerComponent == NULL)
		{
			NSLog(@"Couldn't find packet reassembler component");
			return NO;
		}
		
		err = OpenAComponent(reassemblerComponent, &videoPacketReassembler);
		if(err != noErr)
		{
			NSLog(@"Opening packetReassembler failed %d", (int)err);
			return NO;
		}
		
		// we pass the required information to the XMPacketReassembler through
		// the default RTPRssmInitParams call.
		// However, the meaning of timeBase and timeScale are redefined as
		// follows:
		// timeBase contains the codecType and
		// timeScale contains the sessionID to be used
		RTPRssmInitParams initParams;
		initParams.payloadType = videoPayloadType;
		initParams.ssrc = videoCodecType;
		initParams.timeScale = sessionID;
		err = RTPRssmInitialize(videoPacketReassembler, &initParams);
		if(err != noErr)
		{
			NSLog(@"RTPRssmInitialize failed %d", (int)err);
			return NO;
		}
	}
	
	QTSStreamBuffer *streamBuffer = NULL;
	err = QTSNewStreamBuffer(length, 0, &streamBuffer);
	if(err != noErr)
	{
		NSLog(@"Creating StreamBuffer failed: %d", (int)err);
		return NO;
	}
	
	void *dest = streamBuffer->rptr;
	memcpy(dest, data, length);
	streamBuffer->wptr += length;
	
	didSucceedDecodingFrame = YES;
	
	err = RTPRssmHandleNewPacket(videoPacketReassembler,
								 streamBuffer,
								 0);
	if(err != noErr)
	{
		NSLog(@"RTPRssmHandleNewPacket failed: %d", (int)err);
		return NO;
	}
		
	return didSucceedDecodingFrame;		
}

- (void)_processFrame:(const UInt8 *)data length:(unsigned)length session:(unsigned)sessionID
{
	ComponentResult err = noErr;
	
	if(videoDecompressionSession == NULL)
	{
		ImageDescriptionHandle imageDesc;
		
		NSSize videoDimensions;
		
		videoDimensions = XMGetVideoFrameDimensions(videoMediaSize);
		CodecType codecType;
		
		switch(videoCodecType)
		{
			case _XMVideoCodec_H261:
				codecType = kH261CodecType;
				break;
			default:
				NSLog(@"illegal codecType");
				return;
		}
		
		imageDesc = (ImageDescriptionHandle)NewHandleClear(sizeof ( **imageDesc ));
		(**imageDesc).idSize = sizeof( **imageDesc);
		(**imageDesc).cType = codecType;
		(**imageDesc).version = 1;
		(**imageDesc).revisionLevel = 1;
		(**imageDesc).vendor = FOUR_CHAR_CODE('XMet');
		(**imageDesc).temporalQuality = codecNormalQuality;
		(**imageDesc).spatialQuality = codecNormalQuality;
		(**imageDesc).width = (short)videoDimensions.width;
		(**imageDesc).height = (short)videoDimensions.height;
		(**imageDesc).dataSize = 0;
		(**imageDesc).frameCount = 1;
		(**imageDesc).clutID = -1;
		
		ICMDecompressionSessionOptionsRef sessionOptions = NULL;
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
		didSucceedDecodingFrame = NO;
	}
}

@end

void XMProcessFrame(const UInt8* data, unsigned length, unsigned sessionID)
{
	[_XMMediaReceiverSharedInstance _processFrame:data length:length session:sessionID];
}

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
		CIImage *remoteImage = [[CIImage alloc] initWithCVImageBuffer:(CVImageBufferRef)pixelBuffer];
		[_XMVideoManagerSharedInstance performSelectorOnMainThread:@selector(_handleRemoteImage:) withObject:remoteImage waitUntilDone:NO];
	}
}
