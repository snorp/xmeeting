/*
 * $Id: XMDummyVideoInputModule.m,v 1.7 2006/02/08 23:25:54 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMDummyVideoInputModule.h"

void XMDummyPixelBufferReleaseCallback(void *releaseRefCon, 
									   const void *baseAddress);

@implementation XMDummyVideoInputModule

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	return nil;
}

- (id)_init
{
	self = [super init];
	
	NSString *deviceName = NSLocalizedString(@"<No Device>", @"");
	
	device = [[NSArray alloc] initWithObjects:deviceName, nil];
	
	inputManager = nil;
	
	pixelBuffer = NULL;
	
	return self;
}

- (void)dealloc
{
	[inputManager release];
	
	[device release];
	
	[super dealloc];
}

- (NSString *)name
{
	return @"Dummy Module";
}

- (void)setupWithInputManager:(id<XMVideoInputManager>)theManager
{
	inputManager = [theManager retain];
}

- (void)close
{
	[inputManager release];
	inputManager = nil;
}

- (NSArray *)inputDevices
{
	return device;
}

- (BOOL)openInputDevice:(NSString *)device
{
	[inputManager setTimeScale:600];
	[inputManager noteTimeStampReset];
	timeStamp = 0;
	return YES;
}

- (BOOL)closeInputDevice
{
	if(pixelBuffer != NULL)
	{
		CVPixelBufferRelease(pixelBuffer);
		pixelBuffer = NULL;
	}
	return YES;
}

- (BOOL)setInputFrameSize:(NSSize)theSize
{
	size = theSize;
	
	if(pixelBuffer != NULL)
	{
		CVPixelBufferRelease(pixelBuffer);
		pixelBuffer = NULL;
	}
	return YES;
}

- (BOOL)setFrameGrabRate:(unsigned)theFrameGrabRate
{
	frameGrabRate = theFrameGrabRate;
	
	return YES;
}

- (BOOL)grabFrame
{
	if(pixelBuffer == NULL)
	{
		CVReturn result;
		
		unsigned width = size.width;
		unsigned height = size.height;
		unsigned usedBytes = 4*width*height;
		
		// creating a buffer for the pixels
		void *pixels = malloc(usedBytes);
		
		// filling the buffer with a color (currently black)
		UInt8 *bytes = (UInt8 *)pixels;
		unsigned i;
		unsigned count = width*height;
		for(i = 0; i < count; i++)
		{
			*bytes = 255;	// alpha value
			bytes++;
			*bytes = 0;		// red value
			bytes++;
			*bytes = 0;		// green value
			bytes++;
			*bytes = 0;		// blue value
			bytes++;
		}
		
		// creating the CVPixelBufferRef
		result = CVPixelBufferCreateWithBytes(NULL, (size_t)width, (size_t)height,
											  k32ARGBPixelFormat, pixels, 4*width,
											  XMDummyPixelBufferReleaseCallback, NULL, NULL, &pixelBuffer);
		
		if(result != kCVReturnSuccess)
		{
			//[inputManager handleErrorWithCode:(ComponentResult)result hintCode:1];
			return NO;
		}
	}
	
	[inputManager handleGrabbedFrame:pixelBuffer time:timeStamp];
	timeStamp += (600 / frameGrabRate);
	
	return YES;
}

- (NSString *)descriptionForErrorCode:(unsigned)errorCode device:(NSString *)device
{
	return nil;
}

- (BOOL)hasSettingsForDevice:(NSString *)device
{
	return NO;
}

- (BOOL)requiresSettingsDialogWhenDeviceOpens:(NSString *)device
{
	return NO;
}

- (NSData *)internalSettings
{
	return nil;
}

- (void)applyInternalSettings:(NSData *)settings
{
}

- (NSDictionary *)permamentSettings
{
	return nil;
}

- (BOOL)setPermamentSettings:(NSDictionary *)settings
{
	return NO;
}

- (NSView *)settingsViewForDevice:(NSString *)device
{
	return nil;
}

- (void)setDefaultSettingsForDevice:(NSString *)device
{
}

void XMDummyPixelBufferReleaseCallback(void *releaseRefCon, 
									   const void *baseAddress)
{
	free((void *)baseAddress);
}

@end
