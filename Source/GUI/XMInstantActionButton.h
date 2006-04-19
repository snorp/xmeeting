/*
 * $Id: XMInstantActionButton.h,v 1.2 2006/04/19 11:55:55 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_INSTANT_ACTION_BUTTON_H__
#define __XM_INSTANT_ACTION_BUTTON_H__

#import <Cocoa/Cocoa.h>


@interface XMInstantActionButton : NSView {

	BOOL isPressed;
	
	id target;
	SEL becomesPressedAction;
	SEL becomesReleasedAction;
	
}

- (id)target;
- (void)setTarget:(id)target;

- (SEL)becomesPressedAction;
- (void)setBecomesPressedAction:(SEL)selector;

- (SEL)becomesReleasedAction;
- (void)setBecomesReleasedAction:(SEL)selector;

@end

#endif // __XM_INSTANT_ACTION_BUTTON_H__
