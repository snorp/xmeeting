/*
 * $Id: XMScreenVideoInputModule.m,v 1.1 2006/02/07 18:06:05 hfriederich Exp $
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
		
	[inputManager release];
	
	[screenNames release];
	
	[super dealloc];
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
	unsigned j, top, bottom;
//	unsigned height = CVPixelBufferGetHeight(pixelBuffer);		// check current buffer.
																// simple optimzation is to only copy rect passed.
																// For now only copy row changed.
	CVPixelBufferLockBaseAddress (pixelBuffer, 0);
  
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
		
	CVPixelBufferUnlockBaseAddress	(pixelBuffer, 0);	
	topLine = CVPixelBufferGetHeight(pixelBuffer);	// reset update area to nil.
	bottomLine = 0;
		// Note: need to look out reference callback..
}

//#define optimzeScreenCopy 1
- (void) doRefeshFromScreen: (CGRectCount) count rects: (const CGRect *)rectArray
{
#ifdef optimzeScreenCopy
	UInt8 *bytes;
	UInt8 *screen;
	unsigned i, j, top, bottom;
	unsigned height = CVPixelBufferGetHeight(pixelBuffer);		// check current buffer.

	// simple optimzation is to only copy rect passed.
	// For now only copy top row to last row changed.
	
	
    for (i = 0; i < count; i++) {	// group of rect's.
		top =  rectArray[i].origin.y;
		bottom = top + rectArray[i].size.height;
		if (top < topLine) topLine = top;
		if (bottom > bottomLine) bottomLine = bottom;
	}	// end for i
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
		
			CGRegisterScreenRefreshCallback(refreshCallback, self);
		}

	}	// end for i
	
	[inputManager setTimeScale:600];
	[inputManager noteTimeStampReset];
	timeStamp = 0;
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
	unsigned i, j;
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
		
		unsigned usedBytes = 4*width*height;
		void *pixels = malloc(usedBytes);	// creating a buffer for the pixels
		unsigned count = width*height;
		
		bytes = (UInt8 *)pixels;
		screen = CGDisplayBaseAddress(displayID);
				
		if (rowBytesScreen == 4 * width) {
			NSLog(@"screen same");
			needsUpdate = YES;
			topLine = 0;
			bottomLine = height;
		}




		// creating the CVPixelBufferRef
		
		result = CVPixelBufferCreateWithBytes(NULL, (size_t)width, (size_t)height,
											  k32ARGBPixelFormat, pixels, 4*width,
											  XMScreenPixelBufferReleaseCallback, NULL, NULL, &pixelBuffer);
		
		if(result != kCVReturnSuccess)
		{
			//[inputManager handleErrorWithCode:(ComponentResult)result hintCode:1];
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
		NSLog(@"update frame %d", timeStamp);
		[inputManager handleGrabbedFrame:pixelBuffer time:timeStamp];
		[self setNeedsUpdate: NO];
	}
	timeStamp += (600 / frameGrabRate);
	return YES;
}

- (NSString *)descriptionForErrorCode:(unsigned)errorCode device:(NSString *)device
{
	return nil;
}

- (BOOL)hasSettings
{
	return NO;
}

- (BOOL)requiresSettingsDialogWhenDeviceOpens
{
	return NO;
}

- (NSData *)getInternalSettings
{
	return nil;
}

- (void)applyInternalSettings:(NSData *)settings
{
}

- (NSDictionary *)getSettings
{
	return nil;
}

- (BOOL)setSettings:(NSDictionary *)settings
{
	return NO;
}

- (NSView *)settingsViewForDevice:(NSString *)device
{
	return nil;
}

// cleanup frame buffer...
void XMScreenPixelBufferReleaseCallback(void *releaseRefCon, 
									   const void *baseAddress)
{
	free((void *)baseAddress);
}

@end
