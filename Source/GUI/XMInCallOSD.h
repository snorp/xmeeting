/*
 * $Id: XMInCallOSD.h,v 1.3 2006/05/16 21:33:08 hfriederich Exp $
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
	BOOL enableComplexPinPModes;
	unsigned volume;
}

- (id)initWithFrame:(NSRect)frameRect videoView:(XMOSDVideoView *)videoView andSize:(XMOSDSize)size;

// Enables / disables the advanced display modes.
// On older machines, the 3D PinP mode will not display correctly
- (BOOL)enableComplexPinPModes;
- (void)setEnableComplexPinPModes:(BOOL)flag;

//Functions to set the state of buttons directly
- (void)setPinPMode:(XMPinPMode)mode;
- (void)setIsFullScreen:(BOOL)isFullscreen;

@end

#endif // __XM_IN_CALL_OSD_H__
