/*
 * $Id: XMStillImageVideoInputModule.m,v 1.6 2007/05/08 10:49:54 hfriederich Exp $
 *
 * Copyright (c) 2006-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2007 Mark Fleming, Hannes Friederich. All rights reserved.
 */

#import "XMStillImageVideoInputModule.h"

#import "XMDummyVideoInputModule.h"

@interface XMStillImageVideoInputModule (PrivateMethods)

- (BOOL)_setImagePath:(NSString *)imagePath;
- (void)_updateImage;
- (void)_updateScale;

@end


@implementation XMStillImageVideoInputModule

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	return nil;
}

- (id)_init
{
	self = [super init];
	
	NSString *deviceName = NSLocalizedString(@"XM_FRAMEWORK_STILL_MODULE_DEVICE_NAME", @"");
	stillNames = [[NSArray alloc] initWithObjects:deviceName, nil];
	inputManager = nil;
	
	preserveImagePath = NO;
	imagePath = nil;
	
	actualImagePath = nil;
	actualScaleType = XMImageScaleOperation_NoScaling;
	pixelBuffer = NULL;
	
	deviceSettingsView = nil;
	
	return self;
}

- (void)dealloc
{		
	[inputManager release];
	[stillNames release];
	
	[imagePath release];
	
	[actualImagePath release];
	if(pixelBuffer != NULL)
	{
		CVPixelBufferRelease(pixelBuffer);
		pixelBuffer = NULL;
	}
	
	[super dealloc];
}

- (NSString *)identifier
{
	return @"XMStillImageVideoInputModule";
}

- (NSString *)name
{
	return NSLocalizedString(@"XM_FRAMEWORK_STILL_MODULE_NAME", @"");
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

// Still Image
- (NSArray *)inputDevices
{		
	return stillNames;
}

- (BOOL)openInputDevice:(NSString *)device
{	
	// make sure that the correct image is displayed
	[inputManager noteSettingsDidChangeForModule:self];
	return YES;	// always allow them to select still images. Use dummy image if nothing present
}

- (BOOL)closeInputDevice
{	
	if(pixelBuffer != NULL)
	{
		CVPixelBufferRelease(pixelBuffer);
		pixelBuffer = NULL;
	}
	
	if(preserveImagePath == NO)
	{
		[imagePath release];
		imagePath = nil;
		scaleType = XMImageScaleOperation_NoScaling;
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
		NSString *theImagePath = actualImagePath;
		XMImageScaleOperation scaleOperation = actualScaleType;
		if(theImagePath == nil)
		{
            CVPixelBufferRef dummyPicture = [XMDummyVideoInputModule getDummyImageForVideoSize:videoSize];
            if (dummyPicture != NULL)
            {
                [inputManager handleGrabbedFrame:dummyPicture];
                return YES;
            }
            else
            {
                [inputManager handleErrorWithCode:2 hintCode:1];
                return NO;
            }
		}
		NSData *data = [[NSData alloc] initWithContentsOfFile:theImagePath];
		NSBitmapImageRep *bitmapImageRep = [[NSBitmapImageRep alloc] initWithData:data];
		[data release];
		
		if(bitmapImageRep == nil)
		{
            CVPixelBufferRef dummyPicture = [XMDummyVideoInputModule getDummyImageForVideoSize:videoSize];
            if (dummyPicture != NULL)
            {
                [inputManager handleGrabbedFrame:dummyPicture];
                return YES;
            }
            else
            {
                [inputManager handleErrorWithCode:2 hintCode:2];
                return NO;
            }
		}
		
		UInt8 *bitmapData = (UInt8 *)[bitmapImageRep bitmapData];
		
		unsigned width = [bitmapImageRep pixelsWide];
		unsigned height = [bitmapImageRep pixelsHigh];
		unsigned bytesPerRow = [bitmapImageRep bytesPerRow];
		
		unsigned bitsPerPixel = [bitmapImageRep bitsPerPixel];
		OSType pixelFormat;
		
		switch(bitsPerPixel)
		{
			case 8:
				pixelFormat = k8IndexedPixelFormat;
				break;
			case 16:
				pixelFormat = k16BE555PixelFormat;
				break;
			case 24:
				pixelFormat = k24RGBPixelFormat;
				break;
			default:
				pixelFormat = k32ARGBPixelFormat;
				unsigned bitmapFormat = [bitmapImageRep bitmapFormat];
				if((bitmapFormat & NSAlphaFirstBitmapFormat) == 0)
				{
					// need to convert from RGBA to ARGB
					XMRGBA2ARGB(bitmapData, width, height, bytesPerRow);
				}
				break;
		}
		
		pixelBuffer = XMCreatePixelBuffer(videoSize);
		
		void *context = XMCreateImageCopyContext(width, height, 0, 0, bytesPerRow, pixelFormat, NULL, pixelBuffer, scaleOperation);
		
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

- (NSString *)descriptionForErrorCode:(int)errorCode hintCode:(int)code device:(NSString *)device
{
	return NSLocalizedString(@"XM_FRAMEWORK_STILL_MODULE_ERROR", @"");
}

// Setup dialog options: to select image
- (BOOL)hasSettingsForDevice:(NSString *)device
{	// This method will be called on the main thread.
	
	return YES;
}

- (BOOL)requiresSettingsDialogWhenDeviceOpens:(NSString *)device
{	// This method will be called on the main thread.
	
	// return NO if path exists and is an image.
	if(imagePath == nil)
	{
		return YES;
	}
	
	return NO;
}

- (NSData *)internalSettings
{	// This method is called on the main thread
	
	NSString *theImagePath = imagePath;
	if(imagePath == nil)
	{
		theImagePath = @"";
	}
	
	NSArray *values = [[NSArray alloc] initWithObjects:theImagePath, [NSNumber numberWithUnsignedInt:scaleType], nil];	
	// for now only one image, other for recent images and other parameters.
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:values];
	
	[values release];
	
	return data;
}

- (void)applyInternalSettings:(NSData *)settings
{	// This method is NOT called on the main thread
	NSArray *array = (NSArray *)[NSKeyedUnarchiver unarchiveObjectWithData:settings];
	
	// for now only one image, other for recent images.
	NSString *aPath = (NSString *)[array objectAtIndex:0];	
	NSNumber *scaling = (NSNumber *) [array objectAtIndex:1];	
	actualScaleType = (XMImageScaleOperation)[scaling unsignedIntValue];
	
	if([aPath isEqualToString:@""])
	{
		aPath = nil;
	}
	[actualImagePath release];
	actualImagePath = [aPath copy];
	
	if(pixelBuffer != NULL)
	{
		CVPixelBufferRelease(pixelBuffer);
		pixelBuffer = NULL;
	}
}

- (NSDictionary *)permamentSettings
{	//This method will be called on the main thread.	

	NSString *path = imagePath;
	XMImageScaleOperation scaleOperation = scaleType;
	
	if(preserveImagePath == NO)
	{
		path = nil;
		scaleOperation = XMImageScaleOperation_NoScaling;
	}
		
	if(path == nil)
	{
		path = @"";
	}
	return [NSDictionary dictionaryWithObjectsAndKeys:path, @"stillImage", 
													[NSNumber numberWithInt:scaleOperation], @"stillImageScaling",
													[NSNumber numberWithBool:preserveImagePath], @"preserveImagePath", 
													nil] ;
}

- (BOOL)setPermamentSettings:(NSDictionary *)settings
{	//This method will be called on the main thread.
	
	NSString *aPath = [settings objectForKey: @"stillImage"];
	NSNumber *scaling =  [settings objectForKey: @"stillImageScaling"];
	NSNumber *number = [settings objectForKey: @"preserveImagePath"];
	
	if(aPath == nil || scaling == nil || number == nil)
	{
		return NO;
	}
	
	if([aPath isEqualToString:@""])
	{
		aPath = nil;
	}
	
	[self _setImagePath:aPath];
	
	scaleType = [scaling unsignedShortValue];
	preserveImagePath = [number boolValue];
	
	[inputManager noteSettingsDidChangeForModule:self];

	return YES;
}

- (NSView *)settingsViewForDevice:(NSString *)device
{	//This method will be called on the main thread.
	
	if(deviceSettingsView == nil)
	{
		[NSBundle loadNibNamed:@"StillImageSettings" owner:self];
	}
	
	if(device == nil)
	{
		int state = (preserveImagePath == YES) ? NSOnState : NSOffState;
		[preserveImagePathSwitch setState:state];
		
		return moduleSettingsView;
	}
	else
	{
		[self _updateImage];
		[self _updateScale];
		return deviceSettingsView;
	}
}

- (void)setDefaultSettingsForDevice:(NSString *)device
{	//This method will be called on the main thread.
	
	if(device == nil)
	{
		preserveImagePath = NO;
		[preserveImagePathSwitch setState:NSOffState];
	}
	else
	{
		[imagePath release];
		imagePath = nil;
		scaleType = XMImageScaleOperation_NoScaling;
		
		[self _updateImage];
		[self _updateScale];
		
		[inputManager noteSettingsDidChangeForModule:self];
	}
}

#pragma mark -
#pragma mark GUI Handling

// Update to new image...
- (BOOL)_setImagePath:(NSString *)aPath
{
	if(aPath != nil)
	{
		NSData *data = [[NSData alloc] initWithContentsOfFile:aPath];
		NSBitmapImageRep *bitmapImageRep = [[NSBitmapImageRep alloc] initWithData:data];
		
		BOOL succ = YES;
		
		if(bitmapImageRep == nil)
		{
			succ = NO;
		}
		
		[data release];
		[bitmapImageRep release];
		
		if(succ == NO)
		{
			[inputManager handleErrorWithCode:3 hintCode:0];
			return NO;
		}
	}
		
	NSString *old = imagePath;
	imagePath = [aPath  copy];
	[old release];
	
	[inputManager noteSettingsDidChangeForModule:self];
	
	return YES;
}

- (void)_updateImage
{
	if(deviceSettingsView != nil)
	{
		if(imagePath != nil)
		{	
			NSImage *theImage = (NSImage *) [[NSImage alloc]  initWithContentsOfFile: imagePath];
			[pathField setStringValue: imagePath];
			[previewImage setImage: theImage];
		}
		else
		{
			[pathField setStringValue:NSLocalizedString(@"XM_FRAMEWORK_STILL_MODULE_NO_IMAGE", @"")];
			[previewImage setImage:nil];
		}
	} 
}

- (void)_updateScale
{	
	[imageScaling selectItemWithTag:scaleType];
	[previewImage setImageAlignment:  (scaleType == XMImageScaleOperation_NoScaling) ?   NSImageAlignTopLeft : NSImageAlignCenter];
	[previewImage setImageScaling: (scaleType == XMImageScaleOperation_NoScaling)?  NSScaleNone : ((scaleType == XMImageScaleOperation_ScaleProportionally) ? NSScaleProportionally: NSScaleToFit) ];
}

#pragma mark -
#pragma mark Action Methods

- (void)awakeFromNib
{
	int state = (preserveImagePath == YES) ? NSOnState : NSOffState;
	[preserveImagePathSwitch setState:state];
	
	[self _updateImage];
	[self _updateScale];
}

- (IBAction)_changeImage:(id)sender
{	// Select Image ...
       
	NSOpenPanel *oPanel = [NSOpenPanel openPanel];
	int result;
      
	[oPanel setAllowsMultipleSelection:NO];
	[oPanel setCanChooseDirectories:NO];
	[oPanel setCanChooseFiles:YES];
	[oPanel setPrompt: NSLocalizedString(@"Set Image", @"Set Image")];
	
	NSString *defaultPath = imagePath;
	if(imagePath == nil)
	{
		defaultPath = NSHomeDirectory();
	}

	result = [oPanel runModalForDirectory:defaultPath file:nil types:[NSImage imageUnfilteredFileTypes]];

	if (result == NSOKButton)
	{	
		NSArray *filesToOpen = [oPanel filenames];

		NSString *aPath = [filesToOpen objectAtIndex: 0];
		//NSLog(@"path = %@", aPath);
		[self _setImagePath: aPath];
			
		[self _updateImage];
			
		[inputManager noteSettingsDidChangeForModule:self];
	}
}

- (IBAction)_scaleTypeChanged:(id)sender
{
	//XMImageScaleOperation_NoScaling = 0,
	//XMImageScaleOperation_ScaleProportionally,
	//XMImageScaleOperation_ScaleToFit	
	scaleType = (XMImageScaleOperation)[[imageScaling selectedItem] tag];
	
	//	NSScaleProportionally = 0,   // Fit proportionally
	//	NSScaleToFit,                // Forced fit (distort if necessary)
	//	NSScaleNone                  // Don't scale (clip)
	
	[self _updateScale];
	
	[inputManager noteSettingsDidChangeForModule:self];	
}

- (IBAction)_togglePreserveImagePath:(id)sender
{
	preserveImagePath = ([preserveImagePathSwitch state] == NSOnState) ? YES : NO;
}

@end
