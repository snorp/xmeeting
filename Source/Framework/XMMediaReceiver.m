/*
 * $Id: XMMediaReceiver.m,v 1.13 2006/01/10 15:13:21 hfriederich Exp $
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

- (UInt32)_getH264AVCCAtomLength;
- (void)_createH264AVCCAtomInBuffer:(UInt8 *)buffer;

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
							 videoSize:(XMVideoSize)videoSize;
{
	ComponentResult err = noErr;
	
	err = EnterMoviesOnThread(kQTEnterMoviesFlagDontSetComponentsThreadMode);
	if(err != noErr)
	{
		NSLog(@"EnterMoviesOnThread failed");
	}
	
	videoCodecIdentifier = codecIdentifier;
	videoMediaSize = videoSize;
	
	NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:(unsigned)videoSize];
	[_XMVideoManagerSharedInstance performSelectorOnMainThread:@selector(_handleVideoReceivingStart:)
													withObject:number waitUntilDone:NO];
	[number release];
	
	if(codecIdentifier == XMCodecIdentifier_H264)
	{
		h264SPSAtoms = (XMAtom *)malloc(32 * sizeof(XMAtom));
		h264PPSAtoms = (XMAtom *)malloc(32 * sizeof(XMAtom));
		numberOfH264SPSAtoms = 0;
		numberOfH264PPSAtoms = 0;
	}
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
	
	if(videoCodecIdentifier == XMCodecIdentifier_H264)
	{
		unsigned i;
		
		for(i = 0; i < numberOfH264SPSAtoms; i++)
		{
			free(h264SPSAtoms[i].data);
		}
		
		free(h264SPSAtoms);
		
		for(i = 0; i < numberOfH264PPSAtoms; i++)
		{
			free(h264PPSAtoms[i].data);
		}
		
		free(h264PPSAtoms);
	}
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
				if([self _getH264AVCCAtomLength] == 0)
				{
					NSLog(@"Can't create AVCC atom yet");
					return NO;
				}
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
		
		if(codecType == kH264CodecType)
		{
			UInt32 avccLength = [self _getH264AVCCAtomLength];
			
			Handle avccHandle = NewHandleClear(avccLength);
			[self _createH264AVCCAtomInBuffer:(UInt8 *)*avccHandle];
			
			err = AddImageDescriptionExtension(imageDesc, avccHandle, 'avcC');
			
			DisposeHandle(avccHandle);
		}
		
		ICMDecompressionSessionOptionsRef sessionOptions = NULL;
		err = ICMDecompressionSessionOptionsCreate(NULL, &sessionOptions);
		if(err != noErr)
		{
			NSLog(@"DecompressionSessionOptionsCreate  failed %d", (int)err);
		}
		
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

- (void)_handleH264SPSAtomData:(UInt8 *)data length:(unsigned)length
{
	// Check whether this atom is already stored
	BOOL atomFound = NO;
	unsigned i;
	for(i = 0; i < numberOfH264SPSAtoms; i++)
	{
		UInt16 atomLength = h264SPSAtoms[i].length;
		UInt8 *atomData = h264SPSAtoms[i].data;
		BOOL isSameAtom = YES;
		
		if(atomLength == length)
		{
			unsigned j;
			for(j = 0; j < length; j++)
			{
				if(atomData[j] != data[j])
				{
					isSameAtom = NO;
					break;
				}
			}
		}
		
		if(isSameAtom == YES)
		{
			atomFound = YES;
			break;
		}
	}
	
	if(atomFound == NO)
	{
		UInt8 *atomData = (UInt8 *)malloc(length * sizeof(UInt8));
		memcpy(atomData, data, length);
		h264SPSAtoms[numberOfH264SPSAtoms].length = length;
		h264SPSAtoms[numberOfH264SPSAtoms].data = atomData;
		numberOfH264SPSAtoms++;
	}
}

- (void)_handleH264PPSAtomData:(UInt8 *)data length:(unsigned)length
{
	// Check whether this atom is already stored
	BOOL atomFound = NO;
	unsigned i;
	for(i = 0; i < numberOfH264PPSAtoms; i++)
	{
		UInt16 atomLength = h264PPSAtoms[i].length;
		UInt8 *atomData = h264PPSAtoms[i].data;
		BOOL isSameAtom = YES;
		
		if(atomLength == length)
		{
			unsigned j;
			for(j = 0; j < length; j++)
			{
				if(atomData[j] != data[j])
				{
					isSameAtom = NO;
					break;
				}
			}
		}
		
		if(isSameAtom == YES)
		{
			atomFound = YES;
			break;
		}
	}
	
	if(atomFound == NO)
	{
		UInt8 *atomData = (UInt8 *)malloc(length * sizeof(UInt8));
		memcpy(atomData, data, length);
		h264PPSAtoms[numberOfH264PPSAtoms].length = length;
		h264PPSAtoms[numberOfH264PPSAtoms].data = atomData;
		numberOfH264PPSAtoms++;
	}
}

- (UInt32)_getH264AVCCAtomLength
{
	if(numberOfH264SPSAtoms == 0 || numberOfH264PPSAtoms == 0)
	{
		return 0;
	}
	
	// 1 Byte for configurationVersion, AVCProfileIndication,
	// profile_compatibility, AVCLevelIndication, lengthSizeMinusOne,
	// numOfSequenceParameterSets, numOfPictureParameterSets each.
	unsigned avccLength = 7;
	
	unsigned i;
	for(i = 0; i < numberOfH264SPSAtoms; i++)
	{
		// two bytes for the length of the SPS Atom
		avccLength += 2;
		
		avccLength += h264SPSAtoms[i].length;
	}
	for(i = 0; i < numberOfH264PPSAtoms; i++)
	{
		// two bytes for the length of the PPS Atom
		avccLength += 2;
		
		avccLength += h264PPSAtoms[i].length;
	}
	
	return avccLength;
}

- (void)_createH264AVCCAtomInBuffer:(UInt8 *)buffer
{	
	// Get the required information from the first SPS Atom
	UInt8 *spsAtom = h264SPSAtoms[0].data;
	UInt8 profile = spsAtom[1];
	UInt8 compatibility = spsAtom[2];
	UInt8 level = spsAtom[3];
	
	// configurationVersion is 1
	buffer[0] = 1;
	
	// setting the profile indication
	buffer[1] = profile;
	
	// setting the compatibility indication
	buffer[2] = compatibility;
	
	// setting the level indication
	buffer[3] = level;
	
	// lengthSizeMinusOne is 3 (4 bytes length)
	buffer[4] = 0xff;
	
	// setting the number of SPS atoms
	buffer[5] = numberOfH264SPSAtoms;
	
	unsigned index = 6;
	unsigned i;
	
	for(i = 0; i < numberOfH264SPSAtoms; i++)
	{
		UInt16 length = h264SPSAtoms[i].length;
		UInt8 *data = h264SPSAtoms[i].data;
		
		buffer[index] = (UInt8)(length >> 8);
		buffer[index+1] = (UInt8)(length & 0x00ff);
		
		index += 2;
		
		UInt8 *dest = &(buffer[index]);
		memcpy(dest, data, length);
		
		index += length;
	}
	
	// setting the number of PPS atoms
	buffer[index] = numberOfH264PPSAtoms;
	index++;
	
	for(i = 0; i < numberOfH264PPSAtoms; i++)
	{
		UInt16 length = h264PPSAtoms[i].length;
		UInt8 *data = h264PPSAtoms[i].data;
		
		buffer[index] = (UInt8)(length >> 8);
		buffer[index+1] = (UInt8)(length & 0x00ff);
		
		index += 2;
		
		UInt8 *dest = &(buffer[index]);
		memcpy(dest, data, length);
		
		index += length;
	}
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
