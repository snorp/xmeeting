/*
 * $Id: XMDummyVideoInputModule.m,v 1.22 2009/01/11 17:34:23 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
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
	
  NSString *deviceName = NSLocalizedString(@"XM_FRAMEWORK_NO_DEVICE", @"");
	
  device = [[NSArray alloc] initWithObjects:deviceName, nil];
	
  inputManager = nil;
	
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
  [XMDummyVideoInputModule getDummyImageForVideoSize:XMVideoSize_NoVideo];
  return YES;
}

- (BOOL)setInputFrameSize:(XMVideoSize)theVideoSize
{
  if (videoSize == theVideoSize) {
    return YES;
  }
	
  videoSize = theVideoSize;
	
  return YES;
}

- (BOOL)setFrameGrabRate:(unsigned)theFrameGrabRate
{	
  return YES;
}

- (BOOL)grabFrame
{
  CVPixelBufferRef pixelBuffer = [XMDummyVideoInputModule getDummyImageForVideoSize:videoSize];
  if (pixelBuffer == NULL) {
    [inputManager handleErrorWithCode:2 hintCode:0];
    return NO;
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

+ (CVPixelBufferRef)getDummyImageForVideoSize:(XMVideoSize)videoSize
{
  static CVPixelBufferRef pixelBuffer = NULL;
  static XMVideoSize bufferVideoSize = XMVideoSize_NoVideo;
    
  if (videoSize == XMVideoSize_NoVideo) {
    if (pixelBuffer != NULL) {
      CVPixelBufferRelease(pixelBuffer);
      pixelBuffer = NULL;
    }
    return NULL;
  }
    
  if (bufferVideoSize != videoSize && pixelBuffer != NULL) {
    CVPixelBufferRelease(pixelBuffer);
    pixelBuffer = NULL;
  }
    
  if (pixelBuffer == NULL) {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"DummyImage" ofType:@"gif"];
    NSData *data = [[NSData alloc] initWithContentsOfFile:path];
    NSBitmapImageRep *bitmapImageRep = [[NSBitmapImageRep alloc] initWithData:data];
    [data release];
		
    if (bitmapImageRep == nil) {
      return NULL;
    }
		
    UInt8 *bitmapData = (UInt8 *)[bitmapImageRep bitmapData];
        
    unsigned width = [bitmapImageRep pixelsWide];
    unsigned height = [bitmapImageRep pixelsHigh];
    unsigned bytesPerRow = [bitmapImageRep bytesPerRow];
		
    pixelBuffer = XMCreatePixelBuffer(videoSize);
    
    int bitsPerPixel = [bitmapImageRep bitsPerPixel];
    OSType pixelFormat = k24RGBPixelFormat;
    switch (bitsPerPixel) {
      case 32:
        pixelFormat = k32ARGBPixelFormat;
        break;
      case 24:
        pixelFormat = k24RGBPixelFormat;
        break;
      case 16:
        pixelFormat = k16BE555PixelFormat; // should not appear
        break;
      case 8:
        pixelFormat = k8IndexedPixelFormat; // should not appear
        break;
    }
		
    void *context = XMCreateImageCopyContext(width, height, 0, 0, bytesPerRow, pixelFormat,
                                             NULL, pixelBuffer, XMImageScaleOperation_NoScaling);
		
    BOOL result = XMCopyImageIntoPixelBuffer(bitmapData, pixelBuffer, context);
		
    XMDisposeImageCopyContext(context);
		
    if (result == NO) {
      [bitmapImageRep release];
      CVPixelBufferRelease(pixelBuffer);
      pixelBuffer = NULL;
      return NULL;
    }
		
    [bitmapImageRep release];
        
    bufferVideoSize = videoSize;
  }
    
  return pixelBuffer;
}

@end
