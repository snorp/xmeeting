/*
 * $Id: XMSequenceGrabberVideoInputModule.m,v 1.1 2005/10/06 15:04:42 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMSequenceGrabberVideoInputModule.h"

#define XM_GRAB_WIDTH 352
#define XM_GRAB_HEIGHT 288

// Data Proc that is called whenever the SequenceGrabber
// did grab a frame
static pascal OSErr processGrabDataProc(SGChannel channel,
										Ptr data,
										long length,
										long *offset,
										long channelRefCon,
										TimeValue time,
										short writeType,
										long refCon);

// Proc that is called when the grabbed frame is succcesfully
// decompressed into a CVPixelBufferRef structure
static void processDecompressedFrameProc(void *decompressionTrackingRefCon,
										 OSStatus result,
										 ICMDecompressionTrackingFlags decompressionTrackingFlags,
										 CVPixelBufferRef pixelBuffer, 
										 TimeValue64 displayTime,
										 TimeValue64 displayDuration, 
										 ICMValidTimeFlags validTimeFlags,
										 void* reserved, 
										 void* sourceFrameRefCon);

@interface XMSGDeviceNameIndex : NSObject {
	
	unsigned deviceIndex;
	unsigned inputNameIndex;
	
}

- (id)_initWithDeviceIndex:(unsigned)deviceIndex inputNameIndex:(unsigned)inputNameIndex;

- (unsigned)_deviceIndex;
- (unsigned)_inputNameIndex;

@end

@interface XMSequenceGrabberVideoInputModule (PrivateMethods)

- (BOOL)_startRecording;
- (BOOL)_stopRecording;
- (void)_disposeDecompressionSession;
- (void)_createDecompressionSession;
- (OSErr)_processGrabData:(Ptr)grabData length:(long)length time:(TimeValue)time;
- (void)_processDecompressedFrame:(CVPixelBufferRef)pixelBuffer time:(TimeValue64)time;

@end

@implementation XMSequenceGrabberVideoInputModule

#pragma mark Init & Deallocation Methods

- (id)init
{
	self = [super init];
	
	inputManager = nil;
	
	deviceList = NULL;
	deviceNames = nil;
	deviceNameIndexes = nil;
	
	sequenceGrabber = NULL;
	videoChannel = NULL;
	dataGrabUPP = NULL;
	grabDecompressionSession = NULL;
	lastTime = 0;
	desiredFrameDuration = 0;
	
	frameSize = NSMakeSize(0, 0);
	framesPerSecond = 0;
	
	isGrabbing = NO;
	
	return self;
}

- (void)dealloc
{
	[inputManager release];
	
	[super dealloc];
}

#pragma mark Module Methods

- (NSString *)name
{
	return @"SequenceGrabber Module";
}

- (void)setupWithInputManager:(id<XMVideoInputManager>)theInputManager
{
	ComponentResult err = noErr;
	
	inputManager = [theInputManager retain];
	
	sequenceGrabber = OpenDefaultComponent(SeqGrabComponentType, 0);
	if(sequenceGrabber == NULL)
	{
		NSLog(@"Error opening SequenceGrabber");
	}
	
	err = SGInitialize(sequenceGrabber);
	if(err != noErr)
	{
		NSLog(@"SGInitializeFailed: %d", (int)err);
	}
	
	// we need to explicitely call this function or the code will break
	// although we aren't using any GWorld
	err = SGSetGWorld(sequenceGrabber, NULL, GetMainDevice());
	if(err != noErr)
	{
		NSLog(@"SGSetGWorld failed: %d", (int)err);
	}

	err = SGSetDataRef(sequenceGrabber, 0, 0, seqGrabDontMakeMovie);
	if(err != noErr)
	{
		NSLog(@"SGSetDataRef failed: %d", (int)err);
	}
	
	err = SGNewChannel(sequenceGrabber, VideoMediaType, &videoChannel);
	if(err != noErr)
	{
		NSLog(@"SGNewChannel failed: %d", (int)err);
	}
	
	err = SGSetChannelUsage(videoChannel, seqGrabRecord);
	if(err != noErr)
	{
		NSLog(@"SGSetChannelUsage() failed: %d", err);
	}

	dataGrabUPP = NewSGDataUPP(processGrabDataProc);
	err = SGSetDataProc(sequenceGrabber,
						dataGrabUPP,
						(long)self);
	if(err != noErr)
	{
		NSLog(@"SGSetDataProc failed: %d", (int)err);
	}
}

- (void)closeModule
{
	ComponentResult err = noErr;
	
	err = SGDisposeChannel(sequenceGrabber, videoChannel);
	if(err != noErr)
	{
		NSLog(@"SGDisposeChannel() failed: %d", (int)err);
	}
	videoChannel = NULL;
	
	err = CloseComponent(sequenceGrabber);
	if(err != noErr)
	{
		NSLog(@"CloseComponent() failed: %d", (int)err);
	}
	sequenceGrabber = NULL;
	
	DisposeSGDataUPP(dataGrabUPP);
	dataGrabUPP = NULL;
	
	[inputManager release];
	inputManager = nil;
}

- (NSArray *)inputDevices
{
	if(deviceNames == nil)
	{
		ComponentResult err = noErr;
		
		err = SGGetChannelDeviceList(videoChannel, sgDeviceListIncludeInputs, &deviceList);
		if(err != noErr)
		{
			NSLog(@"SGGetChannelDeviceList failed: %d", (int)err);
			return nil;
		}
		
		SGDeviceListRecord *deviceListRecord = (*deviceList);
		NSMutableArray *namesArray = [[NSMutableArray alloc] initWithCapacity:deviceListRecord->count];
		NSMutableArray *indexArray = [[NSMutableArray alloc] initWithCapacity:deviceListRecord->count];
		unsigned i;
		
		for(i = 0; i < deviceListRecord->count; i++)
		{
			SGDeviceName deviceName = deviceListRecord->entry[i];
			
			if(deviceName.inputs != NULL)
			{
				unsigned j;
				SGDeviceInputListRecord *inputListRecord = *deviceName.inputs;
				
				for(j = 0; j < inputListRecord->count; j++)
				{
					// this structure contains the actual human understandable name
					SGDeviceInputName deviceInputName = inputListRecord->entry[j];
					NSString *name = [[NSString alloc] initWithCString:(const char *)deviceInputName.name encoding:NSASCIIStringEncoding];
					
					// adding the name to the object
					[namesArray addObject:name];
					[name release];
					
					// caching the index of this device
					XMSGDeviceNameIndex *deviceNameIndex = [[XMSGDeviceNameIndex alloc] _initWithDeviceIndex:i
																							  inputNameIndex:j];
					[indexArray addObject:deviceNameIndex];
				}
			}
		}
		
		deviceNames = [namesArray copy];
		deviceNameIndexes = [indexArray copy];
		
		[namesArray release];
		[indexArray release];
	}
	
	return deviceNames;
}

- (void)refreshDeviceList
{
	[deviceNames release];
	deviceNames = nil;
	[deviceNameIndexes release];
	deviceNameIndexes = nil;
	
	if(deviceList != NULL)
	{
		ComponentResult err = noErr;
		
		err = SGDisposeDeviceList(sequenceGrabber, deviceList);
		deviceList = NULL;
		
		if(err != noErr)
		{
			NSLog(@"SGDisposeDeviceList failed: %d", (int)err);
		}
	}
}

- (BOOL)openInputDevice:(NSString *)device
{
	if([self inputDevices] == nil)
	{
		// error occured, already reported
		return NO;
	}
	
	unsigned index = [deviceNames indexOfObject:device];
	
	if(index == NSNotFound)
	{
		// reporting the error here
		NSLog(@"Device %@ not found!", device);
		return NO;
	}
	
	XMSGDeviceNameIndex *deviceNameIndex = [deviceNameIndexes objectAtIndex:index];
	unsigned deviceIndex = [deviceNameIndex _deviceIndex];
	unsigned inputNameIndex = [deviceNameIndex _inputNameIndex];
	
	SGDeviceListRecord *deviceListRecord = *deviceList;
	SGDeviceName deviceName = deviceListRecord->entry[deviceIndex];
	
	ComponentResult err = noErr;
	
	// we have to use the name of the device, not the input device name itself
	err = SGSetChannelDevice(videoChannel, deviceName.name);
	if(err != noErr)
	{
		NSLog(@"SGSetChannelDevice failed: %d", (int)err);
		return NO;
	}
	
	// now we can set the actual input device by its index
	err = SGSetChannelDeviceInput(videoChannel, inputNameIndex);
	if(err != noErr)
	{
		NSLog(@"SGSetChannelDeviceInput failed: %d", (int)err);
		return NO;
	}
	
	[self _startRecording];
	
	isGrabbing = YES;
	
	return YES;
}

- (BOOL)closeInputDevice
{
	[self _stopRecording];
	
	isGrabbing = NO;
	
	return YES;
}

- (BOOL)setInputFrameSize:(NSSize)theFrameSize
{
	frameSize = theFrameSize;
	
	if(isGrabbing == YES)
	{
		NSLog(@"changin");
		//[self _stopRecording];
		//[self _startRecording];
		[self _disposeDecompressionSession];
		[self _createDecompressionSession];
		
	}
	return YES;
}

- (void)setFrameGrabRate:(unsigned)theFramesPerSecond
{
	framesPerSecond = theFramesPerSecond;

	desiredFrameDuration = timeScale / framesPerSecond;
}

- (void)grabFrame
{
	ComponentResult err = noErr;
	
	err = SGIdle(sequenceGrabber);
	
	if(err != noErr)
	{
		NSLog(@"SGIdle() failed: %d", (int)err);
	}
}

- (NSString *)descriptionForErrorCode:(unsigned)errorCode device:(NSString *)device
{
	return @"No Description";
}

#pragma mark Private Methods

- (BOOL)_startRecording
{
	ComponentResult err = noErr;
	
	Rect rect;
	rect.top = 0;
	rect.left = 0;
	rect.bottom = XM_GRAB_HEIGHT;
	rect.right = XM_GRAB_WIDTH;
	
	err = SGSetChannelBounds(videoChannel, &rect);
	if(err != noErr)
	{
		NSLog(@"SGSetChannelBounds failed: %d", (int)err);
		return NO;
	}
	
	err = SGPrepare(sequenceGrabber, false, true);
	if(err != noErr)
	{
		NSLog(@"SGPrepare() failed: %d", (int)err);
		return NO;
	}
	
	err = SGStartRecord(sequenceGrabber);
	if(err != noErr)
	{
		NSLog(@"SGStartRecord() failed: %d", (int)err);
		return NO;
	}

	lastTime = 0;
	timeScale = 0;
	
	[self _createDecompressionSession];

	return YES;
}

- (BOOL)_stopRecording
{
	ComponentResult err = noErr;
	
	err = SGStop(sequenceGrabber);
	if(err != noErr)
	{
		NSLog(@"SGStop() failed: %d", (int)err);
		return NO;
	}
	
	[self _disposeDecompressionSession];
	
	return YES;
}

- (void)_disposeDecompressionSession
{
	ICMDecompressionSessionRelease(grabDecompressionSession);
	grabDecompressionSession = NULL;
}

- (void)_createDecompressionSession
{
	ComponentResult err = noErr;
	
	ImageDescriptionHandle imageDesc = (ImageDescriptionHandle)NewHandle(0);
	err = SGGetChannelSampleDescription(videoChannel, (Handle)imageDesc);
	if(err != noErr)
	{
		NSLog(@"SGGetChannelSampleDescription err: %d", (int)err);
	}
	
	NSNumber *number = nil;
	NSMutableDictionary *pixelBufferAttributes = nil;
	
	pixelBufferAttributes = [[NSMutableDictionary alloc] initWithCapacity:5];
	
	// Setting the Width / Height for the buffer
	number = [[NSNumber alloc] initWithInt:frameSize.width];
	[pixelBufferAttributes setObject:number forKey:(NSString *)kCVPixelBufferWidthKey];
	[number release];
	
	number = [[NSNumber alloc] initWithInt:frameSize.height];
	[pixelBufferAttributes setObject:number forKey:(NSString *)kCVPixelBufferHeightKey];
	[number release];
	
	number = [[NSNumber alloc] initWithInt:k32ARGBPixelFormat];
	[pixelBufferAttributes setObject:number forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
	[number release];
	
	ICMDecompressionTrackingCallbackRecord trackingCallbackRecord;
	trackingCallbackRecord.decompressionTrackingCallback = processDecompressedFrameProc;
	trackingCallbackRecord.decompressionTrackingRefCon = (void *)self;
	
	err = ICMDecompressionSessionCreate(NULL, imageDesc, NULL,
										(CFDictionaryRef)pixelBufferAttributes,
										&trackingCallbackRecord,
										&grabDecompressionSession);
	if(err != noErr)
	{
		NSLog(@"ICMDecompSessionCreate failed: %d", (int)err);
	}
	
	[pixelBufferAttributes release];
	DisposeHandle((Handle)imageDesc);
}

- (OSErr)_processGrabData:(Ptr)data length:(long)length
					 time:(TimeValue)time
{
	ComponentResult err = noErr;
	
	didCallCallback = YES;
	
	if(timeScale == 0)
	{
		err = SGGetChannelTimeScale(videoChannel, &timeScale);
		if(err != noErr)
		{
			NSLog(@"SGGetChannelTimeScale failed: %d", (int)err);
		}
		
		// we use this value to determine whether to drop a frame or not.
		// this is necessary since SGIdle() does produce frames quite
		// unregularly, sometimes even twice per call
		desiredFrameDuration = timeScale / framesPerSecond;
	}
	
	// determining whether to drop the frame or not.
	// we leave a tolerance of half the desiredFrameDuration in
	// order not to drop a frame which is arriving only sligthly
	// before the minimum frame duration
	if(((time - lastTime) < (desiredFrameDuration * 0.5)) && (lastTime > 0))
	{
		// Dropping the frame
		NSLog(@"Dropping");
		return noErr;
	}
	
	if(grabDecompressionSession == NULL)
	{
		NSLog(@"noDecompressionSession");
		return noErr;
	}
	
	err = ICMDecompressionSessionDecodeFrame(grabDecompressionSession,
											 (UInt8 *)data, length,
											 NULL, NULL,
											 (void *)self);
	if(err != noErr)
	{
		NSLog(@"ICMDecompressionDecodeFrame failed: %d", (int)err);
	}
	
	lastTime = time;
	
	return err;
}

- (void)_processDecompressedFrame:(CVPixelBufferRef)pixelBuffer time:(TimeValue64)time
{
	[inputManager handleGrabbedFrame:pixelBuffer time:time];
}

@end

@implementation XMSGDeviceNameIndex

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	return nil;
}

- (id)_initWithDeviceIndex:(unsigned)theDeviceIndex inputNameIndex:(unsigned)theInputNameIndex
{
	self = [super init];
	
	deviceIndex = theDeviceIndex;
	inputNameIndex = theInputNameIndex;
	
	return self;
}

- (unsigned)_deviceIndex
{
	return deviceIndex;
}

- (unsigned)_inputNameIndex
{
	return inputNameIndex;
}

@end

static pascal OSErr processGrabDataProc(SGChannel channel,
										Ptr data,
										long length,
										long *offset,
										long channelRefCon,
										TimeValue time,
										short writeType,
										long refCon)
{
#pragma unused(channel, offset, channelRefCon, writeType)
	
	ComponentResult err = noErr;
	
	XMSequenceGrabberVideoInputModule *module = (XMSequenceGrabberVideoInputModule *)refCon;
	err = [module _processGrabData:data length:length time:time];
	if(err != noErr)
	{
		NSLog(@"_processGrabData failed: %d", (int)err);
	}
	
	return err;
}

static void processDecompressedFrameProc(void *decompressionTrackingRefCon,
										 OSStatus result,
										 ICMDecompressionTrackingFlags decompressionTrackingFlags,
										 CVPixelBufferRef pixelBuffer, 
										 TimeValue64 displayTime,
										 TimeValue64 displayDuration, 
										 ICMValidTimeFlags validTimeFlags,
										 void* reserved, 
										 void* sourceFrameRefCon)
{
	if((kICMDecompressionTracking_EmittingFrame & decompressionTrackingFlags) && pixelBuffer)
	{
		XMSequenceGrabberVideoInputModule *module = (XMSequenceGrabberVideoInputModule *)sourceFrameRefCon;
		[module _processDecompressedFrame:pixelBuffer 
									 time:displayTime];
	}
}
