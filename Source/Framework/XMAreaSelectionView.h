/*
 * $Id: XMAreaSelectionView.h,v 1.1 2007/05/08 10:49:54 hfriederich Exp $
 *
 * Copyright (c) 2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_AREA_SELECTION_VIEW_H__
#define __XM_AREA_SELECTION_VIEW_H__

#import <Cocoa/Cocoa.h>

@interface XMAreaSelectionView : NSView {
    int x;
    int y;
    int width;
    int height;
    
    int status;
    NSRect startRect;
    NSPoint startMousePoint;
}

/**
 * Returns a normalized rectangle. x, y, width and height lie between
 * 0.0 and 1.0
 **/
- (NSRect)selectedArea;

/**
 * Sets the selected area. Expects a normalized rect, with values
 * between 0.0 and 1.0
 **/
- (void)setSelectedArea:(NSRect)selectedArea;

/**
 * Methods for subclasses to override
 **/
- (void)drawBackground:(NSRect)rect doesChangeSelection:(BOOL)doesChangeSelection;
- (void)selectedAreaUpdated;

@end

#endif // __XM_AREA_SELECTION_VIEW_H__
