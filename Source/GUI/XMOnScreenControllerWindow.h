/*
 * $Id: XMOnScreenControllerWindow.h,v 1.2 2006/02/28 09:14:48 zmit Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Ivan Guajana. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

#define STEP 0.1
#define MAX_ALPHA 0.90

enum OpeningEffects {
	RollInFromBottomBorderEffect,
	FadeInEffect,
	NoEffect
};

enum ClosingEffects {
	RollOutToBottomBorderEffect,
	FadeOutEffect
};

@interface XMOnScreenControllerWindow : NSWindow {
	@private
	NSRect parentRect;
	NSTimer* timer;
	BOOL fading;

}
+ (id) controllerWindowWithContollerView:(NSView*)_view parentRect:(NSRect)pRect fullscreen:(BOOL)fullscreen;
- (void) openWithEffect:(int)_effect;
- (void) closeWithEffect:(int)_effect;
- (void) setParentRect:(NSRect)p;


@end
