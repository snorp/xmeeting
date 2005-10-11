/*
 * $Id: XMSequenceGrabberVideoInputModule.m,v 1.2 2005/10/11 09:03:10 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMSequenceGrabberVideoInputModule.h"

#define XM_GRAB_WIDTH 352
#define XM_GRAB_HEIGHT 288

#define XM_CALLBACK_NEVER_CALLED 0
#define XM_CALLBACK_NOT_CALLED 1
#define XM_CALLBACK_CALLED 2
#define XM_CALLBACK_ERROR_REPORTED 4

// Data Proc that is called whenever the SequenceGrabber
// did grab a frame
static pascal OSErr XMSGProcessGrabDataProc(SGChannel channel,
											Ptr data,
											long length,
											long *offset,
											long channelRefCon,
											TimeValue time,
											short writeType,
											long refCon);

// Proc that is called when the grabbed frame is succcesfully
// decompressed into a CVPixelBufferRef structure
static void XMSGProcessDecompressedFrameProc(void *decompressionTrackingRefCon,
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

- (void)_openAndConfigureSeqGrabComponent;
- (void)_disposeSeqGrabComponent;
- (BOOL)_openAndConfigureChannel;
- (BOOL)_createDecompressionSession;
- (BOOL)_disposeDecompressionSession;
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
	selectedDevice = nil;
	
	sequenceGrabber = NULL;
	videoChannel = NULL;
	dataGrabUPP = NULL;
	grabDecompressionSession = NULL;
	lastTime = 0;
	desiredFrameDuration = 0;
	
	frameSize = NSMakeSize(0, 0);
	framesPerSecond = 0;
	
	isGrabbing = NO;
	callbackMissCounter = 0;
	callbackStatus = XM_CALLBACK_NEVER_CALLED;
	
	return self;
}

- (void)dealloc
{
	[inputManager release];
	[deviceNames release];
	[deviceNameIndexes release];
	[selectedDevice release];
	
	[super dealloc];
}

#pragma mark Module Methods

- (NSString *)name
{
	return @"SequenceGrabber Module";
}

- (void)setupWithInputManager:(id<XMVideoInputManager>)theInputManager
{
	inputManager = [theInputManager retain];
	
	[self _openAndConfigureSeqGrabComponent];
}

- (void)closeModule
{
	[self _disposeSeqGrabComponent];
	
	[inputManager release];
	inputManager = nil;
}

- (NSArray *)inputDevices
{
	if(deviceNames == nil)
	{
		ComponentResult err = noErr;
		unsigned hintCode = 0;
		
		if(videoChannel == NULL)
		{
			// it wasn't possible to create the SGChannel, indicating
			// that no video device is plugged in.
			deviceNames = [[NSArray alloc] init];
		}
		else
		{
			err = SGGetChannelDeviceList(videoChannel, sgDeviceListIncludeInputs, &deviceList);
			if(err != noErr)
			{
				hintCode = 0x002001;
				[inputManager handleErrorWithCode:err hintCode:hintCode];
				
				deviceNames = [[NSArray alloc] init];
			}
			else
			{
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
							NSString *name = [[NSString alloc] initWithCString:(const char *)deviceInputName.name 
																	  encoding:NSASCIIStringEncoding];
					
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
		}
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
		unsigned hintCode;
		
		err = SGDisposeDeviceList(sequenceGrabber, deviceList);
		deviceList = NULL;
		
		if(err != noErr)
		{
			hintCode = 0x003001;
			[inputManager handleErrorWithCode:err hintCode:hintCode];
		}
	}
	
	// In case we've failed to create a SGChannel previously, due
	// to the lack of an attached video device, we'll try again here
	if(videoChannel == NULL)
	{
		if([self _openAndConfigureChannel] == NO)
		{
			videoChannel = NULL;
		}
	}
}

- (BOOL)openInputDevice:(NSString *)device
{	
	ComponentResult err = noErr;
	unsigned hintCode = 0;
	
	unsigned index = [deviceNames indexOfObject:device];
	
	if(index == NSNotFound)
	{
		// reporting the error here
		err = -1;
		hintCode = 0x004001;
		goto bail;
	}
	
	selectedDevice = [device retain];
	
	XMSGDeviceNameIndex *deviceNameIndex = [deviceNameIndexes objectAtIndex:index];
	unsigned deviceIndex = [deviceNameIndex _deviceIndex];
	unsigned inputNameIndex = [deviceNameIndex _inputNameIndex];
	
	SGDeviceListRecord *deviceListRecord = *deviceList;
	SGDeviceName deviceName = deviceListRecord->entry[deviceIndex];
	
	// we have to use the name of the device, not the input device name itself
	err = SGSetChannelDevice(videoChannel, deviceName.name);
	if(err != noErr)
	{
		hintCode = 0x004002;
		goto bail;
	}
	
	// now we can set the actual input device by its index
	err = SGSetChannelDeviceInput(videoChannel, inputNameIndex);
	if(err != noErr)
	{
		hintCode = 0x004003;
		goto bail;
	}
	
	Rect rect;
	rect.top = 0;
	rect.left = 0;
	rect.bottom = XM_GRAB_HEIGHT;
	rect.right = XM_GRAB_WIDTH;
	err = SGSetChannelBounds(videoChannel, &rect);
	if(err != noErr)
	{
		hintCode = 0x004004;
		goto bail;
	}
	
	err = SGPrepare(sequenceGrabber, false, true);
	if(err != noErr)
	{
		hintCode = 0x004005;
		goto bail;
	}
	
	err = SGStartRecord(sequenceGrabber);
	if(err != noErr)
	{
		hintCode = 0x004006;
		goto bail;
	}
	
	err = SGGetChannelTimeScale(videoChannel, &timeScale);
	if(err != noErr)
	{
		NSLog(@"SGGetChannelTimeScale failed(1): %d", (int)err);
	}
	
	lastTime = 0;
	timeScale = 0;
	
	if([self _createDecompressionSession] == NO)
	{
		// the error has already been reported
		return NO;
	}
	
	isGrabbing = YES;
	callbackMissCounter = 0;
	callbackStatus = XM_CALLBACK_NEVER_CALLED;
	
	return YES;
	
bail:
	// stopping any sequence if needed
	SGStop(sequenceGrabber);
	
	[selectedDevice release];
	selectedDevice = nil;
	
	[inputManager handleErrorWithCode:err hintCode:hintCode];
	return NO;
}

- (BOOL)closeInputDevice
{
	BOOL result = YES;
	
	isGrabbing = NO;
	
	if(SGStop(sequenceGrabber) != noErr)
	{
		result = NO;
	}
	
	if([self _disposeDecompressionSession] == NO)
	{
		result = NO;
	}
	
	[selectedDevice release];
	selectedDevice = nil;
	
	return result;
}

- (BOOL)setInputFrameSize:(NSSize)theFrameSize
{
	BOOL result = YES;
	
	frameSize = theFrameSize;
	
	if(isGrabbing == YES)
	{
		
		if([self _disposeDecompressionSession] == NO)
		{
			result = NO;
		}
		if([self _createDecompressionSession] == NO)
		{
			result = NO;
		}
	}
	return result;
}

- (void)setFrameGrabRate:(unsigned)theFramesPerSecond
{
	framesPerSecond = theFramesPerSecond;

	desiredFrameDuration = timeScale / framesPerSecond;
}

- (BOOL)grabFrame
{
	ComponentResult err = noErr;
	unsigned hintCode = 0;
	
	// Workaround for the FW-Cam Freeze Bug:
	// After some time running, a FW-Cam may freeze
	// so that the SGDataUPP doesn't get called anymore
	// We detect this by counting the subsequent
	// callback misses and restart the sequence grabbing
	// process after some time running
	if(callbackStatus != XM_CALLBACK_NEVER_CALLED)
	{
		callbackStatus = XM_CALLBACK_NOT_CALLED;
	}
	err = SGIdle(sequenceGrabber);
	if(callbackStatus == XM_CALLBACK_NOT_CALLED)
	{
		// incrementing the counter and check for 10 subsequent misses
		callbackMissCounter++;
		if(callbackMissCounter == 10)
		{
			NSLog(@"Callback not called 10 times, restarting the grabbing process");
			NSString *device = [selectedDevice retain];
			[self closeInputDevice];
			[self _disposeSeqGrabComponent];
			[self _openAndConfigureSeqGrabComponent];
			[self openInputDevice:device];
			[device release];
		}
	}
	else if(callbackStatus == XM_CALLBACK_CALLED)
	{
		// resetting the counter
		callbackMissCounter = 0;
	}
	
	if(err != noErr)
	{
		// only reporting an error if not already done so.
		if(callbackStatus != XM_CALLBACK_ERROR_REPORTED)
		{
			hintCode = 0x005001;
			[inputManager handleErrorWithCode:err hintCode:hintCode];
		}
		return NO;
	}
	
	return YES;
}

- (NSString *)descriptionForErrorCode:(unsigned)errorCode device:(NSString *)device
{
	return @"No Description";
}

#pragma mark Private Methods

- (void)_openAndConfigureSeqGrabComponent
{
	ComponentResult err = noErr;
	unsigned hintCode = 0;
	
	sequenceGrabber = OpenDefaultComponent(SeqGrabComponentType, 0);
	if(sequenceGrabber == NULL)
	{
		hintCode = 0x001001;
		goto bail;
	}
	
	err = SGInitialize(sequenceGrabber);
	if(err != noErr)
	{
		hintCode = 0x001002;
		goto bail;
	}
	
	// we need to explicitely call this function or the code will break
	// although we aren't using any GWorld
	err = SGSetGWorld(sequenceGrabber, NULL, GetMainDevice());
	if(err != noErr)
	{
		hintCode = 0x001003;
		goto bail;
	}
	
	err = SGSetDataRef(sequenceGrabber, 0, 0, seqGrabDontMakeMovie);
	if(err != noErr)
	{
		hintCode = 0x001004;
		goto bail;
	}
	
	if([self _openAndConfigureChannel] == NO)
	{
		// Opening the channel failed, probably no video input
		// device attached to the computer
		videoChannel = NULL;
	}
	
	return;
	
bail:
		
	[inputManager handleErrorWithCode:err hintCode:hintCode];
	
	if(sequenceGrabber != NULL)
	{
		CloseComponent(sequenceGrabber);
		sequenceGrabber = NULL;
	}
}

- (void)_disposeSeqGrabComponent
{
	// we don't report any errors occuring in this method
	if(videoChannel != NULL)
	{
		SGDisposeChannel(sequenceGrabber, videoChannel);
		videoChannel = NULL;
	}
	
	if(sequenceGrabber != NULL)
	{
		CloseComponent(sequenceGrabber);
		sequenceGrabber = NULL;
	}
	
	if(dataGrabUPP != NULL)
	{
		DisposeSGDataUPP(dataGrabUPP);
		dataGrabUPP = NULL;
	}
}

- (BOOL)_openAndConfigureChannel
{
	ComponentResult err = noErr;
	unsigned hintCode = 0;
	
	err = SGNewChannel(sequenceGrabber, VideoMediaType, &videoChannel);
	if(err != noErr)
	{
		// this indicates that probably no video input device is attached
		return NO;
	}
	
	err = SGSetChannelUsage(videoChannel, seqGrabRecord);
	if(err != noErr)
	{
		hintCode = 0x006001;
		goto bail;
	}
	
	dataGrabUPP = NewSGDataUPP(XMSGProcessGrabDataProc);
	err = SGSetDataProc(sequenceGrabber,
						dataGrabUPP,
						(long)self);
	if(err != noErr)
	{
		hintCode = 0x006002;
		goto bail;
	}
	
	return YES;
	
bail:
	if(dataGrabUPP != NULL)
	{
		DisposeSGDataUPP(dataGrabUPP);
		dataGrabUPP = NULL;
	}
	
	[inputManager handleErrorWithCode:err hintCode:hintCode];
	return NO;
}

- (BOOL)_createDecompressionSession
{
	ComponentResult err = noErr;
	unsigned hintCode;
	
	ImageDescriptionHandle imageDesc = (ImageDescriptionHandle)NewHandle(0);
	err = SGGetChannelSampleDescription(videoChannel, (Handle)imageDesc);
	if(err != noErr)
	{
		hintCode = 0x007001;
		goto bail;
	}
	
	NSNumber *number = nil;
	NSMutableDictionary *pixelBufferAttributes = nil;
	
	pixelBufferAttributes = [[NSMutableDictionary alloc] initWithCapacity:3];
	
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
	trackingCallbackRecord.decompressionTrackingCallback = XMSGProcessDecompressedFrameProc;
	trackingCallbackRecord.decompressionTrackingRefCon = (void *)self;
	
	err = ICMDecompressionSessionCreate(NULL, imageDesc, NULL,
										(CFDictionaryRef)pixelBufferAttributes,
										&trackingCallbackRecord,
										&grabDecompressionSession);
	if(err != noErr)
	{
		hintCode = 0x007002;
	}
	
bail:
	
	[pixelBufferAttributes release];
	DisposeHandle((Handle)imageDesc);
	
	if(err != noErr)
	{
		[inputManager handleErrorWithCode:err hintCode:hintCode];
		return NO;
	}
	
	return YES;
}

- (BOOL)_disposeDecompressionSession
{
	ICMDecompressionSessionRelease(grabDecompressionSession);
	grabDecompressionSession = NULL;
	return YES;
}

- (OSErr)_processGrabData:(Ptr)data length:(long)length
					 time:(TimeValue)time
{
	ComponentResult err = noErr;
	unsigned hintCode = 0;
	
	callbackStatus = XM_CALLBACK_CALLED;
	
	if(timeScale == 0)
	{
		err = SGGetChannelTimeScale(videoChannel, &timeScale);
		if(err != noErr)
		{
			hintCode = 0x008001;
			goto bail;
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
		return noErr;
	}
	
	err = ICMDecompressionSessionDecodeFrame(grabDecompressionSession,
											 (UInt8 *)data, length,
											 NULL, NULL,
											 (void *)self);
	if(err != noErr)
	{
		hintCode = 0x008002;
		goto bail;
	}
	
	lastTime = time;
	
bail:
	
	if(err != noErr)
	{
		[inputManager handleErrorWithCode:err hintCode:hintCode];
		callbackStatus = XM_CALLBACK_ERROR_REPORTED;
	}
	
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

static pascal OSErr XMSGProcessGrabDataProc(SGChannel channel,
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
	
	return err;
}

static void XMSGProcessDecompressedFrameProc(void *decompressionTrackingRefCon,
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
