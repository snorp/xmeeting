/*
 * $Id: XMScreenVideoInputModule.m,v 1.10 2006/04/26 21:49:03 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Mark Fleming. All rights reserved.
 */

#import "XMScreenVideoInputModule.h"

void XMScreenModuleRefreshCallback(CGRectCount count, const CGRect *rectArray, void *context);

@interface XMScreenVideoInputModule (PrivateMethods)

- (void)_setNeedsUpdate:(BOOL)flag;
- (void)_doScreenCopy;
- (void)_doScreenCopy_32;
- (void)_doScreenCopy_24;
- (void)_doScreenCopy_16;
- (void)_handleUpdatedScreenRects:(const CGRect *)rectArray count:(CGRectCount)count;

@end

@implementation XMScreenVideoInputModule

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
	
	inputManager = nil;
	
	NSString *deviceName = NSLocalizedString(@"Screen %d", @"");
	int i;
	NSArray *screens = [NSScreen screens];	// array of NSScreen objects representing all of the screens available on the system.
	
	// When the display configuration is changed, NSApplicationDidChangeScreenParametersNotification is sent by the default notification center.

	// The first screen in the screens array is always the "zero" screen. To obtain the menu bar screen use [[NSScreen screens] objectAtIndex:0]
	// (after checking that the screens array is not empty).

	screenNames = [[NSMutableArray alloc] initWithObjects: nil];

	for (i = 0; i < [screens count]; i++) 
	{
		[screenNames addObject: [NSString stringWithFormat:deviceName, i]];	// one device for each screen.
		
		NSScreen *aScreen = [[NSScreen screens] objectAtIndex:i];
		NSDictionary *deviceDescription = [aScreen deviceDescription];
		NSLog(@"screen %d, %@", i, deviceDescription);		// DEBUG
	}
	
	displayID = NULL;
	screenRect = NSMakeRect(0, 0, 0, 0);
	rowBytesScreen = 0;
	needsUpdate = NO;
	topLine = 0;
	bottomLine = 0;
	screenPixelFormat = 0;
	
	updateLock = [[NSLock alloc] init];
	
	frameRect = NSMakeRect(0, 0, 0, 0);
	
	videoSize = XMVideoSize_NoVideo;
	
	pixelBuffer = NULL;
	imageBuffer = NULL;
	imageCopyContext = NULL;
	
	droppedFrameCounter = 0;
	
	return self;
}

- (void)dealloc
{	
	if (displayID != NULL)
	{
		[self closeInputDevice];
	}
	
	[inputManager release];
	
	[updateLock release];
	
	[screenNames release];
	
	if(pixelBuffer != NULL)
	{
		CVPixelBufferRelease(pixelBuffer);
	}
	if(imageCopyContext != NULL)
	{
		XMDisposeImageCopyContext(imageCopyContext);
	}
	if(imageBuffer != NULL)
	{
		free(imageBuffer);
	}
	
	[super dealloc];
}

#pragma mark -
#pragma mark XMVideoInputModue methods

- (NSString *)identifier
{
	return @"XMScreenVideoInputModule";
}

- (NSString *)name
{
	return @"Screen Module";
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
	return screenNames;
}

- (BOOL)setInputFrameSize:(XMVideoSize)theVideoSize
{
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

// locate screen with this device... Screen 0, Screen 2, etc...
- (BOOL)openInputDevice:(NSString *)device
{	
	int i;

	for (i = 0; i < [screenNames count]; i++)
	{
		if ([device isEqualToString:[screenNames objectAtIndex:i]]) 
		{
			// screen X selected.
			NSArray *screens = [NSScreen screens];	// array of NSScreen objects representing all of the screens available on the system.
			NSScreen *aScreen;
			NSDictionary *deviceDescription;
			NSNumber *aNum;
			if (i + 1 > [screens count]) 
			{
				// screen no longer available
				return NO;
			}
		
			aScreen = [[NSScreen screens] objectAtIndex:i];
			screenRect = [aScreen frame];
			NSLog(@"screenRect: %d %d %d %d", (int)screenRect.origin.x, (int)screenRect.origin.y, (int)screenRect.size.width, (int)screenRect.size.height);
			//[self setFrameRect: &aRect];	
			deviceDescription = [aScreen deviceDescription];
			//  	@"NSScreenNumber"	An NSNumber that contains the CGDirectDisplayID for the screen device. This key is only valid for the device description dictionary for an NSScreen.
			aNum = [deviceDescription objectForKey: @"NSScreenNumber"];
			displayID = (CGDirectDisplayID)[aNum intValue];
			NSLog(@"screen %@", deviceDescription);
			
/* 
	2006-02-08 17:29:39.566 XMeeting[3348] screen {
    NSDeviceBitsPerSample = 8; 
    NSDeviceColorSpaceName = NSCalibratedRGBColorSpace; 
    NSDeviceIsScreen = YES; 
    NSDeviceResolution = <42900000 42900000 >; 
    NSDeviceSize = <44a00000 44400000 >; 
    NSScreenNumber = 1535231424; 
}

1024 x 768 - Millons:
2006-02-08 17:31:29.909 XMeeting[3373] screen {
    NSDeviceBitsPerSample = 8; 
    NSDeviceColorSpaceName = NSCalibratedRGBColorSpace; 
    NSDeviceIsScreen = YES; 
    NSDeviceResolution = <42900000 42900000 >; 
    NSDeviceSize = <44800000 44400000 >; 
    NSScreenNumber = 1535231424; 
}
2006-02-08 17:31:29.913 XMeeting[3373] Screen Geometry Changed - (1024,768) Depth: 32, Samples: 3, rowBytesScreen 4096

2006-02-08 17:32:49.837 XMeeting[3373] screen {
    NSDeviceBitsPerSample = 8; 
    NSDeviceColorSpaceName = NSCalibratedRGBColorSpace; 
    NSDeviceIsScreen = YES; 
    NSDeviceResolution = <42900000 42900000 >; 
    NSDeviceSize = <44a00000 44400000 >; 
    NSScreenNumber = 1535231424; 
}
2006-02-08 17:32:49.872 XMeeting[3373] Screen Geometry Changed - (1280,768) Depth: 32, Samples: 3, rowBytesScreen 5120


Thousands of color:
2006-02-08 17:34:09.579 XMeeting[3373] screen {
    NSDeviceBitsPerSample = 8; 
    NSDeviceColorSpaceName = NSCalibratedRGBColorSpace; 
    NSDeviceIsScreen = YES; 
    NSDeviceResolution = <42900000 42900000 >; 
    NSDeviceSize = <44800000 44400000 >; 
    NSScreenNumber = 1535231424; 
}
2006-02-08 17:34:09.616 XMeeting[3373] Screen Geometry Changed - (1024,768) Depth: 16, Samples: 3, rowBytesScreen 2048

256 color does not work
*/
		}

	}	// end for i
	
	CGRegisterScreenRefreshCallback(XMScreenModuleRefreshCallback, self);
	
	return YES;
}

- (BOOL)closeInputDevice
{	
	CGUnregisterScreenRefreshCallback(XMScreenModuleRefreshCallback, self);
	displayID = NULL;
	
	if(pixelBuffer != NULL)
	{
		CVPixelBufferRelease(pixelBuffer);
		pixelBuffer = NULL;
	}
	if(imageBuffer != NULL)
	{
		free(imageBuffer);
		imageBuffer = NULL;
	}
	if(imageCopyContext != NULL)
	{
		XMDisposeImageCopyContext(imageCopyContext);
		imageCopyContext = NULL;
	}
	
	return YES;
}

// called by timer to get updates...
- (BOOL)grabFrame
{	
	if(pixelBuffer == NULL)
	{
		// see:  CoreGraphics/CGDirectDisplay.h
		rowBytesScreen = CGDisplayBytesPerRow(displayID);
		unsigned height = CGDisplayPixelsHigh(displayID);
		unsigned width = CGDisplayPixelsWide(displayID);
		
		NSLog(@"Screen Geometry Changed - (%d,%d) Depth: %d, Samples: %d, rowBytesScreen %d\n", 
			  width,  height,
			  CGDisplayBitsPerPixel(displayID), CGDisplaySamplesPerPixel(displayID), rowBytesScreen);
		
		unsigned usedBytes = rowBytesScreen*height;
		
		if (rowBytesScreen == 4 * width) 
		{
			screenPixelFormat = k32ARGBPixelFormat;		// 32bit color for video
		} 
		else if (rowBytesScreen == 3 * width) 
		{
			screenPixelFormat = k24RGBPixelFormat;		// 24 bit color for video
		} 
		else if (rowBytesScreen == 2 * width)
		{
			screenPixelFormat = k16BE555PixelFormat;	// Thousands for video
		} 
		else
		{
			[inputManager handleErrorWithCode:1 hintCode:1]; //256 color video
			return NO;
		}
	
		// creating the CVPixelBufferRef
		pixelBuffer = XMCreatePixelBuffer(XMVideoSize_CIF);
		
		if(pixelBuffer == NULL)
		{
			return NO;
		}
		
		imageBuffer = malloc(usedBytes);	// creating an buffer for the pixels
		
		imageCopyContext = XMCreateImageCopyContext(imageBuffer, width, height, rowBytesScreen,
													screenPixelFormat, pixelBuffer, 
													XMImageScaleOperation_ScaleProportionally);
		
		[self _setNeedsUpdate:YES];
		topLine = 0;
		bottomLine = height;
	}
	
	if (needsUpdate) 
	{
		[self _doScreenCopy];
		
		[inputManager handleGrabbedFrame:pixelBuffer];
		[self _setNeedsUpdate:NO];
		
		droppedFrameCounter = 0;
	}
	else
	{
		droppedFrameCounter++;
		
		if(droppedFrameCounter == 5)
		{
			[inputManager handleGrabbedFrame:pixelBuffer];
			droppedFrameCounter = 0;
		}
	}
	
	return YES;
}

- (NSString *)descriptionForErrorCode:(int)errorCode hintCode:(int)code device:(NSString *)device
{
	return @"Cannot grab from screen with 256 colors";
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

#pragma mark -
#pragma mark Handling Screen settings

- (NSRect)frameRect
{
	return frameRect;
}

- (void)setFrameRect:(NSRect *)aRect;
{	
	frameRect = *aRect;
}

#pragma mark -
#pragma mark Screen update handling

- (void)_setNeedsUpdate:(BOOL)v
{	
	needsUpdate = v;
}

- (void)_doScreenCopy
{	
	[updateLock lock];
	
	UInt8 *bytes = imageBuffer;
	UInt8 *screenPtr = CGDisplayBaseAddress(displayID);
	bytes += (topLine * rowBytesScreen);
	screenPtr += (topLine * rowBytesScreen);
	
	unsigned numberOfLines = bottomLine - topLine;
	
	memcpy(bytes, screenPtr, numberOfLines*rowBytesScreen);
	
	topLine = screenRect.size.height;
	bottomLine = 0;
	
	[updateLock unlock];
	
	BOOL result = XMCopyImageIntoPixelBuffer(imageBuffer, pixelBuffer, imageCopyContext);
	
	if(result == NO)
	{
		NSLog(@"Couldn't copy to pixel buffer");
	}
}

- (void)_handleUpdatedScreenRects:(const CGRect *)rectArray count:(CGRectCount)count;
{
	unsigned i;
	
	[updateLock lock];
	
	for(i = 0; i < count; i++)
	{
		CGRect theRect = rectArray[i];
		NSRect rect = NSMakeRect(theRect.origin.x, theRect.origin.y, theRect.size.width, theRect.size.height);
		NSRect intersection = NSIntersectionRect(screenRect, rect);
		
		if(intersection.size.width != 0.0f || intersection.size.height != 0.0f)
		{
			unsigned top = intersection.origin.y - screenRect.origin.y;
			unsigned bottom = top + intersection.size.height;
			
			if(top < topLine)
			{
				topLine = top;
			}
			
			if(bottom > bottomLine)
			{
				bottomLine = bottom;
			}
			
			[self _setNeedsUpdate:YES];
		}
	}
	
	[updateLock unlock];
}

@end

#pragma mark -
#pragma mark Callbacks

void XMScreenModuleRefreshCallback(CGRectCount count, const CGRect *rectArray, void *context) 
{
	XMScreenVideoInputModule *module = (XMScreenVideoInputModule *)context;

	[module _handleUpdatedScreenRects:rectArray count:count];
}
