/*
 * $Id: XMVideoManager.m,v 1.8 2006/02/08 23:25:54 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMTypes.h"
#import "XMStringConstants.h"
#import "XMPrivate.h"
#import "XMVideoManager.h"
#import "XMMediaTransmitter.h"
#import "XMVideoView.h"

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
	if(_XMVideoManagerSharedInstance == nil)
	{
		NSLog(@"Attempt to access VideoManager prior to initialization");
	}
	
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
	
	videoInputModules = nil;
	videoViews = [[NSMutableArray alloc] initWithCapacity:3];
	
	inputDevices = nil;
	selectedInputDevice = nil;
	
	localVideoSize = XMVideoSize_NoVideo;
	remoteVideoSize = XMVideoSize_NoVideo;
	
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
	
	CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
	CVDisplayLinkSetOutputCallback(displayLink, &_XMDisplayLinkCallback, NULL);
	CVDisplayLinkStart(displayLink);
	
	return self;
}

- (void)_close
{	
	if(displayLink != NULL)
	{
		CVDisplayLinkStop(displayLink);
		CVDisplayLinkRelease(displayLink);
		displayLink = NULL;
	}
	
	[videoLock lock];
	
	if(videoInputModules != nil)
	{
		[videoInputModules release];
		videoInputModules = nil;
	}
	if(videoViews != nil)
	{
		[videoViews release];
		videoViews = nil;
	}
	if(inputDevices != nil)
	{
		[inputDevices release];
		inputDevices = nil;
	}
	if(selectedInputDevice != nil)
	{
		[selectedInputDevice release];
		selectedInputDevice = nil;
	}
	if(openGLPixelFormat != nil)
	{
		[openGLPixelFormat release];
		openGLPixelFormat = nil;
	}
	if(openGLContext != nil)
	{
		[openGLContext release];
		openGLContext = nil;
	}
	if(textureCache != NULL)
	{
		CVOpenGLTextureCacheRelease(textureCache);
		textureCache = NULL;
	}
	
	[videoLock unlock];
}

- (void)dealloc
{	
	[self _close];
	
	[videoLock release];
	
	[super dealloc];
}

#pragma mark Public Methods

- (NSArray *)inputDevices
{
	return inputDevices;
}

- (void)updateInputDeviceList
{
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_VideoManagerDidStartInputDeviceListUpdate
														object:self];
	[XMMediaTransmitter _getDeviceList];
}

- (NSString *)selectedInputDevice
{
	return selectedInputDevice;
}

- (void)setSelectedInputDevice:(NSString *)inputDevice
{
	if(inputDevice != nil && ![inputDevice isEqualToString:selectedInputDevice])
	{
		[selectedInputDevice release];
		selectedInputDevice = [inputDevice retain];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_VideoManagerDidStartSelectedInputDeviceChange object:self];
		[_XMMediaTransmitterSharedInstance _setDevice:selectedInputDevice];
	}
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

- (void)startGrabbing
{
	[XMMediaTransmitter _startGrabbing];
}

- (void)stopGrabbing
{
	[XMMediaTransmitter _stopGrabbing];
}

- (XMVideoSize)localVideoSize
{
	return localVideoSize;
}

- (XMVideoSize)remoteVideoSize
{
	return remoteVideoSize;
}

- (void)addVideoView:(id<XMVideoView>)videoView
{
	[videoLock lock];
	
	[videoViews addObject:videoView];
	[videoView renderLocalVideo:localVideoTexture didChange:YES 
					remoteVideo:remoteVideoTexture didChange:YES
					   isForced:YES];
	
	[videoLock unlock];
}

- (void)removeVideoView:(id<XMVideoView>)videoView
{
	[videoLock lock];
	
	[videoViews removeObject:videoView];
	
	[videoLock unlock];
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

#pragma mark Framework Methods

- (void)_handleDeviceList:(NSArray *)deviceList
{
	[inputDevices release];
	
	inputDevices = [deviceList copy];
	
	BOOL firstRun = (selectedInputDevice == nil);
	
	if(firstRun == YES || [inputDevices indexOfObject:selectedInputDevice] == NSNotFound)
	{
		[selectedInputDevice release];
		selectedInputDevice = [[inputDevices objectAtIndex:0] retain];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_VideoManagerDidUpdateInputDeviceList
														object:nil];
	if(firstRun == YES)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_VideoManagerDidChangeSelectedInputDevice object:self];
	}
}

- (void)_handleInputDeviceChangeComplete:(NSString *)device
{
	if([device isEqualToString:selectedInputDevice] == NO)
	{
		[selectedInputDevice release];
		selectedInputDevice = [device retain];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_VideoManagerDidChangeSelectedInputDevice object:self];
}

- (void)_handleVideoReceivingStart:(NSNumber *)videoSize
{
	remoteVideoSize = (XMVideoSize)[videoSize unsignedIntValue];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_VideoManagerDidStartReceivingVideo object:self];
}

- (void)_handleVideoReceivingEnd
{
	remoteVideoSize = XMVideoSize_NoVideo;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_VideoManagerDidEndReceivingVideo object:self];
}

- (void)_handleLocalVideoFrame:(CVPixelBufferRef)pixelBuffer
{	
	[videoLock lock];
	
	// preventing to run any drawing operation after -_close has been
	// called
	if(textureCache == NULL)
	{
		[videoLock unlock];
		return;
	}
	
	// transform the CVPixelBufferRef into an OpenGL texture
	CVOpenGLTextureRef openGLTexture;
	CVOpenGLTextureCacheCreateTextureFromImage(NULL, textureCache,
											   pixelBuffer, NULL, &openGLTexture);
	
	if(localVideoTexture != NULL)
	{
		CVOpenGLTextureRelease(localVideoTexture);
	}
	localVideoTexture = openGLTexture;
	CVOpenGLTextureCacheFlush(textureCache, 0);
	
	localVideoTextureDidChange = YES;
	
	[videoLock unlock];
}

- (void)_handleRemoteVideoFrame:(CVPixelBufferRef)pixelBuffer
{
	[videoLock lock];
	
	// preventing to run any drawing operation after -_close has been
	// called
	if(textureCache == NULL)
	{
		[videoLock unlock];
		return;
	}
	
	// transform the CVPixelBufferRef into an OpenGL texture
	CVOpenGLTextureRef openGLTexture;
	CVOpenGLTextureCacheCreateTextureFromImage(NULL, textureCache,
											   pixelBuffer, NULL, &openGLTexture);
	
	if(remoteVideoTexture != NULL)
	{
		CVOpenGLTextureRelease(remoteVideoTexture);
	}
	remoteVideoTexture = openGLTexture;
	CVOpenGLTextureCacheFlush(textureCache, 0);
	
	remoteVideoTextureDidChange = YES;
	
	[videoLock unlock];
}

#pragma mark Private Methods

- (void)_outputFrames
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	[videoLock lock];
	
	if(localVideoTextureDidChange == YES ||
	   remoteVideoTextureDidChange == YES)
	{
		unsigned count = [videoViews count];
		unsigned i;
	
		for(i = 0; i < count; i++)
		{
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