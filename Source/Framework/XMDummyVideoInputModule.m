/*
 * $Id: XMDummyVideoInputModule.m,v 1.3 2005/11/29 18:56:29 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
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

- (void)refreshDeviceList
{
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

- (void)setFrameGrabRate:(unsigned)theFrameGrabRate
{
	frameGrabRate = theFrameGrabRate;
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
			*bytes = 255;	// red value
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

void XMDummyPixelBufferReleaseCallback(void *releaseRefCon, 
									   const void *baseAddress)
{
	free((void *)baseAddress);
}

@end
