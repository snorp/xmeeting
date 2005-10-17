/*
 * $Id: XMRecentCallsView.m,v 1.2 2005/10/17 12:57:54 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMeeting.h"
#import "XMRecentCallsView.h"
#import "XMCallInfoView.h"

#define SPACING 2

@interface XMRecentCallsView (PrivateMethods)

- (void)_callCleared:(NSNotification *)notif;
- (void)_layoutSubviews;

@end

@implementation XMRecentCallsView

#pragma mark Init & Deallocation Methods

- (id)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_callCleared:)
												 name:XMNotification_CallManagerDidClearCall
											   object:nil];

	layoutDone = NO;
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

#pragma mark Public Methods

- (void)noteSubviewHeightDidChange:(NSView *)subview
{
	[self _layoutSubviews];
	
	NSRect frame = [subview frame];
	
	frame.size.height += SPACING;
	
	[self scrollRectToVisible:frame];
}

#pragma mark NSView Methods

- (void)drawRect:(NSRect)frameRect
{
	if(layoutDone == NO || [self inLiveResize])
	{
		[self _layoutSubviews];
		layoutDone = YES;
	}
	[super drawRect:frameRect];
}

#pragma mark Private Methods

- (void)_callCleared:(NSNotification *)notif
{
	XMCallInfo *callInfo = (XMCallInfo *)[[[XMCallManager sharedInstance] recentCalls] objectAtIndex:0];
	
	XMCallInfoView *callInfoView = [[XMCallInfoView alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
	[callInfoView setCallInfo:callInfo];
	[callInfoView setAutoresizingMask:NSViewWidthSizable];
	[self addSubview:callInfoView];
	[callInfoView release];
	
	[self _layoutSubviews];
	
	NSRect frame = [callInfoView frame];
	frame.size.height += SPACING;
	
	[self scrollRectToVisible:frame];
}

- (void)_layoutSubviews
{
	NSArray *subviews = [self subviews];
	
	unsigned i;
	unsigned count = [subviews count];
	
	float width = [self frame].size.width - 2*SPACING;
	float usedHeight = SPACING;
	
	for(i = 0; i < count; i++)
	{
		XMCallInfoView *callInfoView = (XMCallInfoView *)[subviews objectAtIndex:i];
		float requiredHeight = [callInfoView requiredHeightForWidth:width];
		[callInfoView setFrame:NSMakeRect(SPACING, usedHeight, width, requiredHeight)];
		usedHeight += (requiredHeight + SPACING);
	}
	
	float actualHeight = [scrollView contentSize].height;
	float heightDifference = actualHeight - usedHeight;
	
	NSRect frame = [self frame];
		
	if(heightDifference > 0)
	{
		for(i = 0; i < count; i++)
		{
			XMCallInfoView *callInfoView = (XMCallInfoView *)[subviews objectAtIndex:i];
			NSRect frame = [callInfoView frame];
			frame.origin.y += heightDifference;
			[callInfoView setFrame:frame];
		}
		
		frame.size.height = actualHeight;
	}
	else
	{
		frame.size.height = usedHeight;
	}
	
	[self setFrame:frame];
	
	[self setNeedsDisplay:YES];
		
}

@end
