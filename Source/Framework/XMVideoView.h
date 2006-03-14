/*
 * $Id: XMVideoView.h,v 1.3 2006/03/14 23:05:57 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_VIDEO_VIEW_H__
#define __XM_VIDEO_VIEW_H__

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

/**
 * This protocol declares the methods necessary to draw video
 * from the XMeeting framework on screen
 **/
@protocol XMVideoView <NSObject>
	
/**
 * Called every time a video frame from either the local or
 * remote video did change. both localVideo and remoteVideo
 * may be NULL.
 * This method is NOT always called on the main thread! The
 * system is locked, however, so that it is not necessary
 * to add locks to protect the OpenGL code.
 * If, for some reason, you need to force drawing on the
 * main thread, you can call -forceRenderingForView: of
 * the VideoManager.
 **/
- (void)renderLocalVideo:(CVOpenGLTextureRef)localVideo didChange:(BOOL)localVideoDidChange
			 remoteVideo:(CVOpenGLTextureRef)remoteVideo didChange:(BOOL)remoteVideoDidChange
				isForced:(BOOL)isForced;

@end

#endif // __XM_VIDEO_VIEW_H__
