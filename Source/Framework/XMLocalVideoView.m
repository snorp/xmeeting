/*
 * $Id: XMLocalVideoView.m,v 1.2 2005/04/28 20:26:27 hfriederich Exp $
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
	NSLog(@"starting displaying local video");
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
