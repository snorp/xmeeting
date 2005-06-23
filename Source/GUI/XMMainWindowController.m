/*
 * $Id: XMMainWindowController.m,v 1.3 2005/06/23 12:35:57 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */


#import "XMMainWindowController.h"
#import "XMMouseOverButton.h"

NSString *XMKey_MainWindowTopLeftCorner = @"XMeeting_MainWindowTopLeftCorner";
NSString *XMKey_WindowSaveNameFormat = @"XMeeting_BottomModule<%@>WindowFrame";

@interface XMMainWindowController (PrivateMethods)

- (id)_init;

- (void)windowWillClose:(NSNotification *)notif;
- (void)windowDidMove:(NSNotification *)notif;

- (void)_showMainModuleAtIndex:(unsigned)index;
- (void)_showAdditionModuleAtIndex:(unsigned)index;
- (void)_showSeparateWindowWithAdditionModuleAtIndex:(unsigned)index;
- (void)_layoutAdditionButtons;

@end

@implementation XMMainWindowController

+ (XMMainWindowController *)sharedInstance
{
	static XMMainWindowController *sharedInstance = nil;
	
	if(sharedInstance == nil)
	{
		sharedInstance = [[XMMainWindowController alloc] _init];
	}
	
	return sharedInstance;
}

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	
	return nil;
}

- (id)_init
{
	self = [super initWithWindowNibName:@"MainWindow"];
	
	mainModules = [[NSMutableArray alloc] initWithCapacity:2];
	additionModules = [[NSMutableArray alloc] initWithCapacity:3];
	bottomButtons = [[NSMutableArray alloc] initWithCapacity:3];
	separateWindows = [[NSMutableArray alloc] initWithCapacity:3];
	
	return self;
}

- (void)dealloc
{
	[mainModules release];
	[additionModules release];
	[bottomButtons release];
	[separateWindows release];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	/* making sure that the gui looks properly when displayed the first time */
	currentSelectedMainModuleIndex = UINT_MAX;
	[self _showMainModuleAtIndex:0];
	
	[bottomContentDisclosure setState:NSOffState];
	currentSelectedBottomModuleIndex = 0;
	[self _showAdditionModuleAtIndex:UINT_MAX];
	
	/* arranging the bottom content buttons */
	unsigned count = [bottomButtons count];
	unsigned i;
	unsigned x = 23; // x-value to start
	for(i = 0; i < count; i++)
	{
		NSButton *button = (NSButton *)[bottomButtons objectAtIndex:i];
		
		// calculating the location of the button
		NSRect rect = [button frame];
		rect.origin.y = 1;
		rect.origin.x = x;
		[separatorContentBox addSubview:button];
		[button setFrame:rect];
		x += rect.size.width;	// stacking the buttons in a row
	}
	
	NSWindow *window = [self window];
	NSString *windowTopLeftCornerString = [[NSUserDefaults standardUserDefaults] stringForKey:XMKey_MainWindowTopLeftCorner];
	if(windowTopLeftCornerString != nil)
	{
		NSPoint windowTopLeftCorner = NSPointFromString(windowTopLeftCornerString);
		NSRect windowFrame = [window frame];
		windowFrame.origin = windowTopLeftCorner;
		windowFrame.origin.y -= windowFrame.size.height;
		[window setFrame:windowFrame display:NO];
	}
	
	/* Setting up the localAudioVideo drawer */
	NSView *contentView = [localAudioVideoDrawer contentView];
	NSSize contentSize = [contentView bounds].size;
	[localAudioVideoDrawer setMaxContentSize:contentSize];
	[localAudioVideoDrawer setMinContentSize:contentSize];
	[localAudioVideoDrawer setContentSize:contentSize];
	[self toggleShowLocalAudioVideoDrawer:self];
}

#pragma mark Action Methods

- (void)showMainWindow
{
	[self showWindow:self];
}

- (IBAction)toggleShowAdditionContentView:(id)sender
{
	unsigned index;
	
	if(bottomIsExpanded)
	{
		index = UINT_MAX;
	}
	else
	{
		index = currentSelectedBottomModuleIndex;
	}
	[self _showAdditionModuleAtIndex:index];
	
}

- (IBAction)additionContentButtonAction:(id)sender
{
	int tag = [sender tag];
	
	NSWindow *window = [separateWindows objectAtIndex:tag];
	
	if((id)window == (id)[NSNull null])
	{
		[self _showAdditionModuleAtIndex:tag];
	}
	else
	{
		NSButton *button = (NSButton *)[bottomButtons objectAtIndex:tag];
		[button setState:NSOffState];
		[window makeKeyAndOrderFront:self];
	}
}

- (IBAction)showAdditionModuleInSeparateWindow:(id)sender
{
	[self _showSeparateWindowWithAdditionModuleAtIndex:currentSelectedBottomModuleIndex];
	
	unsigned i;
	unsigned count = [separateWindows count];
	
	for(i = 0; i < count; i++)
	{
		id object = [separateWindows objectAtIndex:i];
		
		if(object == [NSNull null])
		{
			[self _showAdditionModuleAtIndex:i];
			return;
		}
	}
	
	[self _showAdditionModuleAtIndex:UINT_MAX];
	[bottomContentDisclosure setEnabled:NO];
}

- (void)toggleShowLocalAudioVideoDrawer:(id)sender
{
	int state = [localAudioVideoDrawer state];
	if(state == NSDrawerClosedState)
	{
		[localAudioVideoDrawer openOnEdge:NSMaxXEdge];
	}
	else if(state == NSDrawerOpenState)
	{
		[localAudioVideoDrawer close];
	}
}

#pragma mark Module Methods

- (void)addMainModule:(id<XMMainWindowModule>)module
{
	[mainModules addObject:module];
}

- (void)showMainModule:(id<XMMainWindowModule>)module
{
	unsigned index = [mainModules indexOfObject:module];
	
	if(index == NSNotFound)
	{
		return;
	}
	[self _showMainModuleAtIndex:index];
}

- (void)addAdditionModule:(id<XMMainWindowAdditionModule>)module
{
	// adding the module
	[additionModules addObject:module];
	
	// creating a new button for this module and adding it to the array
	XMMouseOverButton *button = [[XMMouseOverButton alloc] initWithFrame:NSMakeRect(0,0,0,0)];
	[button setImage:[module image]];
	[button setToolTip:[module name]];
	[button setBezelStyle:NSShadowlessSquareBezelStyle];
	[button setButtonType:NSOnOffButton];
	[[button cell] setFont:[NSFont controlContentFontOfSize:9]];
	[button sizeToFit];
	[button setTarget:self];
	[button setAction:@selector(additionContentButtonAction:)];
	[button setTag:[bottomButtons count]];
	[bottomButtons addObject:button];
	[button release];
	
	// adding NSNull to the windows array to increase the array's count as well
	[separateWindows addObject:[NSNull null]];
}

- (void)showAdditionModule:(id<XMMainWindowAdditionModule>)module
{
	unsigned index = [additionModules indexOfObject:module];
	
	if(index == NSNotFound)
	{
		return;
	}
	[self _showAdditionModuleAtIndex:index];
}

#pragma mark NSWindow Delegate Methods

- (void)windowWillClose:(NSNotification *)notif
{
	NSWindow *windowToClose = (NSWindow *)[notif object];
	
	if(windowToClose == [self window])
	{
		/* storing the preference window's top left corner */
		NSRect windowFrame = [[self window] frame];
		NSPoint topLeftWindowCorner = windowFrame.origin;
		topLeftWindowCorner.y += windowFrame.size.height;
		NSString *topLeftWindowCornerString = NSStringFromPoint(topLeftWindowCorner);
		[[NSUserDefaults standardUserDefaults] setObject:topLeftWindowCornerString
												  forKey:XMKey_MainWindowTopLeftCorner];
	}
	else
	{
		unsigned index = [separateWindows indexOfObject:windowToClose];
	
		if(index == NSNotFound)
		{
			return;
		}
	
		[separateWindows replaceObjectAtIndex:index withObject:[NSNull null]];
	
		if([bottomContentDisclosure isEnabled] == NO)
		{
			[bottomContentDisclosure setEnabled:YES];
		
			currentSelectedBottomModuleIndex = index;
		}
	}
}

- (void)windowDidMove:(NSNotification *)notif
{
	NSWindow *window = [notif object];
	
	if(window == [self window])
	{
		return;
	}
	NSString *name = [[NSString alloc] initWithFormat:XMKey_WindowSaveNameFormat, [window title]];
	[window saveFrameUsingName:name];
	[name release];
}

#pragma mark Private Methods

- (void)_showMainModuleAtIndex:(unsigned)index
{
	
	if(index == currentSelectedMainModuleIndex)
	{
		return;
	}
	
	NSWindow *window = [self window];
	NSRect windowFrame = [window frame];
	id<XMMainWindowModule> module = [mainModules objectAtIndex:index];
	NSView *viewToDisplay = [module contentView];
	NSSize mainSize = [mainContentBox bounds].size;
	NSSize viewSize = [module contentViewSize];
	
	currentSelectedMainModuleIndex = index;
	[module prepareForDisplay];
	
	// calculating the new frame rect's y and height values
	float heightDifference = viewSize.height - mainSize.height;
	windowFrame.origin.y = windowFrame.origin.y - heightDifference;
	windowFrame.size.height = windowFrame.size.height + heightDifference;
	
	float widthDifference = viewSize.width - mainSize.width;
	windowFrame.size.width += widthDifference;
	
	[mainContentBox setContentView:nil];
	[window setFrame:windowFrame display:YES animate:YES];
	[mainContentBox setContentView:viewToDisplay];
	
	NSSize size = windowFrame.size;
	if([module allowsContentViewResizing])
	{
		NSSize minSize = [module contentViewMinSize];
		heightDifference = viewSize.height - minSize.height;
		widthDifference = viewSize.width - minSize.width;
		size.height = size.height - heightDifference;
		size.width = size.width - widthDifference;
		[window setMinSize:size];
		[window setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
	}
	else
	{
		[window setMinSize:size];
		[window setMaxSize:size];
	}
}

- (void)_showAdditionModuleAtIndex:(unsigned)index
{
	NSWindow *window;
	NSRect windowFrame;
	float height;
	NSView *viewToDisplay;
	
	// if the same button is pressed again, we simply do nothing besides
	// again making sure that the button's state is NSOnState
	if(bottomIsExpanded && index == currentSelectedBottomModuleIndex)
	{
		XMMouseOverButton *button = [bottomButtons objectAtIndex:index];
		[button setState:NSOnState];
		return;
	}
	
	window = [self window];
	windowFrame = [window frame];
	
	// Set the "old" button to NSOffState
	XMMouseOverButton *button = [bottomButtons objectAtIndex:currentSelectedBottomModuleIndex];
	[button setState:NSOffState];
	int bottomContentDisclosureState;
	BOOL enableShowModuleInSeparateWindowButton;
	
	// we are expanding
	if(index != UINT_MAX)
	{
		id<XMMainWindowAdditionModule> module = [additionModules objectAtIndex:index];
		[module prepareForDisplay];
		
		bottomIsExpanded = YES;
		viewToDisplay = [module contentView];
		height = [module contentViewSize].height;
		
		currentSelectedBottomModuleIndex = index;
		
		// set the "new" button's state to NSOnState
		button = [bottomButtons objectAtIndex:index];
		[button setState:NSOnState];
		
		// setting the correct state for the disclosure
		bottomContentDisclosureState = NSOnState;
		enableShowModuleInSeparateWindowButton = YES;
	}
	else	// we are collapsing
	{
		bottomIsExpanded = NO;
		viewToDisplay = nil;
		height = 0;
		
		// setting the correct state for the disclosure
		bottomContentDisclosureState = NSOffState;
		enableShowModuleInSeparateWindowButton = NO;
	}
	
	[bottomContentDisclosure setState:bottomContentDisclosureState];
	
	[showModuleInSeparateWindowButton setHidden:!enableShowModuleInSeparateWindowButton];
	[showModuleInSeparateWindowButton setEnabled:enableShowModuleInSeparateWindowButton];
	if(!enableShowModuleInSeparateWindowButton)
	{
		[showModuleInSeparateWindowButton reset];
	}
	
	// calculating the new frame rect
	float bottomHeight = [bottomContentBox bounds].size.height;
	float heightDifference = height - bottomHeight;
	windowFrame.origin.y = windowFrame.origin.y - heightDifference;
	windowFrame.size.height = windowFrame.size.height + heightDifference;
	
	// adjusting the autoresizing mask to make a smooth animated window resize
	[mainContentBox setAutoresizingMask:NSViewMinYMargin];
	[separatorContentBox setAutoresizingMask:NSViewMinYMargin];
	[bottomContentBox setAutoresizingMask:NSViewHeightSizable];
	
	// resizing the window
	[bottomContentBox setContentView:nil];
	[window setFrame:windowFrame display:YES animate:YES];
	[bottomContentBox setContentView:viewToDisplay];
	
	// changing the autoresizing mask back to the desired behaviour
	[mainContentBox setAutoresizingMask:(NSViewHeightSizable | NSViewWidthSizable)];
	[separatorContentBox setAutoresizingMask:(NSViewWidthSizable | NSViewMaxYMargin)];
	[bottomContentBox setAutoresizingMask:(NSViewWidthSizable | NSViewMaxYMargin)];
	
	NSSize minSize = [window minSize];
	minSize.height = minSize.height + heightDifference;
	[window setMinSize:minSize];
	if([window maxSize].height != FLT_MAX)
	{
		[window setMaxSize:minSize];
	}
}

- (void)_showSeparateWindowWithAdditionModuleAtIndex:(unsigned)index
{
	id<XMMainWindowAdditionModule> module = (id<XMMainWindowAdditionModule>)[additionModules objectAtIndex:index];
	NSView *contentView = [module contentView];
	NSNumber *number;
	NSSize contentSize = [module contentViewSize];
	NSRect contentRect = NSMakeRect(0, 0, contentSize.width, contentSize.height);
	
	NSWindow *separateWindow = [[NSWindow alloc] initWithContentRect:contentRect
														   styleMask:(NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask)
															 backing:NSBackingStoreBuffered
															   defer:NO];
	
	[separateWindow setTitle:[module name]];
	[separateWindow setContentView:contentView];
	
	NSString *windowSaveName = [[NSString alloc] initWithFormat:XMKey_WindowSaveNameFormat, [module name]];
	if(![separateWindow setFrameUsingName:windowSaveName force:YES])
	{
		[separateWindow center];
		[separateWindow saveFrameUsingName:windowSaveName];
	}
	[separateWindow setDelegate:self];
	[separateWindows replaceObjectAtIndex:index withObject:separateWindow];
	
	[separateWindow makeKeyAndOrderFront:self];
	
	// workaround since the state of the button does not automatically
	// return to NSOffState.
	[showModuleInSeparateWindowButton setState:NSOffState];
}

@end
