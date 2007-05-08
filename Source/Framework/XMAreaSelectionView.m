/*
 * $Id: XMAreaSelectionView.m,v 1.1 2007/05/08 10:49:54 hfriederich Exp $
 *
 * Copyright (c) 2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2007 Hannes Friederich. All rights reserved.
 */

#import "XMAreaSelectionView.h"

#define LINE_WIDTH 2

#define NONE 0
#define MOVING 1
#define RESIZE_LEFT 2
#define RESIZE_RIGHT 3
#define RESIZE_BOTTOM 4
#define RESIZE_TOP 5
#define RESIZE_BOTTOM_LEFT 6
#define RESIZE_BOTTOM_RIGHT 7
#define RESIZE_TOP_LEFT 8
#define RESIZE_TOP_RIGHT 9
#define SPAWN 10

#define OUTER_BOTTOM_RECT NSMakeRect(0,0,bounds.size.width,y-1)
#define OUTER_TOP_RECT NSMakeRect(0,y+height+1,bounds.size.width,bounds.size.height-y-height-1)
#define OUTER_LEFT_RECT NSMakeRect(0,y,x-1,height)
#define OUTER_RIGHT_RECT NSMakeRect(x+width+1,y,bounds.size.width-x-width-1,height)

#define LEFT_RECT(a) NSMakeRect(x-1,y+LINE_WIDTH+1+a,LINE_WIDTH+2,height-2*LINE_WIDTH-2)
#define RIGHT_RECT(a) NSMakeRect(x+width-LINE_WIDTH-1,y+LINE_WIDTH+1+a,LINE_WIDTH+2,height-2*LINE_WIDTH-2)

#define BOTTOM_RECT(a) NSMakeRect(x+LINE_WIDTH+1,y-1+a,width-2*LINE_WIDTH-2,LINE_WIDTH+2)
#define TOP_RECT(a) NSMakeRect(x+LINE_WIDTH+1,y+height-LINE_WIDTH-1+a,width-2*LINE_WIDTH-2,LINE_WIDTH+2)

#define BOTTOM_LEFT_RECT(a) NSMakeRect(x-1,y-1+a,LINE_WIDTH+2,LINE_WIDTH+2)
#define BOTTOM_RIGHT_RECT(a) NSMakeRect(x+width-LINE_WIDTH-1,y-1+a,LINE_WIDTH+2,LINE_WIDTH+2)
#define TOP_LEFT_RECT(a) NSMakeRect(x-1,y+height-LINE_WIDTH-1+a,LINE_WIDTH+2,LINE_WIDTH+2)
#define TOP_RIGHT_RECT(a) NSMakeRect(x+width-LINE_WIDTH-1,y+height-LINE_WIDTH-1+a,LINE_WIDTH+2,LINE_WIDTH+2)

#define MOVE_RECT(a) NSMakeRect(x+LINE_WIDTH+1,y+LINE_WIDTH+1+a,width-2*LINE_WIDTH-2,height-2*LINE_WIDTH-2)

@interface XMAreaSelectionView (PrivateMethods)

- (NSPoint)_getLocation:(NSEvent *)theEvent;

@end

@implementation XMAreaSelectionView

#pragma mark Init & Deallocation Methods

- (id)initWithFrame:(NSRect)frame 
{
    self = [super initWithFrame:frame];
    if (self) {
        x = 0;
        y = 0;
        width = frame.size.width;
        height = frame.size.height;
        
        status = NONE;
        startRect = NSMakeRect(x, y, width, height);
        startMousePoint = NSMakePoint(0, 0);
    }
    return self;
}

#pragma mark -
#pragma mark Overriding NSView methods

- (void)drawRect:(NSRect)rect 
{
    [self drawBackground:rect doesChangeSelection:(status != NONE)];
    
    [[NSColor redColor] set];
    
    NSFrameRectWithWidth(NSMakeRect(x, y, width, height), LINE_WIDTH);
}

- (void)resetCursorRects
{
    NSRect bounds = [self bounds];
    NSCursor * crosshair = [NSCursor crosshairCursor];
    NSCursor * leftRight = [NSCursor resizeLeftRightCursor];
    NSCursor * upDown = [NSCursor resizeUpDownCursor];
    
    [self addCursorRect:OUTER_BOTTOM_RECT cursor:crosshair];
    [self addCursorRect:OUTER_TOP_RECT cursor:crosshair];
    [self addCursorRect:OUTER_LEFT_RECT cursor:crosshair];
    [self addCursorRect:OUTER_RIGHT_RECT cursor:crosshair];
    
    [self addCursorRect:LEFT_RECT(0) cursor:leftRight];
    [self addCursorRect:RIGHT_RECT(0) cursor:leftRight];
    
    [self addCursorRect:BOTTOM_RECT(0) cursor:upDown];
    [self addCursorRect:TOP_RECT(0) cursor:upDown];
    
    [self addCursorRect:MOVE_RECT(0) cursor:[NSCursor openHandCursor]];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint location = [self _getLocation:theEvent];
    
    startRect = NSMakeRect(x, y, width, height);
    startMousePoint = location;
    
    if (NSPointInRect(location, MOVE_RECT(1))) {
        status = MOVING;
        [[NSCursor closedHandCursor] set];
    }
    else if (NSPointInRect(location, LEFT_RECT(1))) {
        status = RESIZE_LEFT;
    }
    else if (NSPointInRect(location, RIGHT_RECT(1))) {
        status = RESIZE_RIGHT;
    }
    else if (NSPointInRect(location, BOTTOM_RECT(1))) {
        status = RESIZE_BOTTOM;
    }
    else if (NSPointInRect(location, TOP_RECT(1))) {
        status = RESIZE_TOP;
    }
    else if (NSPointInRect(location, BOTTOM_LEFT_RECT(1))) {
        status = RESIZE_BOTTOM_LEFT;
    }
    else if (NSPointInRect(location, BOTTOM_RIGHT_RECT(1))) {
        status = RESIZE_BOTTOM_RIGHT;
    }
    else if (NSPointInRect(location, TOP_LEFT_RECT(1))) {
        status = RESIZE_TOP_LEFT;
    }
    else if (NSPointInRect(location, TOP_RIGHT_RECT(1))) {
        status = RESIZE_TOP_RIGHT;
    }
    else
    {
        status = SPAWN;
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    status = NONE;
    [[self window] invalidateCursorRectsForView:self];
    [self selectedAreaUpdated];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint location = [self _getLocation:theEvent];
    NSRect bounds = [self bounds];
    
    if (status == MOVING)
    {
        int deltaX = (int)location.x - (int)startMousePoint.x;
        int deltaY = (int)location.y - (int)startMousePoint.y;
        int maxX = bounds.size.width - width;
        int maxY = bounds.size.height - height;
        x = (int)startRect.origin.x + deltaX;
        y = (int)startRect.origin.y + deltaY;
        if (x < 0) {
            x = 0;
        }
        if (y < 0) {
            y = 0;
        }
        if (x > maxX) {
            x = maxX;
        }
        if (y > maxY) {
            y = maxY;
        }
    }
    else if (status == RESIZE_LEFT)
    {
        int deltaX = (int)location.x - (int)startMousePoint.x;
        int maxX = (int)startRect.origin.x + (int)startRect.size.width;
        x = (int)startRect.origin.x + deltaX;
        if (x < 0) {
            x = 0;
        }
        if (x > maxX-4*LINE_WIDTH) {
            x = maxX-4*LINE_WIDTH;
        }
        width = maxX - x;
    }
    else if (status == RESIZE_RIGHT)
    {
        int deltaX = (int)location.x - (int)startMousePoint.x;
        int maxWidth = (int)bounds.size.width - x;
        width = (int)startRect.size.width + deltaX;
        if (width < 4*LINE_WIDTH) {
            width = 4*LINE_WIDTH;
        }
        if (width > maxWidth) {
            width = maxWidth;
        }
    }
    else if (status == RESIZE_BOTTOM)
    {
        int deltaY = (int)location.y - (int)startMousePoint.y;
        int maxY = (int)startRect.origin.y + (int)startRect.size.height;
        y = (int)startRect.origin.y + deltaY;
        if (y < 0) {
            y = 0;
        }
        if (y > maxY-4*LINE_WIDTH) {
            y = maxY-4*LINE_WIDTH;
        }
        height = maxY - y;
    }
    else if (status == RESIZE_TOP)
    {
        int deltaY = (int)location.y - (int)startMousePoint.y;
        int maxHeight = (int)bounds.size.height - y;
        height = (int)startRect.size.height + deltaY;
        if (height < 4*LINE_WIDTH) {
            height = 4*LINE_WIDTH;
        }
        if (height > maxHeight) {
            height = maxHeight;
        }
    }
    else if (status == RESIZE_BOTTOM_LEFT)
    {
        int deltaX = (int)location.x - (int)startMousePoint.x;
        int deltaY = (int)location.y - (int)startMousePoint.y;
        int maxX = (int)startRect.origin.x + (int)startRect.size.width;
        int maxY = (int)startRect.origin.y + (int)startRect.size.height;
        x = (int)startRect.origin.x + deltaX;
        y = (int)startRect.origin.y + deltaY;
        if (x < 0) {
            x = 0;
        }
        if (x > maxX-4*LINE_WIDTH) {
            x = maxX-4*LINE_WIDTH;
        }
        if (y < 0) {
            y = 0;
        }
        if (y > maxY-4*LINE_WIDTH) {
            y = maxY-4*LINE_WIDTH;
        }
        height = maxY - y;
        width = maxX - x;
    }
    else if (status == RESIZE_BOTTOM_RIGHT)
    {
        int deltaX = (int)location.x - (int)startMousePoint.x;
        int deltaY = (int)location.y - (int)startMousePoint.y;
        int maxWidth = (int)bounds.size.width - x;
        int maxY = (int)startRect.origin.y + (int)startRect.size.height;
        width = (int)startRect.size.width + deltaX;
        y = (int)startRect.origin.y + deltaY;
        if (width < 4*LINE_WIDTH) {
            width = 4*LINE_WIDTH;
        }
        if (width > maxWidth) {
            width = maxWidth;
        }
        if (y < 0) {
            y = 0;
        }
        if (y > maxY-4*LINE_WIDTH) {
            y = maxY-4*LINE_WIDTH;
        }
        height = maxY - y;
    }
    else if (status == RESIZE_TOP_LEFT)
    {      
        int deltaX = (int)location.x - (int)startMousePoint.x;
        int deltaY = (int)location.y - (int)startMousePoint.y;
        int maxX = (int)startRect.origin.x + (int)startRect.size.width;
        int maxHeight = (int)bounds.size.height - y;
        x = (int)startRect.origin.x + deltaX;
        height = (int)startRect.size.height + deltaY;
        if (x < 0) {
            x = 0;
        }
        if (x > maxX-4*LINE_WIDTH) {
            x = maxX-4*LINE_WIDTH;
        }
        if (height < 4*LINE_WIDTH) {
            height = 4*LINE_WIDTH;
        }
        if (height > maxHeight) {
            height = maxHeight;
        }
        width = maxX - x;
    }
    else if (status == RESIZE_TOP_RIGHT)
    {
        int deltaX = (int)location.x - (int)startMousePoint.x;
        int deltaY = (int)location.y - (int)startMousePoint.y;
        int maxWidth = (int)bounds.size.width - x;
        int maxHeight = (int)bounds.size.height - y;
        width = (int)startRect.size.width + deltaX;
        height = (int)startRect.size.height + deltaY;
        if (width < 4*LINE_WIDTH) {
            width = 4*LINE_WIDTH;
        }
        if (width > maxWidth) {
            width = maxWidth;
        }
        if (height < 4*LINE_WIDTH) {
            height = 4*LINE_WIDTH;
        }
        if (height > maxHeight) {
            height = maxHeight;
        }
    }
    else if (status == SPAWN)
    {
        x = MIN(location.x, startMousePoint.x);
        y = MIN(location.y, startMousePoint.y);
        width = ABS(location.x - startMousePoint.x);
        height = ABS(location.y - startMousePoint.y);
        
        if (x < 0) {
            width += x;
            x = 0;
        }
        if (x > bounds.size.width-4*LINE_WIDTH) {
            x = bounds.size.width-4*LINE_WIDTH;
        }
        if (y < 0) {
            height += y;
            y = 0;
        }
        if (y > bounds.size.height-4*LINE_WIDTH) {
            y = bounds.size.height-4*LINE_WIDTH;
        }
        
        int maxWidth = bounds.size.width - x;
        int maxHeight = bounds.size.height - y;
        
        if (width < 4*LINE_WIDTH) {
            width = 4*LINE_WIDTH;
        }
        if (width > maxWidth) {
            width = maxWidth;
        }
        if (height < 4*LINE_WIDTH) {
            height = 4*LINE_WIDTH;
        }
        if (height > maxHeight) {
            height = maxHeight;
        }
    }
    
    [self display];
}

#pragma mark -
#pragma mark Public Methods

- (NSRect)selectedArea
{
    NSRect bounds = [self bounds];
    
    double normX = x / bounds.size.width;
    double normY = y / bounds.size.height;
    double normWidth = width / bounds.size.width;
    double normHeight = height / bounds.size.height;
    
    return NSMakeRect(normX, normY, normWidth, normHeight);
}

- (void)setSelectedArea:(NSRect)rect
{
    NSRect bounds = [self bounds];
    
    x = rect.origin.x * bounds.size.width;
    y = rect.origin.y * bounds.size.height;
    width = rect.size.width * bounds.size.width;
    height = rect.size.height * bounds.size.height;
    
    [[self window] invalidateCursorRectsForView:self];
    [self setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark Methods for subclasses

- (void)drawBackground:(NSRect)rect doesChangeSelection:(BOOL)doesChangeSelection
{
    NSRectFill(rect);
}

- (void)selectedAreaUpdated
{
}

#pragma mark -
#pragma mark Private Methods

- (NSPoint)_getLocation:(NSEvent *)theEvent
{
    NSPoint location = [theEvent locationInWindow];
    location = [self convertPoint:location fromView:nil];
    return location;
}

@end
