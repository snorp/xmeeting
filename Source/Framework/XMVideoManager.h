/*
 * $Id: XMVideoManager.h,v 1.8 2005/11/29 18:56:29 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_VIDEO_MANAGER_H__
#define __XM_VIDEO_MANAGER_H__

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

#import "XMTypes.h"
#import "XMVideoView.h"

/**
 * The XMeeting framework uses a highly optimized, extensible
 * and flexible engine using QuickTime, CoreVideo and OpenGL
 * to
 * - grab video from a local video source (e.g. webcam),
 * - compress/decompress video data and
 * - display the video data on screen
 *
 * XMVideoManager is the interface to this engine, with the help
 * of the XMVideoView protocol. This manager provides methods to
 * select input devices, register interested video draw views and
 * get additional information.
 * The XMeeting framework does not provide actual code to draw the
 * video data on screen but faciliates this task through the
 * XMVideoView protocol. To draw on screen, OpenGL has to be used.
 * This way, the application can add their own rendering code used
 * to display the frames on screen.
 **/
@interface XMVideoManager : NSObject {
	
	NSMutableArray *videoInputModules;
	NSMutableArray *videoViews;
	
	NSArray *inputDevices;
	NSString *selectedInputDevice;
	
	XMVideoSize localVideoSize;
	XMVideoSize remoteVideoSize;
	
	NSLock *videoLock;
	NSOpenGLPixelFormat *openGLPixelFormat;
	NSOpenGLContext *openGLContext;
	CVOpenGLTextureCacheRef textureCache;
	CVOpenGLTextureRef localVideoTexture;
	BOOL localVideoTextureDidChange;
	CVOpenGLTextureRef remoteVideoTexture;
	BOOL remoteVideoTextureDidChange;
	CVDisplayLinkRef displayLink;
}

/**
 * Returns the shared singleton instance of this class
 **/
+ (XMVideoManager *)sharedInstance;

/**
 * Returns an array of strings containing the input devices.
 * Note that this method does not return valid devices before
 * the appropriate Notification.
 **/
- (NSArray *)inputDevices;

/**
 * Discards the current device list and refreshes the list
 * Note that the new device list isn't available until the
 * appropriate notification is posted. Sometimes, creating
 * a new device list might take some time (1s or even more)
 **/
- (void)updateInputDeviceList;

/**
 * Returns the currently selected device
 **/
- (NSString *)selectedInputDevice;

/**
 * Sets the device to use. Does nothing if inputDevice isn't a valid
 * device.
 **/
- (void)setSelectedInputDevice:(NSString *)inputDevice;

/**
 * Starts the grabbing process
 **/
- (void)startGrabbing;

/**
 * Stops the grabbing process. Calling this method
 * will raise an exception if called while a transmission
 * is ongoing
 **/
- (void)stopGrabbing;

/**
 * Returns the size of the video currently transmitted.
 * If no video is transmitted, this method returns
 * XMVideoSize_NoVideo
 **/
- (XMVideoSize)localVideoSize;

/**
 * Returns the size of the remote video currently received.
 * If no video is received, returns XMVideoSize_NoVideo.
 **/
- (XMVideoSize)remoteVideoSize;

/**
 * Adds videoView to the list of views interested in rendering
 * local and/or remote video on the screen.
 * This method contains an implicit call to -forceRenderingForView,
 * thus when this method returns, -renderLocalVideo:remoteVideo:
 * has been called at least once.
 **/
- (void)addVideoView:(id<XMVideoView>)videoView;

/**
 * Removes videoView from the list of views interested in
 * rendering video
 **/
- (void)removeVideoView:(id<XMVideoView>)videoView;

/**
 * Returns the OpenGL pixel format to be used when creating
 * OpenGL contexts to be used to render video
 **/
- (NSOpenGLPixelFormat *)openGLPixelFormat;

/**
 * Returns the OpenGL context with which the OpenGL textures
 * are created. The contexts used by the application to draw
 * video on screen must share this context
 **/
- (NSOpenGLContext *)openGLContext;

/**
 * Causes the manager call -renderLocalVideo:remoteVideo:
 * on videoView after the system has been locked properly.
 * This method works also for views which arent't registered
 * using -addVideoView.
 **/
- (void)forceRenderingForView:(id<XMVideoView>)videoView;

@end


#endif // __XM_VIDEO_MANAGER_H__
