/*
 * $Id: XMTransmitManager.m,v 1.1 2005/10/06 15:04:42 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMTransmitManager.h"
#import "XMVideoManager.h"
#import "XMPrivate.h"

typedef enum XMTransmitManagerMessage
{
	// general messages
	XMTransmitManagerMessage_Shutdown= 0x0000,
	
	// configuration messages
	XMTransmitManagerMessage_GetDeviceList = 0x0100,
	XMTransmitManagerMessage_SetDevice = 0x0101,
	XMTransmitManagerMessage_SetFrameGrabRate = 0x0102,
	
	// "action" messages
	XMTransmitManagerMessage_StartGrabbing = 0x0200,
	XMTransmitManagerMessage_StopGrabbing = 0x0201,
} XMTransmitManagerMessage;

@interface XMTransmitManager (PrivateMethods)

+ (void)_sendMessage:(XMTransmitManagerMessage)message withComponents:(NSArray *)components;

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

@end

@implementation XMTransmitManager

static XMTransmitManager *transmitManager = nil;

#pragma mark Class Methods

+ (void)_startupWithVideoInputModules:(NSArray *)inputModules
{
	if(transmitManager == nil)
	{
		transmitManager = [[XMTransmitManager alloc] _initWithVideoInputModules:inputModules];
		[NSThread detachNewThreadSelector:@selector(_runVideoTransmitThread) toTarget:transmitManager withObject:nil];
	}
}

+ (void)_getDeviceList
{
	[XMTransmitManager _sendMessage:XMTransmitManagerMessage_GetDeviceList withComponents:nil];
}

+ (void)_setDevice:(NSString *)device
{
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:device];
	NSArray *components = [[NSArray alloc] initWithObjects:data, nil];
	
	[XMTransmitManager _sendMessage:XMTransmitManagerMessage_SetDevice withComponents:components];
	
	[components release];
}

+ (void)_setFrameGrabRate:(unsigned)frameGrabRate
{
	NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:frameGrabRate];
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:number];
	NSArray *components = [[NSArray alloc] initWithObjects:data, nil];
	
	[XMTransmitManager _sendMessage:XMTransmitManagerMessage_SetFrameGrabRate withComponents:components];
	
	[components release];
	[number release];
}

+ (void)_startGrabbing
{
	[XMTransmitManager _sendMessage:XMTransmitManagerMessage_StartGrabbing withComponents:nil];
}

+ (void)_stopGrabbing
{
	[XMTransmitManager _sendMessage:XMTransmitManagerMessage_StopGrabbing withComponents:nil];
}

+ (void)_shutdown
{
	[XMTransmitManager _sendMessage:XMTransmitManagerMessage_Shutdown withComponents:nil];
}

+ (void)_sendMessage:(XMTransmitManagerMessage)message withComponents:(NSArray *)components
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
	XMTransmitManagerMessage message = (XMTransmitManagerMessage)[portMessage msgid];
	
	switch(message)
	{
		case XMTransmitManagerMessage_Shutdown:
			[self _handleShutdownMessage];
			break;
		case XMTransmitManagerMessage_GetDeviceList:
			[self _handleGetDeviceListMessage];
			break;
		case XMTransmitManagerMessage_SetDevice:
			[self _handleSetDeviceMessage:[portMessage components]];
			break;
		case XMTransmitManagerMessage_SetFrameGrabRate:
			[self _handleSetFrameGrabRateMessage:[portMessage components]];
			break;
		case XMTransmitManagerMessage_StartGrabbing:
			[self _handleStartGrabbingMessage];
			break;
		case XMTransmitManagerMessage_StopGrabbing:
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
	[activeModule setInputFrameSize:NSMakeSize(352, 288)];
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
	
	if(isGrabbing == YES)
	{
		[activeModule closeInputDevice];
	}
	
	[selectedDevice release];
	selectedDevice = nil;
	
	unsigned count = [videoInputModules count];
	unsigned i;
	
	for(i = 0; i < count; i++)
	{
		id<XMVideoInputModule> module = (id<XMVideoInputModule>)[videoInputModules objectAtIndex:0];
		
		NSArray *inputDevices = [module inputDevices];
		
		unsigned inputDeviceCount = [inputDevices count];
		unsigned j;
		
		for(j = 0; j < inputDeviceCount; j++)
		{
			NSString *device = (NSString *)[inputDevices objectAtIndex:j];
			if([device isEqualToString:deviceToSelect])
			{
				selectedDevice = [deviceToSelect retain];
				activeModule = module;
				
				if(isGrabbing == YES)
				{
					[activeModule openInputDevice:selectedDevice];
				}
				
				[[XMVideoManager sharedInstance] performSelectorOnMainThread:@selector(_handleInputDeviceChangeComplete)
																  withObject:nil waitUntilDone:NO];
				return;
			}
		}
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
	[activeModule grabFrame];
}

#pragma mark XMVideoInputManager Methods

- (void)handleGrabbedFrame:(CVPixelBufferRef)frame time:(TimeValue64)time
{	
	// sending the preview image to the video manager
	CIImage *previewImage = [[CIImage alloc] initWithCVImageBuffer:(CVImageBufferRef)frame];
	
	[[XMVideoManager sharedInstance] performSelectorOnMainThread:@selector(_handlePreviewImage:) withObject:previewImage waitUntilDone:NO];
}

- (void)handleErrorWithCode:(unsigned)errorCode
{
}

@end
