/*
 * $Id: IGPopupView.h,v 1.2 2006/03/14 23:06:00 hfriederich Exp $
 *
 * Copyright (c) 2005 IGDocks
 * All rights reserved.
 * Copyright (c) 2005-2006 Ivan Guajana. All rights reserved.
 */

/* IGPopupView */
#ifndef __IGPopupView_H__
#define __IGPopupView_H__

#import <Cocoa/Cocoa.h>

@interface IGPopupView : NSPopUpButton
{
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
