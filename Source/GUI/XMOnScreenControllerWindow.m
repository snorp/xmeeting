/*
 * $Id: XMOnScreenControllerWindow.m,v 1.2 2006/02/28 09:14:48 zmit Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Ivan Guajana. All rights reserved.
 */

#import "XMOnScreenControllerWindow.h"
#import "XMOnScreenControllerView.h"

@interface XMOnScreenControllerWindow (privateMethods)
- (void)_changeAlpha:(NSTimer*)timer;
- (void)_displayTimeout:(NSTimer*)timer;
- (void)_windowWillMove:(NSNotification*)notif;

@end

@implementation XMOnScreenControllerWindow
+ (id) controllerWindowWithContollerView:(NSView*)_view parentRect:(NSRect)pRect fullscreen:(BOOL)fullscreen
{
	XMOnScreenControllerWindow* superWindow;
	if ((superWindow = [[super alloc] initWithContentRect:pRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES]) == nil) {
		[self release];
		return nil;
	}
	[superWindow setParentRect:pRect];
	[superWindow setHidesOnDeactivate:YES];
	[superWindow setOpaque:NO];
	[superWindow setAlphaValue:0.0];
	[superWindow setBackgroundColor:[NSColor clearColor]];
	[superWindow setContentView:_view];
	[superWindow setFrame:pRect display:YES animate:NO];
	
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:superWindow selector:@selector(_windowWillMove:) name:NSWindowWillMoveNotification object:nil];

	if (fullscreen){
		[superWindow setLevel:NSScreenSaverWindowLevel+1];
	}

	return [superWindow autorelease];
}


- (void)dealloc{

	[super dealloc];
}


- (void)setParentRect:(NSRect)rect{
	parentRect = rect;
}

#pragma mark -

- (void) openWithEffect:(int)_effect
{
	NSRect screenRect = parentRect;
	//NSLog(@"[openWithEffect]Parent view frame at %f, %f; size %f x %f", parentRect.origin.x, parentRect.origin.y, parentRect.size.width, parentRect.size.height);

	NSRect inRect;
	
	switch(_effect) {
		case RollInFromBottomBorderEffect:
			[self setAlphaValue:MAX_ALPHA];
			inRect = NSMakeRect(NSMinX(screenRect),NSMinY(screenRect)-screenRect.size.height,screenRect.size.width,screenRect.size.height);
			[self setFrame:inRect display:YES];
			[self makeKeyAndOrderFront:self];
			[self setFrame:screenRect display:YES animate:YES];

			break;
		case FadeInEffect:
			
			if (fading){
				[timer invalidate];
				[timer release];
			}
			
			fading = YES;
			[self makeKeyAndOrderFront:self];
			[self setFrame:screenRect display:YES animate:NO];
			timer = [[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)0.04 target:self selector:@selector(_changeAlpha:) userInfo:[NSNumber numberWithFloat:0.1] repeats:YES] retain];
			break;
		default:
			break;
	}
	
}


- (void) closeWithEffect:(int)_effect
{
	NSRect screenRect = parentRect;
	NSRect outRect;
	
	switch(_effect) {
		case RollInFromBottomBorderEffect:
			outRect = NSMakeRect(NSMinX(screenRect),NSMinY(screenRect)-screenRect.size.height,screenRect.size.width,screenRect.size.height);
			
			[self setFrame:screenRect display:YES];
			[self setFrame:outRect display:YES animate:YES];
			[self orderOut:self];
			break;
		case FadeOutEffect:
			outRect = NSMakeRect(NSMinX(screenRect),NSMinY(screenRect)-screenRect.size.height,screenRect.size.width,screenRect.size.height);
			
			if (fading){
				[timer invalidate];
				[timer release];
			}
			
			fading = YES;
			timer = [[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)0.04 target:self selector:@selector(_changeAlpha:) userInfo:[NSNumber numberWithFloat:-0.1] repeats:YES] retain];
			[self orderOut:self];
			break;
		case NoEffect:
			[self setAlphaValue:0.0];
			[self orderOut:self];
			break;
		default:
			break;
	}
}

- (NSTimeInterval)animationResizeTime:(NSRect)newFrame
{
	return 1.5;
}


#pragma mark -
#pragma mark Private Methods
- (void)_windowWillMove:(NSNotification*)notif{
	[self closeWithEffect:NoEffect];
}


- (void)_changeAlpha:(NSTimer*)t{
	if ([self alphaValue] > MAX_ALPHA){
		[self setAlphaValue:MAX_ALPHA];
		[t invalidate];
		[t release];
		fading = NO;
	}
	else if ([self alphaValue] < 0.0){
		[self setAlphaValue:0.0];
		[t invalidate];
		[t release];
		fading = NO;
	}
	else{
		[self setAlphaValue:[self alphaValue] + [[t userInfo] floatValue]];
	}
	
}

@end
