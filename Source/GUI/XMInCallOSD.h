/*
 * $Id: XMInCallOSD.h,v 1.2 2006/03/23 10:04:48 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Ivan Guajana. All rights reserved.
 */

#ifndef __XM_IN_CALL_OSD_H__
#define __XM_IN_CALL_OSD_H__

#import <Cocoa/Cocoa.h>

#import "XMOnScreenControllerView.h"
#import "XMOSDVideoView.h"

@interface XMInCallOSD : XMOnScreenControllerView {

	XMOSDVideoView *videoView;
	XMPinPMode pinpMode;
	unsigned volume;
}

- (id)initWithFrame:(NSRect)frameRect videoView:(XMOSDVideoView *)videoView andSize:(XMOSDSize)size;

//Functions to set the state of buttons directly
- (void)setPinPMode:(XMPinPMode)mode;
- (void)setIsFullScreen:(BOOL)isFullscreen;

@end

#endif // __XM_IN_CALL_OSD_H__
