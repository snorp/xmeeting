/*
 * $Id: XMOnScreenControllerView.m,v 1.9 2008/11/03 21:34:03 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Ivan Guajana, Hannes Friederich. All rights reserved.
 */

#import "XMOnScreenControllerView.h"

NSString *XM_OSD_Separator = @"separator";

#define SmallButtonWidth 30.0
#define SmallButtonHeight 24.0
#define LargeButtonWidth 60.0
#define LargeButtonHeight 48.0
#define SmallSeparatorWidth 10.0
#define LargeSeparatorWidth 20.0

#define OSDWidthSpacing 5.0
#define OSDHeightSpacing 3.0
#define OSDBottomMargin 16.0
#define OSDRadius 10.0

@interface XMOnScreenControllerView (PrivateMethods)

// Action
- (SEL)_selectorForButton:(NSMutableDictionary*)button;
- (id)_targetForButton:(NSMutableDictionary*)button;
- (BOOL)_actionIsValidForButton:(NSMutableDictionary*)button; // YES if target and selector are non-nil

// Utilities
- (NSString*)_stringFromRect:(NSRect)rect;
- (NSRect)_rectFromString:(NSString*)string;

// Draw
- (void)_constructBezierPath:(NSBezierPath *)bezierPath forRoundedRect:(NSRect)aRect withRadius:(float)radius;
- (void)_drawControls:(NSRect)aRect;
- (void)_drawSeparatorInRect:(NSRect)aRect;
- (void)_drawButton:(NSMutableDictionary*)button;

// Buttons
- (void)_updateIsPressedInformation:(NSEvent *)theEvent;

@end

@implementation XMOnScreenControllerView

#pragma mark Class Methods

+ (float)osdHeightForSize:(XMOSDSize)size
{
  float buttonHeight;
  
  if (size == XMOSDSize_Large) {
    buttonHeight = LargeButtonHeight;
  } else {
    buttonHeight = SmallButtonHeight;
  }
  
  return buttonHeight + 2*OSDHeightSpacing + OSDBottomMargin;
}

#pragma mark -
#pragma mark Init & Deallocation Methods

- (id) initWithFrame:(NSRect)frameRect andSize:(XMOSDSize)size
{
  if ([super initWithFrame:frameRect] == nil) {
    [self release];
    return nil;
  }
  
  backgroundColor = [[NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0.8] retain];

  buttons = [[NSMutableArray alloc] initWithCapacity:4];
  
  [self setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
  [self setOSDSize:size];
  
  currentPressedButtonIndex = -1;
  numberOfButtons = -1;
  numberOfSeparators = -1;
  
  osdHeightOffset = 0;

  return self;
}

- (void) dealloc
{
  [backgroundColor release];
  [buttons release];
  
  [super dealloc];
}

#pragma mark -
#pragma mark Button Management

- (NSMutableArray *)buttons
{
  return buttons;
}

- (void)addButtons:(NSArray*)newButtons
{
  [buttons addObjectsFromArray:newButtons];
  numberOfSeparators = -1;
  numberOfButtons = -1;
}

- (void)addButton:(NSMutableDictionary*)newBtn
{
  [buttons addObject:newBtn];
  
  if ([newBtn isEqualTo:XM_OSD_Separator]) {
    numberOfSeparators++;
  } else {
    numberOfButtons++;
  }
}

- (void)insertButton:(NSMutableDictionary*)btn atIndex:(int)idx
{
  [buttons insertObject:btn atIndex:idx];
  
  if ([btn isEqualTo:XM_OSD_Separator]) {
    numberOfSeparators++;
  } else {
    numberOfButtons++;
  }
}  

- (void)removeButton:(NSMutableDictionary*)btn
{
  if ([btn isEqualTo:XM_OSD_Separator]) {
    numberOfSeparators--;
  } else {
    numberOfButtons--;
  }
  
  // This is actually bogus in case of XM_OSD_Separator
  // since always the first separator is removed
  [buttons removeObject:btn];
}

- (void)removeButtonAtIndex:(int)idx
{
  NSMutableDictionary* victim = [buttons objectAtIndex:idx];
  
  if ([victim isEqualTo:XM_OSD_Separator]) {
    numberOfSeparators--;
  } else {
    numberOfButtons--;
  }
  
  [buttons removeObjectAtIndex:idx];
}

- (NSMutableDictionary*)createButtonNamed:(NSString*)name tooltips:(NSArray*)tooltips 
                                    icons:(NSArray*)icons pressedIcons:(NSArray*)pressedIcons 
                                selectors:(NSArray*)selectors targets:(NSArray*)targets 
                        currentStateIndex:(int)currentIdx
{
  NSNumber *currentStateIndex = [[NSNumber alloc] initWithInt:currentIdx];
  NSString *rectString = [self _stringFromRect:NSZeroRect];
  NSNumber *isPressed = [[NSNumber alloc] initWithBool:NO];
  
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:name,  @"Name",
                                                                                tooltips,  @"Tooltips",
                                                                                icons, @"Icons",
                                                                                pressedIcons, @"PressedIcons",
                                                                                selectors, @"Selectors",
                                                                                targets, @"Targets",
                                                                                currentStateIndex, @"CurrentStateIndex",
                                                                                rectString, @"Rect",
                                                                                isPressed, @"IsPressed",
                                                                                nil];
  [currentStateIndex release];
  [isPressed release];
  
  return dict;
}

#pragma mark -
#pragma mark Get&Set

- (NSRect)osdRect
{
  return bkgrRect;
}

- (XMOSDSize)osdSize
{
  return osdSize;
}

- (void)setOSDSize:(XMOSDSize)s
{
  osdSize = s;
  
  if (osdSize == XMOSDSize_Small) {
    buttonWidth = SmallButtonWidth;
    buttonHeight = SmallButtonHeight;
    separatorWidth = SmallSeparatorWidth;
    separatorHeight = SmallButtonHeight;
  } else if (osdSize == XMOSDSize_Large) {
    buttonWidth = LargeButtonWidth;
    buttonHeight = LargeButtonHeight;
    separatorWidth = LargeSeparatorWidth;
    separatorHeight = LargeButtonHeight;
  }
  
  [self setNeedsDisplay:YES];
}

- (int)osdHeightOffset
{
  return osdHeightOffset;
}

- (void)setOSDHeightOffset:(int)offset
{
  osdHeightOffset = offset;
}

#pragma mark -
#pragma mark Draw

- (void)drawRect:(NSRect)aRect
{
  [NSBezierPath setDefaultLineWidth:2];
  
  [backgroundColor set];
  
  if (numberOfButtons == -1 || numberOfSeparators == -1) { //if cached values are not valid
    numberOfButtons = numberOfSeparators = 0;
    
    for (unsigned i = 0;  i < [buttons count]; i++) {
      if ([[buttons objectAtIndex:i] isEqualTo:XM_OSD_Separator]) {
        numberOfSeparators++;
      } else {
        numberOfButtons++;
      }
    }
  }
  
  float osdWidth = numberOfButtons * buttonWidth + numberOfSeparators * separatorWidth + 2*OSDWidthSpacing;
  float osdHeight = buttonHeight + 2*OSDHeightSpacing;;
  
  float left = NSMidX(aRect) - (osdWidth / 2.0);
  float bottom = NSMinY(aRect) + OSDBottomMargin + osdHeightOffset;
  
  bkgrRect = NSMakeRect(left, bottom, osdWidth, osdHeight);
  
  NSBezierPath *bezierPath = [[NSBezierPath alloc] init];
  
  [self _constructBezierPath:bezierPath forRoundedRect:bkgrRect withRadius:OSDRadius];
  
  [bezierPath fill];
  
  [[NSColor whiteColor] set];
  
  [bezierPath stroke];
  
  [bezierPath release];
  
  [self _drawControls:bkgrRect];
}

- (void)_constructBezierPath:(NSBezierPath *)path forRoundedRect:(NSRect)aRect withRadius:(float)radius
{
  [path moveToPoint:NSMakePoint(NSMidX(aRect),NSMaxY(aRect))];
  [path appendBezierPathWithArcFromPoint:NSMakePoint(NSMaxX(aRect),NSMaxY(aRect)) toPoint:NSMakePoint(NSMaxX(aRect),NSMidY(aRect)) radius:radius];
  [path appendBezierPathWithArcFromPoint:NSMakePoint(NSMaxX(aRect),NSMinY(aRect)) toPoint:NSMakePoint(NSMidX(aRect),NSMinY(aRect)) radius:radius];
  [path appendBezierPathWithArcFromPoint:NSMakePoint(NSMinX(aRect),NSMinY(aRect)) toPoint:NSMakePoint(NSMinX(aRect),NSMidY(aRect)) radius:radius];
  [path appendBezierPathWithArcFromPoint:NSMakePoint(NSMinX(aRect),NSMaxY(aRect)) toPoint:NSMakePoint(NSMidX(aRect),NSMaxY(aRect)) radius:radius];
  [path closePath];
}

- (void)_drawControls:(NSRect)aRect
{
  float left_border = NSMinX(aRect) + OSDWidthSpacing;
  float bottom_border;
  if (osdSize == XMOSDSize_Small) {
    bottom_border = NSMaxY(aRect) - SmallButtonHeight - OSDHeightSpacing;
  } else if (osdSize == XMOSDSize_Large) {
    bottom_border = NSMaxY(aRect) - LargeButtonHeight - OSDHeightSpacing;
  }
  
  [self removeAllToolTips];
  
  for (unsigned i = 0; i < [buttons count]; i++) {
    NSMutableDictionary* button = [buttons objectAtIndex:i];
    
    if ([button isEqualTo:XM_OSD_Separator]) {
      NSRect separatorRect = NSMakeRect(left_border, bottom_border, separatorWidth, separatorHeight);
      [self _drawSeparatorInRect:separatorRect];
      left_border += separatorWidth;
    } else {
      NSRect buttonRect = NSMakeRect(left_border, bottom_border, buttonWidth, buttonHeight);
      [button setObject:[self _stringFromRect:buttonRect] forKey:@"Rect"];
      
      // implicitely assuming that button don't gets released while tool tips are shown!
      [self addToolTipRect:buttonRect owner:self userData:button];

      [self _drawButton:button];
      
      left_border += buttonWidth;
    }
  }
}

- (void)_drawSeparatorInRect:(NSRect)aRect
{  
  [[NSColor lightGrayColor] set];
  
  NSBezierPath* path = [[NSBezierPath alloc] init];
  
  [path moveToPoint:NSMakePoint(NSMidX(aRect), NSMaxY(aRect) - 2)];
  [path lineToPoint:NSMakePoint(NSMidX(aRect), NSMinY(aRect) + 2)];
  [path setLineWidth:0.5];
  [path stroke];
  
  [path release];
}

- (void)_drawButton:(NSMutableDictionary*)button
{
  int currentStateIdx = [[button objectForKey:@"CurrentStateIndex"] intValue];
  BOOL isPressed = [[button objectForKey:@"IsPressed"] boolValue];
  NSRect targetRect = [self _rectFromString:[button objectForKey:@"Rect"]];
  NSImage *icon;
  
  if (isPressed) {
    icon = [[button objectForKey:@"PressedIcons"] objectAtIndex:currentStateIdx];
  } else {
    icon = [[button objectForKey:@"Icons"] objectAtIndex:currentStateIdx];
  }
  
  NSSize imageSize = [icon size];
  [icon drawInRect:targetRect fromRect:NSMakeRect(0,0,imageSize.width,imageSize.height) operation:NSCompositeSourceAtop fraction:1.0];
}

- (NSString *)view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void *)userData
{
  // BOGUS: Does not work in fullscreen mode!
  NSMutableDictionary *button = (NSMutableDictionary *)userData;
  
  int currentStateIdx = [[button objectForKey:@"CurrentStateIndex"] intValue];
  
  NSString *tooltip = [[button objectForKey:@"Tooltips"] objectAtIndex:currentStateIdx];
  
  return tooltip;
}

#pragma mark -
#pragma mark Event Handling

- (void)mouseDown:(NSEvent *)theEvent
{
  currentPressedButtonIndex = -1;
  [self _updateIsPressedInformation:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
  if (currentPressedButtonIndex != -1) {
    NSMutableDictionary *pressedButton = [buttons objectAtIndex:currentPressedButtonIndex];
    
    if ([[pressedButton objectForKey:@"IsPressed"] boolValue] == NO) {
      // if the mouse moved outside the button while pressed, the button isn't considered pressed
      return;
    }
    
    [pressedButton setObject:[NSNumber numberWithBool:NO] forKey:@"IsPressed"];
    
    id target = nil;
    SEL selector = nil;
    if ([self _actionIsValidForButton:pressedButton]) {
      target = [self _targetForButton:pressedButton];
      selector = [self _selectorForButton:pressedButton];
    }
    
    int numberOfStates = [[pressedButton objectForKey:@"Icons"] count];
    if (numberOfStates > 1) { //multi-state button
      int currentState = [[pressedButton objectForKey:@"CurrentStateIndex"] intValue];
      [pressedButton setObject:[NSNumber numberWithInt: ((currentState + 1) % numberOfStates)] forKey:@"CurrentStateIndex"];
    }
    
    [target performSelector:selector];
  }
  
  [self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
  [self _updateIsPressedInformation:(NSEvent *)theEvent];
}

- (void)_updateIsPressedInformation:(NSEvent *)theEvent
{
  NSPoint mloc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
  unsigned i = 0;
  unsigned count = [buttons count];
  
  NSMutableDictionary *currentButton = nil;
  BOOL needsDisplay = NO;
  
  while (i < count) {
    currentButton = [buttons objectAtIndex:i];
    if ([currentButton isEqualTo:XM_OSD_Separator]) {
      i++;
      continue;
    }
    
    NSRect currentRect = [self _rectFromString:[currentButton objectForKey:@"Rect"]];
    
    if (NSMouseInRect(mloc, currentRect, NO) &&
      (currentPressedButtonIndex == -1 || currentPressedButtonIndex == i)) {
      NSNumber *isPressedNumber = [[NSNumber alloc] initWithBool:YES];
      [currentButton setObject:isPressedNumber forKey:@"IsPressed"];
      [isPressedNumber release];
      currentPressedButtonIndex = i;
      needsDisplay = YES;
    } else if (currentPressedButtonIndex == i) {
      NSNumber *isPressedNumber = [[NSNumber alloc] initWithBool:NO];
      [currentButton setObject:isPressedNumber forKey:@"IsPressed"];
      [isPressedNumber release];
      needsDisplay = YES;
    }
    i++;
  }
  
  if (needsDisplay == YES) {
    [self setNeedsDisplay:YES];
  }
}

#pragma mark -
#pragma mark Private Methods

- (SEL)_selectorForButton:(NSMutableDictionary*)button
{
  NSArray *selectors = [button objectForKey:@"Selectors"];
  NSString *selector = nil;
  
  if (selectors != nil) {
    selector = [selectors objectAtIndex:[[button objectForKey:@"CurrentStateIndex"] intValue]];
  }
  
  return NSSelectorFromString(selector);
}

- (id)_targetForButton:(NSMutableDictionary*)button
{
  NSArray *targets = [button objectForKey:@"Targets"];
  id target = nil;
  if (targets != nil) {
    target = [targets objectAtIndex:[[button objectForKey:@"CurrentStateIndex"] intValue]];
  }
  
  return target;
}

- (BOOL)_actionIsValidForButton:(NSMutableDictionary*)button
{  
  if ([self _targetForButton:button] != nil && [self _selectorForButton:button] != nil) {
    return YES;
  }
  
  return NO;
}

- (NSString*)_stringFromRect:(NSRect)rect
{
  NSString *res = [NSString stringWithFormat:@"%f,%f,%f,%f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height];
  
  return res;
}

- (NSRect)_rectFromString:(NSString*)string
{
  NSRect res;
  NSArray* parts = [string componentsSeparatedByString:@","];
  res.origin.x = [[parts objectAtIndex:0] floatValue];
  res.origin.y = [[parts objectAtIndex:1] floatValue];
  res.size.width = [[parts objectAtIndex:2] floatValue];
  res.size.height = [[parts objectAtIndex:3] floatValue];
  
  return res;
}

@end
