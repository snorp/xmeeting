/*
 * $Id: XMInstantActionButton.h,v 1.3 2006/04/23 16:18:57 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_INSTANT_ACTION_BUTTON_H__
#define __XM_INSTANT_ACTION_BUTTON_H__

#import <Cocoa/Cocoa.h>


@interface XMInstantActionButton : NSButton {
	
	BOOL isPressed;
	
	SEL becomesPressedAction;
	SEL becomesReleasedAction;	
	
	unichar keyCode;
}

- (SEL)becomesPressedAction;
- (void)setBecomesPressedAction:(SEL)selector;

- (SEL)becomesReleasedAction;
- (void)setBecomesReleasedAction:(SEL)selector;

- (unichar)keyCode;
- (void)setKeyCode:(unichar)keyCode;

@end

#endif // __XM_INSTANT_ACTION_BUTTON_H__
