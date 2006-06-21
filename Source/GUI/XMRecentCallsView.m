/*
 * $Id: XMRecentCallsView.m,v 1.4 2006/06/21 18:22:58 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMeeting.h"
#import "XMRecentCallsView.h"
#import "XMCallInfoView.h"

#define SPACING 4

@interface XMRecentCallsView (PrivateMethods)

- (void)_callCleared:(NSNotification *)notif;
- (void)_layoutSubviews:(BOOL)animate;

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
	// unlike the case of live resize, the width of the objects
	// does not change. Thus, the other subviews do not change
	// in height either.
	NSArray *subviews = [self subviews];
	unsigned index = [subviews indexOfObject:subview];
	
	if(index == NSNotFound)
	{
		return;
	}
	
	NSRect frame = [subview frame];
	float width = frame.size.width;
	float currentHeight = frame.size.height;
	float newHeight = [(XMCallInfoView *)subview requiredHeightForWidth:width];
	
	float actualHeight = [scrollView contentSize].height;
	NSRect viewFrame = [self frame];
	float totalHeightDifference = viewFrame.size.height - actualHeight;
	float newTotalHeight;
	
	float heightDifference = newHeight - currentHeight;
	
	float heightOffsetDifference;
	float totalHeight;
	
	unsigned count = [subviews count];
	unsigned i;
	for(i = 0; i < count; i++)
	{
		XMCallInfoView *infoView = (XMCallInfoView *)[subviews objectAtIndex:i];
		frame = [infoView frame];
		
		if(i == 0)
		{
			float heightOffset = frame.origin.y - SPACING;
			float newHeightOffset;
			if(totalHeightDifference > 0)
			{
				newTotalHeight = viewFrame.size.height + heightDifference;
				if(newTotalHeight < actualHeight)
				{
					newHeightOffset = actualHeight - newTotalHeight;
					newTotalHeight = actualHeight;
				}
				else
				{
					newHeightOffset = 0;
				}
			}
			else
			{
				newTotalHeight = viewFrame.size.height + heightDifference - heightOffset;
				if(newTotalHeight < actualHeight)
				{
					newHeightOffset = actualHeight - newTotalHeight;
					newTotalHeight = actualHeight;
				}
				else
				{
					newHeightOffset = 0;
				}
			}
			
			if(newHeightOffset < 0)
			{
				newHeightOffset = 0;
			}
			
			heightOffsetDifference = heightOffset - newHeightOffset;
		}
		
		if(i < index)
		{
			frame.origin.y -= heightOffsetDifference;
		}
		else if(i == index)
		{
			frame.origin.y -= heightOffsetDifference;
			frame.size.height = newHeight;
		}
		else
		{
			frame.origin.y += (heightDifference - heightOffsetDifference);
		}
		[infoView setFrame:frame];
		
		if(i == (count - 1))
		{
			totalHeight = frame.origin.y + frame.size.height + SPACING;
		}
	}
	
	viewFrame.size.height = newTotalHeight;

	[self setFrame:viewFrame];
	[self display];
	
	frame = [subview frame];
	
	frame.size.height += SPACING;
	
	[self scrollRectToVisible:frame];
}

#pragma mark NSView Methods

- (void)drawRect:(NSRect)frameRect
{
	if(layoutDone == NO || [self inLiveResize])
	{
		[self _layoutSubviews:NO];
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
	
	[self _layoutSubviews:NO];
	
	NSRect frame = [callInfoView frame];
	frame.size.height += SPACING;
	
	[self scrollRectToVisible:frame];
}

- (void)_layoutSubviews:(BOOL)animate
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
