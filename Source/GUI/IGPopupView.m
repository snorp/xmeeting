/*
 * $Id: IGPopupView.m,v 1.5 2006/03/14 23:06:00 hfriederich Exp $
 *
 * Copyright (c) 2005 IGDocks
 * All rights reserved.
 * Copyright (c) 2005-2006 Ivan Guajana. All rights reserved.
 */
#import "IGPopupView.h"


@interface IGPopupView (PrivateMethods)
- (void)_resetTrackingRect;
- (void)_frameDidChange;
@end

@implementation IGPopupView

//suggested height: 24px

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect]) != nil) {
            oval=[[NSBezierPath alloc] init];
            triangle=[[NSBezierPath alloc] init];
            title=@"";
            
            //initialize  variables
            mouseOver=FALSE;
            
            //define attributes for the title
            id attributes[2], attributesOver[2];;
            id keys[2];
            fontSize=frameRect.size.height/2.0;
            attributes[0]=[NSFont titleBarFontOfSize:fontSize];
            attributes[1]=[NSColor colorWithCalibratedRed:0.95 green:0.95 blue:0.95 alpha:1.0];
            attributesOver[0]=[NSFont titleBarFontOfSize:fontSize];
            attributesOver[1]= [NSColor colorWithCalibratedRed:0.2 green:0.2 blue:0.2 alpha:1.0];
            keys[0]=NSFontAttributeName;
            keys[1]=NSForegroundColorAttributeName;
            titleAttributes = [[NSDictionary alloc] initWithObjects:attributes forKeys:keys count:2]; 
            titleAttributesOver=[[NSDictionary alloc] initWithObjects:attributesOver forKeys:keys count:2];
            
            //create paths
            //...oval
            [oval appendBezierPathWithArcWithCenter:NSMakePoint(frameRect.size.height/2.0+2.0,frameRect.size.height/2.0) radius:frameRect.size.height/2.0-2 startAngle:270.0 endAngle:90.0 clockwise:YES];
            [oval appendBezierPathWithArcWithCenter:NSMakePoint(frameRect.size.width-frameRect.size.height/2.0,frameRect.size.height/2.0) radius:frameRect.size.height/2.0-2 startAngle:90.0 endAngle:270.0 clockwise:YES];
            [oval lineToPoint:NSMakePoint(frameRect.size.height/2.0,2.0)];
            
            //...triangle
            [triangle moveToPoint:NSMakePoint(frameRect.size.width-frameRect.size.height/2.0-2-fontSize/2.0, frameRect.size.height/2.0+fontSize/4.0)];
            
            [triangle lineToPoint:NSMakePoint(frameRect.size.width-frameRect.size.height/2.0-2-fontSize/2.0+fontSize/2.5, frameRect.size.height/2.0-fontSize/4.0)];
            [triangle lineToPoint:NSMakePoint(frameRect.size.width-frameRect.size.height/2.0-2-fontSize/2.0-fontSize/2.5, frameRect.size.height/2.0-fontSize/4.0)];
            [triangle lineToPoint:NSMakePoint(frameRect.size.width-frameRect.size.height/2.0-2-fontSize/2.0, frameRect.size.height/2.0+fontSize/4.0)];

			theMenu = [[NSMenu alloc] init];
			[self setMenu:theMenu];
       	}
	return self;
}

-(void)awakeFromNib{
	showingTitleOfSelectedItem = YES;

    [self setPullsDown:NO];
	
}

- (void)drawRect:(NSRect)rect
{
    //draw the silhouette
	if (mouseOver){
		[self isEnabled] ? [[NSColor colorWithCalibratedRed:0.4 green:0.4 blue:0.4 alpha:1.0] set] : [[NSColor colorWithCalibratedRed:0.55 green:0.55 blue:0.55 alpha:1.0] set];
	}
	else
	{
		[self isEnabled] ? [[NSColor colorWithCalibratedRed:0.55 green:0.55 blue:0.55 alpha:1.0] set]: [[NSColor colorWithCalibratedRed:0.55 green:0.55 blue:0.55 alpha:1.0] set];
	}
    [oval setLineWidth:2.0];
    [oval stroke];
    
   	if (mouseOver){
		[self isEnabled] ? [[NSColor colorWithCalibratedRed:0.45 green:0.45 blue:0.45 alpha:1.0]  set] : [[NSColor colorWithCalibratedRed:0.65 green:0.65 blue:0.65 alpha:1.0] set];
	}
	else
	{
		[self isEnabled] ? [[NSColor colorWithCalibratedRed:0.65 green:0.65 blue:0.65 alpha:1.0] set]: [[NSColor colorWithCalibratedRed:0.65 green:0.65 blue:0.65 alpha:1.0] set];
	}
	[oval fill];
    
    //draw the disclosure triangle
	if (mouseOver){
		[self isEnabled] ? [[NSColor colorWithCalibratedRed:0.9 green:0.9 blue:0.9 alpha:1.0] set] : [[NSColor grayColor] set];
	}
	else
	{
		[self isEnabled] ? [[NSColor grayColor] set]: [[NSColor grayColor] set];
	}
	[triangle fill];
			
    [self synchronizeTitleAndSelectedItem];
	//draw the text
    [title drawAtPoint:NSMakePoint(rect.size.height/2.0+5.0,rect.size.height/2.0-fontSize/2.0-2) withAttributes:((!mouseOver && [self isEnabled])?titleAttributesOver:titleAttributes)];
    
}

#pragma mark -
#pragma mark Item Selection

- (void)synchronizeTitleAndSelectedItem{
	//NSLog(@"synch popup");
	if (showingTitleOfSelectedItem) {
		[self setTitle:[super titleOfSelectedItem]];
	}
	
}

#pragma mark -
#pragma mark Event Handling
- (void)mouseEntered:(NSEvent *)theEvent {
    mouseOver=YES;
    [self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent*)theEvent{
    mouseOver=NO;
    [self setNeedsDisplay:YES];
}

-(void)dealloc{
    [self removeTrackingRect:trackingRect];
    [titleAttributesOver release];
    [titleAttributes release];
    [oval release];
    [triangle release];
    [super dealloc];
}

#pragma mark -
#pragma mark - get/set methods -

-(void) setTitle:(NSString*)t{
	id tmp = title;
	title = [[NSString stringWithFormat:@"Location: %@", t] retain];
	[tmp release];
}

-(void) setCustomMenu:(NSMenu*)m{
    id tmp = theMenu;
	theMenu = [m retain];
	[tmp release];
}

#pragma mark -
#pragma mark Tracking rect stuff
- (void)_resetTrackingRect{
	if ( trackingRect )
    {
        [self removeTrackingRect:trackingRect];
    }
	
	NSTrackingRectTag theTrackingRect=[self addTrackingRect:[self bounds] owner:self userData:@"rectData" assumeInside:NO];
	if(theTrackingRect != 0)
	{
		trackingRect = theTrackingRect;
	}
	
}

- (void)_frameDidChange:(NSNotification *)notif{
	[self _resetTrackingRect];
}

- (void) viewDidMoveToWindow {
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	[notificationCenter removeObserver:self name:NSViewFrameDidChangeNotification object:nil];
	if([self window] != nil)
	{
		[notificationCenter  addObserver:self selector:@selector(_frameDidChange:) name:NSViewFrameDidChangeNotification object:[[self window] contentView]];
	}
	
	[self _resetTrackingRect];
}

@end
