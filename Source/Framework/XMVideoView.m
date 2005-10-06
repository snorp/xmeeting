/*
 * $Id: XMVideoView.m,v 1.1 2005/10/06 15:04:42 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMVideoView.h"
#import "XMVideoManager.h"
#import "XMPrivate.h"

#define XM_NO_VIDEO_DISPLAY 0
#define XM_LOCAL_VIDEO_DISPLAY 1
#define XM_REMOTE_VIDEO_DISPLAY 2

@interface XMVideoView (PrivateMethods)

- (void)_init;

@end

@implementation XMVideoView

- (id)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	
	[self _init];
	
	return self;
}

- (void)awakeFromNib
{
	[self _init];
}

- (void)_init
{
	if(busyIndicator != NULL)
	{
		return;
	}
	
	displayType = XM_NO_VIDEO_DISPLAY;
	
	busyIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, 32, 32)];
	[busyIndicator setIndeterminate:YES];
	[busyIndicator setStyle:NSProgressIndicatorSpinningStyle];
	[busyIndicator setControlSize:NSRegularControlSize];
	[busyIndicator setDisplayedWhenStopped:NO];
	[busyIndicator setAnimationDelay:(5.0/60.0)];
	[busyIndicator setAutoresizingMask:(NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin)];
	[busyIndicator sizeToFit];
	
	[self addSubview:busyIndicator positioned:NSWindowAbove relativeTo:nil];
	
	NSRect ownBounds = [self bounds];
	NSRect busyIndicatorFrame = [busyIndicator frame];
	
	float x = (ownBounds.size.width - busyIndicatorFrame.size.width) / 2;
	float y = (ownBounds.size.height - busyIndicatorFrame.size.height) / 2;
	
	[busyIndicator setFrame:NSMakeRect(x, y, busyIndicatorFrame.size.width, busyIndicatorFrame.size.height)];
}

- (void)startDisplayingLocalVideo
{
	if(displayType == XM_LOCAL_VIDEO_DISPLAY)
	{
		return;
	}
	else if(displayType == XM_REMOTE_VIDEO_DISPLAY)
	{
		[self stopDisplayingRemoteVideo];
	}
	
	[[XMVideoManager sharedInstance] _addLocalVideoView:self];
	displayType = XM_LOCAL_VIDEO_DISPLAY;
}

- (void)stopDisplayingLocalVideo
{
	[[XMVideoManager sharedInstance] _removeLocalVideoView:self];
	displayType = XM_NO_VIDEO_DISPLAY;
}

- (void)startDisplayingRemoteVideo
{
	if(displayType == XM_REMOTE_VIDEO_DISPLAY)
	{
		return;
	}
	else if(displayType == XM_LOCAL_VIDEO_DISPLAY)
	{
		[self stopDisplayingLocalVideo];
	}
	
	[[XMVideoManager sharedInstance] _addRemoteVideoView:self];
	displayType = XM_REMOTE_VIDEO_DISPLAY;
}

- (void)stopDisplayingRemoteVideo
{
	[[XMVideoManager sharedInstance] _removeRemoteVideoView:self];
	displayType = XM_NO_VIDEO_DISPLAY;
}

- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];
	
	if(displayType == XM_LOCAL_VIDEO_DISPLAY)
	{
		[[XMVideoManager sharedInstance] _drawLocalVideoInRect:[self bounds]];
	}
	else if(displayType == XM_REMOTE_VIDEO_DISPLAY)
	{
		[[XMVideoManager sharedInstance] _drawRemoteVideoInRect:[self bounds]];
	}
	else
	{
		NSEraseRect(rect);
	}
}

- (BOOL)isOpaque
{
	return YES;
}

#pragma mark Framework Methods

- (void)_startBusyIndicator
{
	[busyIndicator startAnimation:self];
}

- (void)_stopBusyIndicator
{
	[busyIndicator stopAnimation:self];
}

@end
