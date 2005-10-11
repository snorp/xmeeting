/*
 * $Id: XMMediaTransmitter.m,v 1.1 2005/10/11 09:03:10 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMMediaTransmitter.h"
#import "XMVideoManager.h"
#import "XMPrivate.h"

typedef enum XMMediaTransmitterMessage
{
	// general messages
	XMMediaTransmitterMessage_Shutdown= 0x0000,
	
	// configuration messages
	XMMediaTransmitterMessage_GetDeviceList = 0x0100,
	XMMediaTransmitterMessage_SetDevice = 0x0101,
	XMMediaTransmitterMessage_SetFrameGrabRate = 0x0102,
	
	// "action" messages
	XMMediaTransmitterMessage_StartGrabbing = 0x0200,
	XMMediaTransmitterMessage_StopGrabbing = 0x0201,
} XMMediaTransmitterMessage;

@interface XMMediaTransmitter (PrivateMethods)

+ (void)_sendMessage:(XMMediaTransmitterMessage)message withComponents:(NSArray *)components;

- (id)_initWithVideoInputModules:(NSArray *)videoInputModules;

- (NSPort *)_receivePort;

- (void)_runVideoTransmitThread;
- (void)handlePortMessage:(NSPortMessage *)portMessage;

- (void)_handleShutdownMessage;
- (void)_handleGetDeviceListMessage;
- (void)_handleSetDeviceMessage:(NSArray *)messageComponents;
- (void)_handleSetFrameGrabRateMessage:(NSArray *)messageComponents;
- (void)_handleStartGrabbingMessage;
- (void)_handleStopGrabbingMessage;

- (void)_grabFrame:(NSTimer *)timer;

- (void)_updateDeviceListAndSelectDummy;

@end

@implementation XMMediaTransmitter

static XMMediaTransmitter *transmitManager = nil;

#pragma mark Class Methods

+ (void)_startupWithVideoInputModules:(NSArray *)inputModules
{
	if(transmitManager == nil)
	{
		transmitManager = [[XMMediaTransmitter alloc] _initWithVideoInputModules:inputModules];
		[NSThread detachNewThreadSelector:@selector(_runVideoTransmitThread) toTarget:transmitManager withObject:nil];
	}
}

+ (void)_getDeviceList
{
	[XMMediaTransmitter _sendMessage:XMMediaTransmitterMessage_GetDeviceList withComponents:nil];
}

+ (void)_setDevice:(NSString *)device
{
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:device];
	NSArray *components = [[NSArray alloc] initWithObjects:data, nil];
	
	[XMMediaTransmitter _sendMessage:XMMediaTransmitterMessage_SetDevice withComponents:components];
	
	[components release];
}

+ (void)_setFrameGrabRate:(unsigned)frameGrabRate
{
	NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:frameGrabRate];
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:number];
	NSArray *components = [[NSArray alloc] initWithObjects:data, nil];
	
	[XMMediaTransmitter _sendMessage:XMMediaTransmitterMessage_SetFrameGrabRate withComponents:components];
	
	[components release];
	[number release];
}

+ (void)_startGrabbing
{
	[XMMediaTransmitter _sendMessage:XMMediaTransmitterMessage_StartGrabbing withComponents:nil];
}

+ (void)_stopGrabbing
{
	[XMMediaTransmitter _sendMessage:XMMediaTransmitterMessage_StopGrabbing withComponents:nil];
}

+ (void)_shutdown
{
	[XMMediaTransmitter _sendMessage:XMMediaTransmitterMessage_Shutdown withComponents:nil];
}

+ (void)_sendMessage:(XMMediaTransmitterMessage)message withComponents:(NSArray *)components
{
	if(transmitManager == nil)
	{
		NSLog(@"Would raise an exception here!");
		return;
	}
	NSPort *thePort = [transmitManager _receivePort];
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

- (id)_initWithVideoInputModules:(NSArray *)inputModules
{
	self = [super init];
	
	videoInputModules = [inputModules copy];
	receivePort = [[NSPort port] retain];
	
	isGrabbing = NO;
	isTransmitting = NO;
	
	frameGrabRate = 20;
	
	compressionSession = NULL;
	mediaPacketizer = 0L;

	return self;
}

- (void)dealloc
{
	// have yet to complete
	
	[super dealloc];
}

#pragma mark Thread methods

- (NSPort *)_receivePort
{
	return receivePort;
}

- (void)_runVideoTransmitThread
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	EnterMovies();
	
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
	[[XMVideoManager sharedInstance] performSelectorOnMainThread:@selector(_handleDeviceList:) withObject:devices
												   waitUntilDone:NO];
	[devices release];
	
	// running the run loop
	[[NSRunLoop currentRunLoop] run];
	
	[autoreleasePool release];
	autoreleasePool = nil;
}

- (void)handlePortMessage:(NSPortMessage *)portMessage
{
	XMMediaTransmitterMessage message = (XMMediaTransmitterMessage)[portMessage msgid];
	
	switch(message)
	{
		case XMMediaTransmitterMessage_Shutdown:
			[self _handleShutdownMessage];
			break;
		case XMMediaTransmitterMessage_GetDeviceList:
			[self _handleGetDeviceListMessage];
			break;
		case XMMediaTransmitterMessage_SetDevice:
			[self _handleSetDeviceMessage:[portMessage components]];
			break;
		case XMMediaTransmitterMessage_SetFrameGrabRate:
			[self _handleSetFrameGrabRateMessage:[portMessage components]];
			break;
		case XMMediaTransmitterMessage_StartGrabbing:
			[self _handleStartGrabbingMessage];
			break;
		case XMMediaTransmitterMessage_StopGrabbing:
			[self _handleStopGrabbingMessage];
			break;
		default:
			// ignore it
			break;
	}
}

#pragma mark Message handling methods

- (void)_handleShutdownMessage
{
	NSLog(@"Should shutdown here");
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
	
	[[XMVideoManager sharedInstance] performSelectorOnMainThread:@selector(_handleDeviceList:) withObject:devices
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
						[module setInputFrameSize:NSMakeSize(176, 144)];
						[module setFrameGrabRate:frameGrabRate];
					}
					
					didSucceed = [module openInputDevice:deviceToSelect];
				}
				
				if(didSucceed == YES)
				{
					activeModule = module;
					selectedDevice = [deviceToSelect retain];
					
					[[XMVideoManager sharedInstance] performSelectorOnMainThread:@selector(_handleInputDeviceChangeComplete:)
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
	
	[activeModule setInputFrameSize:NSMakeSize(176, 144)];
	[activeModule setFrameGrabRate:frameGrabRate];
	BOOL result = [activeModule openInputDevice:[[activeModule inputDevices] objectAtIndex:0]];
	
	if(result == NO)
	{
		NSLog(@"Opening device failed");
	}
	
	isGrabbing = YES;
	
	// starting the timer and grabbing the first frame
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
}

- (void)_grabFrame:(NSTimer *)timer
{
	if(isGrabbing == NO)
	{
		[timer invalidate];
		return;
	}
	
	NSTimeInterval desiredTimeInterval = 1.0/frameGrabRate;
	
	// readjusting the timer interval if needed
	if(timer == nil || [timer timeInterval] != desiredTimeInterval)
	{
		[timer invalidate];
		
		[NSTimer scheduledTimerWithTimeInterval:desiredTimeInterval target:self 
									   selector:@selector(_grabFrame:) userInfo:nil repeats:YES];
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
	
	[[XMVideoManager sharedInstance] performSelectorOnMainThread:@selector(_handleInputDeviceChangeComplete:)
													  withObject:selectedDevice waitUntilDone:NO];
	[[XMVideoManager sharedInstance] performSelectorOnMainThread:@selector(_handleDeviceList:) withObject:devices
												   waitUntilDone:NO];
	[devices release];
	
	[activeModule openInputDevice:selectedDevice];
}

#pragma mark XMVideoInputManager Methods

- (void)handleGrabbedFrame:(CVPixelBufferRef)frame time:(TimeValue64)time
{	
	// sending the preview image to the video manager
	CIImage *previewImage = [[CIImage alloc] initWithCVImageBuffer:(CVImageBufferRef)frame];
	
	[[XMVideoManager sharedInstance] performSelectorOnMainThread:@selector(_handlePreviewImage:) withObject:previewImage waitUntilDone:NO];
}

- (void)handleErrorWithCode:(ComponentResult)errorCode hintCode:(unsigned)hintCode
{
	NSLog(@"gotErrorReport: %d hint: %d", (int)errorCode, (int)hintCode);
}

@end
