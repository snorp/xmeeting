/*
 * $Id: XMSimpleVideoView.h,v 1.1 2005/11/29 18:56:29 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_SIMPLE_VIDEO_VIEW_H__
#define __XM_SIMPLE_VIDEO_VIEW_H__

#import <Cocoa/Cocoa.h>
#import "XMeeting.h"

/**
 * A simple view that draws either the local or remote
 * video within its frame
 **/
@interface XMSimpleVideoView : NSView <XMVideoView> {

	NSOpenGLContext *openGLContext;
	unsigned displayState;
	NSSize previousSize;
	
	// only used to draw into the window draw buffer when
	// the window does miniaturize or there is no local video
	// (e.g. when the device is changed)
	NSCIImageRep *ciImageRep;
	BOOL isMiniaturized;
	BOOL isBusy;
	
	// indicates that something video-related is in progress
	NSProgressIndicator *busyIndicator;
}

/**
 * Displaying local or remote video are mutually exclusive.
 **/
- (void)startDisplayingLocalVideo;
- (void)startDisplayingRemoteVideo;
- (void)stopDisplayingVideo;

@end

#endif // __XM_LOCAL_VIDEO_VIEW_H__
