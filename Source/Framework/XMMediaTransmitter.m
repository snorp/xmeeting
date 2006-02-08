/*
 * $Id: XMMediaTransmitter.m,v 1.19 2006/02/08 23:25:54 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMMediaTransmitter.h"

#import "XMPrivate.h"

#import "XMPacketBuilder.h"
#import "XMRTPH263Packetizer.h"
#import "XMRTPH264Packetizer.h"

#import "XMSequenceGrabberVideoInputModule.h"
#import "XMScreenVideoInputModule.h"
#import "XMDummyVideoInputModule.h"

#import "XMCallbackBridge.h"

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
	_XMMediaTransmitterMessage_UpdatePicture,
	_XMMediaTransmitterMessage_SetVideoBytesSent,
	
	_XMMediaTransmitterMessage_SendSettingsToModule = 0x300
	
} XMMediaTransmitterMessage;

@class XMVideoInputModuleWrapper;

@interface XMMediaTransmitter (PrivateMethods)

+ (void)_sendMessage:(XMMediaTransmitterMessage)message withComponents:(NSArray *)components;

- (NSPort *)_receivePort;
- (XMVideoInputModuleWrapper *)_wrapperForDevice:(NSString *)device;
- (void)_sendDeviceList;
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
- (void)_handleSetVideoBytesSentMessage:(NSArray *)messageComponents;
- (void)_handleSendSettingsToModuleMessage:(NSArray *)messageComponents;

- (void)_grabFrame:(NSTimer *)timer;

- (void)_updateDeviceListAndSelectDummy;

- (void)_startCompressionSession;
- (void)_stopCompressionSession;
- (void)_compressionSessionCompressFrame:(CVPixelBufferRef)frame timeStamp:(TimeValue)timeStamp;

- (void)_startCompressSequence;
- (void)_stopCompressSequence;
- (void)_compressSequenceCompressFrame:(CVPixelBufferRef)frame timeStamp:(TimeValue)timeStamp;

- (OSStatus)_packetizeCompressedFrame:(UInt8 *)data 
							   length:(UInt32)dataLength
					 imageDescription:(ImageDescriptionHandle)imageDesc 
							timeStamp:(UInt32)timeStamp;

- (void)_adjustH261Data:(UInt8 *)h261Data;

@end

@interface XMVideoInputModuleWrapper : NSObject <XMVideoModule> {

	id<XMVideoInputModule> videoInputModule;
	NSArray *devices;
	BOOL isEnabled;
}

- (id)_initWithVideoInputModule:(id<XMVideoInputModule>)videoInputModule;

- (id<XMVideoInputModule>)_videoInputModule;

- (NSArray *)_devices;
- (void)_setDevices:(NSArray *)devices;

- (BOOL)_hasSettingsForDevice:(NSString *)device;
- (NSView *)_settingsViewForDevice:(NSString *)device;
- (void)_setDefaultSettingsForDevice:(NSString *)device;

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

+ (void)_selectModule:(unsigned)moduleIndex device:(NSString *)device
{
	NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:moduleIndex];
	NSData *moduleData = [NSKeyedArchiver archivedDataWithRootObject:number];
	[number release];
	
	NSData *deviceData = [NSKeyedArchiver archivedDataWithRootObject:device];
	
	NSArray *components = [[NSArray alloc] initWithObjects:moduleData, deviceData, nil];
	
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

+ (void)_startTransmittingForSession:(unsigned)sessionID
						   withCodec:(XMCodecIdentifier)codecIdentifier
						   videoSize:(XMVideoSize)videoSize 
				  maxFramesPerSecond:(unsigned)maxFramesPerSecond
						  maxBitrate:(unsigned)maxBitrate
							   flags:(unsigned)flags
{
	NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:sessionID];
	NSData *sessionData = [NSKeyedArchiver archivedDataWithRootObject:number];
	[number release];
	
	number = [[NSNumber alloc] initWithUnsignedInt:codecIdentifier];
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
	
	number = [[NSNumber alloc] initWithUnsignedInt:flags];
	NSData *flagsData = [NSKeyedArchiver archivedDataWithRootObject:number];
	[number release];
	
	NSArray *components = [[NSArray alloc] initWithObjects:sessionData, codecData, sizeData, framesData,
															bitrateData, flagsData, nil];
	
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

+ (void)_setVideoBytesSent:(unsigned)videoBytesSent
{
	NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:videoBytesSent];
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:number];
	[number release];
	
	NSArray *components = [[NSArray alloc] initWithObjects:data, nil];
	
	[XMMediaTransmitter _sendMessage:_XMMediaTransmitterMessage_SetVideoBytesSent withComponents:components];
	
	[components release];
}

+ (void)_sendSettings:(NSData *)settings toModule:(id<XMVideoInputModule>)module
{
	NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:(unsigned)module];
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:number];
	[number release];
	
	NSArray *components = [[NSArray alloc] initWithObjects:data, settings, nil];
	
	[XMMediaTransmitter _sendMessage:_XMMediaTransmitterMessage_SendSettingsToModule withComponents:components];
	
	[components release];
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
	
	receivePort = [[NSPort port] retain];
	
	XMSequenceGrabberVideoInputModule *seqGrabModule = [[XMSequenceGrabberVideoInputModule alloc] _init];
	XMScreenVideoInputModule *screenModule = [[XMScreenVideoInputModule alloc] _init];
	XMDummyVideoInputModule *dummyModule = [[XMDummyVideoInputModule alloc] _init];
	
	XMVideoInputModuleWrapper *seqGrabWrapper = [[XMVideoInputModuleWrapper alloc] _initWithVideoInputModule:seqGrabModule];
	XMVideoInputModuleWrapper *screenWrapper = [[XMVideoInputModuleWrapper alloc] _initWithVideoInputModule:screenModule];
	XMVideoInputModuleWrapper *dummyWrapper = [[XMVideoInputModuleWrapper alloc] _initWithVideoInputModule:dummyModule];
		
	videoInputModules = [[NSArray alloc] initWithObjects:seqGrabWrapper, screenWrapper, dummyWrapper, nil];
	
	[seqGrabModule release];
	[screenModule release];
	[dummyModule release];
	
	[seqGrabWrapper release];
	[screenWrapper release];
	[dummyWrapper release];
	
	activeModule = nil;
	selectedDevice = nil;
	
	frameGrabTimer = nil;
	
	isGrabbing = NO;
	frameGrabRate = 30;
	timeScale = 600;
	timeOffset = 0;
	lastTime = 1;
	
	isTransmitting = NO;
	transmitFrameGrabRate = UINT_MAX;
	videoSize = XMVideoSize_QCIF;
	codecType = 0;
	codecSpecificCallFlags = 0;
	bitrateToUse = 0;
	
	needsPictureUpdate = NO;
	
	useCompressionSessionAPI = NO;
	compressor = NULL;
	
	compressionSession = NULL;
	compressionFrameOptions = NULL;
	
	compressSequenceIsActive = NO;
	compressSequence = 0;
	compressSequenceImageDescription = NULL;
	compressSequenceCompressedFrame = NULL;
	compressSequenceFrameCounter = 0;
	compressSequenceLastVideoBytesSent = 0;
	compressSequenceNonKeyFrameCounter = 0;
	
	mediaPacketizer = NULL;
	
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

- (void)_setDevice:(NSString *)deviceToSelect
{
	unsigned count = [videoInputModules count];
	unsigned i;
	
	for(i = 0; i < count; i++)
	{
		XMVideoInputModuleWrapper *moduleWrapper = (XMVideoInputModuleWrapper *)[videoInputModules objectAtIndex:i];
		
		NSArray *inputDevices = [moduleWrapper _devices];
		
		unsigned inputDeviceCount = [inputDevices count];
		unsigned j;
		
		for(j = 0; j < inputDeviceCount; j++)
		{
			NSString *device = (NSString *)[inputDevices objectAtIndex:j];
			if([device isEqualToString:deviceToSelect])
			{
				[XMMediaTransmitter _selectModule:i device:device];
				return;
			}
		}
	}
	
	// If the desired device isn't found, we select the dummy device
	[XMMediaTransmitter _selectModule:(count-1) device:0];
}

- (BOOL)_deviceHasSettings:(NSString *)device
{
	XMVideoInputModuleWrapper *moduleWrapper = [self _wrapperForDevice:device];
	
	if(moduleWrapper != nil)
	{
		return [moduleWrapper _hasSettingsForDevice:device];
	}
	
	return NO;
}

- (BOOL)_requiresSettingsDialogWhenDeviceIsSelected:(NSString *)device
{
	XMVideoInputModuleWrapper *moduleWrapper = [self _wrapperForDevice:device];
	
	if(moduleWrapper != nil)
	{
		return [[moduleWrapper _videoInputModule] requiresSettingsDialogWhenDeviceOpens:device];
	}
	
	return NO;
}

- (NSView *)_settingsViewForDevice:(NSString *)device
{
	XMVideoInputModuleWrapper *moduleWrapper = [self _wrapperForDevice:device];
	
	if(moduleWrapper != nil)
	{
		return [moduleWrapper _settingsViewForDevice:device];
	}
	
	return nil;
}

- (void)_setDefaultSettingsForDevice:(NSString *)device
{
	XMVideoInputModuleWrapper *moduleWrapper = [self _wrapperForDevice:device];
	
	if(moduleWrapper != nil)
	{
		[moduleWrapper _setDefaultSettingsForDevice:device];
	}
}

- (unsigned)_videoModuleCount
{
	// we're not returning the dummy device
	unsigned count = [videoInputModules count];
	
	return (count-1);
}

- (id<XMVideoModule>)_videoModuleAtIndex:(unsigned)index
{
	unsigned count = [videoInputModules count];
	
	if(index == (count-1))
	{
		return nil;
	}
	
	return [videoInputModules objectAtIndex:index];
}

- (XMVideoInputModuleWrapper *)_wrapperForDevice:(NSString *)device
{
	unsigned i;
	unsigned count = [videoInputModules count];
	
	for(i = 0; i < count; i++)
	{
		XMVideoInputModuleWrapper *moduleWrapper = (XMVideoInputModuleWrapper *)[videoInputModules objectAtIndex:i];
		
		if([[moduleWrapper _devices] containsObject:device])
		{
			return moduleWrapper;
		}
	}
	
	return nil;
}

- (void)_sendDeviceList
{
	unsigned i;
	unsigned count = [videoInputModules count];
	
	NSMutableArray *devices = [[NSMutableArray alloc] initWithCapacity:5];
	
	for(i = 0; i < count; i++)
	{
		XMVideoInputModuleWrapper *moduleWrapper = (XMVideoInputModuleWrapper *)[videoInputModules objectAtIndex:i];
		
		if([moduleWrapper isEnabled] == YES)
		{
			NSArray *inputDevices = [moduleWrapper _devices];
			[devices addObjectsFromArray:inputDevices];
		}
	}
	
	[_XMVideoManagerSharedInstance _handleDeviceList:devices];
	
	[devices release];
}

- (void)_handleMediaTransmitterThreadDidExit
{
	_XMThreadExit();
}

#pragma mark MediaTransmitterThread methods

- (void)_runMediaTransmitterThread
{	
	EnterMovies();
	XMRegisterPacketBuilder();
	XMRegisterRTPH263Packetizer();
	XMRegisterRTPH264Packetizer();
	
	[receivePort setDelegate:self];
	[[NSRunLoop currentRunLoop] addPort:receivePort forMode:NSDefaultRunLoopMode];
	
	// initializing all modules
	BOOL activeModuleSet = NO;
	unsigned count = [videoInputModules count];
	unsigned i;
	for(i = 0; i < count; i++)
	{
		XMVideoInputModuleWrapper *moduleWrapper = (XMVideoInputModuleWrapper *)[videoInputModules objectAtIndex:i];
		id<XMVideoInputModule> module = [moduleWrapper _videoInputModule];
		
		[module setupWithInputManager:self];
		NSArray *inputDevices = [module inputDevices];
		
		[moduleWrapper performSelectorOnMainThread:@selector(_setDevices:) withObject:inputDevices waitUntilDone:NO];
		
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

	[self performSelectorOnMainThread:@selector(_sendDeviceList) withObject:nil waitUntilDone:NO];
	
	// running the run loop
	[[NSRunLoop currentRunLoop] run];
	
	// Due to the problem that this run loop will never exit at the moment,
	// we kill the associated thread after having cleaned up
}

#pragma mark Message handling methods

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
		case _XMMediaTransmitterMessage_SetVideoBytesSent:
			[self _handleSetVideoBytesSentMessage:[portMessage components]];
			break;
		case _XMMediaTransmitterMessage_SendSettingsToModule:
			[self _handleSendSettingsToModuleMessage:[portMessage components]];
			break;
		default:
			// ignore it
			break;
	}
}

- (void)_handleShutdownMessage
{
	[self _handleStopTransmittingMessage:nil];
	[self _handleStopGrabbingMessage];
	
	unsigned i;
	unsigned count = [videoInputModules count];
	
	for(i = 0; i < count; i++)
	{
		XMVideoInputModuleWrapper *moduleWrapper = (XMVideoInputModuleWrapper *)[videoInputModules objectAtIndex:i];
		id<XMVideoInputModule> module = [moduleWrapper _videoInputModule];
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
	
	for(i = 0; i < count; i++)
	{
		XMVideoInputModuleWrapper *moduleWrapper = (XMVideoInputModuleWrapper *)[videoInputModules objectAtIndex:i];
		id<XMVideoInputModule> module = [moduleWrapper _videoInputModule];
		
		NSArray *devices = [module inputDevices];
		[moduleWrapper performSelectorOnMainThread:@selector(_setDevices:) withObject:devices waitUntilDone:NO];
	}
	
	[self performSelectorOnMainThread:@selector(_sendDeviceList) withObject:nil waitUntilDone:NO];
}

- (void)_handleSetDeviceMessage:(NSArray *)messageComponents
{
	NSData *data = [messageComponents objectAtIndex:0];
	NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
	unsigned moduleIndex = [number unsignedIntValue];
	
	data = [messageComponents objectAtIndex:1];
	NSString *device = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
	
	XMVideoInputModuleWrapper *moduleWrapper = (XMVideoInputModuleWrapper *)[videoInputModules objectAtIndex:moduleIndex];
	id<XMVideoInputModule> module = [moduleWrapper _videoInputModule];
	
	[selectedDevice release];
	selectedDevice = nil;
	
	BOOL didSucceed = YES;
	
	if(isGrabbing == YES)
	{
		[activeModule closeInputDevice];
		
		if(module != activeModule)
		{
			[module setInputFrameSize:XMGetVideoFrameDimensions(videoSize)];
			[module setFrameGrabRate:frameGrabRate];
		}
		
		didSucceed = [module openInputDevice:device];
	}
	
	if(didSucceed == YES)
	{
		activeModule = module;
		selectedDevice = [device retain];
		
		[_XMVideoManagerSharedInstance performSelectorOnMainThread:@selector(_handleInputDeviceChangeComplete:)
														withObject:selectedDevice waitUntilDone:NO];
	}
	else
	{
		activeModule = nil;
	
		//The device could not be opened.
		// We now 1) refresh the device list and 2) select the last module's only device
		// which happens to be the dummy module/device
		[self _updateDeviceListAndSelectDummy];
	}
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
	BOOL result = [activeModule openInputDevice:selectedDevice];
	
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
	
	XMCodecIdentifier codecIdentifier;
	XMVideoSize requiredVideoSize;
	
	NSData *data = (NSData *)[components objectAtIndex:1];
	NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
	codecIdentifier = [number unsignedIntValue];
	
	data = (NSData *)[components objectAtIndex:2];
	number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
	requiredVideoSize = (XMVideoSize)[number unsignedIntValue];
	
	data = (NSData *)[components objectAtIndex:3];
	number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
	transmitFrameGrabRate = [number unsignedIntValue];
	
	data = (NSData *)[components objectAtIndex:4];
	number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
	bitrateToUse = [number unsignedIntValue];
	
	data = (NSData *)[components objectAtIndex:5];
	number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
	codecSpecificCallFlags = [number unsignedIntValue];
	
	switch(codecIdentifier)
	{
		case XMCodecIdentifier_H261:
			codecType = kH261CodecType;
			codecManufacturer = 'appl';
			useCompressionSessionAPI = NO;
			break;
		case XMCodecIdentifier_H263:
			codecType = kH263CodecType;
			codecManufacturer = 'surf';
			useCompressionSessionAPI = NO;
			break;
		case XMCodecIdentifier_H264:
			codecType = kH264CodecType;
			codecManufacturer = 'appl';
			useCompressionSessionAPI = YES;
			break;
		default:
			codecType = 0;
			// no valid codec means an error
			// should be reported here
			return;
	}
	
	if(videoSize != requiredVideoSize)
	{
		NSSize frameDimensions = XMGetVideoFrameDimensions(requiredVideoSize);
		
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
	
	if(useCompressionSessionAPI == YES)
	{
		[self _startCompressionSession];
	}
	else
	{
		[self _startCompressSequence];
	}
	
	timeOffset = lastTime;
	lastTime = 1;
	
	isTransmitting = YES;
}

- (void)_handleStopTransmittingMessage:(NSArray *)components
{
	if(isTransmitting == NO)
	{
		return;
	}
	
	if(useCompressionSessionAPI == YES)
	{
		[self _stopCompressionSession];
	}
	else
	{
		[self _stopCompressSequence];
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

- (void)_handleSetVideoBytesSentMessage:(NSArray *)components
{
	if(compressSequence != 0)
	{
		
		NSData *data = (NSData *)[components objectAtIndex:0];
		NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
		unsigned videoBytesSent = [number unsignedIntValue];
		
		long currentDataRate = (videoBytesSent - compressSequenceLastVideoBytesSent);
		long dataRateWanted = (bitrateToUse / 8);
		long overrun = currentDataRate - dataRateWanted;
		
		// avoid division by zero
		if(compressSequenceFrameCounter == 0)
		{
			compressSequenceFrameCounter = 1;
		}
		
		DataRateParams dataRateParams;
		dataRateParams.dataRate = dataRateWanted;
		dataRateParams.dataOverrun = overrun;
		dataRateParams.frameDuration = 1000/compressSequenceFrameCounter;
		dataRateParams.keyFrameRate = 0;
		dataRateParams.minSpatialQuality = codecLowQuality;
		dataRateParams.minTemporalQuality = codecLowQuality;
		
		OSStatus err = noErr;
		err = SetCSequenceDataRateParams(compressSequence, &dataRateParams);
		if(err != noErr)
		{
			NSLog(@"Setting data rate contraints failed %d", err);
		}
		
		compressSequenceFrameCounter = 0;
		compressSequenceLastVideoBytesSent = videoBytesSent;
	}
}

- (void)_handleSendSettingsToModuleMessage:(NSArray *)messageComponents
{
	NSData *data = (NSData *)[messageComponents objectAtIndex:0];
	NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
	
	id<XMVideoInputModule> module = (id<XMVideoInputModule>)[number unsignedIntValue];
	
	NSData *settings = (NSData *)[messageComponents objectAtIndex:1];
	
	[module applyInternalSettings:settings];
}

#pragma mark XMVideoInputManager Methods

- (void)handleGrabbedFrame:(CVPixelBufferRef)frame time:(TimeValue)time
{	
	if(isTransmitting == YES)
	{
		TimeValue convertedTime = (90000 / timeScale) * time;
		TimeValue timeStamp = convertedTime - timeOffset;
	
		timeStamp -= (timeStamp % 3003);
	
		if(timeStamp <= lastTime && lastTime != 1)
		{
			timeStamp = lastTime + 3003;
		}
	
		lastTime = timeStamp;
		
		SInt32 timeStampDifference = (timeStamp - convertedTime);
		if(timeStampDifference >= 3003)
		{
			return;
		}
	
		if(useCompressionSessionAPI == YES)
		{
			[self _compressionSessionCompressFrame:frame timeStamp:timeStamp];
		}	
		else
		{
			[self _compressSequenceCompressFrame:frame timeStamp:timeStamp];
		}
	}
	
	// handling the frame to the video manager to draw the preview image
	// on screen
	[_XMVideoManagerSharedInstance _handleLocalVideoFrame:frame];
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

- (void)noteSettingsDidChangeForModule:(id<XMVideoInputModule>)module
{
	NSString *theSelectedDevice = [_XMVideoManagerSharedInstance selectedInputDevice];
	
	unsigned i;
	unsigned count = [videoInputModules count];
	
	for(i = 0; i < count; i++)
	{
		XMVideoInputModuleWrapper *moduleWrapper = (XMVideoInputModuleWrapper *)[videoInputModules objectAtIndex:i];
		if([moduleWrapper _videoInputModule] == module)
		{
			if([[moduleWrapper _devices] containsObject:theSelectedDevice])
			{
				NSData *settings = [module internalSettings];
				[XMMediaTransmitter _sendSettings:settings toModule:module];
			}
			return;
		}
	}
}

- (void)handleErrorWithCode:(ComponentResult)errorCode hintCode:(unsigned)hintCode
{
	NSLog(@"gotErrorReport: %d hint: %d", (int)errorCode, (int)hintCode);
}

#pragma mark Private Methods

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
	
	unsigned count = [videoInputModules count];
	
	XMVideoInputModuleWrapper *dummyModuleWrapper = (XMVideoInputModuleWrapper *)[videoInputModules objectAtIndex:(count-1)];
	activeModule = [dummyModuleWrapper _videoInputModule];
	
	selectedDevice = (NSString *)[[[activeModule inputDevices] objectAtIndex:0] retain];
	
	[_XMVideoManagerSharedInstance performSelectorOnMainThread:@selector(_handleInputDeviceChangeComplete:)
													withObject:selectedDevice waitUntilDone:NO];
	
	// updating the device list
	[self _handleGetDeviceListMessage];
	
	[activeModule openInputDevice:selectedDevice];
}

- (void)_startCompressionSession
{
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
	
	err = ICMCompressionSessionOptionsSetAllowFrameReordering(sessionOptions, false);
	if(err != noErr)
	{
		NSLog(@"allow frame reordering failed: %d", (int)err);
	}	
	
	err = ICMCompressionSessionOptionsSetMaxKeyFrameInterval(sessionOptions, 120);
	if(err != noErr)
	{
		NSLog(@"set max keyFrameInterval failed: %d", (int)err);
	}
	
	err = ICMCompressionSessionOptionsSetAllowFrameTimeChanges(sessionOptions, false);
	if(err != noErr)
	{
		NSLog(@"setAllowFrameTimeChanges failed: %d", (int)err);
	}
	
	err = ICMCompressionSessionOptionsSetDurationsNeeded(sessionOptions, true);
	if(err != noErr)
	{
		NSLog(@"SetDurationsNeeded failed: %d", (int)err);
	}
	
	// averageDataRate is in bytes/s
	SInt32 averageDataRate = bitrateToUse / 8;
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
	
	SInt32 maxFrameDelayCount = 0;
	err = ICMCompressionSessionOptionsSetProperty(sessionOptions,
												  kQTPropertyClass_ICMCompressionSessionOptions,
												  kICMCompressionSessionOptionsPropertyID_MaxFrameDelayCount,
												  sizeof(maxFrameDelayCount),
												  &maxFrameDelayCount);
	if(err != noErr)
	{
		NSLog(@"SetMaxFrameDelayCount failed: %d", (int)err);
	}
	
	ComponentDescription componentDescription;
	componentDescription.componentType = FOUR_CHAR_CODE('imco');
	componentDescription.componentSubType = codecType;
	componentDescription.componentManufacturer = codecManufacturer;
	componentDescription.componentFlags = 0;
	componentDescription.componentFlagsMask = 0;
	
	Component compressorComponent = FindNextComponent(0, &componentDescription);
	if(compressorComponent == NULL)
	{
		NSLog(@"No such compressor");
	}
	
	err = OpenAComponent(compressorComponent, &compressor);
	if(err != noErr)
	{
		NSLog(@"Opening the component failed");
	}
	
	if(codecType == FOUR_CHAR_CODE('avc1'))
	{
		// Profile is currently fixed to Baseline
		// The level is adjusted by the use of the
		// bitrate, but the SPS returned reveals
		// level 1.1 in case of QCIF and level 1.3
		// in case of CIF
		
		Handle h264Settings = NewHandleClear(0);
		
		err = ImageCodecGetSettings(compressor, h264Settings);
		if(err != noErr)
		{
			NSLog(@"ImageCodecGetSettings failed");
		}
		
		// For some reason, the QTAtomContainer functions will crash if used on the atom
		// container returned by ImageCodecGetSettings.
		// Therefore, we have to parse the atoms self to set the correct settings.
		unsigned i;
		unsigned settingsSize = GetHandleSize(h264Settings) / 4;
		UInt32 *data = (UInt32 *)*h264Settings;
		for(i = 0; i < settingsSize; i++)
		{
			if(data[i] == FOUR_CHAR_CODE('sprf'))
			{
				// Forcing Baseline profile
				i+=4;
				data[i] = 1;
			}
			
			// if video sent is CIF size, we set this flag to one to have the picture
			// encoded in 5 slices instead of two.
			// If QCIF is sent, this flag remains zero to send two slices instead of
			// one.
			else if(videoSize == XMVideoSize_CIF && data[i] == FOUR_CHAR_CODE('susg'))
			{
				i+=4;
				data[i] = 1;
			}
		}
		
		err = ImageCodecSetSettings(compressor, h264Settings);
		if(err != noErr)
		{
			NSLog(@"ImageCodecSetSettings failed");
		}
	}
	
	err = ICMCompressionSessionOptionsSetProperty(sessionOptions,
												  kQTPropertyClass_ICMCompressionSessionOptions,
												  kICMCompressionSessionOptionsPropertyID_CompressorComponent,
												  sizeof(compressor),
												  &compressor);
	if(err != noErr)
	{
		NSLog(@"No such codec found");
	}
	
	encodedFrameOutputRecord.encodedFrameOutputCallback = XMPacketizeCompressedFrameProc;
	encodedFrameOutputRecord.encodedFrameOutputRefCon = (void *)self;
	encodedFrameOutputRecord.frameDataAllocator = NULL;
	
	NSSize frameDimensions = XMGetVideoFrameDimensions(videoSize);
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
}

- (void)_stopCompressionSession
{
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
	
	if(compressor != NULL)
	{
		CloseComponent(compressor);
		compressor = NULL;
	}
}

- (void)_compressionSessionCompressFrame:(CVPixelBufferRef)frame timeStamp:(TimeValue)timeStamp
{
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
			NSLog(@"Forcing Keyframe");
		}
		
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
		
		needsPictureUpdate = NO;
	}
}

- (void)_startCompressSequence
{
	// Since the CompressSequence API needs a PixMap to be
	// present when callling CompressSequenceBegin,
	// we defer this task to _compressSequenceCompressFrame:timeStamp:
	compressSequenceIsActive = YES;
}

- (void)_stopCompressSequence
{
	if(compressSequence != 0)
	{
		CDSequenceEnd(compressSequence);
		compressSequence = 0;
	}
	
	if(compressSequenceImageDescription != NULL)
	{
		DisposeHandle((Handle)compressSequenceImageDescription);
		compressSequenceImageDescription = NULL;
	}
	
	if(compressSequenceCompressedFrame != NULL)
	{
		DisposePtr(compressSequenceCompressedFrame);
		compressSequenceCompressedFrame = NULL;
	}
	
	if(compressor != NULL)
	{
		CloseComponent(compressor);
		compressor = NULL;
	}
	
	compressSequenceIsActive = NO;
}

- (void)_compressSequenceCompressFrame:(CVPixelBufferRef)frame timeStamp:(TimeValue)timeStamp
{
	if(compressSequenceIsActive == YES)
	{
		ComponentResult err = noErr;
		
		PixMap pixMap;
		
		CVPixelBufferLockBaseAddress(frame, 0);
		
		pixMap.baseAddr = CVPixelBufferGetBaseAddress(frame);
		pixMap.rowBytes = 0x8000;
		pixMap.rowBytes |= (CVPixelBufferGetBytesPerRow(frame) & 0x3fff);
		pixMap.bounds.top = 0;
		pixMap.bounds.left = 0;
		pixMap.bounds.bottom = CVPixelBufferGetHeight(frame);
		pixMap.bounds.right = CVPixelBufferGetWidth(frame);
		pixMap.pmVersion = 0;
		pixMap.packType = 0;
		pixMap.packSize = 0;
		pixMap.hRes = Long2Fix(72);
		pixMap.vRes = Long2Fix(72);
		pixMap.pixelType = 16;
		pixMap.pixelSize = 32;
		pixMap.cmpCount = 4;
		pixMap.cmpSize = 8;
		pixMap.pixelFormat = CVPixelBufferGetPixelFormatType(frame);
		pixMap.pmTable = NULL;
		pixMap.pmExt = NULL;
		
		PixMapPtr pixMapPtr = &pixMap;
		
		if(compressSequence == 0)
		{
			ComponentDescription componentDescription;
			componentDescription.componentType = FOUR_CHAR_CODE('imco');
			componentDescription.componentSubType = codecType;
			componentDescription.componentManufacturer = codecManufacturer;
			componentDescription.componentFlags = 0;
			componentDescription.componentFlagsMask = 0;
			
			Component compressorComponent = FindNextComponent(0, &componentDescription);
			if(compressorComponent == NULL)
			{
				NSLog(@"No such compressor");
			}
			
			err = OpenAComponent(compressorComponent, &compressor);
			if(err != noErr)
			{
				NSLog(@"Opening the component failed");
			}
			
			compressSequenceImageDescription = (ImageDescriptionHandle)NewHandleClear(0);
			
			err = CompressSequenceBegin(&compressSequence,
										&pixMapPtr,
										NULL,
										&(pixMap.bounds),
										&(pixMap.bounds),
										32,
										codecType,
										(CompressorComponent)compressor,
										codecNormalQuality,
										codecNormalQuality,
										0,
										NULL,
										codecFlagUpdatePreviousComp,
										compressSequenceImageDescription);
			if(err != noErr)
			{
				NSLog(@"CompressSequenceBegin failed: %d", err);
			}
			
			err = SetCSequencePreferredPacketSize(compressSequence, 1420);
			if(err != noErr)
			{
				NSLog(@"Setting packet size failed %d", err);
			}
			
			long maxCompressionSize;
			err = GetMaxCompressionSize(&pixMapPtr,
										&(pixMap.bounds),
										0,
										codecNormalQuality,
										codecType,
										(CompressorComponent)compressor,
										&maxCompressionSize);
			
			if(err != noErr)
			{
				NSLog(@"GetMaxCompressionSize failed: %d", err);
			}
			
			compressSequenceCompressedFrame = QTSNewPtr(maxCompressionSize,
														kQTSMemAllocHoldMemory,
														NULL);
			
			compressSequencePreviousTimeStamp = 0;
			compressSequenceFrameNumber = 0;
			
			NSLog(@"limiting bitrate to %d", bitrateToUse);
			DataRateParams dataRateParams;
			dataRateParams.dataRate = (bitrateToUse / 8);
			dataRateParams.dataOverrun = 0;
			dataRateParams.frameDuration = 34;
			dataRateParams.keyFrameRate = 0;
			dataRateParams.minSpatialQuality = codecLowQuality;
			dataRateParams.minTemporalQuality = codecLowQuality;
			err = SetCSequenceDataRateParams(compressSequence, &dataRateParams);
			if(err != noErr)
			{
				NSLog(@"Setting data rate contratints failed %d", err);
			}
			
			compressSequenceFrameCounter = 0;
			compressSequenceLastVideoBytesSent = 0;
			compressSequenceNonKeyFrameCounter = 0;
		}
		
		// rounding timeStamp to the next lower integer multiple of 3003
		timeStamp -= (timeStamp % 3003);
		
		UInt32 numberOfFramesInBetween = 1;
		if(compressSequencePreviousTimeStamp != 0)
		{
			numberOfFramesInBetween = (timeStamp - compressSequencePreviousTimeStamp) / 3003;
			compressSequenceFrameNumber += numberOfFramesInBetween;
		}
		
		err = SetCSequenceFrameNumber(compressSequence,
									  compressSequenceFrameNumber);
		if(err != noErr)
		{
			NSLog(@"SetFrameNumber failed %d", err);
		}
		
		compressSequencePreviousTimeStamp = timeStamp;
		
		CodecFlags compressionFlags = (codecFlagUpdatePreviousComp | codecFlagLiveGrab);
		
		if(compressSequenceNonKeyFrameCounter == 120)
		{
			needsPictureUpdate = YES;
		}
		
		if(needsPictureUpdate == YES)
		{
			NSLog(@"Forcing Keyframe");
			compressionFlags |= codecFlagForceKeyFrame;
			compressSequenceNonKeyFrameCounter = 0;
		}
		else
		{
			compressSequenceNonKeyFrameCounter++;
		}
		
		long dataLength;
		err = CompressSequenceFrame(compressSequence,
									&pixMapPtr,
									&(pixMap.bounds),
									compressionFlags,
									compressSequenceCompressedFrame,
									&dataLength,
									NULL,
									NULL);
		if(err != noErr)
		{
			NSLog(@"CompressSequenceFrame failed: %d", err);
			return;
		}
		
		UInt8 *compressedData = (UInt8 *)compressSequenceCompressedFrame;
		
		[self _packetizeCompressedFrame:compressedData
								 length:dataLength
					   imageDescription:compressSequenceImageDescription
							  timeStamp:timeStamp];
		
		compressSequenceFrameCounter += 1;
		
		needsPictureUpdate = NO;
	}
}

- (OSStatus)_packetizeCompressedFrame:(UInt8 *)data 
							   length:(UInt32)dataLength
					 imageDescription:(ImageDescriptionHandle)imageDesc 
							timeStamp:(UInt32)timeStamp
{	
	OSErr err = noErr;
	
	sampleData.flags = 0;
	
	if(mediaPacketizer == NULL)
	{
		OSType packetizerToUse;
		
		switch(codecType)
		{
			case kH261CodecType:
				packetizerToUse = kRTP261MediaPacketizerType;
				break;
			case kH263CodecType:
				if(codecSpecificCallFlags >= kRTPPayload_FirstDynamic)
				{
					packetizerToUse = kRTP263PlusMediaPacketizerType;
				}
				else
				{
					packetizerToUse = kXMRTPH263PacketizerType;
				}
				break;
			case kH264CodecType:
				packetizerToUse = kXMRTPH264PacketizerType;
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
		
		SInt32 packetizerFlags = kRTPMPRealtimeModeFlag;
		if(codecType == kH264CodecType)
		{
			unsigned packetizationMode = (codecSpecificCallFlags >> 8) & 0xf;
			if(packetizationMode == 2)
			{
				packetizerFlags |= 2;
			}
		}
		err = RTPMPInitialize(mediaPacketizer, packetizerFlags);
		if(err != noErr)
		{
			NSLog(@"RTPMP initialize failed: %d", (int)err);
		}
		
		componentDescription.componentType = kXMPacketBuilderComponentType;
		componentDescription.componentSubType = kXMPacketBuilderComponentSubType;
		componentDescription.componentManufacturer = kXMPacketBuilderComponentManufacturer;
		componentDescription.componentFlags = 0;
		componentDescription.componentFlagsMask = 0;
		
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
		err = RTPMPSetMaxPacketSize(mediaPacketizer, 1438);
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
		
		if(codecType == kH264CodecType)
		{
			// The very first frame should include SPS / PPS atoms
			sampleData.flags = 1;
		}
	}
	
	if(needsPictureUpdate == YES && codecType == kH264CodecType)
	{
		sampleData.flags = 1;
	}
	
	sampleData.timeStamp = timeStamp;
	sampleData.sampleDescription = (Handle)imageDesc;
	sampleData.dataLength = dataLength;
	
	if(codecType == kH261CodecType)
	{
		[self _adjustH261Data:data];
	}
	
	sampleData.data = (const UInt8 *)data;
	
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

#define scanBit(theDataIndex, theMask) \
{ \
	theMask >>= 1; \
		if(theMask == 0) { \
			theDataIndex++; \
				theMask = 0x80; \
		} \
}

#define readBit(out, theData, theDataIndex, theMask) \
{ \
	out = theData[theDataIndex] & theMask; \
		scanBit(theDataIndex, theMask); \
}

- (void)_adjustH261Data:(UInt8 *)h261Data
{	
	// In the H.261 standard, there are two bits in PTYPE which
	// were originally unused. The first bit of them is now the
	// flag defining the still image mode. If this mode isn't used,
	// the flag should be set to one. This applies to the second
	// unused bit as well. Unfortunately, QuickTime sets these two
	// bits to zero, which causes problems on Tandberg devices.
	// Therefore, these bits are here set to one
	UInt32 dataIndex = 1;
	UInt8 mask = 0x01;
	
	UInt8 bit;
	readBit(bit, h261Data, dataIndex, mask);
	
	while(bit == 0)
	{
		readBit(bit, h261Data, dataIndex, mask);
	}
	
	dataIndex += 1;
	scanBit(dataIndex, mask);
	scanBit(dataIndex, mask);
	scanBit(dataIndex, mask);
	scanBit(dataIndex, mask);
	scanBit(dataIndex, mask);
	
	h261Data[dataIndex] |= mask;
	scanBit(dataIndex, mask);
	h261Data[dataIndex] |= mask;
}

@end

@implementation XMVideoInputModuleWrapper

#pragma mark Init & Deallocation Methods

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	return nil;
}

- (id)_initWithVideoInputModule:(id<XMVideoInputModule>)theVideoInputModule
{
	videoInputModule = [theVideoInputModule retain];
	devices = nil;
	isEnabled = YES;
	
	return self;
}

- (void)dealloc
{
	[videoInputModule release];
	[devices release];
	
	[super dealloc];
}

#pragma mark Internal Methods

- (id<XMVideoInputModule>)_videoInputModule
{
	return videoInputModule;
}

- (NSArray *)_devices
{
	return devices;
}

- (void)_setDevices:(NSArray *)theDevices
{
	NSArray *old = devices;
	devices = [theDevices retain];
	[old release];
}

- (BOOL)_hasSettingsForDevice:(NSString *)device
{
	return [videoInputModule hasSettingsForDevice:device];
}

- (NSView *)_settingsViewForDevice:(NSString *)device
{
	if([videoInputModule hasSettingsForDevice:device] == NO)
	{
		return nil;
	}
	
	return [videoInputModule settingsViewForDevice:device];
}

- (void)_setDefaultSettingsForDevice:(NSString *)device
{
	if([videoInputModule hasSettingsForDevice:device] == NO)
	{
		return;
	}
	
	[videoInputModule setDefaultSettingsForDevice:device];
}

#pragma mark XMVideoModule Methods

- (NSString *)name
{
	return [videoInputModule name];
}

- (BOOL)isEnabled
{
	return isEnabled;
}

- (void)setEnabled:(BOOL)flag
{
	if(flag == isEnabled)
	{
		return;
	}
	
	isEnabled = flag;
	
	[_XMMediaTransmitterSharedInstance _sendDeviceList];
}

- (BOOL)hasSettings
{
	return [videoInputModule hasSettingsForDevice:nil];
}

- (NSDictionary *)permamentSettings
{
	if([videoInputModule hasSettingsForDevice:nil] == NO)
	{
		return nil;
	}
	
	return [videoInputModule permamentSettings];
}

- (BOOL)setPermamentSettings:(NSDictionary *)settings
{
	if([videoInputModule hasSettingsForDevice:nil] == NO)
	{
		return NO;
	}
	
	return [videoInputModule setPermamentSettings:settings];
}

- (NSView *)settingsView
{
	return [self _settingsViewForDevice:nil];
}

- (void)setDefaultSettings
{
	[self _setDefaultSettingsForDevice:nil];
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
		UInt8 *data = ICMEncodedFrameGetDataPtr(encodedFrame);
		UInt32 dataLength = ICMEncodedFrameGetDataSize(encodedFrame);
		UInt32 timeStamp = ICMEncodedFrameGetDecodeTimeStamp(encodedFrame);
		ImageDescriptionHandle imageDesc;
		
		err = ICMEncodedFrameGetImageDescription(encodedFrame, &imageDesc);
		if(err != noErr)
		{
			NSLog(@"ICMEncodedFrameGetImageDescription failed: %d", err);
		}
		err = [mediaTransmitter _packetizeCompressedFrame:data length:dataLength imageDescription:imageDesc timeStamp:timeStamp];
	}
	
	return err;
}

void XMPacketizerDataReleaseProc(UInt8 *inData,
								 void *inRefCon)
{
}
