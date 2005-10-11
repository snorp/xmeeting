/*
 * $Id: XMMediaReceiver.m,v 1.1 2005/10/11 09:03:10 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMMediaReceiver.h"
#import "XMVideoManager.h"
#import "XMPacketReassembler.h"

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

#pragma mark Class Methods

+ (XMMediaReceiver *)sharedInstance
{
	static XMMediaReceiver *sharedInstance = nil;
	
	if(sharedInstance == nil)
	{
		sharedInstance = [[XMMediaReceiver alloc] _init];
	}
	
	return sharedInstance;
}

#pragma mark Init & Deallocation Methods

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	return nil;
}

- (id)_init
{
	ComponentResult err = noErr;
	
	self = [super init];
	
	err = EnterMoviesOnThread(kQTEnterMoviesFlagDontSetComponentsThreadMode);
	if(err != noErr)
	{
		NSLog(@"EnterMoviesOnThread failed");
	}
	
	XMRegisterPacketReassembler();
	
	return self;
}

#pragma mark Data Handling Methods

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
		
		RTPRssmInitParams initParams;
		initParams.payloadType = kRTPPayload_H261;
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
	
	err = RTPRssmHandleNewPacket(videoPacketReassembler,
								 streamBuffer,
								 0);
	if(err != noErr)
	{
		NSLog(@"RTPRssmHandleNewPacket failed: %d", (int)err);
		return NO;
	}
		
	return YES;		
}

- (void)_processFrame:(const UInt8 *)data length:(unsigned)length session:(unsigned)sessionID
{
	ComponentResult err = noErr;
	
	if(videoDecompressionSession == NULL)
	{
		ImageDescriptionHandle imageDesc;
		
		imageDesc = (ImageDescriptionHandle)NewHandleClear(sizeof ( **imageDesc ));
		(**imageDesc).idSize = sizeof( **imageDesc);
		(**imageDesc).cType = kH261CodecType;
		(**imageDesc).version = 1;
		(**imageDesc).revisionLevel = 1;
		(**imageDesc).vendor = FOUR_CHAR_CODE('XMet');
		(**imageDesc).temporalQuality = codecNormalQuality;
		(**imageDesc).spatialQuality = codecNormalQuality;
		(**imageDesc).width = 352;
		(**imageDesc).height = 288;
		(**imageDesc).dataSize = 0;
		(**imageDesc).frameCount = 1;
		(**imageDesc).clutID = -1;
		
		ICMDecompressionSessionOptionsRef sessionOptions = NULL;
		ICMDecompressionTrackingCallbackRecord trackingCallbackRecord;
		
		trackingCallbackRecord.decompressionTrackingCallback = XMProcessDecompressedFrameProc;
		trackingCallbackRecord.decompressionTrackingRefCon = (void *)self;
		
		NSMutableDictionary *pixelBufferAttributes = [[NSMutableDictionary alloc] initWithCapacity:3];
		NSNumber *number;
		
		number = [[NSNumber alloc] initWithInt:352];
		[pixelBufferAttributes setObject:number forKey:(NSString *)kCVPixelBufferWidthKey];
		[number release];
		
		number = [[NSNumber alloc] initWithInt:288];
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
	}
}

@end

void XMProcessFrame(const UInt8* data, unsigned length, unsigned sessionID)
{
	[[XMMediaReceiver sharedInstance] _processFrame:data length:length session:sessionID];
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
		[[XMVideoManager sharedInstance] performSelectorOnMainThread:@selector(_handleRemoteImage:) withObject:remoteImage waitUntilDone:NO];
	}
}
