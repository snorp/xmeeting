/*
 * $Id: XMInstantActionButton.h,v 1.5 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2006-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2008 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_INSTANT_ACTION_BUTTON_H__
#define __XM_INSTANT_ACTION_BUTTON_H__

#import <Cocoa/Cocoa.h>


@interface XMInstantActionButton : NSButton {

@private
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
