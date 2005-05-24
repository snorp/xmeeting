/*
 * $Id: XMMouseOverButton.h,v 1.1 2005/05/24 15:21:02 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
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

@end

#endif // __XM_MOUSE_OVER_BUTTON_H__