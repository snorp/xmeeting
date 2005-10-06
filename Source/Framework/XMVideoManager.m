/*
 * $Id: XMVideoManager.m,v 1.1 2005/10/06 15:04:42 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMTypes.h"
#import "XMStringConstants.h"
#import "XMPrivate.h"
#import "XMVideoManager.h"
#import "XMTransmitManager.h"
#import "XMVideoView.h"
#import "XMSequenceGrabberVideoInputModule.h"

@interface XMVideoManager (PrivateMethods)

- (id)_init;
- (void)_startLocalBusyIndicators;

@end

@implementation XMVideoManager

#pragma mark Class Methods

+ (XMVideoManager *)sharedInstance
{
	static XMVideoManager *sharedInstance = nil;
	
	if(sharedInstance == nil)
	{
		sharedInstance = [[XMVideoManager alloc] _init];
	}
	
	return sharedInstance;
}

#pragma mark Init & Deallocation Methods

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self  release];
	return nil;
}

- (id)_init
{
	self = [super init];
	
	localVideoViews = [[NSMutableArray alloc] initWithCapacity:3];
	remoteVideoViews = [[NSMutableArray alloc] initWithCapacity:3];
	
	inputDevices = nil;
	selectedInputDevice = nil;
	
	localVideoImage = nil;
	localVideoImageRep = nil;
	doesMirrorLocalVideo = NO;
	mirrorTransformationMatrix.a = -1;
	mirrorTransformationMatrix.b = 0;
	mirrorTransformationMatrix.c = 0;
	mirrorTransformationMatrix.d = 1;
	mirrorTransformationMatrix.tx = 0;
	mirrorTransformationMatrix.ty = 0;
	
	transmitFrameRate = 20;
	
	needsToStopLocalBusyIndicators = YES;
	
	return self;
}

- (void)dealloc
{
	[localVideoViews release];
	[remoteVideoViews release];
	
	[inputDevices release];
	[selectedInputDevice release];
	
	[localVideoImage release];
	[localVideoImageRep release];
	
	[super dealloc];
}

#pragma mark Public Methods

- (NSArray *)inputDevices
{
	return inputDevices;
}

- (void)updateInputDeviceList
{
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_VideoManagerDidStartInputDeviceListUpdate
														object:self];
	[XMTransmitManager _getDeviceList];
}

- (NSString *)selectedInputDevice
{
	return selectedInputDevice;
}

- (void)setSelectedInputDevice:(NSString *)inputDevice
{
	if(inputDevice != nil && ![inputDevice isEqualToString:selectedInputDevice])
	{
		[selectedInputDevice release];
		selectedInputDevice = [inputDevice retain];
		[self _startLocalBusyIndicators];
		[XMTransmitManager _setDevice:selectedInputDevice];
	}
}

- (BOOL)doesMirrorLocalVideo
{
	return doesMirrorLocalVideo;
}

- (void)setDoesMirrorLocalVideo:(BOOL)flag
{
	doesMirrorLocalVideo = flag;
}

- (unsigned)transmitFrameRate
{
	return transmitFrameRate;
}

- (void)setTransmitFrameRate:(unsigned)theRate
{
	transmitFrameRate = theRate;
	[XMTransmitManager _setFrameGrabRate:transmitFrameRate];
}

- (void)startGrabbing
{
	[XMTransmitManager _startGrabbing];
	
	[NSTimer scheduledTimerWithTimeInterval:7.0 target:self selector:@selector(_test:) userInfo:nil repeats:NO];
}

- (void)_test:(NSTimer *)timer
{
	[XMTransmitManager _shutdown];
}

- (void)stopGrabbing
{
	[XMTransmitManager _stopGrabbing];
}

#pragma mark Framework Methods

- (void)_startup
{
	NSMutableArray *videoInputModules = [[NSMutableArray alloc] initWithCapacity:3];
	
	XMSequenceGrabberVideoInputModule *module = [[XMSequenceGrabberVideoInputModule alloc] init];
	[videoInputModules addObject:module];
	
	[XMTransmitManager _startupWithVideoInputModules:videoInputModules];
	
	[videoInputModules release];
}

- (void)_addLocalVideoView:(XMVideoView *)videoView
{
	[localVideoViews addObject:videoView];
	
	if(localVideoImage == nil)
	{
		[videoView _startBusyIndicator];
	}
	else
	{
		[videoView setNeedsDisplay:YES];
	}
}

- (void)_removeLocalVideoView:(XMVideoView *)videoView
{
	[localVideoViews removeObject:videoView];
	[videoView _stopBusyIndicator];
}

- (void)_addRemoteVideoView:(XMVideoView *)videoView
{
	[remoteVideoViews addObject:videoView];
}

- (void)_removeRemoteVideoView:(XMVideoView *)videoView
{
	[remoteVideoViews removeObject:videoView];
}

- (void)_drawLocalVideoInRect:(NSRect)rect
{
	if(localVideoImage != nil)
	{
		if(localVideoImageRep == nil)
		{
			localVideoImageRep = [[NSCIImageRep alloc] initWithCIImage:localVideoImage];
		}
		
		BOOL result = [localVideoImageRep drawInRect:rect];
		
		if(result == NO)
		{
			NSLog(@"drawing preview failed");
		}
		
		return;
	}
	
	NSEraseRect(rect);
}

- (void)_drawRemoteVideoInRect:(NSRect)rect
{
}

- (void)_handleDeviceList:(NSArray *)deviceList
{
	[inputDevices release];
	
	inputDevices = [deviceList copy];
	
	if(selectedInputDevice == nil || [inputDevices indexOfObject:selectedInputDevice] == NSNotFound)
	{
		[selectedInputDevice release];
		selectedInputDevice = [[inputDevices objectAtIndex:0] retain];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_VideoManagerDidUpdateInputDeviceList
														object:nil];
}

- (void)_handleInputDeviceChangeComplete
{
	needsToStopLocalBusyIndicators = YES;
}

- (void)_handlePreviewImage:(CIImage *)previewImage
{
	if(localVideoImage != nil)
	{
		[localVideoImage release];
		localVideoImage = nil;
		
		[localVideoImageRep release];
		localVideoImageRep = nil;
	}

	localVideoImage = previewImage;
	
	CGRect imageExtent = [localVideoImage extent];
	NSLog(@"image: %d %d", (int)imageExtent.size.width, (int)imageExtent.size.height);
	
	if(doesMirrorLocalVideo)
	{
		CGRect imageExtent = [localVideoImage extent];
		mirrorTransformationMatrix.tx = imageExtent.size.width;
		
		CIImage *image = [localVideoImage imageByApplyingTransform:mirrorTransformationMatrix];
		[localVideoImage release];
		localVideoImage = [image retain];
	}
	
	unsigned count = [localVideoViews count];
	unsigned i;
	
	for(i = 0; i < count; i++)
	{
		XMVideoView *videoView = (XMVideoView *)[localVideoViews objectAtIndex:i];
		
		if(needsToStopLocalBusyIndicators == YES)
		{
			[videoView _stopBusyIndicator];
		}
		[videoView setNeedsDisplay:YES];
	}
	needsToStopLocalBusyIndicators = NO;
}

#pragma mark Private Methods

- (void)_startLocalBusyIndicators
{
	unsigned count = [localVideoViews count];
	unsigned i;
	
	for(i = 0; i < count; i++)
	{
		XMVideoView *videoView = (XMVideoView *)[localVideoViews objectAtIndex:i];
		[videoView _startBusyIndicator];
	}
}

@end