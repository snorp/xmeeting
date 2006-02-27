/*
 * $Id: XMScreenVideoInputModule.m,v 1.8 2006/02/27 23:23:58 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Mark Fleming. All rights reserved.
 */

#import "XMScreenVideoInputModule.h"

void XMScreenPixelBufferReleaseCallback(void *releaseRefCon, 
									   const void *baseAddress);

@implementation XMScreenVideoInputModule

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	return nil;
}

- (id)_init
{
	self = [super init];
	
	updateLock = [[NSLock alloc] init];
	
	// change this to allow for selecting any screen
	
	NSString *deviceName = NSLocalizedString(@"Screen %d", @"");
	int i;
	NSArray *screens = [NSScreen screens];	// array of NSScreen objects representing all of the screens available on the system.
	
	//	When the display configuration is changed, NSApplicationDidChangeScreenParametersNotification is sent by the default notification center.

	//  The first screen in the screens array is always the “zero” screen. To obtain the menu bar screen use [[NSScreen screens] objectAtIndex:0] (after checking that the screens array is not empty).

	screenNames = [[NSMutableArray alloc] initWithObjects: nil];

	for (i= 0; i < [screens count]; i++) {
			[screenNames addObject: [NSString stringWithFormat:deviceName, i]];	// one device for each screen.
		#if 0
		NSScreen *aScreen = [[NSScreen screens] objectAtIndex:i];
		NSDictionary *deviceDescription = [aScreen deviceDescription];
		NSLog(@"screen %d, %@", i, deviceDescription);		// DEBUG
		#endif
	}
	inputManager = nil;
	pixelBuffer = NULL;
	displayID = NULL;
	return self;
}

- (void)dealloc
{	if (displayID != NULL) 
		[self closeInputDevice];
	
	[updateLock release];
		
	[inputManager release];
	
	[screenNames release];
	
	[super dealloc];
}

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
//	if (displayID != NULL) 
//		[self closeInputDevice];
		
	[inputManager release];
	inputManager = nil;
}

- (NSArray *)inputDevices
{
	return screenNames;
}

- (NSRect) frameRect
{
	return frameRect;
}

- (void) setRrameRect: (NSRect *) aRect;
{	frameRect = *aRect;
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


#pragma mark Image handling...
- (void) setNeedsUpdate: (BOOL) v
{	needsUpdate = v;
	
}

- (void) doScreenCopy
{
	UInt8 *bytes;
	UInt8 *screen;
	unsigned j, top;
//	unsigned height = CVPixelBufferGetHeight(pixelBuffer);		// check current buffer.
																// simple optimzation is to only copy rect passed.
																// For now only copy row changed.
	CVPixelBufferLockBaseAddress (pixelBuffer, 0);
  
	[updateLock lock];
		NSLog(@"%d to %d", topLine, bottomLine);
		bytes = CVPixelBufferGetBaseAddress (pixelBuffer);
		screen = CGDisplayBaseAddress(displayID);
		bytes += (topLine * rowBytesScreen);
		screen += (topLine * rowBytesScreen);
		
		for (j = topLine; j < bottomLine; j++) {	// one line at time..
			memcpy(bytes, screen, rowBytesScreen);
			screen += rowBytesScreen;
			bytes  += rowBytesScreen;
		}
		
		topLine = CVPixelBufferGetHeight(pixelBuffer);
		bottomLine = 0;
		[updateLock unlock];
		
	CVPixelBufferUnlockBaseAddress	(pixelBuffer, 0);	
	//topLine = CVPixelBufferGetHeight(pixelBuffer);	// reset update area to nil.
	//bottomLine = 0;
		// Note: need to look out reference callback..
}

#define optimzeScreenCopy 0
- (void) doRefeshFromScreen: (CGRectCount) count rects: (const CGRect *)rectArray
{
#ifdef optimzeScreenCopy
	UInt8 *bytes;
	UInt8 *screen;
	unsigned i, j, top, bottom;
	unsigned height = CVPixelBufferGetHeight(pixelBuffer);		// check current buffer.

	// simple optimzation is to only copy rect passed.
	// For now only copy top row to last row changed.
	
	[updateLock lock];
	
    for (i = 0; i < count; i++) {	// group of rect's.
		top =  rectArray[i].origin.y;
		bottom = top + rectArray[i].size.height;
		if (top < topLine) topLine = top;
		if (bottom > bottomLine) bottomLine = bottom;
	}	// end for i
	
	[updateLock unlock];
#endif
}

void refreshCallback(CGRectCount count, const CGRect *rectArray, void *ignore) {

	XMScreenVideoInputModule *dev = (XMScreenVideoInputModule *)ignore;
	[dev setNeedsUpdate: YES];
	
	[dev doRefeshFromScreen:  count rects: rectArray];
//	NSLog(@"REFRESH CALLBACK %@ : %d", dev, count );

						  
}

// locate screen with this device... Screen 0, Screen 2, etc...
- (BOOL)openInputDevice:(NSString *)device
{	int i;

	for (i= 0; i < [screenNames count]; i++) {
		if ([device isEqual: [screenNames objectAtIndex:i]]) {
			// screen X selected.
			NSArray *screens = [NSScreen screens];	// array of NSScreen objects representing all of the screens available on the system.
			NSScreen *aScreen;
			NSDictionary *deviceDescription;
			NSNumber *aNum;
			NSRect aRect;
			if (i + 1 > [screens count]) return NO;
		
				   
			aScreen = [[NSScreen screens] objectAtIndex:i];
			aRect =[aScreen frame];
			[self setRrameRect: &aRect];	
			deviceDescription = [aScreen deviceDescription];
			//  	@"NSScreenNumber"	An NSNumber that contains the CGDirectDisplayID for the screen device. This key is only valid for the device description dictionary for an NSScreen.
			aNum = [deviceDescription objectForKey: @"NSScreenNumber"];
			displayID = [aNum intValue];
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
			CGRegisterScreenRefreshCallback(refreshCallback, self);
		}

	}	// end for i
	
	return YES;
}

- (BOOL)closeInputDevice
{	CGUnregisterScreenRefreshCallback(refreshCallback, self);
	displayID = NULL;
	if(pixelBuffer != NULL)
	{
		CVPixelBufferRelease(pixelBuffer);
		pixelBuffer = NULL;
	}
	return YES;
}

// called by timer to get updates...
- (BOOL)grabFrame
{	UInt8 *bytes;
	UInt8 *screen;
	unsigned j;
	unsigned height;
	
	if(pixelBuffer == NULL)
	{
		CVReturn result;
		// see:  CoreGraphics/CGDirectDisplay.h
		rowBytesScreen = CGDisplayBytesPerRow(displayID);
		height = CGDisplayPixelsHigh(displayID);
		unsigned width = CGDisplayPixelsWide(displayID);
		NSLog(@"Screen Geometry Changed - (%d,%d) Depth: %d, Samples: %d, rowBytesScreen %d\n", 
			  width,  height,
			  CGDisplayBitsPerPixel(displayID), CGDisplaySamplesPerPixel(displayID), rowBytesScreen);
		
		unsigned usedBytes = rowBytesScreen*height;
		OSType PixType;
		if (rowBytesScreen == 4 * width) 
			PixType = k32ARGBPixelFormat;		// 32bit color for video
		else
		if (rowBytesScreen == 3 * width) 
			PixType = k24RGBPixelFormat;		// 24 bit color for video
		else
		if (rowBytesScreen == 2 * width) 
			PixType = k16BE555PixelFormat;		// Thousands for video
		else
		{
			[inputManager handleErrorWithCode:1 hintCode:1]; //256 color video
			return NO;
		}
	
		void *pixels = malloc(usedBytes);	// creating a buffer for the pixels
		
		bytes = (UInt8 *)pixels;
		screen = CGDisplayBaseAddress(displayID);
				
		needsUpdate = YES;
		topLine = 0;
		bottomLine = height;
	
		// creating the CVPixelBufferRef
		
		result = CVPixelBufferCreateWithBytes(NULL, (size_t)width, (size_t)height,
											  PixType, pixels, rowBytesScreen,
											  XMScreenPixelBufferReleaseCallback, NULL, NULL, &pixelBuffer);
		
		if(result != kCVReturnSuccess)
		{	NSLog(@"ScreenModule failed: %d", result);
			//[inputManager handleErrorWithCode:(ComponentResult)result hintCode:1];
			free(pixels);
			return NO;
		}
	}
	
	if (needsUpdate) {
	
		// CAN WITH USE CIImageProvider TO ALLOCATE IT..
		
		/* Creates a new image whose bitmap data is from 'd'. Each row contains 'bpr'
		* bytes. The dimensions of the image are defined by 'size'. 'f' defines
		* the format and size of each pixel. 'cs' defines the color space
		* that the image is defined in, if nil, the image is not color matched. */
		// CAN I USE THIS:		
		//		+ (CIImage *)imageWithBitmapData:(NSData *)d bytesPerRow:(size_t)bpr size:(CGSize)size format:(CIFormat)f colorSpace:(CGColorSpaceRef)cs;

	#ifndef optimzeScreenCopy
		// non- optimized screen copy.
		CVPixelBufferLockBaseAddress (pixelBuffer, 0);
		bytes = CVPixelBufferGetBaseAddress (pixelBuffer);
		screen = CGDisplayBaseAddress(displayID);
		height = CVPixelBufferGetHeight(pixelBuffer);
		for (j = 0; j < height; j++) {	// one line at time..
			memcpy(bytes, screen, rowBytesScreen);
			screen += rowBytesScreen;
			bytes  += rowBytesScreen;
		}
		CVPixelBufferUnlockBaseAddress	(pixelBuffer, 0);	
	#endif
		[self doScreenCopy];
		//NSLog(@"update frame %d", timeStamp);
		[inputManager handleGrabbedFrame:pixelBuffer];
		[self setNeedsUpdate: NO];
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

// cleanup frame buffer...
void XMScreenPixelBufferReleaseCallback(void *releaseRefCon, 
									   const void *baseAddress)
{
	free((void *)baseAddress);
}

@end
