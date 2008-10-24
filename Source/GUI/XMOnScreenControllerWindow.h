/*
 * $Id: XMOnScreenControllerWindow.h,v 1.6 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Ivan Guajana, Hannes Friederich. All rights reserved.
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
