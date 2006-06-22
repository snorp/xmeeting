/*
 * $Id: XMAudioOnlyOSD.h,v 1.3 2006/06/22 11:11:09 hfriederich Exp $
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

- (void)setMutesAudioInput:(BOOL)mutes;

@end

#endif // __XM_AUDIO_ONLY_OSD_H__
