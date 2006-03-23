/*
 * $Id: XMOnScreenControllerWindow.h,v 1.4 2006/03/23 10:04:49 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Ivan Guajana. All rights reserved.
 */

#ifndef __XM_ON_SCREEN_CONTROLLER_WINDOW_H__
#define __XM_ON_SCREEN_CONTROLLER_WINDOW_H__

#import <Cocoa/Cocoa.h>

#import "XMOSDVideoView.h"

@class XMOnScreenControllerView;

@interface XMOnScreenControllerWindow : NSWindow {
	@private
	NSTimer* timer;
	
	XMOnScreenControllerView *controllerView;

}

- (id)initWithControllerView:(XMOnScreenControllerView *)view contentRect:(NSRect)contentRect;

- (void) openWithEffect:(XMOpeningEffect)effect parentWindow:(NSWindow *)window;
- (void) closeWithEffect:(XMClosingEffect)effect;

@end

#endif // __XM_ON_SCREEN_CONTROLLER_WINDOW_H__
