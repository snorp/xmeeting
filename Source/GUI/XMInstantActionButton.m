//
//  XMInstantActionButton.m
//  XMeeting
//
//  Created by Hannes on 10.4.2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "XMInstantActionButton.h"

@interface XMInstantActionButton (PrivateMethods)

- (void)_updateTrackingRect;

@end

@implementation XMInstantActionButton

- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	
	target = nil;
	becomesPressedAction = NULL;
	becomesReleasedAction = NULL;
	
	return self;
}

- (void)awakeFromNib
{
}

- (id)target
{
	return target;
}

- (void)setTarget:(id)theTarget
{
	target = theTarget;
}

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

- (void)drawRect:(NSRect)rect
{
	if(isPressed)
	{
		[[NSColor redColor] set];
	}
	else
	{
		[[NSColor blueColor] set];
	}
	NSRectFill(rect);
}

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

- (BOOL)isOpaque
{
	return YES;
}

- (void)_setHighlighted:(BOOL)flag
{	
	if(flag != isPressed)
	{
		isPressed = flag;
		
		if(target != nil)
		{
			if(flag == YES && becomesPressedAction != NULL)
			{
				[target performSelector:becomesPressedAction withObject:self];
			}
			else if(flag == NO && becomesReleasedAction != NULL)
			{
				[target performSelector:becomesReleasedAction withObject:self];
			}
		}
		
		[self setNeedsDisplay:YES];
	}
}

@end
