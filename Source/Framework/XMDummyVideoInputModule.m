/*
 * $Id: XMDummyVideoInputModule.m,v 1.15 2006/04/26 21:49:03 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMDummyVideoInputModule.h"

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

- (NSString *)identifier
{
	return @"XMDummyVideoInputModule";
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

- (BOOL)setInputFrameSize:(XMVideoSize)theVideoSize
{
	if(videoSize == theVideoSize)
	{
		return YES;
	}
	
	videoSize = theVideoSize;
	
	if(pixelBuffer != NULL)
	{
		CVPixelBufferRelease(pixelBuffer);
		pixelBuffer = NULL;
	}
	
	return YES;
}

- (BOOL)setFrameGrabRate:(unsigned)theFrameGrabRate
{	
	return YES;
}

- (BOOL)grabFrame
{
	if(pixelBuffer == NULL)
	{
		NSString *path = [[NSBundle mainBundle] pathForResource:@"DummyImage" ofType:@"gif"];
		NSData *data = [[NSData alloc] initWithContentsOfFile:path];
		NSBitmapImageRep *bitmapImageRep = [[NSBitmapImageRep alloc] initWithData:data];
		[data release];
		
		if(bitmapImageRep == nil)
		{
			[inputManager handleErrorWithCode:1 hintCode:0];
			return NO;
		}
		
		
		UInt8 *bitmapData = (UInt8 *)[bitmapImageRep bitmapData];
			
		unsigned width = [bitmapImageRep pixelsWide];
		unsigned height = [bitmapImageRep pixelsHigh];
		unsigned bytesPerRow = [bitmapImageRep bytesPerRow];
		
		pixelBuffer = XMCreatePixelBuffer(videoSize);
		
		void *context = XMCreateImageCopyContext(bitmapData, width, height, bytesPerRow, k24RGBPixelFormat,
												 pixelBuffer, XMImageScaleOperation_NoScaling);
		
		BOOL result = XMCopyImageIntoPixelBuffer(bitmapData, pixelBuffer, context);
		
		XMDisposeImageCopyContext(context);
		
		if(result == NO)
		{
			[inputManager handleErrorWithCode:2 hintCode:0];
			return NO;
		}
		
		[bitmapImageRep release];
	}
	
	[inputManager handleGrabbedFrame:pixelBuffer];
	
	return YES;
}

- (NSString *)descriptionForErrorCode:(int)errorCode hintCode:(int)hintCode device:(NSString *)device
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

@end
