/*
 * $Id: IGPopupView.h,v 1.3 2007/08/17 11:36:43 hfriederich Exp $
 *
 * Copyright (c) 2005 IGDocks
 * All rights reserved.
 * Copyright (c) 2005-2006 Ivan Guajana. All rights reserved.
 */

/* IGPopupView */
#ifndef __IGPopupView_H__
#define __IGPopupView_H__

#import <Cocoa/Cocoa.h>

@interface IGPopupView : NSPopUpButton {
@private
  NSBezierPath* oval, *triangle;
  NSRect area;
  NSString* title;
  NSDictionary* titleAttributes, *titleAttributesOver;
  NSTrackingRectTag trackingRect;
  float fontSize;
  
  BOOL mouseOver;
  BOOL showingTitleOfSelectedItem;
  
  IBOutlet NSMenu* theMenu;
}

- (void)setTitle:(NSString*)t;
- (void)setCustomMenu:(NSMenu*)m;


@end

#endif// __IGPopupView_H__
