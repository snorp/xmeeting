/*
 * $Id: XMAudioOnlyOSD.h,v 1.5 2008/11/03 21:34:03 hfriederich Exp $
 *
 * Copyright (c) 2006-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2008 Ivan Guajana, Hannes Friederich. All rights reserved.
 */

#ifndef __XM_AUDIO_ONLY_OSD_H__
#define __XM_AUDIO_ONLY_OSD_H__

#import <Cocoa/Cocoa.h>

#import "XMOnScreenControllerView.h"

@class XMOSDVideoView;

@interface XMAudioOnlyOSD : XMOnScreenControllerView {

@private
  XMOSDVideoView *videoView;
}

- (id)initWithFrame:(NSRect)frameRect videoView:(XMOSDVideoView *)videoView andSize:(XMOSDSize)size;

- (void)setMutesAudioInput:(BOOL)mutes;

@end

#endif // __XM_AUDIO_ONLY_OSD_H__
