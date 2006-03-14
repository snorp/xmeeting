/*
 * $Id: XMLocalAudioVideoView.h,v 1.3 2006/03/14 23:06:00 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_LOCAL_AUDIO_VIDEO_VIEW_H__
#define __XM_LOCAL_AUDIO_VIDEO_VIEW_H__

#import <Cocoa/Cocoa.h>


@interface XMLocalAudioVideoView : NSView {
	
	IBOutlet NSView *audioContentView;
	IBOutlet NSView *videoContentView;

}


- (NSSize)requiredSize;

@end

#endif // __XM_LOCAL_AUDIO_VIDEO_VIEW_H__
