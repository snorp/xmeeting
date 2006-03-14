/*
 * $Id: XMMouseOverButton.h,v 1.3 2006/03/14 23:06:00 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_MOUSE_OVER_BUTTON_H__
#define __XM_MOUSE_OVER_BUTTON_H__

#import <Cocoa/Cocoa.h>

/**
 * XMMouseOverButtons are borderless buttons unless the mouse
 * is over the buttons bounds rectangle or the button's state
 * is NSOnState. The actual look of the button can be choosen
 * from the normal area of buttons, however, some combinations
 * don't work or simply look ugly...
 **/
@interface XMMouseOverButton : NSButton {
	NSTrackingRectTag trackingTag;
	BOOL isMouseOver;
}

/**
 * Since the tracking rect does not send a mouseExited: message when
 * the button disappears from the window, we sometimes need to
 * reset the internal state of the button
 **/
- (void)reset;

@end

#endif // __XM_MOUSE_OVER_BUTTON_H__