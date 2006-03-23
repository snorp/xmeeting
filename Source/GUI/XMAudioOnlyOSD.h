/*
 * $Id: XMAudioOnlyOSD.h,v 1.2 2006/03/23 10:04:47 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Ivan Guajana. All rights reserved.
 */

#ifndef __XM_AUDIO_ONLY_OSD_H__
#define __XM_AUDIO_ONLY_OSD_H__

#import <Cocoa/Cocoa.h>

#import "XMOnScreenControllerView.h"

@class XMOSDVideoView;

@interface XMAudioOnlyOSD : XMOnScreenControllerView {
	
	XMOSDVideoView *videoView;
}

- (id)initWithFrame:(NSRect)frameRect videoView:(XMOSDVideoView *)videoView andSize:(XMOSDSize)size;

@end

#endif // __XM_AUDIO_ONLY_OSD_H__
