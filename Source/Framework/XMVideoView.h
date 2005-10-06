/*
 * $Id: XMVideoView.h,v 1.1 2005/10/06 15:04:42 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_VIDEO_VIEW_H__
#define __XM_VIDEO_VIEW_H__

#import <Cocoa/Cocoa.h>

/**
 * This class is used to display video on screen
 * you can specify whether to display the local
 * preview image or the remote video. Later,
 * direct PIP-Support is also planned
 **/
@interface XMVideoView : NSView {
	
	unsigned displayType;
	NSProgressIndicator *busyIndicator;
	
}

/**
 * Starts/Stops to display the local video
 * Currently, displaying local or remote
 * video is mutually exclusively.
 * Calling this method stops any
 * remote video display in progress
 * and vice versa
 **/
- (void)startDisplayingLocalVideo;
- (void)stopDisplayingLocalVideo;

/**
 * Starts to display the remote video
 * Currently, displaying local or remote
 * video is mutually exclusively
 * Calling this method stops any
 * local video display in progress
 * and vice versa
 **/
- (void)startDisplayingRemoteVideo;
- (void)stopDisplayingRemoteVideo;

@end

#endif // __XM_VIDEO_VIEW_H__
