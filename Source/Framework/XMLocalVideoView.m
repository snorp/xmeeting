/*
 * $Id: XMLocalVideoView.m,v 1.1 2005/02/11 12:58:44 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMLocalVideoView.h"
#import "XMVideoManager.h"
#import "XMPrivate.h"


@implementation XMLocalVideoView

- (void)startDisplayingLocalVideo
{	
	[[XMVideoManager sharedInstance] _addLocalVideoView:self];
}

- (void)stopDisplayingLocalVideo
{
	[[XMVideoManager sharedInstance] _removeLocalVideoView:nil];
}

- (void)drawRect:(NSRect)rect
{
	[[XMVideoManager sharedInstance] _drawToView:self];
}

@end
