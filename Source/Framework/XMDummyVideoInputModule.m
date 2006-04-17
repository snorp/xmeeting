/*
 * $Id: XMDummyVideoInputModule.m,v 1.14 2006/04/17 17:51:22 hfriederich Exp $
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
		
		NSString *path = [[NSBundle mainBundle] pathForResource:@"DummyImage" ofType:@"gif"];
		NSData *data = [[NSData alloc] initWithContentsOfFile:path];
		NSBitmapImageRep *bitmapImageRep = [[NSBitmapImageRep alloc] initWithData:data];
		[data release];
		
		if(bitmapImageRep == nil)
		{
			[inputManager handleErrorWithCode:1 hintCode:0];
		}
		else
		{
			UInt8 *bytes = (UInt8 *)pixels;
			UInt8 *bitmapData = (UInt8 *)[bitmapImageRep bitmapData];
			
			unsigned bitmapWidth = [bitmapImageRep pixelsWide];
			unsigned bitmapHeight = [bitmapImageRep pixelsHigh];
			
			unsigned heightSpacing = (height - bitmapHeight) / 2;
			unsigned widthSpacing = (width - bitmapWidth) / 2;
			
			unsigned i;
			for(i = 0; i < height; i++)
			{
				unsigned j;
				for(j = 0; j < width; j++)
				{
					if(i < heightSpacing || i >= heightSpacing+bitmapHeight ||
					   j < widthSpacing || j >= widthSpacing+bitmapWidth)
					{
						// set black with full alpha
						*bytes = 255;
						bytes++;
						*bytes = 0;
						bytes++;
						*bytes = 0;
						bytes++;
						*bytes = 0;
						bytes++;
					}
					else
					{
						// full alpha
						*bytes = 255;
						bytes++;
						*bytes = *bitmapData;
						bytes++;
						bitmapData++;
						*bytes = *bitmapData;
						bytes++;
						bitmapData++;
						*bytes = *bitmapData;
						bytes++;
						bitmapData++;
					}
				}
			}
			
		}
		
		// creating the CVPixelBufferRef
		result = CVPixelBufferCreateWithBytes(NULL, (size_t)width, (size_t)height,
											  k32ARGBPixelFormat, pixels, 4*width,
											  XMDummyPixelBufferReleaseCallback, NULL, NULL, &pixelBuffer);
		
		if(result != kCVReturnSuccess)
		{
			[inputManager handleErrorWithCode:2 hintCode:0];
			NSLog(@"FAILED2");
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

void XMDummyPixelBufferReleaseCallback(void *releaseRefCon, 
									   const void *baseAddress)
{
	free((void *)baseAddress);
}

@end
