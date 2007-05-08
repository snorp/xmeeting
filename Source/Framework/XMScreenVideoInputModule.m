/*
 * $Id: XMScreenVideoInputModule.m,v 1.17 2007/05/08 10:49:54 hfriederich Exp $
 *
 * Copyright (c) 2006-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2007 Mark Fleming, Hannes Friederich. All rights reserved.
 */

#import "XMScreenVideoInputModule.h"

void XMScreenModuleRefreshCallback(CGRectCount count, const CGRect *rectArray, void *context);
void XMScreenModuleReconfigurationCallback(CGDirectDisplayID display, 
										   CGDisplayChangeSummaryFlags flags,
										   void *context);

@interface XMScreenVideoInputModule (PrivateMethods)

- (void)_setNeedsUpdate:(BOOL)flag;
- (void)_doScreenCopy;
- (void)_handleUpdatedScreenRects:(const CGRect *)rectArray count:(CGRectCount)count;
- (void)_handleScreenReconfigurationForDisplay:(CGDirectDisplayID)display 
								   changeFlags:(CGDisplayChangeSummaryFlags)flags;
- (void)_handleAreaSelectionChange;
- (void)_drawScreenImage:(NSRect)rect doesChangeSelection:(BOOL)doesChangeSelection;

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
	
    int i;
	NSString *deviceName = NSLocalizedString(@"XM_FRAMEWORK_SCREEN_DEVICE_NAME", @"");
	NSArray *screens = [NSScreen screens];	// array of NSScreen objects representing all of the screens available on the system.
	// TODO: Update screenNames list when screens are added / removed
	// When the display configuration is changed, NSApplicationDidChangeScreenParametersNotification is sent by the default notification center.
	// The first screen in the screens array is always the "zero" screen. To obtain the menu bar screen use [[NSScreen screens] objectAtIndex:0]
	// (after checking that the screens array is not empty).
	screenNames = [[NSMutableArray alloc] initWithObjects: nil];
	for (i = 0; i < [screens count]; i++) 
	{
		[screenNames addObject: [NSString stringWithFormat:deviceName, i]];	// one device for each screen.
	}
	
	displayID = NULL;
	screenRect = NSMakeRect(0, 0, 0, 0);
	rowBytesScreen = 0;
	needsUpdate = NO;
	topLine = 0;
	bottomLine = 0;
	screenPixelFormat = 0;
    screenAreaRect = NSMakeRect(0, 0, 1, 1);
	
	updateLock = [[NSLock alloc] init];
	
	videoSize = XMVideoSize_NoVideo;
	
	pixelBuffer = NULL;
	imageBuffer = NULL;
	imageCopyContext = NULL;
	
	droppedFrameCounter = 0;
	
	locked = NO;
	needsDisposing = NO;
    
    settingsView = nil;
    selectionView = nil;
    overviewBuffer = NULL;
    overviewCopyContext = NULL;
    overviewImageRep = nil;
    updateSelectionView = NO;
    overviewCounter = 0;
	
	return self;
}

- (void)awakeFromNib
{
    [selectionView setInputModule:self];
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
    if (overviewCopyContext != NULL)
    {
        XMDisposeImageCopyContext(overviewCopyContext);
    }
    if (overviewBuffer != NULL)
    {
        CVPixelBufferRelease(overviewBuffer);
    }
    if (overviewImageRep != nil)
    {
        [overviewImageRep release];
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
	return NSLocalizedString(@"XM_FRAMEWORK_SCREEN_MODULE_NAME", @"");
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
    if (imageCopyContext != NULL)
    {
        XMDisposeImageCopyContext(imageCopyContext);
        imageCopyContext = NULL;
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
	displayID = NULL;

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
			if (i >= [screens count]) 
			{
				// screen no longer available
				return NO;
			}
		
			aScreen = [[NSScreen screens] objectAtIndex:i];
			screenRect = [aScreen frame];
    
			deviceDescription = [aScreen deviceDescription];
			//  	@"NSScreenNumber"	An NSNumber that contains the CGDirectDisplayID for the screen device. This key is only valid for the device description dictionary for an NSScreen.
			aNum = [deviceDescription objectForKey: @"NSScreenNumber"];
			displayID = (CGDirectDisplayID)[aNum intValue];
        }

	}	// end for i
    
    if (displayID == NULL) {
        // Screen not found
        return NO;
    }
	
	locked = NO;
	CGRegisterScreenRefreshCallback(XMScreenModuleRefreshCallback, self);
	CGDisplayRegisterReconfigurationCallback(XMScreenModuleReconfigurationCallback, self);
    
    [updateLock lock];
    rowBytesScreen = CGDisplayBytesPerRow(displayID);
    [updateLock unlock];
	
	return YES;
}

- (BOOL)closeInputDevice
{	
	CGUnregisterScreenRefreshCallback(XMScreenModuleRefreshCallback, self);
	CGDisplayRemoveReconfigurationCallback(XMScreenModuleReconfigurationCallback, self);
	displayID = NULL;
	
    if(pixelBuffer != NULL)
	{
		CVPixelBufferRelease(pixelBuffer);
		pixelBuffer = NULL;
	}
    if (imageBuffer != NULL) {
        [updateLock lock];
        free(imageBuffer);
        imageBuffer = NULL;
        [updateLock unlock];
    }
    if (imageCopyContext != NULL) {
        XMDisposeImageCopyContext(imageCopyContext);
        imageCopyContext = NULL;
    }
	
	return YES;
}

// called by timer to get updates...
- (BOOL)grabFrame
{
	if(needsDisposing == YES)
	{
		[updateLock lock];
		
        if (imageBuffer != NULL) {
            [updateLock lock];
            free(imageBuffer);
            imageBuffer = NULL;
            [updateLock unlock];
        }
        if (imageCopyContext != NULL) {
            XMDisposeImageCopyContext(imageCopyContext);
            imageCopyContext = NULL;
        }
        // Need to dispose / release these objects as well, even if they belong
        // to the main thread
        if (overviewCopyContext != NULL) {
            XMDisposeImageCopyContext(overviewCopyContext);
            overviewCopyContext = NULL;
        }
		needsDisposing = NO;
		
		[updateLock unlock];
	}
	
	// Don't grab anything while the screen reconfigures itself
	if(locked == YES)
	{
		return YES;
	}
	
	if(pixelBuffer == NULL)
	{
        pixelBuffer = XMCreatePixelBuffer(videoSize);
    }
    if (pixelBuffer == NULL)
    {
        return NO;
    }
    
    if (imageBuffer == NULL)
    {
        unsigned height = CGDisplayPixelsHigh(displayID);
        unsigned usedBytes = rowBytesScreen * height;
        
        [updateLock lock];
        imageBuffer = malloc(usedBytes);
        [updateLock unlock];
        
        [self _setNeedsUpdate:YES];
        topLine = 0;
		bottomLine = height;
    }
    
    if (imageCopyContext == NULL)
    {
        [updateLock lock];
        
		// see:  CoreGraphics/CGDirectDisplay.h
		unsigned height = CGDisplayPixelsHigh(displayID);
		unsigned width = CGDisplayPixelsWide(displayID);
		unsigned bitsPerPixel = CGDisplayBitsPerPixel(displayID);
		
		CGDirectPaletteRef palette = NULL;
		
		if (bitsPerPixel == 32) 
		{
			screenPixelFormat = k32ARGBPixelFormat;		// 32bit color for video
		} 
		else if (bitsPerPixel == 24) 
		{
			screenPixelFormat = k24RGBPixelFormat;		// 24 bit color for video
		} 
		else if (bitsPerPixel == 16)
		{
			screenPixelFormat = k16BE555PixelFormat;	// Thousands for video
		} 
		else
		{
			screenPixelFormat = k8IndexedPixelFormat;
			palette = CGPaletteCreateWithDisplay(displayID);
		}
        
        unsigned screenWidth = screenAreaRect.size.width * width;
        unsigned screenHeight = screenAreaRect.size.height * height;
        unsigned screenX = screenAreaRect.origin.x * width;
        unsigned screenY = screenAreaRect.origin.y * height;
        
        // Screen / image coordinates have a flipped y-coordinate system compared to normal drawing
        screenY = height - screenY - screenHeight;
        
        // Zero out the pixel buffer since the picture geometry has changed
        XMClearPixelBuffer(pixelBuffer);
		
		imageCopyContext = XMCreateImageCopyContext(screenWidth, screenHeight, screenX, screenY,
                                                    rowBytesScreen, screenPixelFormat, palette, pixelBuffer, 
													XMImageScaleOperation_ScaleProportionally);
		
		if(palette != NULL)
		{
			CGPaletteRelease(palette);
		}
		
		[self _setNeedsUpdate:YES];
		topLine = 0;
		bottomLine = height;
        
        [updateLock unlock];
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
	return @"";
}

- (BOOL)hasSettingsForDevice:(NSString *)device
{
	if (device != nil)
    {
        return YES;
    }
    return NO;
}

- (BOOL)requiresSettingsDialogWhenDeviceOpens:(NSString *)device
{
	return NO;
}

- (NSData *)internalSettings
{
    NSRect areaRect;
    
    if (selectionView != nil)
    {
        areaRect = [selectionView selectedArea];
    }
    else
    {
        areaRect = NSMakeRect(0, 0, 1, 1);
    }
    
    NSData * data = [NSData dataWithBytes:(void *)&areaRect length:sizeof(NSRect)];
	return data;
}

- (void)applyInternalSettings:(NSData *)settings
{
    NSRect * rect = (NSRect *)[settings bytes];
    screenAreaRect = *rect;
    
    if(imageCopyContext != NULL)
	{
		XMDisposeImageCopyContext(imageCopyContext);
        imageCopyContext = NULL;
	}
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
	if (settingsView == nil)
    {
        [NSBundle loadNibNamed:@"ScreenSettings" owner:self];
    }
    
    if (device == nil)
    {
        return nil;
    }
    
    return settingsView;
}

- (void)setDefaultSettingsForDevice:(NSString *)device
{
    [selectionView setSelectedArea:NSMakeRect(0, 0, 1, 1)];
    [inputManager noteSettingsDidChangeForModule:self];
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
	
	if(locked == NO)
	{
		UInt8 *bytes = imageBuffer;
		UInt8 *screenPtr = CGDisplayBaseAddress(displayID);
		bytes += (topLine * rowBytesScreen);
		screenPtr += (topLine * rowBytesScreen);
	
#if defined(__BIG_ENDIAN__)
		unsigned numberOfLines = bottomLine - topLine;
		memcpy(bytes, screenPtr, numberOfLines*rowBytesScreen);
#else
		if(screenPixelFormat == k32ARGBPixelFormat)
		{
			// we need to do byte swapping in order to get correct
			// colors. Reading from the screen buffer seems to be
			// SLOOOOOOOOOOOOW on intel macs, also true for memcpy
			// :-(
			unsigned width = (unsigned)screenRect.size.width;
			unsigned i;
			
			for(i = topLine; i < bottomLine; i++)
			{
				UInt32 *src = (UInt32 *)screenPtr;
				UInt32 *dst = (UInt32 *)bytes;
				
				unsigned j;
				for(j = 0; j < width; j++)
				{
					dst[j] = CFSwapInt32(src[j]);
				}
				
				bytes += rowBytesScreen;
				screenPtr += rowBytesScreen;
			}
		}
		else
		{
			unsigned numberOfLines = bottomLine - topLine;
			memcpy(bytes, screenPtr, numberOfLines*rowBytesScreen);
		}
#endif
	
		topLine = screenRect.size.height;
		bottomLine = 0;
	}
	
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
    
    BOOL found = NO;
	
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
            
            found = YES;
		}
	}
	
	[updateLock unlock];
    
    if (found == YES) {
    
        updateSelectionView = YES;
    
        // Improve performance by reducing the amount of redraws
        overviewCounter++;
        if (overviewCounter > 20) {
            [selectionView setNeedsDisplay:YES];
            overviewCounter = 0;
        }
    }
}

- (void)_handleScreenReconfigurationForDisplay:(CGDirectDisplayID)display 
								   changeFlags:(CGDisplayChangeSummaryFlags)flags
{
	[updateLock lock];
	
	if(display == displayID)
	{
		if((flags & kCGDisplayBeginConfigurationFlag) != 0)
		{
			locked = YES;
			needsDisposing = YES;
		}
		else
		{
			locked = NO;
		}
	}
	
	[updateLock unlock];
}

- (void)_handleAreaSelectionChange
{
    [inputManager noteSettingsDidChangeForModule:self];
}

- (void)_drawScreenImage:(NSRect)rect doesChangeSelection:(BOOL)doesChangeSelection
{
    if (overviewBuffer == NULL)
    {
        overviewBuffer = XMCreatePixelBuffer(XMVideoSize_QCIF);
        
        CVPixelBufferLockBaseAddress(overviewBuffer, 0);
        
        void *src = CVPixelBufferGetBaseAddress(overviewBuffer);
        
        overviewImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:(unsigned char **)&src
                                                                   pixelsWide:CVPixelBufferGetWidth(overviewBuffer)
                                                                   pixelsHigh:CVPixelBufferGetHeight(overviewBuffer)
                                                                bitsPerSample:8
                                                              samplesPerPixel:4
                                                                     hasAlpha:YES
                                                                     isPlanar:NO
                                                               colorSpaceName:NSDeviceRGBColorSpace
                                                                 bitmapFormat:NSAlphaFirstBitmapFormat
                                                                  bytesPerRow:CVPixelBufferGetBytesPerRow(overviewBuffer)
                                                                 bitsPerPixel:32];
    }
    if (overviewBuffer == NULL)
    {
        NSRectFill(rect);
    }
    if (updateSelectionView == YES && doesChangeSelection == NO)
    {
        [updateLock lock];
        
        if (overviewCopyContext == NULL)
        {
            overviewCopyContext = XMCreateImageCopyContext(screenRect.size.width, screenRect.size.height, 0, 0,
                                                           rowBytesScreen, screenPixelFormat, NULL, overviewBuffer,
                                                           XMImageScaleOperation_ScaleToFit);
        }
        XMCopyImageIntoPixelBuffer(imageBuffer, overviewBuffer, overviewCopyContext);
        [updateLock unlock];
        
        updateSelectionView = NO;
        overviewCounter = 0;
    }
    
    [overviewImageRep drawInRect:rect];
}

@end

#pragma mark -
#pragma mark Screen Selection

@implementation XMScreenSelectionView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    
    inputModule = nil;
    
    return self;
}

- (void)setInputModule:(XMScreenVideoInputModule *)_inputModule
{
    inputModule = _inputModule;
}

- (void)drawBackground:(NSRect)rect doesChangeSelection:(BOOL)doesChangeSelection
{
    if (inputModule != nil) {
        [inputModule _drawScreenImage:[self bounds] doesChangeSelection:doesChangeSelection];
    } else {
        [super drawBackground:rect doesChangeSelection:doesChangeSelection];
    }
}

- (void)selectedAreaUpdated
{
    [inputModule _handleAreaSelectionChange];
}

@end

#pragma mark -
#pragma mark Callbacks

void XMScreenModuleRefreshCallback(CGRectCount count, const CGRect *rectArray, void *context) 
{
	XMScreenVideoInputModule *module = (XMScreenVideoInputModule *)context;

	[module _handleUpdatedScreenRects:rectArray count:count];
}

void XMScreenModuleReconfigurationCallback(CGDirectDisplayID display, 
										   CGDisplayChangeSummaryFlags flags,
										   void *context)
{
	XMScreenVideoInputModule *module = (XMScreenVideoInputModule *)context;
	
	[module _handleScreenReconfigurationForDisplay:display changeFlags:flags];
}
