/*
 * $Id: XMOnScreenControllerWindow.m,v 1.8 2006/10/07 07:47:10 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Ivan Guajana. All rights reserved.
 */

#import "XMOnScreenControllerWindow.h"
#import "XMOnScreenControllerView.h"

#define XM_STEP 0.1
#define XM_MAX_ALPHA 0.90

@interface XMOnScreenControllerWindow (privateMethods)

- (void)_changeOSDPosition:(NSTimer *)timer;
- (void)_changeAlpha:(NSTimer*)timer;

@end

@implementation XMOnScreenControllerWindow

#pragma mark Init & Deallocation Methods

- (id) initWithControllerView:(XMOnScreenControllerView *)view contentRect:(NSRect)contentRect
{	
	self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
	[self setOpaque:NO];
	[self setAlphaValue:0.0];
	[self setBackgroundColor:[NSColor clearColor]];
	[self setContentView:nil];
	
	controllerView = [view retain];
	
	return self;
}

- (void)dealloc
{
	[timer invalidate];
	[timer release];
	
	[controllerView release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Animations

- (void) openWithEffect:(XMOpeningEffect)effect parentWindow:(NSWindow *)window
{
	// do nothing if already visible
	if([self parentWindow] != nil)
	{
		[self makeKeyWindow];
		return;
	}
	
	[self setContentView:controllerView];
	
	if(effect == XMOpeningEffect_RollInFromBottomBorder)
	{
		if(timer != nil)
		{
			[timer invalidate];
			[timer release];
		}
		else
		{
			[self setAlphaValue:XM_MAX_ALPHA];

			float osdHeight = [XMOnScreenControllerView osdHeightForSize:[controllerView osdSize]];
			int heightOffset = -osdHeight;
			[controllerView setOSDHeightOffset:heightOffset];
			
			[window addChildWindow:self ordered:NSWindowAbove];
		}
		
		timer = [[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)0.02 target:self
												selector:@selector(_changeOSDPosition:)
												userInfo:[NSNumber numberWithInt:6] repeats:YES] retain];

	}
	else if(effect == XMOpeningEffect_FadeIn)
	{
		if(timer != nil)
		{
			[timer invalidate];
			[timer release];
		}
		else
		{
			[window addChildWindow:self ordered:NSWindowAbove];
			[self setAlphaValue:0.0];
		}
		
		timer = [[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)0.04 target:self 
												selector:@selector(_changeAlpha:) 
												userInfo:[NSNumber numberWithFloat:0.1] repeats:YES] retain];
	}
	else
	{
		// no effect
		[self setAlphaValue:XM_MAX_ALPHA];
		[window addChildWindow:self ordered:NSWindowAbove];
	}
}

- (void) closeWithEffect:(XMClosingEffect)effect
{
	NSWindow *parentWindow = [self parentWindow];
	
	if(parentWindow == nil)
	{
		return;
	}
	
	if(effect == XMClosingEffect_RollOutToBottomBorder)
	{
		if(timer != nil)
		{
			[timer invalidate];
			[timer release];
		}
		
		timer = [[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)0.02 target:self
												selector:@selector(_changeOSDPosition:)
												userInfo:[NSNumber numberWithInt:-6] repeats:YES] retain];
	}
	else if(effect == XMClosingEffect_FadeOut)
	{
		if(timer != nil)
		{
			[timer invalidate];
			[timer release];
		}
		
		timer = [[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)0.04 target:self
												selector:@selector(_changeAlpha:) 
												userInfo:[NSNumber numberWithFloat:-0.1] repeats:YES] retain];
	}
	else
	{
		if(timer != nil)
		{
			[timer invalidate];
			[timer release];
			timer = nil;
		}
		[self setAlphaValue:0.0];
		[parentWindow removeChildWindow:self];
		[self orderOut:self];
		
		[self setContentView:nil];
	}
}

- (NSTimeInterval)animationResizeTime:(NSRect)newFrame
{
	return 0.5;
}

#pragma mark -
#pragma mark Private Methods

- (void)_changeOSDPosition:(NSTimer *)t
{
	int heightOffset = [controllerView osdHeightOffset];
	heightOffset += [[timer userInfo] intValue];
	
	float height = -[XMOnScreenControllerView osdHeightForSize:[controllerView osdSize]];
	
	if(heightOffset >= 0)
	{
		heightOffset = 0;
		[timer invalidate];
		[timer release];
		timer = nil;
	}
	else if(heightOffset <= height)
	{
		heightOffset = height;
		[timer invalidate];
		[timer release];
		timer = nil;
	}
	
	[controllerView setOSDHeightOffset:heightOffset];
	[controllerView setNeedsDisplay:YES];
	
	if(heightOffset == height)
	{
		[[self parentWindow] removeChildWindow:self];
		[self orderOut:self];
		[self setContentView:nil];
		[controllerView setOSDHeightOffset:0];
	}
}

- (void)_changeAlpha:(NSTimer*)t
{
	float alphaValue = [self alphaValue] + [[timer userInfo] floatValue];
	
	if (alphaValue > XM_MAX_ALPHA)
	{
		alphaValue = XM_MAX_ALPHA;
		[timer invalidate];
		[timer release];
		timer = nil;
	}
	else if (alphaValue < 0.0)
	{
		alphaValue = 0.0;
		[timer invalidate];
		[timer release];
		timer = nil;
	}

	[self setAlphaValue:alphaValue];
	
	if(alphaValue == 0.0)
	{
		[[self parentWindow] removeChildWindow:self];
		[self orderOut:self];
		[self setContentView:nil];
	}
}

@end
