/*
 * $Id: XMLocalVideoView.h,v 1.1 2005/02/11 12:58:44 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

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
