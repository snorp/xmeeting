/*
 * $Id: XMMouseOverButton.m,v 1.3 2006/03/14 23:06:00 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMMouseOverButton.h"

@interface XMMouseOverButton (PrivateMethods)

- (void)_windowDidResize:(NSNotification *)notif;

@end

@implementation XMMouseOverButton

#pragma mark Setup methods

- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	
	[self setBordered:NO];
	
	trackingTag = -1;
	isMouseOver = NO;
	
	return self;
}

- (void)reset
{
	isMouseOver = NO;
	[self setState:NSOffState];
}

- (void)sizeToFit
{
	BOOL isBordered = [self isBordered];
	
	if(!isBordered)
	{
		[self setBordered:YES];
	}
	
	[super sizeToFit];
	
	if(!isBordered)
	{
		[self setBordered:NO];
	}
}

- (void)viewDidEndLiveResize
{
	[super viewDidEndLiveResize];
	if(trackingTag != -1)
	{
		[self removeTrackingRect:trackingTag];
	}
	trackingTag = [self addTrackingRect:[self bounds] owner:self userData:nil assumeInside:NO];
}

- (void)removeFromSuperview
{
	[super removeFromSuperview];
	
	[self removeTrackingRect:trackingTag];
}

#pragma mark Enabling Mouse Tracking

- (void)setFrame:(NSRect)frame
{
	[super setFrame:frame];
	if(trackingTag != -1)
	{
		[self removeTrackingRect:trackingTag];
	}
	trackingTag = [self addTrackingRect:[self bounds] owner:self userData:nil assumeInside:NO];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	int state = [self state];
	
	if(state == NSOffState)
	{
		[self setBordered:YES];
	}
	isMouseOver = YES;
}

- (void)mouseExited:(NSEvent *)theEvent
{
	int state = [self state];
	
	if(state == NSOffState)
	{
		[self setBordered:NO];
	}
	isMouseOver = NO;
}

- (void)setState:(int)state
{
	if(state == NSOnState)
	{
		[self setBordered:YES];
	}
	else if(isMouseOver == NO)
	{
		[self setBordered:NO];
	}
	[super setState:state];
}

@end
