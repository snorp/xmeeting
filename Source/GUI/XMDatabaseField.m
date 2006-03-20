/*
 * $Id: XMDatabaseField.m,v 1.11 2006/03/20 18:22:40 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMDatabaseField.h"

#define DISCLOSURE_WIDTH 14
#define DISCLOSURE_RADIUS 6

#define COMPLETIONS_WINDOW 0
#define IMAGE_OPTIONS_WINDOW 1
#define PULLDOWN_OBJECTS_WINDOW 2
#define WINDOW_UPDATE_MODE 3

/**
 * A subclass of NSWindow is required in order to obtain
 * correct display of the scrollers
 **/
@interface XMDatabaseFieldWindow : NSWindow {
}

@end

/**
 * The cell handles the complete drawing of the view.
 * The superclass methods are used to draw the TextField
 * appearance and text. If needed, the image is drawn before
 * the text. On the right side, a disclosure is drawn to
 * enable a NSComboBox-like behaviour
 **/
@interface XMDatabaseFieldCell : NSTextFieldCell
{
	NSTextView *fieldEditor;
	NSImage *image;
	NSImageCell *imageCell;
	BOOL isDisclosureHighlighted;
	BOOL needsDrawing;
}

- (id)_initWithTextFieldCell:(NSTextFieldCell *)cell;

- (NSImage *)_image;
- (void)_setImage:(NSImage *)image;

- (void)_setDisclosureHighlighted:(BOOL)flag;
- (void)_setNeedsDrawing:(BOOL)flag;

@end

@interface XMDatabaseField (PrivateMethods)

- (void)_init;

- (void)_setNeedsDisplay;
- (void)_displayRepresentedObject;
- (void)_displayObjectAtIndex:(unsigned)index;
- (void)_displayWindow:(unsigned)type;
- (void)_hideWindow;
- (void)_updateDisclosureTrackingRect;
- (void)_frameDidChange:(NSNotification *)notif;

@end

@implementation XMDatabaseField

#pragma mark Init & Deallocation Methods

- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	
	[self _init];
	
	return self;
}

- (void)awakeFromNib
{
	[self _init];
}

- (void)_init
{	
	// setting up the window attibutes
	pulldownWindow = [[XMDatabaseFieldWindow alloc] initWithContentRect:NSMakeRect(0,0,0,0) 
															  styleMask:NSBorderlessWindowMask
																backing:NSBackingStoreBuffered
																  defer:YES];
	
	[pulldownWindow setHasShadow:YES];
	[pulldownWindow setReleasedWhenClosed:NO];
	[pulldownWindow setShowsResizeIndicator:NO];
	[pulldownWindow setAlphaValue:0.8];
	
	// setting up the scroll view attributes
	pulldownScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0,0,0,0)];
	[pulldownScrollView setHasHorizontalScroller:NO];
	[pulldownScrollView setHasVerticalScroller:YES];
	[pulldownScrollView setAutohidesScrollers:YES];
	[pulldownScrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
	
	// setting up the table view attributes
	NSTableColumn *pulldownTableViewColumn = [[NSTableColumn alloc] initWithIdentifier:@""];
	[pulldownTableViewColumn setEditable:NO];
	pulldownTableView = [[NSTableView alloc] initWithFrame:NSMakeRect(0,0,0,0)];
	[pulldownTableView addTableColumn:pulldownTableViewColumn];
	[pulldownTableView setDataSource:self];
	[pulldownTableView setAllowsColumnReordering:NO];
	[pulldownTableView setAllowsColumnResizing:NO];
	[pulldownTableView setAllowsMultipleSelection:NO];
	[pulldownTableView setAllowsEmptySelection:NO];
	[pulldownTableView setAllowsColumnSelection:NO];
	[pulldownTableView setIntercellSpacing:NSMakeSize(0.0, 0.0)];
	[pulldownTableView setHeaderView:nil];
	[pulldownTableView setTarget:self];
	[pulldownTableView setAction:@selector(pulldownTableViewAction:)];
	[pulldownTableView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
	[pulldownTableViewColumn release];
	
	// putting all together
	[pulldownScrollView setDocumentView:pulldownTableView];
	[pulldownWindow setContentView:pulldownScrollView];
	
	XMDatabaseFieldCell *databaseFieldCell = [[XMDatabaseFieldCell alloc] _initWithTextFieldCell:(NSTextFieldCell *)[self cell]];
	[self setCell:databaseFieldCell];
	[databaseFieldCell release];
	
	// we are our own delegate :-)
	[super setDelegate:self];
	
	// default values
	windowIsShown = NO;
	shouldFetchCompletions = YES;
	
	representedObject = nil;
	
	defaultImage = nil;
	
	disclosureTrackingRect = 0;
	
	[self setFocusRingType:NSFocusRingTypeNone];
}

- (void)dealloc
{
	[pulldownWindow release];
	[pulldownScrollView release];
	[pulldownTableView release];
	[tableData release];
	
	if(representedObject != nil)
	{
		[representedObject release];
	}
	
	[super dealloc];
}

#pragma mark Public Methods

- (id)dataSource
{
	return dataSource;
}

- (void)setDataSource:(id)aDataSource
{
	dataSource = aDataSource;
}

- (NSImage *)defaultImage;
{
	return defaultImage;
}

- (void)setDefaultImage:(NSImage *)image
{
	NSImage *old = defaultImage;
	defaultImage = [image retain];
	[old release];
	
	[[self cell] _setImage:image];
	
	[self setNeedsDisplay:YES];
}

- (id)representedObject
{
	return representedObject;
}

- (void)setRepresentedObject:(id)theObject
{
	if(representedObject != nil)
	{
		[representedObject release];
		representedObject = nil;
	}
	representedObject = [theObject retain];
	
	[self _displayRepresentedObject];
}

- (void)endEditing
{
	if(representedObject != nil)
	{
		return;
	}
	
	if(dataSource != nil)
	{
		NSString *currentString = [self stringValue];
		
		representedObject = [[dataSource databaseField:self representedObjectForCompletedString:currentString] retain];
		
		[self _displayRepresentedObject];
	}
	
	[self _hideWindow];
	[self _setNeedsDisplay];
}

#pragma mark NSControl delegate methods

- (void)controlTextDidChange:(NSControl *)control
{
	if(representedObject != nil)
	{
		[representedObject release];
		representedObject = nil;
		[[self cell] _setImage:defaultImage];
		[self _setNeedsDisplay];
	}
	
	if(dataSource != nil && shouldFetchCompletions == YES)
	{
		// getting the string to complete
		NSText *currentEditor = [self currentEditor];
		[uncompletedString release];
		uncompletedString = [[currentEditor string] copy];
		
		//release the old completions
		[tableData release];
		
		// asking the data source for new completions
		unsigned indexOfSelectedItem = 0;
		tableData = [[dataSource databaseField:self
						  completionsForString:uncompletedString
						   indexOfSelectedItem:&indexOfSelectedItem] retain];
		
		unsigned count = [tableData count];
		if(count != 0)
		{
			// we have completions, therefore we display the completions window
			pulldownMode = COMPLETIONS_WINDOW;
			[self _displayObjectAtIndex:indexOfSelectedItem];
			[self _displayWindow:COMPLETIONS_WINDOW];
			return;
		}
	}
	
	[self _hideWindow];
	shouldFetchCompletions = YES;
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{	
	BOOL returnValue = NO;
	
	if(command == @selector(moveDown:))
	{
		if(windowIsShown)
		{
			[self moveDown:self];
			returnValue = YES;
		}
		else
		{
			returnValue = NO;
		}
	}
	else if(command == @selector(moveUp:))
	{
		if(windowIsShown)
		{
			[self moveUp:self];
			returnValue = YES;
		}
		else
		{
			returnValue = NO;
		}
	}
	else if(command == @selector(deleteBackward:))
	{
		[self deleteBackward:self];
		returnValue = NO;
	}
	else if(command == @selector(insertTab:))
	{
		if(windowIsShown)
		{
			[self insertTab:self];
			returnValue = YES;
		}
		else
		{
			[self insertTab:self];
			returnValue = NO;
		}
	}
	else if(command == @selector(insertNewline:))
	{
		if(windowIsShown)
		{
			[self insertNewline:self];
			returnValue = YES;
		}
	}
	else if(command == @selector(cancelOperation:))
	{
		// we have to return YES since otherwise, a completions window
		// containing dictionary completions could be shown
		returnValue = YES;
	}
	return returnValue;
}

#pragma mark Implementing NSView / NSResponder Methods

- (BOOL)isOpaque
{
	return NO;
}

- (void)drawRect:(NSRect)rect
{
	if(rect.size.width == 1)
	{
		[[self cell] _setNeedsDrawing:NO];
	}
	else
	{
		[[self cell] _setNeedsDrawing:YES];
	}
	
	[super drawRect:rect];
}

- (void)moveDown:(id)sender
{
	int newSelectedCompletionIndex = [pulldownTableView selectedRow] + 1;
	if(newSelectedCompletionIndex == [tableData count])
	{
		return;
	}
	[self _displayObjectAtIndex:newSelectedCompletionIndex];
}

- (void)moveUp:(id)sender
{
	int newSelectedCompletionIndex = [pulldownTableView selectedRow] - 1;
	if(newSelectedCompletionIndex < 0)
	{
		return ;
	}
	[self _displayObjectAtIndex:newSelectedCompletionIndex];
}

- (void)deleteBackward:(id)sender
{
	NSText *currentEditor = [self currentEditor];
	if([[currentEditor string] length] != 0)
	{
		shouldFetchCompletions = NO;
	}
}

- (void)insertTab:(id)sender
{
	NSString *string;
	
	if(windowIsShown == YES)
	{
		unsigned selectedIndex = [pulldownTableView selectedRow];
		string = [tableData objectAtIndex:selectedIndex];
	}
	else
	{
		string = [self stringValue];
		if(dataSource != nil)
		{
			unsigned index;
			[dataSource databaseField:self completionsForString:string indexOfSelectedItem:&index];
		}
	}
	
	if(dataSource != nil)
	{
		if(pulldownMode == COMPLETIONS_WINDOW)
		{
			if(representedObject != nil)
			{
				[representedObject release];
				representedObject = nil;
			}
			NSLog(@"asking for represented object");
			representedObject = [[dataSource databaseField:self representedObjectForCompletedString:string] retain];
			NSLog(@"GOT %@", [representedObject description]);
			[self _displayRepresentedObject];
		}
		else if(pulldownMode == PULLDOWN_OBJECTS_WINDOW)
		{
			if(representedObject != nil)
			{
				[representedObject release];
				representedObject = nil;
			}
			
			representedObject = (id)[string retain];
			[self _displayRepresentedObject];
			
			if(isOverDisclosure == NO)
			{
				[[self cell] _setDisclosureHighlighted:NO];
			}
		}
		else
		{
			[dataSource databaseField:self userSelectedImageOption:string];
		}
	}
	[self _hideWindow];
	[self _setNeedsDisplay];
	
}

- (void)insertNewline:(id)sender
{
	[self insertTab:self];
}

- (void)mouseDown:(NSEvent *)event
{
	NSPoint eventLocation = [event locationInWindow];
	NSPoint mouseLocation = [self convertPoint:eventLocation fromView:nil];
	NSRect bounds = [self bounds];
	
	if(mouseLocation.x >= bounds.size.width - DISCLOSURE_WIDTH)
	{
		if(windowIsShown == YES)
		{
			if(pulldownMode == PULLDOWN_OBJECTS_WINDOW)
			{
				[self _hideWindow];
				return;
			}
		}
		if(dataSource != nil)
		{
			[self endEditing];
			
			NSArray *pulldownObjects = [dataSource pulldownObjectsForDatabaseField:self];
			unsigned count = [pulldownObjects count];
			
			if(count != 0)
			{
				[tableData release];
				tableData = [pulldownObjects retain];
				
				[self _displayWindow:PULLDOWN_OBJECTS_WINDOW];
			}
		}
	}
	else if([[self cell] _image] != nil &&
			mouseLocation.x <= bounds.size.height + 2)
	{
		if(windowIsShown == YES)
		{
			if(pulldownMode == IMAGE_OPTIONS_WINDOW)
			{
				[self _hideWindow];
			}
		}
		else if(dataSource != nil)
		{
			unsigned selectedIndex = 0;
			NSArray *imageOptions = [dataSource imageOptionsForDatabaseField:self selectedIndex:&selectedIndex];
			if([imageOptions count] != 0)
			{
				[tableData release];
				tableData = [imageOptions retain];
			
				pulldownMode = IMAGE_OPTIONS_WINDOW;
				[self _displayObjectAtIndex:selectedIndex];
				[self _displayWindow:IMAGE_OPTIONS_WINDOW];
			}
		}
	}
	else
	{
		[super mouseDown:event];
	}
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	[[self cell] _setDisclosureHighlighted:YES];
	
	isOverDisclosure = YES;
	
	// since the focus ring invalidation doesn't work correctly,
	// we force a redraw of the complete superview
	NSRect frame = [self frame];
	frame.origin.x -= 3;
	frame.origin.y -= 3;
	frame.size.width += 6;
	frame.size.height += 6;
	[[self superview] setNeedsDisplayInRect:frame];
}

- (void)mouseExited:(NSEvent *)theEvent
{
	isOverDisclosure = NO;
	
	if(windowIsShown == YES &&
	   pulldownMode == PULLDOWN_OBJECTS_WINDOW)
	{
		return;
	}
	
	[[self cell] _setDisclosureHighlighted:NO];
	
	// since the focus ring invalidation doesn't work correctly,
	// we force a redraw of the complete superview
	NSRect frame = [self frame];
	frame.origin.x -= 3;
	frame.origin.y -= 3;
	frame.size.width += 6;
	frame.size.height += 6;
	[[self superview] setNeedsDisplayInRect:frame];
}

- (void)viewDidMoveToWindow
{
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	[notificationCenter removeObserver:self name:NSViewFrameDidChangeNotification object:nil];
	
	if([self window] != nil)
	{
		[notificationCenter addObserver:self selector:@selector(_frameDidChange:) 
								   name:NSViewFrameDidChangeNotification object:[[self window] contentView]];
	}
	[self _updateDisclosureTrackingRect];
}

- (void)resetCursorRects
{
	// do nothing. This way, the cursor rects will be just perfect...
}

- (void)viewWillStartLiveResize
{
	if(windowIsShown)
	{
		[self endEditing];
		[self _hideWindow];
	}
}

#pragma mark Methods controlling the completionsTableView

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [tableData count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn 
			row:(int)rowIndex
{
	if(pulldownMode == PULLDOWN_OBJECTS_WINDOW)
	{
		id object = [tableData objectAtIndex:rowIndex];
		return [dataSource databaseField:self displayStringForRepresentedObject:object];
	}
	
	return [tableData objectAtIndex:rowIndex];
}

- (void)pulldownTableViewAction:(id)sender
{
	int selectedRow = [pulldownTableView selectedRow];
	
	if(selectedRow != -1)
	{
		[self insertTab:self];
	}
}

#pragma mark Private Methods

- (void)_setNeedsDisplay
{
	[self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
	[super setNeedsDisplay:YES];
}

- (void)_displayRepresentedObject
{
	XMDatabaseFieldCell *cell = (XMDatabaseFieldCell *)[self cell];
	NSText *currentEditor = [self currentEditor];
	NSImage *displayImage;
	NSString *displayString;
	
	if(representedObject != nil && dataSource != nil)
	{
		displayImage = [dataSource databaseField:self imageForRepresentedObject:representedObject];
		if(displayImage == nil)
		{
			displayImage = defaultImage;
		}
		displayString = [dataSource databaseField:self displayStringForRepresentedObject:representedObject];
	}
	else
	{
		displayImage = defaultImage;
		displayString = @"";
	}
	
	[cell _setImage:displayImage];
	
	if(currentEditor != nil)
	{
		[currentEditor setString:displayString];
	}
	else
	{
		[cell setStringValue:displayString];
	}
	[self setNeedsDisplay:YES];
}
	
- (void)_displayObjectAtIndex:(unsigned)indexOfObject
{
	// selecting the appropriate index in tableView
	NSIndexSet *indexSet = [[NSIndexSet alloc] initWithIndex:indexOfObject];
	[pulldownTableView selectRowIndexes:indexSet byExtendingSelection:NO];
	[pulldownTableView scrollRowToVisible:indexOfObject];
	[indexSet release];
	
	if(pulldownMode == COMPLETIONS_WINDOW)
	{
		// replacing the old string with the new one
		NSText *currentEditor = [self currentEditor];
		NSString *completedString = [tableData objectAtIndex:indexOfObject];
		unsigned completedStringLength = [completedString length];
		unsigned uncompletedStringLength = [uncompletedString length];
		NSRange selectionRange = NSMakeRange(uncompletedStringLength, completedStringLength - uncompletedStringLength);
		[currentEditor setString:completedString];
		[currentEditor setSelectedRange:selectionRange];
	}
}

- (void)_displayWindow:(unsigned)mode;
{
	NSWindow *parentWindow = [self window];
	
	if(mode != WINDOW_UPDATE_MODE)
	{
		pulldownMode = mode;
	}
	
	// calculate the completion window position
	NSRect frame = [self frame];
	NSPoint startPoint = NSMakePoint(0, frame.size.height);
	NSPoint windowPoint = [self convertPoint:startPoint toView:nil];
	NSPoint screenPoint = [parentWindow convertBaseToScreen:windowPoint];
	
	// calculating the size, adjusting the scrollers accordingly
	if(mode != WINDOW_UPDATE_MODE)
	{
		unsigned numberOfItems = [tableData count];
		if(numberOfItems > 5)
		{
			numberOfItems = 5;
			[pulldownScrollView setHasVerticalScroller:YES];
		}
		else
		{
			[pulldownScrollView setHasVerticalScroller:NO];
		}
	
		// calculating the window's size
		float height = (float)([pulldownTableView rowHeight] * numberOfItems);
		float width;
	
		if(pulldownMode == COMPLETIONS_WINDOW)
		{
			width = frame.size.width - DISCLOSURE_WIDTH;
		}
		else if(pulldownMode == IMAGE_OPTIONS_WINDOW)
		{
			width = 50.0;
		}
		else
		{
			width = frame.size.width;
		}
		NSRect menuWindowFrame = NSMakeRect(screenPoint.x, screenPoint.y - height, width, height);
		[pulldownWindow setFrame:menuWindowFrame display:NO];
		[pulldownTableView sizeToFit];
		[pulldownTableView reloadData];
		[pulldownWindow makeFirstResponder:pulldownScrollView];
	
		// display on screen if necessary
		if(!windowIsShown)
		{
			[parentWindow addChildWindow:pulldownWindow ordered:NSWindowAbove];
			windowIsShown = YES;
		}
	}
	else
	{
		NSRect frame = [pulldownWindow frame];
		frame.origin.x = screenPoint.x;
		frame.origin.y = screenPoint.y;
		
		[pulldownWindow setFrame:frame display:YES];
	}
}

- (void)_hideWindow
{
	if(windowIsShown)
	{
		NSWindow *window = [self window];
		[window removeChildWindow:pulldownWindow];
		[pulldownWindow orderOut:self];
		windowIsShown = NO;
	}
}

- (void)_updateDisclosureTrackingRect
{
	if(disclosureTrackingRect != 0)
	{
		[self removeTrackingRect:disclosureTrackingRect];
	}
	
	NSRect bounds = [self bounds];
	bounds.origin.x = bounds.size.width - DISCLOSURE_WIDTH;
	bounds.size.width = DISCLOSURE_WIDTH;
	NSTrackingRectTag theTrackingRect = [self addTrackingRect:bounds owner:self userData:@"test" assumeInside:NO];
	if(theTrackingRect != 0)
	{
		disclosureTrackingRect = theTrackingRect;
	}
}

- (void)_frameDidChange:(NSNotification *)notif
{
	[self _updateDisclosureTrackingRect];
}

@end

@implementation XMDatabaseFieldWindow

/**
 * This undocumented method returns NO if the window has no
 * title bar. If NO is returned, the scrollers are drawed gray
 * and without any visible indication if the user presses the
 * scroll arrows or knob. Therefore, we simply return YES to 
 * obtain the desired behaviour
 **/
- (BOOL)_hasActiveControls
{
	return YES;
}

@end

@implementation XMDatabaseFieldCell

- (id)_initWithTextFieldCell:(NSTextFieldCell *)textFieldCell
{
	self = [super initTextCell:@""];
	
	// taking over the attributes from the original text field.
	// This allows convenient adjustement within InterfaceBuilder.app
	[self setEditable:[textFieldCell isEditable]];
	[self setBezeled:[textFieldCell isBezeled]];
	[self setBezelStyle:[textFieldCell bezelStyle]];
	[self setScrollable:[textFieldCell isScrollable]];
	[self setFont:[textFieldCell font]];
	[self setShowsFirstResponder:NO];
	
	// optimizing drawing behaviour
	[self setDrawsBackground:YES];
	
	// drawing the focus ring is not deferred to the superclass,
	// as we have to adjust the rect of the focus ring
	[self setFocusRingType:NSFocusRingTypeNone];
	
	fieldEditor = nil;
	image = nil;
	imageCell = [[NSImageCell alloc] initImageCell:nil];
	[imageCell setImageFrameStyle:NSImageFrameNone];
	[imageCell setImageScaling:NSScaleProportionally];
	[imageCell setImageAlignment:NSImageAlignCenter];
	
	return self;
}

- (void)dealloc
{
	[fieldEditor release];
	[image release];
	[imageCell release];
	
	[super dealloc];
}

- (NSImage *)_image
{
	return image;
}

- (void)_setImage:(NSImage *)theImage
{
	NSImage *old = image;
	image = [theImage retain];
	[old release];
	
	[imageCell setImage:image];
}

- (void)_setDisclosureHighlighted:(BOOL)flag
{
	isDisclosureHighlighted = flag;
}

- (void)_setNeedsDrawing:(BOOL)flag
{
	needsDrawing = flag;
}

#pragma mark Drawing Methods

/**
 * By adjusting the returned NSRect, we can determine where the
 * system does draw the text content
 **/
- (NSRect)drawingRectForBounds:(NSRect)bounds
{	
	bounds = [super drawingRectForBounds:bounds];
	
	// we only adjust the bounds if we have an image to draw
	if(image != nil)
	{
		// width is bounds height
		float width = bounds.size.height;
		
		bounds.origin.x += width;
		bounds.size.width -= width;
	}
	
	// we implicitely assume an height of 24 pixels using 13pt font
	// Normal height for NSTextFields in this case is 22px.
	// BOUGS: Make this routine more general
	bounds.origin.y += 2;
	bounds.size.height -= 4;
	
	// subtracting the space for the disclosure triange
	bounds.size.width -= DISCLOSURE_WIDTH;
	
	return bounds;
}

- (void)drawWithFrame:(NSRect)frame inView:(NSView *)view
{	
	if(needsDrawing == YES)
	{

		// drawing the disclosure border
		NSBezierPath *borderPath = [[NSBezierPath alloc] init];
		NSPoint borderStartPoint = NSMakePoint(frame.size.width - DISCLOSURE_WIDTH, 1);
		NSPoint firstArcCenter = NSMakePoint(frame.size.width - DISCLOSURE_RADIUS-1, DISCLOSURE_RADIUS+1);
		NSPoint secondArcCenter = NSMakePoint(frame.size.width - DISCLOSURE_RADIUS-1, frame.size.height - DISCLOSURE_RADIUS - 1);
		NSPoint borderEndPoint = NSMakePoint(frame.size.width - DISCLOSURE_WIDTH, frame.size.height-1);
			
		[borderPath moveToPoint:borderStartPoint];
		[borderPath appendBezierPathWithArcWithCenter:firstArcCenter radius:DISCLOSURE_RADIUS startAngle:270.0 endAngle:0];
		[borderPath appendBezierPathWithArcWithCenter:secondArcCenter radius:DISCLOSURE_RADIUS startAngle:0 endAngle:90.0];
		[borderPath lineToPoint:borderEndPoint];
		[borderPath closePath];
		
		if(isDisclosureHighlighted == YES)
		{
			[[NSColor colorWithCalibratedRed:0.4 green:0.4 blue:0.4 alpha:1.0] set];
		}
		else
		{
			[[NSColor colorWithCalibratedRed:0.55 green:0.55 blue:0.55 alpha:1.0] set];
		}
		[borderPath setLineWidth:2.0];
		[borderPath stroke];
		
		if(isDisclosureHighlighted)
		{
			[[NSColor colorWithCalibratedRed:0.45 green:0.45 blue:0.45 alpha:1.0] set];
		}
		else
		{
			[[NSColor colorWithCalibratedRed:0.65 green:0.65 blue:0.65 alpha:1.0] set];
		}
		[borderPath fill];
		[borderPath release];
	
		// drawing the disclosure rectangle
		NSBezierPath *disclosurePath = [[NSBezierPath alloc] init];
		NSPoint pointA = NSMakePoint(frame.size.width - 3.0, frame.size.height/2.0 - 3);
		NSPoint pointB = NSMakePoint(frame.size.width - 3.0 - 8.0, frame.size.height/2.0 - 3);
		NSPoint pointC = NSMakePoint(frame.size.width - 3.0 - 4.0, frame.size.height/2.0 + 2.5);
	
		[disclosurePath moveToPoint:pointA];
		[disclosurePath lineToPoint:pointB];
		[disclosurePath lineToPoint:pointC];
		[disclosurePath lineToPoint:pointA];
	
		if(isDisclosureHighlighted == YES)
		{
			[[NSColor colorWithCalibratedRed:0.9 green:0.9 blue:0.9 alpha:1.0] set];
		}
		else
		{
			[[NSColor grayColor] set];
		}
		[disclosurePath fill];
		[disclosurePath release];
	}
	
	// adjusting the frame to draw to make room for the disclosure triangles
	frame.size.width -= DISCLOSURE_WIDTH;
	
	// using the superclass to draw text and borders
	[super drawWithFrame:frame inView:view];
	
	if(needsDrawing == YES && image != nil)
	{
		// drawing the image
		float dimension = frame.size.height - 6;
		[imageCell drawWithFrame:NSMakeRect(frame.origin.x + 3, frame.origin.y + 3, dimension, dimension) inView:view];
	}
	
	// drawing the focus ring if needed
	if(needsDrawing == YES && [self showsFirstResponder])
	{
		[NSGraphicsContext saveGraphicsState];
		NSSetFocusRingStyle(NSFocusRingOnly);
		
		NSBezierPath *bezierPath = [[NSBezierPath alloc] init];
		
		[bezierPath appendBezierPathWithRect:frame];
		[bezierPath fill];
		[bezierPath release];
		
		[NSGraphicsContext restoreGraphicsState];
	}
}

@end