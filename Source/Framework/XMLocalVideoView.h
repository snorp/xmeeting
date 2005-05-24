/*
 * $Id: XMLocalVideoView.h,v 1.2 2005/05/24 15:21:01 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_LOCAL_VIDEO_VIEW_H__
#define __XM_LOCAL_VIDEO_VIEW_H__

#import <Cocoa/Cocoa.h>

/* 
 * This class is used to display grabbed video on screen.
 * The view registers itself with XMVideoManager so that the local
 * video grabbed is displayed on screen.
 * NOTE: Currently, only ONE XMLocalVideoView is allowed, only the
 * last registered view gets any video content.
 */
@interface XMLocalVideoView : NSQuickDrawView {
}

- (void)startDisplayingLocalVideo;
- (void)stopDisplayingLocalVideo;

@end

#endif // __XM_LOCAL_VIDEO_VIEW_H__
