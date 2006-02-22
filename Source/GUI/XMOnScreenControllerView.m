/*
 * $Id: XMOnScreenControllerView.m,v 1.1 2006/02/22 16:12:33 zmit Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Ivan Guajana. All rights reserved.
 */

#import "XMOnScreenControllerView.h"

@interface XMOnScreenControllerView (PrivateMethods)
- (SEL)_selectorForButton:(NSMutableDictionary*)button;
- (id)_targetForButton:(NSMutableDictionary*)button;
- (BOOL)_actionIsValidForButton:(NSMutableDictionary*)button;
- (void)_performSelectorForButton:(NSMutableDictionary*)button;

//Utilities
- (NSString*)_stringFromRect:(NSRect)rect;
- (NSRect)_rectFromString:(NSString*)string;

//Draw
- (void)_strokeRoundedRect:(NSRect)aRect withRadius:(float)radius;
- (void)_fillRoundedRect:(NSRect)aRect withRadius:(float)radius;
- (void)_drawSeparatorInRect:(NSRect)aRect;
- (void)_drawButton:(NSMutableDictionary*)button;
- (void)_drawBackground:(NSRect)aRect;
- (void)_drawControls:(NSRect)aRect;

@end

@implementation XMOnScreenControllerView

- (id) initWithFrame:(NSRect)frameRect andSize:(int)size
{
	if ([super initWithFrame:frameRect] == nil) {
		[self release];
		return nil;
	}
	
	backgroundColor = [[NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0.8] retain];

	buttons = [[NSMutableArray alloc] initWithCapacity:4];
	
	[self setOSDSize:size];
	currentPressedButtonIndex = -1;
	numberOfButtons = -1;
	numberOfSeparators = -1;


	return self;
}

- (void) dealloc
{
	[buttons release];
	[backgroundColor release];
	[super dealloc];
}


#pragma mark -
#pragma mark Button Management
- (void)addButtons:(NSArray*)newButtons{
	[buttons addObjectsFromArray:newButtons];
	numberOfSeparators = -1;
	numberOfButtons = -1;
}

- (void)addButton:(NSMutableDictionary*)newBtn{
	[buttons addObject:newBtn];
	if ([newBtn isEqualTo:XM_OSD_Separator]){
		numberOfSeparators++;
	}
	else
	{
		numberOfButtons++;
	}
}

- (void)insertButton:(NSMutableDictionary*)btn atIndex:(int)idx{
	[buttons insertObject:btn atIndex:idx];
	if ([btn isEqualTo:XM_OSD_Separator]){
		numberOfSeparators++;
	}
	else
	{
		numberOfButtons++;
	}
}	

- (void)removeButton:(NSMutableDictionary*)btn{
	if ([btn isEqualTo:XM_OSD_Separator]){
		numberOfSeparators--;
	}
	else
	{
		numberOfButtons--;
	}
	[buttons removeObject:btn];

}

- (void)removeButtonAtIndex:(int)idx{
	NSMutableDictionary* victim = [buttons objectAtIndex:idx];
	if ([victim isEqualTo:XM_OSD_Separator]){
		numberOfSeparators--;
	}
	else
	{
		numberOfButtons--;
	}
	[buttons removeObjectAtIndex:idx];

}

- (NSMutableDictionary*)createButtonNamed:(NSString*)name tooltips:(NSArray*)tooltips icons:(NSArray*)icons pressedIcons:(NSArray*)pressedIcons selectors:(NSArray*)selectors targets:(NSArray*)targets currentStateIndex:(int)currentIdx{
	return [NSMutableDictionary dictionaryWithObjectsAndKeys:name, @"Name",
														tooltips, @"Tooltips",
														icons, @"Icons",
														pressedIcons, @"PressedIcons",
														selectors, @"Selectors",
														targets, @"Targets",
														[NSNumber numberWithInt:currentIdx], @"CurrentStateIndex",
														[self _stringFromRect:NSZeroRect], @"Rect",
														[NSNumber numberWithBool:NO], @"IsPressed",
														nil];
														
}

#pragma mark -
#pragma mark Draw

- (void)_fillRoundedRect:(NSRect)aRect withRadius:(float)radius
{
	NSBezierPath* path = [NSBezierPath bezierPath];
	[path moveToPoint:NSMakePoint(NSMidX(aRect),NSMaxY(aRect))];
	[path appendBezierPathWithArcFromPoint:NSMakePoint(NSMaxX(aRect),NSMaxY(aRect)) toPoint:NSMakePoint(NSMaxX(aRect),NSMidY(aRect)) radius:radius];
	[path appendBezierPathWithArcFromPoint:NSMakePoint(NSMaxX(aRect),NSMinY(aRect)) toPoint:NSMakePoint(NSMidX(aRect),NSMinY(aRect)) radius:radius];
	[path appendBezierPathWithArcFromPoint:NSMakePoint(NSMinX(aRect),NSMinY(aRect)) toPoint:NSMakePoint(NSMinX(aRect),NSMidY(aRect)) radius:radius];
	[path appendBezierPathWithArcFromPoint:NSMakePoint(NSMinX(aRect),NSMaxY(aRect)) toPoint:NSMakePoint(NSMidX(aRect),NSMaxY(aRect)) radius:radius];
	
	[path closePath];
	[path fill];
}

- (void)_strokeRoundedRect:(NSRect)aRect withRadius:(float)radius
{
	NSBezierPath* path = [NSBezierPath bezierPath];
	[path moveToPoint:NSMakePoint(NSMidX(aRect),NSMaxY(aRect))];
	[path appendBezierPathWithArcFromPoint:NSMakePoint(NSMaxX(aRect),NSMaxY(aRect)) toPoint:NSMakePoint(NSMaxX(aRect),NSMidY(aRect)) radius:radius];
	[path appendBezierPathWithArcFromPoint:NSMakePoint(NSMaxX(aRect),NSMinY(aRect)) toPoint:NSMakePoint(NSMidX(aRect),NSMinY(aRect)) radius:radius];
	[path appendBezierPathWithArcFromPoint:NSMakePoint(NSMinX(aRect),NSMinY(aRect)) toPoint:NSMakePoint(NSMinX(aRect),NSMidY(aRect)) radius:radius];
	[path appendBezierPathWithArcFromPoint:NSMakePoint(NSMinX(aRect),NSMaxY(aRect)) toPoint:NSMakePoint(NSMidX(aRect),NSMaxY(aRect)) radius:radius];
	
	[path closePath];
	[path stroke];
}


- (void)_drawSeparatorInRect:(NSRect)aRect{	
	[[NSColor lightGrayColor] set];
	NSBezierPath* path = [NSBezierPath bezierPath];
	[path moveToPoint:NSMakePoint(NSMidX(aRect), NSMaxY(aRect) - 2)];
	[path lineToPoint:NSMakePoint(NSMidX(aRect), NSMinY(aRect) + 2)];
	[path setLineWidth:0.5];
	[path stroke];
}

- (void)_drawButton:(NSMutableDictionary*)button{
	int currentStateIdx = [[button objectForKey:@"CurrentStateIndex"] intValue];
	BOOL isPressed = [[button objectForKey:@"IsPressed"] boolValue];
	NSRect targetRect = [self _rectFromString:[button objectForKey:@"Rect"]];
	NSImage *icon;
	
	if (isPressed){
		icon = [[button objectForKey:@"PressedIcons"] objectAtIndex:currentStateIdx];
	}
	else
	{
		icon = [[button objectForKey:@"Icons"] objectAtIndex:currentStateIdx];
	}
	
	[icon drawInRect:targetRect fromRect:NSMakeRect(0,0,60,48) operation:NSCompositeSourceAtop fraction:1.0];
	
}

- (void)_drawControls:(NSRect)aRect
{
	float left_border = NSMinX(aRect) + 5.0;
	float bottom_border;
	if (OSDSize == OSD_SMALL){
		bottom_border = NSMaxY(aRect) - 7.0 - 20.0;
	}
	else if (OSDSize == OSD_LARGE){
		bottom_border = NSMaxY(aRect) - 11.0 - 20.0 * (OSDSize + 1);
	}	
	
	int i;
	for (i = 0; i < [buttons count]; i++){
		NSMutableDictionary* button = [buttons objectAtIndex:i];
		
		if ([button isEqualTo:XM_OSD_Separator]){
			NSRect separatorRect = NSMakeRect(left_border, bottom_border, separatorWidth, separatorHeight);
			[self _drawSeparatorInRect:separatorRect];
			left_border += separatorWidth;
			
		}
		else
		{
			NSRect buttonRect = NSMakeRect(left_border, bottom_border, buttonWidth, buttonHeight);
			[button setObject:[self _stringFromRect:buttonRect] forKey:@"Rect"];
			[self _drawButton:button];
			left_border += buttonWidth;
		}
	}

}


- (void)_drawBackground:(NSRect)aRect
{
	[backgroundColor set];
	
	if (numberOfButtons == -1 || numberOfSeparators == -1){ //if cached values are not valid
		int i;
		numberOfButtons = numberOfSeparators = 0;
		for (i = 0;  i < [buttons count]; i++){
			if ([[buttons objectAtIndex:i] isEqualTo:XM_OSD_Separator]){
				numberOfSeparators++;
			}
			else
			{
				numberOfButtons++;
			}
		}
	}

	float osdWidth = numberOfButtons * buttonWidth + numberOfSeparators * separatorWidth + 10;
	float osdHeight = buttonHeight;
	
	float left = NSMidX(aRect) - (osdWidth / 2.0);
	float bottom = NSMinY(aRect) + 16.0;
	bkgrRect = NSMakeRect(left, bottom, osdWidth, osdHeight + 6.0);
	
	[self _fillRoundedRect:bkgrRect withRadius:10.0];
	
	[[NSColor whiteColor] set];
	[self _strokeRoundedRect:bkgrRect withRadius:10.0];
	
	
	[self _drawControls:bkgrRect];
}

- (void)drawRect:(NSRect)aRect
{	
	[NSBezierPath setDefaultLineWidth:2];
	[self _drawBackground:aRect];
}


#pragma mark -
#pragma mark Event Handling

- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint mloc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	int i = 0;
	NSMutableDictionary *currentButton = nil;
	currentPressedButtonIndex = -1;
	
	while (i < [buttons count]){
		currentButton = [buttons objectAtIndex:i];
		if ([currentButton isEqualTo:XM_OSD_Separator]) {
			i++;
			continue;
		}
		NSRect currentRect = [self _rectFromString:[currentButton objectForKey:@"Rect"]];
		
		if (NSMouseInRect(mloc, currentRect, NO)){
			[currentButton setObject:[NSNumber numberWithBool:YES] forKey:@"IsPressed"];
			currentPressedButtonIndex = i;
			break;
		}
		i++;
	}
	[self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	if (currentPressedButtonIndex != -1){
		NSMutableDictionary *pressedButton = [buttons objectAtIndex:currentPressedButtonIndex];
		[pressedButton setObject:[NSNumber numberWithBool:NO] forKey:@"IsPressed"];
		if ([self _actionIsValidForButton:pressedButton]){
			[self _performSelectorForButton:pressedButton];
		}
		int numberOfStates = [[pressedButton objectForKey:@"Icons"] count];
		if (numberOfStates > 1){ //multi-state button
			int currentState = [[pressedButton objectForKey:@"CurrentStateIndex"] intValue];
			[pressedButton setObject:[NSNumber numberWithInt: ((currentState + 1) % numberOfStates)] forKey:@"CurrentStateIndex"];
		}
		
	}
	
	[self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
}



#pragma mark -
- (void)_windowDidMove:(NSNotification *)notif{
}

#pragma mark -
#pragma mark Private Methods
- (NSString*)_stringFromRect:(NSRect)rect{
	NSString *res = [NSString stringWithFormat:@"%f,%f,%f,%f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height];
	
	return res;
}

- (NSRect)_rectFromString:(NSString*)string{
	NSRect res;
	NSArray* parts = [string componentsSeparatedByString:@","];
	res.origin.x = [[parts objectAtIndex:0] floatValue];
	res.origin.y = [[parts objectAtIndex:1] floatValue];
	res.size.width = [[parts objectAtIndex:2] floatValue];
	res.size.height = [[parts objectAtIndex:3] floatValue];
	
	return res;
}

- (SEL)_selectorForButton:(NSMutableDictionary*)button
{
	NSArray *selectors = [button objectForKey:@"Selectors"];
	NSString *selector = nil;
	
	if (selectors != nil){
		selector = [selectors objectAtIndex:[[button objectForKey:@"CurrentStateIndex"] intValue]];
	}
	
	return NSSelectorFromString(selector);
}

- (id)_targetForButton:(NSMutableDictionary*)button
{
	NSArray *targets = [button objectForKey:@"Targets"];
	id target = nil;
	if (targets != nil){
		target = [targets objectAtIndex:[[button objectForKey:@"CurrentStateIndex"] intValue]];
	}
	
	return target;
}


- (void)_performSelectorForButton:(NSMutableDictionary*)button
{
	[[self _targetForButton:button] performSelector:[self _selectorForButton:button]];
}

- (BOOL)_actionIsValidForButton:(NSMutableDictionary*)button
{	
	if ([self _targetForButton:button] != nil && [self _selectorForButton:button] != nil)
		return YES;
	
	return NO;
}


#pragma mark -
#pragma mark Get&Set
- (NSRect)osdRect{
	return bkgrRect;
}

- (void)setOSDSize:(int)s{
	OSDSize = s;
	if (OSDSize == OSD_SMALL){
		buttonWidth = SmallButtonWidth;
		buttonHeight = SmallButtonHeight;
		separatorWidth = SmallSeparatorWidth;
		separatorHeight = SmallButtonHeight;
	}
	else if (OSDSize == OSD_LARGE){
		buttonWidth = LargeButtonWidth;
		buttonHeight = LargeButtonHeight;
		separatorWidth = LargeSeparatorWidth;
		separatorHeight = LargeButtonHeight;
	}
	[self setNeedsDisplay:YES];
}

@end
