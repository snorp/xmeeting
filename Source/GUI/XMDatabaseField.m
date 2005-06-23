/*
 * $Id: XMDatabaseField.m,v 1.3 2005/06/23 12:35:56 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMDatabaseField.h"

NSString *dataSourceExceptionFormat = @"*** Illegal XMDatabaseComboBox data source (%@).\
Must implement databaseField:completionsForString:indexOfSelectedItem:, \
databaseField:representedObjectForcompletedString:,\
databaseField:displayStringForRepresentedObject: and \
databaseField:imageForRepresentedObject:";

/**
 * We have to use a subclass of NSWindow in order to obtain
 * correct display of the scrollers
 **/
@interface XMDatabaseFieldCompletionsWindow : NSWindow {
}

@end

/**
 * We also need to use our own NSTextFieldCell subclass
 * in order to have access to the keyboard events
 * sent to this cell
 **/
@interface XMDatabaseFieldCell : NSTextFieldCell
{
	NSTextView *fieldEditor;
	NSImage *image;
	NSImageCell *imageCell;
}

- (id)_initWithTextFieldCell:(NSTextFieldCell *)cell;

- (NSImage *)_image;
- (void)_setImage:(NSImage *)image;

@end

@interface XMDatabaseField (PrivateMethods)

- (void)_init;

- (void)_setNeedsDisplay;
- (void)_displayRepresentedObject;
- (void)_displayCompletionAtIndex:(unsigned)index;
- (void)_displayCompletionsWindow;
- (void)_hideCompletionsWindow;

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
	completionsWindow = [[XMDatabaseFieldCompletionsWindow alloc] initWithContentRect:NSMakeRect(0,0,0,0) styleMask:NSBorderlessWindowMask
											   backing:NSBackingStoreBuffered defer:YES];
	
	[completionsWindow setHasShadow:YES];
	[completionsWindow setReleasedWhenClosed:NO];
	[completionsWindow setShowsResizeIndicator:NO];
	[completionsWindow setAlphaValue:0.8];
	
	// setting up the scroll view attributes
	completionsScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0,0,0,0)];
	[completionsScrollView setHasHorizontalScroller:NO];
	[completionsScrollView setHasVerticalScroller:YES];
	[completionsScrollView setAutohidesScrollers:YES];
	[completionsScrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
	
	// setting up the table view attributes
	NSTableColumn *completionsTableViewColumn = [[NSTableColumn alloc] initWithIdentifier:@""];
	[completionsTableViewColumn setEditable:NO];
	completionsTableView = [[NSTableView alloc] initWithFrame:NSMakeRect(0,0,0,0)];
	[completionsTableView addTableColumn:completionsTableViewColumn];
	[completionsTableView setDataSource:self];
	[completionsTableView setAllowsColumnReordering:NO];
	[completionsTableView setAllowsColumnResizing:NO];
	[completionsTableView setAllowsMultipleSelection:NO];
	[completionsTableView setAllowsEmptySelection:NO];
	[completionsTableView setAllowsColumnSelection:NO];
	[completionsTableView setIntercellSpacing:NSMakeSize(0.0, 0.0)];
	[completionsTableView setHeaderView:nil];
	[completionsTableView setTarget:self];
	[completionsTableView setAction:@selector(completionsTableViewAction:)];
	[completionsTableView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
	[completionsTableViewColumn release];
	
	// putting all together
	[completionsScrollView setDocumentView:completionsTableView];
	[completionsWindow setContentView:completionsScrollView];
	
	XMDatabaseFieldCell *databaseFieldCell = [[XMDatabaseFieldCell alloc] _initWithTextFieldCell:(NSTextFieldCell *)[self cell]];
	[self setCell:databaseFieldCell];
	[databaseFieldCell release];
	
	// we are our own delegate :-)
	[super setDelegate:self];
	
	// default values
	completionsWindowIsShown = NO;
	shouldFetchCompletions = YES;
	
	representedObject = nil;
}

- (void)dealloc
{
	[completionsWindow release];
	[completionsScrollView release];
	[completionsTableView release];
	[currentCompletions release];
	
	[super dealloc];
}

#pragma mark Public Methods

- (id)dataSource
{
	return dataSource;
}

- (void)setDataSource:(id)aSource
{
	if(aSource == nil)
	{
		dataSource = nil;
		return;
	}
	if(![aSource respondsToSelector:@selector(databaseField:completionsForString:indexOfSelectedItem:)] ||
	   ![aSource respondsToSelector:@selector(databaseField:representedObjectForCompletedString:)] ||
	   ![aSource respondsToSelector:@selector(databaseField:displayStringForRepresentedObject:)] ||
	   ![aSource respondsToSelector:@selector(databaseField:imageForRepresentedObject:)])
	{
		NSLog(dataSourceExceptionFormat, [aSource description]);
		return;
	}
	else
	{
		dataSource = aSource;
	}
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
}

- (id)representedObject
{
	return representedObject;
}

- (void)setRepresentedObject:(id)theObject
{
	[representedObject release];
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
	[self _hideCompletionsWindow];
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
		[currentCompletions release];
		
		// asking the data source for new completions
		unsigned indexOfSelectedItem = 0;
		currentCompletions = [[dataSource databaseField:self
								  completionsForString:uncompletedString
								   indexOfSelectedItem:&indexOfSelectedItem] retain];
		
		unsigned count = [currentCompletions count];
		if(count != 0)
		{
			// we have completions, therefore we display the completions window
			[self _displayCompletionAtIndex:indexOfSelectedItem];
			[self _displayCompletionsWindow];
			return;
		}
	}
	
	[self _hideCompletionsWindow];
	shouldFetchCompletions = YES;
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{	
	BOOL returnValue = NO;
	
	if(command == @selector(moveDown:))
	{
		if(completionsWindowIsShown)
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
		if(completionsWindowIsShown)
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
		if(completionsWindowIsShown)
		{
			[self insertTab:self];
			returnValue = YES;
		}
		else
		{
			returnValue = NO;
		}
	}
	else if(command == @selector(insertNewline:))
	{
		if(completionsWindowIsShown)
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

#pragma mark Implementing NSResponder Methods

- (void)moveDown:(id)sender
{
	int newSelectedCompletionIndex = [completionsTableView selectedRow] + 1;
	if(newSelectedCompletionIndex == [currentCompletions count])
	{
		return;
	}
	[self _displayCompletionAtIndex:newSelectedCompletionIndex];
}

- (void)moveUp:(id)sender
{
	int newSelectedCompletionIndex = [completionsTableView selectedRow] - 1;
	if(newSelectedCompletionIndex < 0)
	{
		return ;
	}
	[self _displayCompletionAtIndex:newSelectedCompletionIndex];
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
	NSText *currentEditor = [self currentEditor];
	unsigned selectedCompletionIndex = [completionsTableView selectedRow];
	NSString *currentString = [currentCompletions objectAtIndex:selectedCompletionIndex];
	
	if(dataSource != nil)
	{
		representedObject = [[dataSource databaseField:self representedObjectForCompletedString:currentString] retain];
		[self _displayRepresentedObject];
	}
	[self _hideCompletionsWindow];
	[self _setNeedsDisplay];
}

- (void)insertNewline:(id)sender
{
	[self insertTab:self];
}

#pragma mark Methods controlling the completionsTableView

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [currentCompletions count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn 
			row:(int)rowIndex
{
	return [currentCompletions objectAtIndex:rowIndex];
}

- (void)completionsTableViewAction:(id)sender
{
	int selectedRow = [completionsTableView selectedRow];
	
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
}
	
- (void)_displayCompletionAtIndex:(unsigned)indexOfCompletion
{
	// selecting the appropriate index in tableView
	NSIndexSet *indexSet = [[NSIndexSet alloc] initWithIndex:indexOfCompletion];
	[completionsTableView selectRowIndexes:indexSet byExtendingSelection:NO];
	[completionsTableView scrollRowToVisible:indexOfCompletion];
	[indexSet release];
	
	// replacing the old string with the new one
	NSText *currentEditor = [self currentEditor];
	NSString *completedString = [currentCompletions objectAtIndex:indexOfCompletion];
	unsigned completedStringLength = [completedString length];
	unsigned uncompletedStringLength = [uncompletedString length];
	NSRange selectionRange = NSMakeRange(uncompletedStringLength, completedStringLength - uncompletedStringLength);
	[currentEditor setString:completedString];
	[currentEditor setSelectedRange:selectionRange];
}

- (void)_displayCompletionsWindow
{
	NSWindow *parentWindow = [self window];
	
	// calculate the completion window position
	NSRect frame = [self frame];
	NSPoint startPoint = NSMakePoint(0, frame.size.height);
	NSPoint windowPoint = [self convertPoint:startPoint toView:nil];
	NSPoint screenPoint = [parentWindow convertBaseToScreen:windowPoint];
	
	// calculating the size, adjusting the scrollers accordingly
	unsigned numberOfItems = [currentCompletions count];
	if(numberOfItems > 5)
	{
		numberOfItems = 5;
		[completionsScrollView setHasVerticalScroller:YES];
	}
	else
	{
		[completionsScrollView setHasVerticalScroller:NO];
	}
	
	// calculating the windo's size
	float height = (float)([completionsTableView rowHeight] * numberOfItems);
	NSRect menuWindowFrame = NSMakeRect(screenPoint.x, screenPoint.y - height, frame.size.width, height);
	[completionsWindow setFrame:menuWindowFrame display:NO];
	[completionsTableView sizeToFit];
	[completionsTableView reloadData];
	[completionsWindow makeFirstResponder:completionsScrollView];
	
	// display on screen if necessary
	if(!completionsWindowIsShown)
	{
		[parentWindow addChildWindow:completionsWindow ordered:NSWindowAbove];
		completionsWindowIsShown = YES;
	}
}

- (void)_hideCompletionsWindow
{
	if(completionsWindowIsShown)
	{
		NSWindow *window = [self window];
		[window removeChildWindow:completionsWindow];
		[completionsWindow orderOut:self];
		completionsWindowIsShown = NO;
	}
}

@end

@implementation XMDatabaseFieldCompletionsWindow

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
	
	[self setEditable:[textFieldCell isEditable]];
	[self setBezeled:[textFieldCell isBezeled]];
	[self setBezelStyle:[textFieldCell bezelStyle]];
	[self setDrawsBackground:NO];
	
	fieldEditor = nil;
	image = nil;
	imageCell = [[NSImageCell alloc] initImageCell:nil];
	[imageCell setImageFrameStyle:NSImageFrameNone];
	[imageCell setImageScaling:NSScaleNone];
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
		bounds.origin.x += 19;
		bounds.size.width -= 19;
	}
	return bounds;
}

- (void)drawWithFrame:(NSRect)frame inView:(NSView *)view
{
	// workaround for NSTextFieldCell not drawing the entire Focus ring
	// since the -drawRectForBounds: has returned a different drawRect.
	if(image != nil && [self showsFirstResponder])
	{
		NSRect theRect = NSMakeRect(frame.origin.x, frame.origin.y, 1, frame.size.height);
		[NSGraphicsContext saveGraphicsState];
		NSSetFocusRingStyle(NSFocusRingOnly);
		[[NSBezierPath bezierPathWithRect:theRect] fill];
		[NSGraphicsContext restoreGraphicsState];
	}
	
	// using the superclass to draw all text
	[super drawWithFrame:frame inView:view];
	
	// finally, drawing the image
	float dimension = frame.size.height;
	[imageCell drawWithFrame:NSMakeRect(frame.origin.x, frame.origin.y, dimension, dimension) inView:view];
}

@end