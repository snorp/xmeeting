//
//  XMInstantActionButton.h
//  XMeeting
//
//  Created by Hannes on 10.4.2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

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
