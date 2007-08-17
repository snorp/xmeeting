/*
 * $Id: XMOnScreenControllerView.h,v 1.5 2007/08/17 11:36:44 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Ivan Guajana. All rights reserved.
 */

#ifndef __XM_ON_SCREEN_CONTROLLER_VIEW_H__
#define __XM_ON_SCREEN_CONTROLLER_VIEW_H__

#import <Cocoa/Cocoa.h>

extern NSString *XM_OSD_Separator;

typedef enum XMOSDSize
{
  XMOSDSize_Small = 0,
  XMOSDSize_Large = 1	
} XMOSDSize;

@interface XMOnScreenControllerView : NSView {
	
@private
  NSColor *backgroundColor;
  
  NSRect bkgrRect;
  
  XMOSDSize osdSize;
  float buttonWidth, buttonHeight, separatorWidth, separatorHeight;
  
  int osdHeightOffset;
  
  /*Array containing the buttons to be displayed
   *Each button is stored as a dictionary with the following keys:
   *
   *Icons - NSArray of NSImage
   *PressedIcons - NSArray of NSImage
   *Selectors - NSArray of selector
   *Targets - NSArray of NSObject
   *Tooltips - NSArray of NSString
   *CurrentStateIndex - NSNumber
   *IsPressed - NSNumber wrapping BOOL
   *Rect - NSRect
   *Name - NSString
   *
   * OR
   *
   * A separator, which is a string defined by XM_OSD_Separator
   */
  
  NSMutableArray *buttons;
  int currentPressedButtonIndex;
  
  int numberOfButtons, numberOfSeparators;

}

+ (float)osdHeightForSize:(XMOSDSize)size;

- (id)initWithFrame:(NSRect)frameRect andSize:(XMOSDSize)size;

//Managing buttons
- (NSMutableArray *)buttons;
- (void)addButton:(NSMutableDictionary*)newBtn;
- (void)addButtons:(NSArray*)newButtons;
- (void)insertButton:(NSMutableDictionary*)btn atIndex:(int)idx;
- (void)removeButton:(NSMutableDictionary*)btn;
- (void)removeButtonAtIndex:(int)idx;

//Creating buttons
- (NSMutableDictionary*)createButtonNamed:(NSString*)name tooltips:(NSArray*)tooltips icons:(NSArray*)icons pressedIcons:(NSArray*)pressedIcons selectors:(NSArray*)selectors targets:(NSArray*)targets currentStateIndex:(int)currentIdx;

//Get&Set
- (NSRect)osdRect;

- (XMOSDSize)osdSize;
- (void)setOSDSize:(XMOSDSize)s;

- (int)osdHeightOffset;
- (void)setOSDHeightOffset:(int)offset;

@end

#endif // __XM_ON_SCREEN_CONTROLLER_VIEW_H__
