/*
 * $Id: XMVideoManager.m,v 1.2 2005/10/11 09:03:10 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMTypes.h"
#import "XMStringConstants.h"
#import "XMPrivate.h"
#import "XMVideoManager.h"
#import "XMMediaTransmitter.h"
#import "XMVideoView.h"
#import "XMSequenceGrabberVideoInputModule.h"
#import "XMDummyVideoInputModule.h"

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
	
	videoInputModules = nil;
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
	
	remoteVideoImage = nil;
	remoteVideoImageRep = nil;
	
	transmitFrameRate = 20;
	
	needsToStopLocalBusyIndicators = YES;
	
	return self;
}

- (void)dealloc
{
	[videoInputModules release];
	[localVideoViews release];
	[remoteVideoViews release];
	
	[inputDevices release];
	[selectedInputDevice release];
	
	[localVideoImage release];
	[localVideoImageRep release];
	
	[remoteVideoImage release];
	[remoteVideoImageRep release];
	
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
	[XMMediaTransmitter _getDeviceList];
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
		[XMMediaTransmitter _setDevice:selectedInputDevice];
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
	[XMMediaTransmitter _setFrameGrabRate:transmitFrameRate];
}

- (void)startGrabbing
{
	[XMMediaTransmitter _startGrabbing];
}

- (void)stopGrabbing
{
	[XMMediaTransmitter _stopGrabbing];
}

#pragma mark Framework Methods

- (void)_startup
{
	videoInputModules = [[NSMutableArray alloc] initWithCapacity:3];
	
	XMSequenceGrabberVideoInputModule *seqGrabModule = [[XMSequenceGrabberVideoInputModule alloc] init];
	[videoInputModules addObject:seqGrabModule];
	[seqGrabModule release];
	
	XMDummyVideoInputModule *dummyModule = [[XMDummyVideoInputModule alloc] init];
	[videoInputModules addObject:dummyModule];
	[dummyModule release];
	
	[XMMediaTransmitter _startupWithVideoInputModules:videoInputModules];
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
	if(remoteVideoImage != nil)
	{
		if(remoteVideoImageRep == nil)
		{
			remoteVideoImageRep = [[NSCIImageRep alloc] initWithCIImage:remoteVideoImage];
		}
		
		BOOL result = [remoteVideoImageRep drawInRect:rect];
		
		if(result == NO)
		{
			NSLog(@"Drawing remote failed");
		}
		
		return;
	}
	
	NSRectFill(rect);
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

- (void)_handleInputDeviceChangeComplete:(NSString *)device
{
	if([device isEqualToString:selectedInputDevice] == NO)
	{
		[selectedInputDevice release];
		selectedInputDevice = [device retain];
	}
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

	// we inherit the retain count from the MediaTransmitter
	localVideoImage = previewImage;
	
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

- (void)_handleRemoteImage:(CIImage *)remoteImage
{
	if(remoteVideoImage != nil)
	{
		[remoteVideoImage release];
		remoteVideoImage = nil;
		
		[remoteVideoImageRep release];
		remoteVideoImageRep = nil;
	}
	
	// we inherit the retain count from the MediaTransmitter
	remoteVideoImage = remoteImage;
	
	unsigned count = [remoteVideoViews count];
	unsigned i;
	
	for(i = 0; i < count; i++)
	{
		XMVideoView *videoView = (XMVideoView *)[remoteVideoViews objectAtIndex:i];
		
		[videoView setNeedsDisplay:YES];
	}
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