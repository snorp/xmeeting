/*
 * $Id: XMMediaReceiver.m,v 1.29 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#import "XMMediaReceiver.h"

#import "XMPrivate.h"
#import "XMUtils.h"
#import "XMVideoManager.h"
#import "XMCallbackBridge.h"
#import "XMBridge.h"

#define XM_PACKET_POOL_GRANULARITY 16
#define XM_CHUNK_BUFFER_SIZE 352*288*4

#define scanBit() \
mask >>= 1; \
if (mask == 0) { \
  dataIndex++; \
  mask = 0x80; \
}

#define readBit() \
bit = data[dataIndex] & mask; \
scanBit();

#define scanExpGolombSymbol() \
zero_counter = 0; \
readBit(); \
while (bit == 0) { \
  zero_counter++; \
  readBit(); \
} \
while (zero_counter != 0) { \
  zero_counter--; \
  scanBit(); \
}

#define readExpGolombSymbol() \
zero_counter = 0; \
readBit(); \
while (bit == 0) { \
  zero_counter++; \
  readBit(); \
} \
expGolombSymbol = (0x01 << zero_counter); \
while (zero_counter != 0) { \
  zero_counter--; \
  readBit(); \
  if (bit != 0) { \
    expGolombSymbol |= (0x01 << zero_counter); \
  } \
} \
expGolombSymbol -= 1;

@interface XMMediaReceiver (PrivateMethods)

- (UInt32)_getH264AVCCAtomLength;
- (NSSize)_getH261VideoSize:(UInt8 *)frame length:(UInt32)length videoSize:(XMVideoSize *)size;
- (NSSize)_getH263VideoSize:(UInt8 *)frame length:(UInt32)length videoSize:(XMVideoSize *)size;
- (NSSize)_getH264VideoSize:(XMVideoSize *)size;
- (void)_createH264AVCCAtomInBuffer:(UInt8 *)buffer;

- (void)_releaseDecompressionSession;

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
  videoImageDescription = NULL;
	
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

- (void)_startMediaReceivingForSession:(unsigned)sessionID withCodec:(XMCodecIdentifier)codecIdentifier;
{
  ComponentResult err = noErr;
	
  err = EnterMoviesOnThread(kQTEnterMoviesFlagDontSetComponentsThreadMode);
  if (err != noErr) {
    NSLog(@"EnterMoviesOnThread failed");
  }
	
  videoCodecIdentifier = codecIdentifier;
	
  if (codecIdentifier == XMCodecIdentifier_H264) {
    h264SPSAtoms = (XMAtom *)malloc(32 * sizeof(XMAtom));
    h264PPSAtoms = (XMAtom *)malloc(32 * sizeof(XMAtom));
    numberOfH264SPSAtoms = 0;
    numberOfH264PPSAtoms = 0;
  }
}

- (void)_stopMediaReceivingForSession:(unsigned)sessionID
{	
  [self _releaseDecompressionSession];
	
  [_XMVideoManagerSharedInstance performSelectorOnMainThread:@selector(_handleVideoReceivingEnd)
													withObject:nil waitUntilDone:NO];
  ExitMoviesOnThread();
	
  if (videoCodecIdentifier == XMCodecIdentifier_H264) {
		
    for (unsigned i = 0; i < numberOfH264SPSAtoms; i++) {
      free(h264SPSAtoms[i].data);
    }
		
    free(h264SPSAtoms);
		
    for (unsigned i = 0; i < numberOfH264PPSAtoms; i++) {
      free(h264PPSAtoms[i].data);
    }
		
    free(h264PPSAtoms);
  }
}

- (BOOL)_decodeFrameForSession:(unsigned)sessionID data:(UInt8 *)data length:(unsigned)length callToken:(const char *)callToken
{
  ComponentResult err = noErr;
	
  if (videoDecompressionSession == NULL) {
    CodecType codecType;
    char *codecName;
		
    NSSize videoDimensions;
    XMVideoSize videoMediaSize;
		
    switch (videoCodecIdentifier) {
      case XMCodecIdentifier_H261:
        codecType = kH261CodecType;
        codecName = "H.261";
        videoDimensions = [self _getH261VideoSize:data length:length videoSize:&videoMediaSize];
        break;
      case XMCodecIdentifier_H263:
        codecType = kH263CodecType;
        codecName = "H.263";
        videoDimensions = [self _getH263VideoSize:data length:length videoSize:&videoMediaSize];
        break;
      case XMCodecIdentifier_H264:
        codecType =  kH264CodecType;
        codecName = "H.264";
        if ([self _getH264AVCCAtomLength] == 0) {
          NSLog(@"Can't create AVCC atom yet");
          return NO;
        } else {
          videoDimensions = [self _getH264VideoSize:&videoMediaSize];
        }
        break;
      default:
        return NO;
    }
		
    if (videoMediaSize == XMVideoSize_NoVideo) {
      _XMLogMessage("No valid video data size");
      return NO;
    }
		
    videoImageDescription = (ImageDescriptionHandle)NewHandleClear(sizeof(**videoImageDescription)+4);
    (**videoImageDescription).idSize = sizeof( **videoImageDescription)+4;
    (**videoImageDescription).cType = codecType;
    (**videoImageDescription).resvd1 = 0;
    (**videoImageDescription).resvd2 = 0;
    (**videoImageDescription).dataRefIndex = 0;
    (**videoImageDescription).version = 1;
    (**videoImageDescription).revisionLevel = 1;
    (**videoImageDescription).vendor = 'XMet';
    (**videoImageDescription).temporalQuality = codecNormalQuality;
    (**videoImageDescription).spatialQuality = codecNormalQuality;
    (**videoImageDescription).width = (short)videoDimensions.width;
    (**videoImageDescription).height = (short)videoDimensions.height;
    (**videoImageDescription).hRes = Long2Fix(72);
    (**videoImageDescription).vRes = Long2Fix(72);
    (**videoImageDescription).dataSize = 0;
    (**videoImageDescription).frameCount = 1;
    (**videoImageDescription).depth = 24;
    (**videoImageDescription).clutID = -1;
		
    if (codecType == kH264CodecType) {
      UInt32 avccLength = [self _getH264AVCCAtomLength];
			
      Handle avccHandle = NewHandleClear(avccLength);
      [self _createH264AVCCAtomInBuffer:(UInt8 *)*avccHandle];
			
      err = AddImageDescriptionExtension(videoImageDescription, avccHandle, 'avcC');
			
      DisposeHandle(avccHandle);
    }
		
    ICMDecompressionSessionOptionsRef sessionOptions = NULL;
    err = ICMDecompressionSessionOptionsCreate(NULL, &sessionOptions);
    if (err != noErr) {
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
		
    err = ICMDecompressionSessionCreate(NULL, videoImageDescription, sessionOptions,
                                        (CFDictionaryRef)pixelBufferAttributes,
                                        &trackingCallbackRecord, &videoDecompressionSession);
    if (err != noErr) {
      NSLog(@"Creating of the decompressionSession failed %d", (int)err);
    }
		
    [pixelBufferAttributes release];
    ICMDecompressionSessionOptionsRelease(sessionOptions);
		
    NSNumber *sizeNumber = [[NSNumber alloc] initWithUnsignedInt:(unsigned)videoMediaSize];
    NSNumber *widthNumber = [[NSNumber alloc] initWithUnsignedInt:(unsigned)videoDimensions.width];
    NSNumber *heightNumber = [[NSNumber alloc] initWithUnsignedInt:(unsigned)videoDimensions.height];
    NSArray *array = [[NSArray alloc] initWithObjects:sizeNumber, widthNumber, heightNumber, nil];
		
    [_XMVideoManagerSharedInstance performSelectorOnMainThread:@selector(_handleVideoReceivingStart:)
                                                    withObject:array waitUntilDone:NO];
    [array release];
    [sizeNumber release];
    [widthNumber release];
    [heightNumber release];
		
    // Informing the application that we've started sending a certain codec. This is done here since
    // in case of H.264, the size has to be extracted from the SPS atom.
    _XMHandleVideoStreamOpened(callToken, codecName, videoMediaSize, true, (unsigned)videoDimensions.width, (unsigned)videoDimensions.height);
  }
  err = ICMDecompressionSessionDecodeFrame(videoDecompressionSession,
                                           data, length,
                                           NULL, NULL,
                                           (void *)self);
  // before responding to any errors received,
  // handle the frame recording
  BOOL needsIFrame = ![_XMCallRecorderSharedInstance _handleCompressedRemoteVideoFrame:data
                                                                                length:length
                                                                      imageDescription:videoImageDescription];
	
  if (err != noErr || needsIFrame == YES) {
    if (err == qErr && videoCodecIdentifier == XMCodecIdentifier_H263) {
      // H.263 will display a green picture in this case.
      // Workaround: release and recreate the decompression session.
      // Hopefully, the remote pary will send an I-frame soon
      [self _releaseDecompressionSession];
    }
    return NO;
  }
  return YES;
}

- (void)_handleH264SPSAtomData:(UInt8 *)data length:(unsigned)length
{
  // Check whether this atom is already stored
  BOOL atomFound = NO;
  for (unsigned i = 0; i < numberOfH264SPSAtoms; i++) {
    UInt16 atomLength = h264SPSAtoms[i].length;
    UInt8 *atomData = h264SPSAtoms[i].data;
    BOOL isSameAtom = YES;
		
    if (atomLength == length) {
      for (unsigned j = 0; j < length; j++) {
        if (atomData[j] != data[j]) {
          isSameAtom = NO;
          break;
        }
      }
    }
		
    if (isSameAtom == YES) {
      atomFound = YES;
      break;
    }
  }
	
  if (atomFound == NO) {
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
	for (unsigned i = 0; i < numberOfH264PPSAtoms; i++) {
    UInt16 atomLength = h264PPSAtoms[i].length;
    UInt8 *atomData = h264PPSAtoms[i].data;
    BOOL isSameAtom = YES;
		
    if (atomLength == length) {
      for (unsigned j = 0; j < length; j++) {
        if (atomData[j] != data[j]) {
          isSameAtom = NO;
          break;
        }
      }
    }
		
    if (isSameAtom == YES) {
      atomFound = YES;
      break;
    }
  }
	
  if (atomFound == NO) {
    UInt8 *atomData = (UInt8 *)malloc(length * sizeof(UInt8));
    memcpy(atomData, data, length);
    h264PPSAtoms[numberOfH264PPSAtoms].length = length;
    h264PPSAtoms[numberOfH264PPSAtoms].data = atomData;
    numberOfH264PPSAtoms++;
  }
}

- (UInt32)_getH264AVCCAtomLength
{
  if (numberOfH264SPSAtoms == 0 || numberOfH264PPSAtoms == 0) {
    return 0;
  }
	
  // 1 Byte for configurationVersion, AVCProfileIndication,
  // profile_compatibility, AVCLevelIndication, lengthSizeMinusOne,
  // numOfSequenceParameterSets, numOfPictureParameterSets each.
  unsigned avccLength = 7;
	
	//for (i = 0; i < numberOfH264SPSAtoms; i++)
	for (unsigned i = 0; i < 1; i++) {
    // two bytes for the length of the SPS Atom
    avccLength += 2;
		
    avccLength += h264SPSAtoms[i].length;
  }
  //for (i = 0; i < numberOfH264PPSAtoms; i++)
	for (unsigned i = 0; i < 1; i++) {
    // two bytes for the length of the PPS Atom
    avccLength += 2;
		
    avccLength += h264PPSAtoms[i].length;
  }
	
  return avccLength;
}

- (NSSize)_getH261VideoSize:(UInt8 *)frame length:(UInt32)length videoSize:(XMVideoSize *)size;
{
  UInt8 *data = frame;
  UInt32 dataIndex = 0;
  UInt8 mask = 0x80;
  UInt8 bit;
	
  if (length < 4) {
    *size = XMVideoSize_NoVideo;
    return NSMakeSize(0, 0);
  }
	
  if (frame[0] == 0 &&
      frame[1] == 0 &&
      frame[2] == 0 &&
      frame[3] == 0) {
    *size = XMVideoSize_NoVideo;
    return NSMakeSize(0, 0);
  }
	
  // determining the PSC location
  readBit();
  while (bit == 0) {
    readBit();
  }
	
  // check whether it is PSC
  readBit();
  if (bit != 0) {
    *size = XMVideoSize_NoVideo;
    return NSMakeSize(0, 0);
  }
  readBit();
  if (bit != 0) {
    *size = XMVideoSize_NoVideo;
    return NSMakeSize(0, 0);
  }
  readBit();
  if (bit != 0) {
    *size = XMVideoSize_NoVideo;
    return NSMakeSize(0, 0);
  }
  readBit();
  if (bit != 0) {
    *size = XMVideoSize_NoVideo;
    return NSMakeSize(0, 0);
  }
	
  // scanning past TR, SplitScreenIndicator, DocumentCameraIndicator, FreezePictureRelease
  dataIndex++;

  readBit();
  if (bit == 0) {
    *size = XMVideoSize_QCIF;
    return XMVideoSizeToDimensions(XMVideoSize_QCIF);
  } else {
    *size = XMVideoSize_CIF;
    return XMVideoSizeToDimensions(XMVideoSize_CIF);
  }
}

- (NSSize)_getH263VideoSize:(UInt8 *)frame length:(UInt32)length videoSize:(XMVideoSize *)videoSize
{	
  if (length < 5) {
    *videoSize = XMVideoSize_NoVideo;
    return NSMakeSize(0, 0);
  }
	
  if (frame[0] == 0 &&
      frame[1] == 0 &&
      frame[2] == 0 &&
      frame[3] == 0 &&
      frame[4] == 0) {
    *videoSize = XMVideoSize_NoVideo;
    return NSMakeSize(0, 0);
  }
	
  if (frame[0] != 0 ||
      frame[1] != 0) {
    *videoSize = XMVideoSize_NoVideo;
    return NSMakeSize(0, 0);
  }
	
  UInt8 *data = frame;
  UInt32 dataIndex = 2;
  UInt8 mask = 0x80;
  UInt8 bit;
	
  do {
    readBit();
  } while (bit == 0);
	
  dataIndex += 2;
  scanBit();
  scanBit();
	
  UInt8 size = 0;
  readBit();
  if (bit) {
    size |= 0x04;
  }
  readBit();
  if (bit) {
    size |= 0x02;
  }
  readBit();
  if (bit) {
    size |= 0x01;
  }
	
  if (size == 1) {
    *videoSize = XMVideoSize_SQCIF;
    return XMVideoSizeToDimensions(XMVideoSize_SQCIF);
  } else if (size == 2) {
    *videoSize = XMVideoSize_QCIF;
    return XMVideoSizeToDimensions(XMVideoSize_QCIF);
  } else if (size == 3) {
    *videoSize = XMVideoSize_CIF;
    return XMVideoSizeToDimensions(XMVideoSize_CIF);
  } else {
    *videoSize = XMVideoSize_NoVideo;
    return NSMakeSize(0, 0);
  }
}

- (NSSize)_getH264VideoSize:(XMVideoSize *)size
{
  if (numberOfH264SPSAtoms == 0) {
    *size = XMVideoSize_NoVideo;
    return NSMakeSize(0, 0);
  }
	
  const UInt8 *data = h264SPSAtoms[0].data;
  UInt32 dataIndex;
  UInt8 mask;
  UInt8 bit;
  UInt8 zero_counter;
  UInt8 expGolombSymbol;
		
  // starting at byte 5 since the four first bytes are fixed-size
  dataIndex = 4;
  mask = 0x80;
	
  // scanning past seq_parameter_set_id
  scanExpGolombSymbol();
	
  // scanning past log2_max_frame_num_minus_4
  scanExpGolombSymbol();
  //readExpGolombSymbol();
	
  //reading pic_order_cnt_type
  readExpGolombSymbol();
	
  if (expGolombSymbol == 0) {
    // scanning past log2_max_pic_order_cnt_lsb_minus4
    scanExpGolombSymbol();
  } else if (expGolombSymbol == 1) {
    // scanning past delta_pic_order_always_zero_flag
    scanBit();
		
    // scanning past offset_for_non_ref_pic
    scanExpGolombSymbol();
		
    // scanning past offset_for_top_to_bottom_field
    scanExpGolombSymbol();
		
    // reading num_ref_frames_in_pic_order_cnt_cycle
    readExpGolombSymbol();
		
    for (UInt32 i = 0; i < expGolombSymbol; i++) {
      // scanning past offset_for_ref_frame[i]
      scanExpGolombSymbol();
    }
  }
	
  // scanning past num_ref_frames
  scanExpGolombSymbol();
	
  // scanning past gaps_in_frame_num_value_allowed_flag
  scanBit();
	
  // reading pic_width_in_mbs_minus1
  readExpGolombSymbol();
  UInt8 picWidthMinus1 = expGolombSymbol;
	
  // reading pic_height_in_mbs_minus1
  readExpGolombSymbol();
  UInt8 picHeightMinus1 = expGolombSymbol;
	
  if (picWidthMinus1 == 21 && picHeightMinus1 == 17) {
    *size = XMVideoSize_CIF;
    return XMVideoSizeToDimensions(XMVideoSize_CIF);
  } else if (picWidthMinus1 == 10 && picHeightMinus1 == 8) {
    *size = XMVideoSize_QCIF;
    return XMVideoSizeToDimensions(XMVideoSize_QCIF);
  }
	
  // Return XMVideoSize_Custom and the actual size
  *size = XMVideoSize_Custom;
  return NSMakeSize(((picWidthMinus1+1)*16), ((picHeightMinus1+1)*16));
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
	
  // There is only ever one SPS atom, or QuickTime will not
  // understand the AVCC structure
  buffer[5] = 1;
	
  unsigned index = 6;
	
  UInt16 length = h264SPSAtoms[0].length;
  UInt8 *data = h264SPSAtoms[0].data;
		
  buffer[index] = (UInt8)(length >> 8);
  buffer[index+1] = (UInt8)(length & 0x00ff);
		
  index += 2;
		
  UInt8 *dest = &(buffer[index]);
  memcpy(dest, data, length);
		
  index += length;
	
  // There is only ever one PPS atom, or QuickTime will not
  // understand the AVCC structure
  buffer[index] = 1;
  index++;
	
  length = h264PPSAtoms[0].length;
  data = h264PPSAtoms[0].data;
		
  buffer[index] = (UInt8)(length >> 8);
  buffer[index+1] = (UInt8)(length & 0x00ff);
		
  index += 2;
	
  dest = &(buffer[index]);
  memcpy(dest, data, length);
	
  index += length;
	
  printf("********\nReceived SPS and PPS Atoms:\n");
	for (unsigned i = 0; i < numberOfH264SPSAtoms; i++) {
    UInt8 *data = h264SPSAtoms[i].data;
    printf("SPS [%d]\n", i);
    for (unsigned j = 0; j < h264SPSAtoms[i].length; j++) {
      printf("%x ", data[j]);
    }
    printf("\n");
  }

  for (unsigned i = 0; i < numberOfH264PPSAtoms; i++) {
    UInt8 *data = h264PPSAtoms[i].data;
    printf("PPS [%d]\n", i);
    for (unsigned j = 0; j < h264PPSAtoms[i].length; j++) {
      printf("%x ", data[j]);
    }
    printf("\n");
  }
  printf("********\n");
	
  NSLog(@"Created AVCC Atom. There are %d SPS and %d PPS atoms to choose", numberOfH264SPSAtoms, numberOfH264PPSAtoms);
}

- (void)_releaseDecompressionSession
{
  if (videoDecompressionSession != NULL) {
    ICMDecompressionSessionRelease(videoDecompressionSession);
    videoDecompressionSession = NULL;
  }
	
  if (videoImageDescription != NULL) {
    DisposeHandle((Handle)videoImageDescription);
    videoImageDescription = NULL;
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
  if ((kICMDecompressionTracking_EmittingFrame & decompressionTrackingFlags) && pixelBuffer != NULL) {
    [_XMVideoManagerSharedInstance _handleRemoteVideoFrame:pixelBuffer];
  }
}
