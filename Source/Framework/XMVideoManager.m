/*
 * $Id: XMVideoManager.m,v 1.23 2008/10/07 23:19:17 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMTypes.h"
#import "XMStringConstants.h"
#import "XMPrivate.h"
#import "XMVideoManager.h"
#import "XMMediaTransmitter.h"
#import "XMVideoView.h"
#import "XMCallRecorder.h"

static CVReturn _XMDisplayLinkCallback(CVDisplayLinkRef displayLink, 
                                       const CVTimeStamp *inNow, 
                                       const CVTimeStamp *inOutputTime, 
                                       CVOptionFlags flagsIn, 
                                       CVOptionFlags *flagsOut, 
                                       void *displayLinkContext);

@interface XMVideoManager (PrivateMethods)

- (id)_init;
- (void)_outputFrames;

@end

@implementation XMVideoManager

#pragma mark Class Methods

+ (XMVideoManager *)sharedInstance
{	
	return _XMVideoManagerSharedInstance;
}

#pragma mark Init & Deallocation Methods

- (id)init
{
  [self doesNotRecognizeSelector:_cmd];
  [self  release];
  return nil;
}

- (id)_init
{
  self = [super init];
	
  videoViews = [[NSMutableArray alloc] initWithCapacity:3];
	
  inputDevices = nil;
  selectedInputDevice = nil;
	
  isDoingVideoDisplay = FALSE;
  localVideoSize = XMVideoSize_NoVideo;
  remoteVideoSize = XMVideoSize_NoVideo;
  remoteVideoDimensions = NSMakeSize(0, 0);
	
  // Initializing the OpenGL structures
  videoLock = [[NSLock alloc] init];
	
  // Default Attributes, see QTQuartzPlayer sample code
  NSOpenGLPixelFormatAttribute attributes[] = {
    NSOpenGLPFAColorSize, (NSOpenGLPixelFormatAttribute)24,
    NSOpenGLPFAAlphaSize, (NSOpenGLPixelFormatAttribute)8,
    NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute)32,
    (NSOpenGLPixelFormatAttribute)0
  };
	
  openGLPixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
  openGLContext = [[NSOpenGLContext alloc] initWithFormat:openGLPixelFormat shareContext:nil];
  CVOpenGLTextureCacheCreate(NULL, NULL, (CGLContextObj)[openGLContext CGLContextObj],
                             (CGLPixelFormatObj)[openGLPixelFormat CGLPixelFormatObj],
                             NULL, &textureCache);
	
  localVideoTexture = NULL;
  localVideoTextureDidChange = NO;
  remoteVideoTexture = NULL;
  remoteVideoTextureDidChange = NO;
	
  displayLink = NULL;
	
  errorDescription = nil;
	
  return self;
}

- (void)_close
{	
  if (displayLink != NULL) {
    CVDisplayLinkStop(displayLink);
    CVDisplayLinkRelease(displayLink);
    displayLink = NULL;
  }
	
  [videoLock lock];
	
  [videoViews release];
  [inputDevices release];
  [selectedInputDevice release];
  [openGLPixelFormat release];
  [openGLContext release];
  
  videoViews = nil;
  inputDevices = nil;
  selectedInputDevice = nil;
  openGLPixelFormat = nil;
  openGLContext = nil;

	if (textureCache != NULL) {
    CVOpenGLTextureCacheRelease(textureCache);
    textureCache = NULL;
  }
	
  [videoLock unlock];
}

- (void)dealloc
{	
  [self _close];
	
  [videoLock release];
	
  [errorDescription release];
	
  [super dealloc];
}

#pragma mark Public Methods

- (NSArray *)inputDevices
{
  return inputDevices;
}

- (void)updateInputDeviceList
{
  [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_VideoManagerDidStartInputDeviceListUpdate object:self];
  [XMMediaTransmitter _getDeviceList];
}

- (NSString *)selectedInputDevice
{
  return selectedInputDevice;
}

- (void)setSelectedInputDevice:(NSString *)inputDevice
{
  if (inputDevice != nil && ![inputDevice isEqualToString:selectedInputDevice]) {
    [selectedInputDevice release];
    selectedInputDevice = [inputDevice retain];
		
    [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_VideoManagerDidStartSelectedInputDeviceChange object:self];
    [_XMMediaTransmitterSharedInstance _setDevice:selectedInputDevice];
  }
}

- (id<XMVideoModule>)videoModuleProvidingSelectedInputDevice
{
  return selectedVideoModule;
}

- (BOOL)deviceHasSettings:(NSString *)device
{
  return [_XMMediaTransmitterSharedInstance _deviceHasSettings:device];
}

- (BOOL)requiresSettingsDialogWhenDeviceIsSelected:(NSString *)device
{
  return [_XMMediaTransmitterSharedInstance _requiresSettingsDialogWhenDeviceIsSelected:device];
}

- (NSView *)settingsViewForDevice:(NSString *)device
{
  return [_XMMediaTransmitterSharedInstance _settingsViewForDevice:device];
}

- (void)setDefaultSettingsForDevice:(NSString *)device
{
  [_XMMediaTransmitterSharedInstance _setDefaultSettingsForDevice:device];
}

- (unsigned)videoModuleCount
{
  return [_XMMediaTransmitterSharedInstance _videoModuleCount];
}

- (id<XMVideoModule>)videoModuleAtIndex:(unsigned)index
{
  return [_XMMediaTransmitterSharedInstance _videoModuleAtIndex:index];
}

- (BOOL)isDoingVideoDisplay
{
  return isDoingVideoDisplay;
}

- (BOOL)isSendingVideo
{
  return (localVideoSize != XMVideoSize_NoVideo);
}

- (BOOL)isReceivingVideo
{
  return (remoteVideoSize != XMVideoSize_NoVideo);
}

- (XMVideoSize)localVideoSize
{
  return localVideoSize;
}

- (XMVideoSize)remoteVideoSize
{
  return remoteVideoSize;
}

- (NSSize)remoteVideoDimensions
{
  return remoteVideoDimensions;
}

- (void)addVideoView:(id<XMVideoView>)videoView
{
  BOOL doesStart = NO;
    
  [videoLock lock];
    
  if ([videoViews count] == 0) {
    doesStart = YES;
  }
	
  [videoViews addObject:videoView];
    
  [videoView renderLocalVideo:localVideoTexture didChange:YES 
                  remoteVideo:remoteVideoTexture didChange:YES
                     isForced:YES];
	
  [videoLock unlock];
    
  if (doesStart == YES) {
    [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_VideoManagerDidStartSelectedInputDeviceChange object:self];
        
    [XMMediaTransmitter _startVideoDisplay];
        
    if (displayLink == NULL) {
      CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
      CVDisplayLinkSetOutputCallback(displayLink, &_XMDisplayLinkCallback, NULL);
      CVDisplayLinkStart(displayLink);
    }
        
    isDoingVideoDisplay = YES;
  }
}

- (void)removeVideoView:(id<XMVideoView>)videoView
{
  BOOL doesStop = NO;
      
  [videoLock lock];
	
  [videoViews removeObject:videoView];
    
  if ([videoViews count] == 0) {
    doesStop = YES;
  }
	
  [videoLock unlock];
    
  if (doesStop == YES) {
    [XMMediaTransmitter _stopVideoDisplay];
    
    if (displayLink != NULL) {
      CVDisplayLinkStop(displayLink);
      CVDisplayLinkRelease(displayLink);
      displayLink = NULL;
    }
        
    isDoingVideoDisplay = NO;
  }
}

- (NSOpenGLPixelFormat *)openGLPixelFormat
{
  return openGLPixelFormat;
}

- (NSOpenGLContext *)openGLContext
{
  return openGLContext;
}

- (void)forceRenderingForView:(id<XMVideoView>)videoView
{
  [videoLock lock];
	
  [videoView renderLocalVideo:localVideoTexture didChange:YES 
                  remoteVideo:remoteVideoTexture didChange:YES
                     isForced:YES];
	
  [videoLock unlock];
}

- (void)lockVideoSystem
{
  [videoLock lock];
}

- (void)unlockVideoSystem
{
  [videoLock unlock];
}

- (CVOpenGLTextureRef)createTextureFromImage:(CVPixelBufferRef)pixelBuffer
{
  if (textureCache == NULL) {
    return NULL;
  }
	
  // transform the CVPixelBufferRef into an OpenGL texture
  CVOpenGLTextureRef openGLTexture;
  CVReturn result = CVOpenGLTextureCacheCreateTextureFromImage(NULL, textureCache, pixelBuffer, NULL, &openGLTexture);
	
  if (result != kCVReturnSuccess) {
    return NULL;
  }
	
  return openGLTexture;
}

- (NSDictionary *)settings
{
  unsigned count = [_XMMediaTransmitterSharedInstance _videoModuleCount];
	
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:count];
	
	for (unsigned i = 0; i < count; i++) {
    id<XMVideoModule> module = [_XMMediaTransmitterSharedInstance _videoModuleAtIndex:i];
    NSDictionary *moduleDict = [module permamentSettings];
		
    if (moduleDict != nil) {
      [dict setObject:moduleDict forKey:[module identifier]];
    }
  }
	
  return dict;
}

- (void)setSettings:(NSDictionary *)settings
{
  unsigned count = [_XMMediaTransmitterSharedInstance _videoModuleCount];
	
  for (unsigned i = 0; i < count; i++) {
    id<XMVideoModule> module = [_XMMediaTransmitterSharedInstance _videoModuleAtIndex:i];
		
    NSDictionary *dict = (NSDictionary *)[settings objectForKey:[module identifier]];
		
    if (dict != nil) {
      [module setPermamentSettings:dict];
    }
  }
}

- (NSString *)errorDescription
{
  return errorDescription;
}

#pragma mark Framework Methods

- (void)_handleDeviceList:(NSArray *)deviceList
{
  [inputDevices release];
	
  inputDevices = [deviceList copy];
	
  BOOL firstRun = (selectedInputDevice == nil);
	
  if (firstRun == YES || [inputDevices indexOfObject:selectedInputDevice] == NSNotFound) {
    [selectedInputDevice release];
    unsigned dummyIndex = [inputDevices count] - 1;
    selectedInputDevice = [[inputDevices objectAtIndex:dummyIndex] retain];
  }
	
  [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_VideoManagerDidUpdateInputDeviceList object:nil];
	
  if (firstRun == YES) {
    [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_VideoManagerDidChangeSelectedInputDevice object:self];
  }
}

- (void)_handleInputDeviceChangeComplete:(NSArray *)info
{
  NSString *device = (NSString *)[info objectAtIndex:0];
  id<XMVideoModule> videoModule = (id<XMVideoModule>)[info objectAtIndex:1];
	
  if ([device isEqualToString:selectedInputDevice] == NO) {
    [selectedInputDevice release];
    selectedInputDevice = [device retain];
  }
    
  if (![videoModule isEqual:[NSNull null]]) {
    [selectedVideoModule release];
    selectedVideoModule = [videoModule retain];
  }
	
  [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_VideoManagerDidChangeSelectedInputDevice object:self];
}

- (void)_handleVideoReceivingStart:(NSArray *)info
{
  NSNumber *number = [info objectAtIndex:0];
  remoteVideoSize = (XMVideoSize)[number unsignedIntValue];
	
  number = [info objectAtIndex:1];
  unsigned width = [number unsignedIntValue];
	
  number = [info objectAtIndex:2];
  unsigned height = [number unsignedIntValue];
	
  remoteVideoDimensions = NSMakeSize(width, height);
	
  [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_VideoManagerDidStartReceivingVideo object:self];
}

- (void)_handleVideoReceivingEnd
{
  remoteVideoSize = XMVideoSize_NoVideo;
  remoteVideoDimensions = NSMakeSize(0, 0);
	
  [videoLock lock];
	
  if (remoteVideoTexture != NULL) {
    CVOpenGLTextureRelease(remoteVideoTexture);
    remoteVideoTexture = NULL;
  }
  CVOpenGLTextureCacheFlush(textureCache, 0);
	
  [videoLock unlock];
	
  [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_VideoManagerDidEndReceivingVideo object:self];
}

- (void)_handleVideoTransmittingStart:(NSNumber *)videoSize
{
  localVideoSize = (XMVideoSize)[videoSize unsignedIntValue];
	
  [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_VideoManagerDidStartTransmittingVideo object:self];
}

- (void)_handleVideoTransmittingEnd
{
  localVideoSize = XMVideoSize_NoVideo;
	
  [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_VideoManagerDidEndTransmittingVideo object:self];
}

- (void)_handleErrorDescription:(NSString *)theErrorDescription
{
  if (theErrorDescription == nil) {
    return;
  }
    
  [errorDescription release];
  errorDescription = [theErrorDescription copy];
	
  [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_VideoManagerDidGetError object:self];
}

- (void)_handleLocalVideoFrame:(CVPixelBufferRef)pixelBuffer
{
  [videoLock lock];
	
  // preventing to run any drawing operation after -_close has been called
  if (textureCache == NULL) {
    [videoLock unlock];
    return;
  }
	
  // transform the CVPixelBufferRef into an OpenGL texture
  CVOpenGLTextureRef openGLTexture;
  CVOpenGLTextureCacheCreateTextureFromImage(NULL, textureCache, pixelBuffer, NULL, &openGLTexture);
	
  if (localVideoTexture != NULL) {
    CVOpenGLTextureRelease(localVideoTexture);
  }
  localVideoTexture = openGLTexture;
  CVOpenGLTextureCacheFlush(textureCache, 0);
	
  localVideoTextureDidChange = YES;
	
  [videoLock unlock];
		
  [_XMCallRecorderSharedInstance _handleUncompressedLocalVideoFrame:pixelBuffer];
}

- (void)_handleRemoteVideoFrame:(CVPixelBufferRef)pixelBuffer
{
  [videoLock lock];
	
  // preventing to run any drawing operation after -_close has been called
  if (textureCache == NULL) {
    [videoLock unlock];
    return;
  }
	
  // transform the CVPixelBufferRef into an OpenGL texture
  CVOpenGLTextureRef openGLTexture;
  CVOpenGLTextureCacheCreateTextureFromImage(NULL, textureCache, pixelBuffer, NULL, &openGLTexture);
	
  if (remoteVideoTexture != NULL) {
    CVOpenGLTextureRelease(remoteVideoTexture);
  }
  remoteVideoTexture = openGLTexture;
  CVOpenGLTextureCacheFlush(textureCache, 0);
	
  remoteVideoTextureDidChange = YES;
	
  [videoLock unlock];
	
  [_XMCallRecorderSharedInstance _handleUncompressedRemoteVideoFrame:pixelBuffer];
}

#pragma mark Private Methods

- (void)_outputFrames
{
  NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
  [videoLock lock];
	
  if (localVideoTextureDidChange == YES || remoteVideoTextureDidChange == YES) {
    
    unsigned count = [videoViews count];
    for (unsigned i = 0; i < count; i++) {
      id<XMVideoView> videoView = (id<XMVideoView>)[videoViews objectAtIndex:i];
      [videoView renderLocalVideo:localVideoTexture didChange:localVideoTextureDidChange 
                      remoteVideo:remoteVideoTexture didChange:remoteVideoTextureDidChange
                         isForced:NO];
    }
    localVideoTextureDidChange = NO;
    remoteVideoTextureDidChange = NO;
  }
	
  [videoLock unlock];
	
  [autoreleasePool release];
}

@end

#pragma mark Callbacks

static CVReturn _XMDisplayLinkCallback(CVDisplayLinkRef displayLink, 
                                       const CVTimeStamp *inNow, 
                                       const CVTimeStamp *inOutputTime, 
                                       CVOptionFlags flagsIn, 
                                       CVOptionFlags *flagsOut, 
                                       void *displayLinkContext)
{
  [_XMVideoManagerSharedInstance _outputFrames];
  return kCVReturnSuccess;
}