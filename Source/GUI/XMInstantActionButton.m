/*
 * $Id: XMInstantActionButton.m,v 1.5 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#import "XMInstantActionButton.h"

@interface XMInstantActionButton (PrivateMethods)

- (void)_setHighlighted:(BOOL)flag;

@end

@implementation XMInstantActionButton

#pragma mark Init & Deallocation Methods

- (id)initWithFrame:(NSRect)frame
{
  self = [super initWithFrame:frame];
  
  isPressed = NO;
  
  becomesPressedAction = NULL;
  becomesReleasedAction = NULL;
  
  keyCode = 0x0000;
  
  return self;
}

#pragma mark -
#pragma mark Public Methods

- (SEL)becomesPressedAction
{
  return becomesPressedAction;
}

- (void)setBecomesPressedAction:(SEL)action
{
  becomesPressedAction = action;
}

- (SEL)becomesReleasedAction
{
  return becomesReleasedAction;
}

- (void)setBecomesReleasedAction:(SEL)action
{
  becomesReleasedAction = action;
}

- (unichar)keyCode
{
  return keyCode;
}

- (void)setKeyCode:(unichar)theKeyCode
{
  keyCode = theKeyCode;
}

#pragma mark -
#pragma mark Overriding NSButton Methods

- (void)mouseDown:(NSEvent *)theEvent
{
  [self _setHighlighted:YES];
}

- (void)mouseUp:(NSEvent *)theEvent
{
  [self _setHighlighted:NO];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
  NSPoint windowPoint = [theEvent locationInWindow];
  NSPoint localPoint = [self convertPoint:windowPoint fromView:nil];
  
  BOOL isInside = NSPointInRect(localPoint, [self bounds]);
  
  [self _setHighlighted:isInside];
}

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
  NSString *characters = [theEvent characters];
  unichar character = [characters characterAtIndex:0];
  
  if (character == keyCode) {
    NSEventType type = [theEvent type];
    
    if (type == NSKeyDown) {
      [self _setHighlighted:YES];
    } else if (type == NSKeyUp) {
      [self _setHighlighted:NO];
    }
    return YES;
  }
  return [super performKeyEquivalent:theEvent];
}

- (BOOL)acceptsFirstResponder
{
  return YES;
}

#pragma mark -
#pragma mark Private Methods

- (void)_setHighlighted:(BOOL)flag
{
  if (flag != isPressed) {
    isPressed = flag;
    [self highlight:flag];
    
    id target = [self target];
    
    if (target != nil) {
      if (flag == YES && becomesPressedAction != NULL) {
        [target performSelector:becomesPressedAction withObject:self];
      } else if (flag == NO && becomesReleasedAction != NULL) {
        [target performSelector:becomesReleasedAction withObject:self];
      }
    }
  }
}

@end