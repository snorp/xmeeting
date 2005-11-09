/*
 * $Id: XMLocalAudioVideoView.h,v 1.1 2005/11/09 20:00:27 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_LOCAL_AUDIO_VIDEO_VIEW_H__
#define __XM_LOCAL_AUDIO_VIDEO_VIEW_H__

#import <Cocoa/Cocoa.h>


@interface XMLocalAudioVideoView : NSView {
	
	IBOutlet NSView *audioContentView;
	IBOutlet NSView *videoContentView;
	IBOutlet NSView *disclosureContentView;
	
	BOOL contentVisible;
	BOOL showAudioVideoContent;
	BOOL showVideoContent;
}

- (void)setContentVisible:(BOOL)flag;
- (void)setShowAudioVideoContent:(BOOL)flag;
- (void)setShowVideoContent:(BOOL)flag;

- (NSSize)requiredSize;

@end

#endif // __XM_LOCAL_AUDIO_VIDEO_VIEW_H__
