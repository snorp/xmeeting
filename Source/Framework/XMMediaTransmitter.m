/*
 * $Id: XMMediaTransmitter.m,v 1.7 2005/10/28 06:59:57 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMMediaTransmitter.h"
#import "XMPacketBuilder.h"
#import "XMVideoManager.h"
#import "XMPrivate.h"
#import "XMUtils.h"
#import "XMCallbackBridge.h"

#import "XMSequenceGrabberVideoInputModule.h"
#import "XMDummyVideoInputModule.h"

typedef enum XMMediaTransmitterMessage
{
	// general messages
	_XMMediaTransmitterMessage_Shutdown= 0x0000,
	
	// configuration messages
	_XMMediaTransmitterMessage_GetDeviceList = 0x0100,
	_XMMediaTransmitterMessage_SetDevice,
	_XMMediaTransmitterMessage_SetFrameGrabRate,
	
	// "action" messages
	_XMMediaTransmitterMessage_StartGrabbing = 0x0200,
	_XMMediaTransmitterMessage_StopGrabbing,
	_XMMediaTransmitterMessage_StartTransmitting,
	_XMMediaTransmitterMessage_StopTransmitting,
	_XMMediaTransmitterMessage_UpdatePicture
	
} XMMediaTransmitterMessage;

@interface XMMediaTransmitter (PrivateMethods)

+ (void)_sendMessage:(XMMediaTransmitterMessage)message withComponents:(NSArray *)components;

- (NSPort *)_receivePort;
- (void)_handleMediaTransmitterThreadDidExit;

- (void)_runMediaTransmitThread;
- (void)handlePortMessage:(NSPortMessage *)portMessage;

- (void)_handleShutdownMessage;
- (void)_handleGetDeviceListMessage;
- (void)_handleSetDeviceMessage:(NSArray *)messageComponents;
- (void)_handleSetFrameGrabRateMessage:(NSArray *)messageComponents;
- (void)_handleStartGrabbingMessage;
- (void)_handleStopGrabbingMessage;
- (void)_handleStartTransmittingMessage:(NSArray *)messageComponents;
- (void)_handleStopTransmittingMessage:(NSArray *)messageComponents;
- (void)_handleUpdatePictureMessage;

- (void)_grabFrame:(NSTimer *)timer;

- (void)_updateDeviceListAndSelectDummy;

- (OSStatus)_packetizeCompressedFrame:(ICMEncodedFrameRef)encodedFrame;

@end

OSStatus XMPacketizeCompressedFrameProc(void*						encodedFrameOutputRefCon, 
										ICMCompressionSessionRef	session, 
										OSStatus					err,
										ICMEncodedFrameRef			encodedFrame,
										void*						reserved);

void XMPacketizerDataReleaseProc(UInt8 *inData,
								 void *inRefCon);

@implementation XMMediaTransmitter

#pragma mark Class Methods

+ (void)_getDeviceList
{
	[XMMediaTransmitter _sendMessage:_XMMediaTransmitterMessage_GetDeviceList withComponents:nil];
}

+ (void)_setDevice:(NSString *)device
{
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:device];
	NSArray *components = [[NSArray alloc] initWithObjects:data, nil];
	
	[XMMediaTransmitter _sendMessage:_XMMediaTransmitterMessage_SetDevice withComponents:components];
	
	[components release];
}

+ (void)_setFrameGrabRate:(unsigned)frameGrabRate
{
	NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:frameGrabRate];
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:number];
	[number release];
	NSArray *components = [[NSArray alloc] initWithObjects:data, nil];
	
	[XMMediaTransmitter _sendMessage:_XMMediaTransmitterMessage_SetFrameGrabRate withComponents:components];
	
	[components release];
}

+ (void)_startGrabbing
{
	[XMMediaTransmitter _sendMessage:_XMMediaTransmitterMessage_StartGrabbing withComponents:nil];
}

+ (void)_stopGrabbing
{
	[XMMediaTransmitter _sendMessage:_XMMediaTransmitterMessage_StopGrabbing withComponents:nil];
}

+ (void)_startTransmittingWithCodec:(unsigned)codecType 
						  videoSize:(XMVideoSize)videoSize 
				 maxFramesPerSecond:(unsigned)maxFramesPerSecond
						 maxBitrate:(unsigned)maxBitrate
							session:(unsigned)sessionID
{
	NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:codecType];
	NSData *codecData = [NSKeyedArchiver archivedDataWithRootObject:number];
	[number release];
	
	number = [[NSNumber alloc] initWithUnsignedInt:videoSize];
	NSData *sizeData = [NSKeyedArchiver archivedDataWithRootObject:number];
	[number release];
	
	number = [[NSNumber alloc] initWithUnsignedInt:maxFramesPerSecond];
	NSData *framesData = [NSKeyedArchiver archivedDataWithRootObject:number];
	[number release];
	
	number = [[NSNumber alloc] initWithUnsignedInt:maxBitrate];
	NSData *bitrateData = [NSKeyedArchiver archivedDataWithRootObject:number];
	[number release];
	
	number = [[NSNumber alloc] initWithUnsignedInt:sessionID];
	NSData *sessionData = [NSKeyedArchiver archivedDataWithRootObject:number];
	[number release];
	
	NSArray *components = [[NSArray alloc] initWithObjects:codecData, sizeData, framesData,
															bitrateData, sessionData, nil];
	
	[XMMediaTransmitter _sendMessage:_XMMediaTransmitterMessage_StartTransmitting withComponents:components];
	
	[components release];
}

+ (void)_stopTransmittingForSession:(unsigned)sessionID
{
	NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:sessionID];
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:number];
	[number release];
	
	NSArray *components = [[NSArray alloc] initWithObjects:data, nil];
	
	[XMMediaTransmitter _sendMessage:_XMMediaTransmitterMessage_StopTransmitting withComponents:components];
	
	[components release];
}

+ (void)_updatePicture
{
	[XMMediaTransmitter _sendMessage:_XMMediaTransmitterMessage_UpdatePicture withComponents:nil];
}

+ (void)_sendMessage:(XMMediaTransmitterMessage)message withComponents:(NSArray *)components
{
	if(_XMMediaTransmitterSharedInstance == nil)
	{
		NSLog(@"Attempt to access XMMediaTransmitter prior to initialization");
		return;
	}
	NSPort *thePort = [_XMMediaTransmitterSharedInstance _receivePort];
	NSPortMessage *portMessage = [[NSPortMessage alloc] initWithSendPort:thePort receivePort:nil components:components];
	[portMessage setMsgid:(unsigned)message];
	if([portMessage sendBeforeDate:[NSDate date]] == NO)
	{
		NSLog(@"Sending the message failed");
	}
	[portMessage release];
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
	self = [super init];
	
	XMSequenceGrabberVideoInputModule *seqGrabModule = [[XMSequenceGrabberVideoInputModule alloc] _init];
	XMDummyVideoInputModule *dummyModule = [[XMDummyVideoInputModule alloc] _init];
	
	videoInputModules = [[NSArray alloc] initWithObjects:seqGrabModule, dummyModule, nil];
	
	[seqGrabModule release];
	[dummyModule release];
	
	receivePort = [[NSPort port] retain];
	
	isGrabbing = NO;
	isTransmitting = NO;
	needsPictureUpdate = NO;
	
	frameGrabRate = 20;
	transmitFrameGrabRate = UINT_MAX;
	videoSize = XMVideoSize_QCIF;
	codecType = 0;
	timeScale = 600;
	
	compressionSession = NULL;
	compressionFrameOptions = NULL;
	mediaPacketizer = 0L;
	
	return self;
}

- (void)_close
{
	[XMMediaTransmitter _sendMessage:_XMMediaTransmitterMessage_Shutdown withComponents:nil];
}

- (void)dealloc
{
	[videoInputModules release];
	
	[receivePort release];
	
	[super dealloc];
}

#pragma mark MainThread methods

- (NSPort *)_receivePort
{
	return receivePort;
}

- (void)_handleMediaTransmitterThreadDidExit
{
	_XMThreadExit();
}

#pragma mark MediTransmitterThread methods

- (void)_runMediaTransmitterThread
{	
	EnterMovies();
	XMRegisterPacketBuilder();
	
	[receivePort setDelegate:self];
	[[NSRunLoop currentRunLoop] addPort:receivePort forMode:NSDefaultRunLoopMode];
	
	// initializing all modules
	NSMutableArray *devices = [[NSMutableArray alloc] initWithCapacity:5];
	BOOL activeModuleSet = NO;
	unsigned count = [videoInputModules count];
	unsigned i;
	for(i = 0; i < count; i++)
	{
		id<XMVideoInputModule> module = (id<XMVideoInputModule>)[videoInputModules objectAtIndex:i];
		
		[module setupWithInputManager:self];
		NSArray *inputDevices = [module inputDevices];
		
		[devices addObjectsFromArray:inputDevices];
		
		if(activeModuleSet == NO)
		{
			if([inputDevices count] != 0)
			{
				activeModule = module;
				selectedDevice = (NSString *)[inputDevices objectAtIndex:0];
				[selectedDevice retain];
				
				activeModuleSet = YES;
			}
		}
		
	}
	
	[_XMVideoManagerSharedInstance performSelectorOnMainThread:@selector(_handleDeviceList:) withObject:devices
												 waitUntilDone:NO];
	[devices release];
	
	// running the run loop
	[[NSRunLoop currentRunLoop] run];
	
	// Due to the problem that this run loop will never exit at the moment,
	// we kill the associated thread after having cleaned up
}

- (void)handlePortMessage:(NSPortMessage *)portMessage
{
	XMMediaTransmitterMessage message = (XMMediaTransmitterMessage)[portMessage msgid];
	
	switch(message)
	{
		case _XMMediaTransmitterMessage_Shutdown:
			[self _handleShutdownMessage];
			break;
		case _XMMediaTransmitterMessage_GetDeviceList:
			[self _handleGetDeviceListMessage];
			break;
		case _XMMediaTransmitterMessage_SetDevice:
			[self _handleSetDeviceMessage:[portMessage components]];
			break;
		case _XMMediaTransmitterMessage_SetFrameGrabRate:
			[self _handleSetFrameGrabRateMessage:[portMessage components]];
			break;
		case _XMMediaTransmitterMessage_StartGrabbing:
			[self _handleStartGrabbingMessage];
			break;
		case _XMMediaTransmitterMessage_StopGrabbing:
			[self _handleStopGrabbingMessage];
			break;
		case _XMMediaTransmitterMessage_StartTransmitting:
			[self _handleStartTransmittingMessage:[portMessage components]];
			break;
		case _XMMediaTransmitterMessage_StopTransmitting:
			[self _handleStopTransmittingMessage:[portMessage components]];
			break;
		case _XMMediaTransmitterMessage_UpdatePicture:
			[self _handleUpdatePictureMessage];
			break;
		default:
			// ignore it
			break;
	}
}

#pragma mark Message handling methods

- (void)_handleShutdownMessage
{
	[self _handleStopTransmittingMessage:nil];
	[self _handleStopGrabbingMessage];
	
	unsigned i;
	unsigned count = [videoInputModules count];
	
	for(i = 0; i < count; i++)
	{
		id<XMVideoInputModule> module = (id<XMVideoInputModule>)[videoInputModules objectAtIndex:i];
		[module close];
	}
	
	// exiting from the run loop
	[[NSRunLoop currentRunLoop] removePort:receivePort forMode:NSDefaultRunLoopMode];
	
	// Since the run loop wil not exit as long as QuickTime is enabled, we have
	// to kill the thread "by hand"
	ExitMovies();
	
	[self performSelectorOnMainThread:@selector(_handleMediaTransmitterThreadDidExit) withObject:nil waitUntilDone:NO];
	
	[NSThread exit];
}

- (void)_handleGetDeviceListMessage
{
	unsigned count = [videoInputModules count];
	unsigned i;
	
	NSMutableArray *devices = [[NSMutableArray alloc] initWithCapacity:5];
	
	for(i = 0; i < count; i++)
	{
		id<XMVideoInputModule> module = (id<XMVideoInputModule>)[videoInputModules objectAtIndex:i];
		
		[module refreshDeviceList];
		[devices addObjectsFromArray:[module inputDevices]];
	}
	
	[_XMVideoManagerSharedInstance performSelectorOnMainThread:@selector(_handleDeviceList:) withObject:devices
												 waitUntilDone:NO];
	[devices release];
}

- (void)_handleSetDeviceMessage:(NSArray *)messageComponents
{
	NSData *data = [messageComponents objectAtIndex:0];
	NSString *deviceToSelect = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
	
	[selectedDevice release];
	selectedDevice = nil;
	
	unsigned moduleCount = [videoInputModules count];
	unsigned i;
	
	for(i = 0; i < moduleCount; i++)
	{
		id<XMVideoInputModule> module = (id<XMVideoInputModule>)[videoInputModules objectAtIndex:i];
		
		NSArray *inputDevices = [module inputDevices];
		
		unsigned inputDeviceCount = [inputDevices count];
		unsigned j;
		
		for(j = 0; j < inputDeviceCount; j++)
		{
			NSString *device = (NSString *)[inputDevices objectAtIndex:j];
			if([device isEqualToString:deviceToSelect])
			{
				BOOL didSucceed = YES;
				
				if(isGrabbing == YES)
				{
					[activeModule closeInputDevice];
					
					if(module != activeModule)
					{
						[module setInputFrameSize:XMGetVideoFrameDimensions(videoSize)];
						[module setFrameGrabRate:frameGrabRate];
					}
					
					didSucceed = [module openInputDevice:deviceToSelect];
				}
				
				if(didSucceed == YES)
				{
					activeModule = module;
					selectedDevice = [deviceToSelect retain];
					
					[_XMVideoManagerSharedInstance performSelectorOnMainThread:@selector(_handleInputDeviceChangeComplete:)
																	withObject:selectedDevice waitUntilDone:NO];
					return;
				}
				else
				{
					activeModule = nil;
				}
			}
		}
	}
	
	// either the desired device didn't exist or the module failed to open the device.
	// We now 1) refresh the device list and 2) select the last module's only device
	// which happens to be the dummy module/device
	[self _updateDeviceListAndSelectDummy];
}

- (void)_handleSetFrameGrabRateMessage:(NSArray *)messageComponents
{
	NSData *data = [messageComponents objectAtIndex:0];
	NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
	frameGrabRate = [number unsignedIntValue];
	
	[activeModule setFrameGrabRate:frameGrabRate];
}

- (void)_handleStartGrabbingMessage
{
	if(isGrabbing == YES)
	{
		return;
	}
	
	[activeModule setInputFrameSize:XMGetVideoFrameDimensions(videoSize)];
	[activeModule setFrameGrabRate:frameGrabRate];
	BOOL result = [activeModule openInputDevice:[[activeModule inputDevices] objectAtIndex:0]];
	
	if(result == NO)
	{
		activeModule = nil;
		[self _updateDeviceListAndSelectDummy];
	}
	
	isGrabbing = YES;
	
	// starting the timer and grabbing the first frame
	
	NSTimeInterval desiredTimeInterval = 1.0/frameGrabRate;
	frameGrabTimer = [[NSTimer scheduledTimerWithTimeInterval:desiredTimeInterval target:self 
													 selector:@selector(_grabFrame:) userInfo:nil
													  repeats:YES] retain];
	[self _grabFrame:nil];
}

- (void)_handleStopGrabbingMessage
{
	if(isGrabbing == NO)
	{
		return;
	}
	
	isGrabbing = NO;
	
	BOOL result = [activeModule closeInputDevice];
	
	if(result == NO)
	{
		NSLog(@"Closing the device failed");
	}
	
	[frameGrabTimer invalidate];
	[frameGrabTimer release];
	frameGrabTimer = nil;
}

- (void)_handleStartTransmittingMessage:(NSArray *)components
{
	if(isTransmitting == YES)
	{
		return;
	}
	
	unsigned codecCode;
	XMVideoSize requiredVideoSize;
	unsigned bitrate;
	
	NSData *data = (NSData *)[components objectAtIndex:0];
	NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
	codecCode = [number unsignedIntValue];
	
	data = (NSData *)[components objectAtIndex:1];
	number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
	requiredVideoSize = (XMVideoSize)[number unsignedIntValue];
	
	data = (NSData *)[components objectAtIndex:2];
	number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
	transmitFrameGrabRate = [number unsignedIntValue];
	
	data = (NSData *)[components objectAtIndex:3];
	number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
	bitrate = [number unsignedIntValue];
	
	switch(codecCode)
	{
		case _XMVideoCodec_H261:
			codecType = kH261CodecType;
			break;
		default:
			codecType = 0;
			// no valid codec means an error
			// should be reported here
			return;
	}
	
	NSSize frameDimensions = XMGetVideoFrameDimensions(videoSize);
	
	if(videoSize != requiredVideoSize)
	{
		videoSize = requiredVideoSize;
		
		if(isGrabbing == YES)
		{
			[activeModule setInputFrameSize:frameDimensions];
		}
	}
	
	// check if the frameGrabRate needs to be adjusted
	if((transmitFrameGrabRate < frameGrabRate) && (isGrabbing == YES))
	{
		[activeModule setFrameGrabRate:transmitFrameGrabRate];
	}
	
	// start grabbing, just to be sure
	[self _handleStartGrabbingMessage];
	
	ComponentResult err = noErr;
	ICMEncodedFrameOutputRecord encodedFrameOutputRecord = {0};
	ICMCompressionSessionOptionsRef sessionOptions = NULL;
	
	err = ICMCompressionSessionOptionsCreate(NULL, &sessionOptions);
	if(err != noErr)
	{
		NSLog(@"ICMCompressionSessionOptionsCreate failed: %d", (int)err);
	}
	
	err = ICMCompressionSessionOptionsSetAllowTemporalCompression(sessionOptions, true);
	if(err != noErr)
	{
		NSLog(@"allowTemporalCompression failed: %d", (int)err);
	}
	
	err = ICMCompressionSessionOptionsSetAllowFrameReordering(sessionOptions, true);
	if(err != noErr)
	{
		NSLog(@"allow frame reordering failed: %d", (int)err);
	}
	
	err = ICMCompressionSessionOptionsSetMaxKeyFrameInterval(sessionOptions, 100);
	if(err != noErr)
	{
		NSLog(@"set max keyFrameInterval failed: %d", (int)err);
	}
	
	err = ICMCompressionSessionOptionsSetAllowFrameTimeChanges(sessionOptions, true);
	if(err != noErr)
	{
		NSLog(@"setallowFrameTimeChanges failed: %d", (int)err);
	}
	
	err = ICMCompressionSessionOptionsSetDurationsNeeded(sessionOptions, true);
	if(err != noErr)
	{
		NSLog(@"SetDurationsNeeded failed: %d", (int)err);
	}
	
	// averageDataRate is in bytes/s
	SInt32 averageDataRate = bitrate / 8;
	NSLog(@"limiting dataRate to %d", averageDataRate);
	err = ICMCompressionSessionOptionsSetProperty(sessionOptions,
												  kQTPropertyClass_ICMCompressionSessionOptions,
												  kICMCompressionSessionOptionsPropertyID_AverageDataRate,
												  sizeof(averageDataRate),
												  &averageDataRate);
	if(err != noErr)
	{
		NSLog(@"SetAverageDataRate failed: %d", (int)err);
	}
	
	encodedFrameOutputRecord.encodedFrameOutputCallback = XMPacketizeCompressedFrameProc;
	encodedFrameOutputRecord.encodedFrameOutputRefCon = (void *)self;
	encodedFrameOutputRecord.frameDataAllocator = NULL;
	
	err = ICMCompressionSessionCreate(NULL, frameDimensions.width, frameDimensions.height, codecType,
									  90000, sessionOptions, NULL, &encodedFrameOutputRecord,
									  &compressionSession);
	if(err != noErr)
	{
		NSLog(@"ICMCompressionSessionCreate failed: %d", (int)err);
	}
	
	ICMCompressionSessionOptionsRelease(sessionOptions);
	
	err = ICMCompressionFrameOptionsCreate(NULL,
										   compressionSession,
										   &compressionFrameOptions);
	if(err != noErr)
	{
		NSLog(@"ICMCompressionFrameOptionsCreate failed %d", (int)err);
	}
	
	timeOffset = lastTime;
	
	isTransmitting = YES;
}

- (void)_handleStopTransmittingMessage:(NSArray *)components
{
	if(isTransmitting == NO)
	{
		return;
	}
	
	if(compressionFrameOptions != NULL)
	{
		ICMCompressionFrameOptionsRelease(compressionFrameOptions);
		compressionFrameOptions = NULL;
	}
	
	if(compressionSession != NULL)
	{
		ICMCompressionSessionRelease(compressionSession);
		compressionSession = NULL;
	}
	
	if(mediaPacketizer != NULL)
	{
		CloseComponent(mediaPacketizer);
		mediaPacketizer = NULL;
	}
	
	RTPMPDataReleaseUPP dataReleaseProc = sampleData.releaseProc;
	if(dataReleaseProc != NULL)
	{
		DisposeRTPMPDataReleaseUPP(dataReleaseProc);
		sampleData.releaseProc = NULL;
	}
	
	if(transmitFrameGrabRate < frameGrabRate)
	{
		[activeModule setFrameGrabRate:frameGrabRate];
	}
	
	transmitFrameGrabRate = UINT_MAX;
	
	_XMDidStopTransmitting(2);
	
	timeOffset = 0;
	
	isTransmitting = NO;
}

- (void)_handleUpdatePictureMessage
{
	needsPictureUpdate = YES;
}

- (void)_grabFrame:(NSTimer *)timer
{	
	NSTimeInterval desiredTimeInterval = 1.0/frameGrabRate;
	
	// readjusting the timer interval if needed
	if([frameGrabTimer timeInterval] != desiredTimeInterval)
	{
		[frameGrabTimer invalidate];
		[frameGrabTimer release];
		
		
		frameGrabTimer = [[NSTimer scheduledTimerWithTimeInterval:desiredTimeInterval target:self 
														 selector:@selector(_grabFrame:) userInfo:nil
														  repeats:YES] retain];
	}
	
	// calling the active module to grab a frame
	BOOL result = [activeModule grabFrame];
	
	if(result == NO)
	{
		// an error occured, we switch to the dummy device
		[self _updateDeviceListAndSelectDummy];
	}
}

- (void)_updateDeviceListAndSelectDummy
{
	if(activeModule != nil)
	{
		[activeModule closeInputDevice];
	}
	
	NSMutableArray *devices = [[NSMutableArray alloc] initWithCapacity:3];
	unsigned moduleCount = [videoInputModules count];
	unsigned i;
	for(i = 0; i < moduleCount; i++)
	{
		id<XMVideoInputModule> module = (id<XMVideoInputModule>)[videoInputModules objectAtIndex:i];
		[module refreshDeviceList];
		[devices addObjectsFromArray:[module inputDevices]];
	}
	
	activeModule = (id<XMVideoInputModule>)[videoInputModules objectAtIndex:(moduleCount-1)];
	selectedDevice = (NSString *)[[[activeModule inputDevices] objectAtIndex:0] retain];
	
	[_XMVideoManagerSharedInstance performSelectorOnMainThread:@selector(_handleInputDeviceChangeComplete:)
													withObject:selectedDevice waitUntilDone:NO];
	[_XMVideoManagerSharedInstance performSelectorOnMainThread:@selector(_handleDeviceList:) withObject:devices
												 waitUntilDone:NO];
	[devices release];
	
	[activeModule openInputDevice:selectedDevice];
}

- (OSStatus)_packetizeCompressedFrame:(ICMEncodedFrameRef)encodedFrame
{
	OSErr err = noErr;
	
	ImageDescriptionHandle imageDesc = NULL;
	
	err = ICMEncodedFrameGetImageDescription(encodedFrame, &imageDesc);
	
	if(mediaPacketizer == NULL)
	{
		OSType packetizerToUse;
		
		switch(codecType)
		{
			case kH261CodecType:
				packetizerToUse = kRTP261MediaPacketizerType;
				break;
			default:
				return qtsBadStateErr;
		}
		
		ComponentDescription componentDescription;
		componentDescription.componentType = kRTPMediaPacketizerType;
		componentDescription.componentSubType = packetizerToUse;
		componentDescription.componentManufacturer = 0;
		componentDescription.componentFlags = 0;
		componentDescription.componentFlagsMask = 0;
		
		Component component = FindNextComponent(0, &componentDescription);
		if(component == NULL)
		{
			NSLog(@"No Packetizer found");
		}
		
		err = OpenAComponent(component, &mediaPacketizer);
		if(err != noErr)
		{
			NSLog(@"Open packetizer failed: %d", (int)err);
		}
		
		err = RTPMPPreflightMedia(mediaPacketizer,
								  VideoMediaType,
								  (SampleDescriptionHandle)imageDesc);
		if(err != noErr)
		{
			NSLog(@"PreflightMedia failed: %d", (int)err);
		}
		
		err = RTPMPInitialize(mediaPacketizer, kRTPMPRealtimeModeFlag);
		if(err != noErr)
		{
			NSLog(@"RTPMP initialize failed: %d", (int)err);
		}
		
		XMGetPacketBuilderComponentDescription(&componentDescription);
		
		Component packetBuilderComponent = FindNextComponent(0, &componentDescription);
		ComponentInstance packetBuilder;
		err = OpenAComponent(packetBuilderComponent, &packetBuilder);
		
		err = RTPMPSetPacketBuilder(mediaPacketizer, packetBuilder);
		if(err != noErr)
		{
			NSLog(@"SetPacketBuilder failed: %d", (int)err);
		}
		
		err = RTPMPSetTimeBase(mediaPacketizer, NewTimeBase());
		if(err != noErr)
		{
			NSLog(@"SetTimeBase failed: %d", (int)err);
		}
		
		err = RTPMPSetTimeScale(mediaPacketizer, 90000);
		if(err != noErr)
		{
			NSLog(@"SetTimeScale failed: %d", (int)err);
		}
		
		// Preventing the packetizer from creating packets
		// greater than the ethernet packet size
		err = RTPMPSetMaxPacketSize(mediaPacketizer, 1400);
		if(err != noErr)
		{
			NSLog(@"SetMaxPacketSize failed: %d", (int)err);
		}
		
		RTPMPDataReleaseUPP dataReleaseProc = NewRTPMPDataReleaseUPP(XMPacketizerDataReleaseProc);
		sampleData.version = 0;
		sampleData.timeStamp = 0;
		sampleData.duration = 0;
		sampleData.playOffset = 0;
		sampleData.playRate = fixed1;
		sampleData.flags = 0;
		sampleData.sampleDescSeed = 0;
		sampleData.sampleRef = 0;
		sampleData.releaseProc = dataReleaseProc;
		sampleData.refCon = (void *)self;
	}

	sampleData.timeStamp = ICMEncodedFrameGetDecodeTimeStamp(encodedFrame);
	sampleData.sampleDescription = (Handle)imageDesc;
	sampleData.dataLength = ICMEncodedFrameGetDataSize(encodedFrame);
	sampleData.data = ICMEncodedFrameGetDataPtr(encodedFrame);
	
	SInt32 outFlags;
	err = RTPMPSetSampleData(mediaPacketizer, &sampleData, &outFlags);
	if(err != noErr)
	{
		NSLog(@"SetSampleData  failed %d", (int)err);
	}
	if(kRTPMPStillProcessingData & outFlags)
	{
		NSLog(@"Still processing data");
	}
	
	while(kRTPMPStillProcessingData & outFlags)
	{
		err = RTPMPIdle(mediaPacketizer, 0, &outFlags);
		if(err != noErr)
		{
			NSLog(@"RTPMPIdle failed %d", (int)err);
		}
	}
	
	return err;
}

#pragma mark XMVideoInputManager Methods

- (void)handleGrabbedFrame:(CVPixelBufferRef)frame time:(TimeValue)time
{	
	//NSLog(@"got frame with timeValue: %d", (int)time);
	// sending the preview image to the video manager
	CIImage *previewImage = [[CIImage alloc] initWithCVImageBuffer:(CVImageBufferRef)frame];
	
	[_XMVideoManagerSharedInstance performSelectorOnMainThread:@selector(_handlePreviewImage:) withObject:previewImage waitUntilDone:NO];
	
	TimeValue convertedTime = (90000 / timeScale) * time;
	TimeValue timeStamp = convertedTime - timeOffset;
	lastTime = timeStamp;
	
	if(compressionSession != NULL)
	{
		OSErr err = noErr;
		
		err = ICMCompressionFrameOptionsSetForceKeyFrame(compressionFrameOptions,
														 needsPictureUpdate);
		if(err != noErr)
		{
			NSLog(@"ICMCompressionFrameOptionsSetForceKeyFrame failed %d", (int)err);
		}
		
		if(needsPictureUpdate == YES)
		{
			NSLog(@"Forcing keyframe");
		}
		
		needsPictureUpdate = NO;
		
		err = ICMCompressionSessionEncodeFrame(compressionSession, 
											   frame,
											   timeStamp, 
											   0, 
											   kICMValidTime_DisplayTimeStampIsValid,
											   compressionFrameOptions, 
											   NULL, 
											   NULL);
		if(err != noErr)
		{
			NSLog(@"ICMCompressionSessionEncodeFrame failed %d", (int)err);
		}
	}
}

- (void)setTimeScale:(TimeScale)theTimeScale
{
	timeScale = theTimeScale;
}

- (void)noteTimeStampReset
{
	if(isTransmitting)
	{
		// we have to adjust the timeOffset so that the
		// produced timeStamps are correctly moving onwards
		// the new timeoffset is the negative value of the
		// lastTime minus one frame time (calculated using
		// the current frame grab rate.
		timeOffset = (-1 * lastTime) - (90000/frameGrabRate);
	}
}

- (void)handleErrorWithCode:(ComponentResult)errorCode hintCode:(unsigned)hintCode
{
	NSLog(@"gotErrorReport: %d hint: %d", (int)errorCode, (int)hintCode);
}

@end

#pragma mark QT-Procs

OSStatus XMPacketizeCompressedFrameProc(void*						encodedFrameOutputRefCon, 
										ICMCompressionSessionRef	session, 
										OSStatus					err,
										ICMEncodedFrameRef			encodedFrame,
										void*						reserved)
{
	if(err == noErr)
	{
		XMMediaTransmitter *mediaTransmitter = (XMMediaTransmitter *)encodedFrameOutputRefCon;
		err = [mediaTransmitter _packetizeCompressedFrame:encodedFrame];
	}
	
	return err;
}

void XMPacketizerDataReleaseProc(UInt8 *inData,
								 void *inRefCon)
{
}
