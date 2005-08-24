/*
 * $Id: XMMainWindowController.m,v 1.4 2005/08/24 22:29:39 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */


#import "XMMainWindowController.h"
#import "XMMouseOverButton.h"

#define ADDITION_BUTTONS_X_OFFSET 23
#define ADDITION_BUTTONS_Y_OFFSET 5

NSString *XMKey_MainWindowTopLeftCorner = @"XMeeting_MainWindowTopLeftCorner";
NSString *XMKey_WindowSaveNameFormat = @"XMeeting_BottomModule<%@>WindowFrame";

@interface XMMainWindowController (PrivateMethods)

- (id)_init;

- (void)windowWillClose:(NSNotification *)notif;
- (void)windowDidMove:(NSNotification *)notif;

- (void)_additionButtonAction:(id)sender;

- (void)_showMainModuleAtIndex:(unsigned)index;
- (void)_showSupportModuleAtIndex:(unsigned)index;
- (void)_showAdditionModuleAtIndex:(unsigned)index;
- (void)_showSeparateWindowWithAdditionModuleAtIndex:(unsigned)index;

@end

@implementation XMMainWindowController

#pragma mark Class Methods

+ (XMMainWindowController *)sharedInstance
{
	static XMMainWindowController *sharedInstance = nil;
	
	if(sharedInstance == nil)
	{
		sharedInstance = [[XMMainWindowController alloc] _init];
	}
	
	return sharedInstance;
}

#pragma mark Init & Deallocation Methods

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
	supportModules = [[NSMutableArray alloc] initWithCapacity:2];
	additionModules = [[NSMutableArray alloc] initWithCapacity:3];
	additionButtons = [[NSMutableArray alloc] initWithCapacity:3];
	additionWindows = [[NSMutableArray alloc] initWithCapacity:3];
	
	activeMainModuleIndex = UINT_MAX;
	activeSupportModuleIndex = UINT_MAX;
	activeAdditionModuleIndex = 0;
	
	bottomIsExpanded = NO;
	
	return self;
}

- (void)dealloc
{
	[mainModules release];
	[supportModules release];
	[additionModules release];
	[additionButtons release];
	[additionWindows release];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	// filling the separator content box and the status bar content box with their respecive views
	[separatorContentBox setContentView:separatorContentView];
	[statusBarContentBox setContentView:statusBarContentView];
	
	/* making sure that the gui looks properly when displayed the first time */
	if([mainModules count] != 0)
	{
		[self _showMainModuleAtIndex:0];
	}
	
	if([supportModules count] != 0)
	{
		[self _showSupportModuleAtIndex:0];
	}
	
	//[bottomContentDisclosure setState:NSOffState];
	[self _showAdditionModuleAtIndex:UINT_MAX];
	
	/* arranging the bottom content buttons */
	unsigned count = [additionButtons count];
	unsigned i;
	unsigned x = ADDITION_BUTTONS_X_OFFSET; // x-value to start
	for(i = 0; i < count; i++)
	{
		NSButton *button = (NSButton *)[additionButtons objectAtIndex:i];
		
		// calculating the location of the button
		NSRect rect = [button frame];
		rect.origin.y = ADDITION_BUTTONS_Y_OFFSET;
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
}

#pragma mark General Public Methods

- (void)showMainWindow
{
	[self showWindow:self];
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

- (id<XMMainWindowModule>)activeMainModule
{
	if(activeMainModuleIndex != UINT_MAX)
	{
		return (id<XMMainWindowModule>)[mainModules objectAtIndex:activeMainModuleIndex];
	}
	return nil;
}

- (void)noteSizeValuesDidChangeOfMainModule:(id<XMMainWindowModule>)module
{
	id<XMMainWindowModule> activeModule = [mainModules objectAtIndex:activeMainModuleIndex];
	
	if(activeModule != module)
	{
		return;
	}
	
	// fetching the size values
	NSSize currentSize = [mainContentBox frame].size;
	NSSize newSize = [module contentViewSize];
	NSSize newMinSize = [module contentViewMinSize];
	NSSize newMaxSize = [module contentViewMaxSize];
	float supportContentHeight;
	if(activeSupportModuleIndex != UINT_MAX)
	{
		id<XMMainWindowSupportModule> supportModule = [supportModules objectAtIndex:activeSupportModuleIndex];
		supportContentHeight = [supportModule contentViewSize].height;
	}
	else
	{
		supportContentHeight = 0.0;
	}
	
	NSWindow *window = [self window];
	NSRect windowFrame = [window frame];
	
	// calculating the new height
	float newHeight = ((newSize.height > supportContentHeight) ? newSize.height : supportContentHeight);
	float heightDifference = newHeight - currentSize.height;
	windowFrame.origin.y -= heightDifference;
	windowFrame.size.height += heightDifference;
	
	// calculating the new width
	float widthDifference = newSize.width - currentSize.width;
	windowFrame.size.width += widthDifference;
	
	// resizing the window
	[window setFrame:windowFrame display:YES animate:YES];
	
	// calculating the new window min size
	NSSize minSize = windowFrame.size;
	float newMinHeight = ((newMinSize.height > supportContentHeight) ? newMinSize.height : supportContentHeight);
	heightDifference = newHeight - newMinHeight;
	widthDifference = newSize.width - newMinSize.width;
	minSize.height -= heightDifference;
	minSize.width -= widthDifference;
	[window setMinSize:minSize];
	
	NSSize maxSize = windowFrame.size;
	heightDifference = newMaxSize.height - newHeight;
	widthDifference = newMaxSize.width - newSize.width;
	maxSize.height += heightDifference;
	maxSize.width += widthDifference;
	[window setMaxSize:maxSize];
}

- (void)addSupportModule:(id<XMMainWindowSupportModule>)module
{
	[supportModules addObject:module];
}

- (void)showSupportModule:(id<XMMainWindowSupportModule>)module
{
	unsigned index = [supportModules indexOfObject:module];
	
	if(index == NSNotFound)
	{
		return;
	}
	[self _showSupportModuleAtIndex:index];
}

- (id<XMMainWindowSupportModule>)activeSupportModule
{
	if(activeSupportModuleIndex != UINT_MAX)
	{
		return (id<XMMainWindowSupportModule>)[supportModules objectAtIndex:activeSupportModuleIndex];
	}
	return nil;
}

- (void)noteSizeValuesDidChangeOfSupportModule:(id<XMMainWindowSupportModule>)module
{
	id<XMMainWindowSupportModule> activeModule = [supportModules objectAtIndex:activeSupportModuleIndex];
	
	if(activeModule != module)
	{
		return;
	}
	
	// fetching the relevant data
	NSSize oldSize = [rightContentBox frame].size;
	NSSize newSize = [module contentViewSize];
	float mainContentHeight;
	float mainContentMinHeight;
	
	if(activeMainModuleIndex != UINT_MAX)
	{
		id<XMMainWindowModule> mainModule = [mainModules objectAtIndex:activeMainModuleIndex];
		mainContentHeight = [mainModule contentViewSize].height;
		mainContentMinHeight = [mainModule contentViewMinSize].height;
	}
	else
	{
		mainContentHeight = 0.0;
		mainContentMinHeight = 0.0;
	}
	
	NSWindow *window = [self window];
	NSRect windowFrame = [window frame];
	
	// calculating the new height
	float newHeight = ((mainContentHeight > newSize.height) ? mainContentHeight : newSize.height);
	float heightDifference = newHeight - oldSize.height;
	windowFrame.origin.y -= heightDifference;
	windowFrame.size.height += heightDifference;
	
	// calculating the new width
	float widthDifference = newSize.width - oldSize.width;
	windowFrame.size.width += widthDifference;
	
	// changing the autoresizing mask before this resize operation
	[mainContentBox setAutoresizingMask:NSViewMaxXMargin];
	[rightContentBox setAutoresizingMask:NSViewWidthSizable];
	
	// resizing the window
	[window setFrame:windowFrame display:YES animate:YES];
	
	// restoring the autoresizing mask
	[mainContentBox setAutoresizingMask:(NSViewHeightSizable | NSViewWidthSizable)];
	[rightContentBox setAutoresizingMask:(NSViewMinXMargin | NSViewHeightSizable)];
	
	// adjusting the window min size
	NSSize minSize = [window minSize];
	minSize.height += heightDifference;
	minSize.width += widthDifference;
	[window setMinSize:minSize];
	
	// adjusting the window max size
	NSSize maxSize = [window maxSize];
	maxSize.height += heightDifference;
	maxSize.width += widthDifference;
	[window setMaxSize:maxSize];
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
	[button setAction:@selector(_additionButtonAction:)];
	[button setTag:[additionButtons count]];
	[additionButtons addObject:button];
	[button release];
	
	// adding NSNull to the windows array to increase the array's count as well
	[additionWindows addObject:[NSNull null]];
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

- (id<XMMainWindowAdditionModule>)activeAdditionModule
{
	if(activeAdditionModuleIndex != UINT_MAX)
	{
		return (id<XMMainWindowAdditionModule>)[additionModules objectAtIndex:activeAdditionModuleIndex];
	}
	return nil;
}

#pragma mark Action Methods

- (IBAction)toggleShowAdditionContent:(id)sender
{
	unsigned index;
	
	if(bottomIsExpanded)
	{
		index = UINT_MAX;
	}
	else
	{
		index = activeAdditionModuleIndex;
	}
	[self _showAdditionModuleAtIndex:index];
}

- (IBAction)showAdditionModuleInSeparateWindow:(id)sender
{
	[self _showSeparateWindowWithAdditionModuleAtIndex:activeAdditionModuleIndex];
	
	unsigned i;
	unsigned count = [additionWindows count];
	
	for(i = 0; i < count; i++)
	{
		id object = [additionWindows objectAtIndex:i];
		
		if(object == [NSNull null])
		{
			[self _showAdditionModuleAtIndex:i];
			return;
		}
	}
	
	[self _showAdditionModuleAtIndex:UINT_MAX];
	[additionContentDisclosure setEnabled:NO];
}

#pragma mark NSWindow Delegate Methods

- (void)windowWillClose:(NSNotification *)notif
{
	NSWindow *windowToClose = (NSWindow *)[notif object];
	
	if(windowToClose == [self window])
	{
		// storing the preference window's top left corner
		NSRect windowFrame = [[self window] frame];
		NSPoint topLeftWindowCorner = windowFrame.origin;
		topLeftWindowCorner.y += windowFrame.size.height;
		NSString *topLeftWindowCornerString = NSStringFromPoint(topLeftWindowCorner);
		[[NSUserDefaults standardUserDefaults] setObject:topLeftWindowCornerString
												  forKey:XMKey_MainWindowTopLeftCorner];
	}
	else
	{
		unsigned index = [additionWindows indexOfObject:windowToClose];
	
		if(index == NSNotFound)
		{
			return;
		}
	
		[additionWindows replaceObjectAtIndex:index withObject:[NSNull null]];
	
		if([additionContentDisclosure isEnabled] == NO)
		{
			[additionContentDisclosure setEnabled:YES];
		
			activeAdditionModuleIndex = index;
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

- (void)_additionButtonAction:(id)sender
{
	unsigned index = (unsigned)[sender tag];
	
	[self _showAdditionModuleAtIndex:index];
}

- (void)_showMainModuleAtIndex:(unsigned)index
{
	if(index == activeMainModuleIndex)
	{
		return;
	}
	
	// deactivating the old module
	if(activeMainModuleIndex != UINT_MAX)
	{
		id<XMMainWindowModule> oldModule = [mainModules objectAtIndex:activeMainModuleIndex];
		[oldModule becomeInactiveModule];
	}
	
	activeMainModuleIndex = index;
	
	// fetching the relevant data
	id<XMMainWindowModule> module = [mainModules objectAtIndex:index];
	NSSize currentMainContentSize = [mainContentBox bounds].size;
	NSSize newMainContentSize = [module contentViewSize];
	NSSize newMainContentMinSize = [module contentViewMinSize];
	NSSize newMainContentMaxSize = [module contentViewMaxSize];
	float supportContentHeight;
	if(activeSupportModuleIndex != UINT_MAX)
	{
		id<XMMainWindowSupportModule> supportModule = [supportModules objectAtIndex:activeSupportModuleIndex];
		supportContentHeight = [supportModule contentViewSize].height;
	}
	else
	{
		supportContentHeight = 0.0;
	}
	NSWindow *window = [self window];
	NSRect windowFrame = [window frame];
	
	// setting the new height of the window
	float newHeight = ((newMainContentSize.height > supportContentHeight) ? newMainContentSize.height : supportContentHeight);
	float heightDifference = newHeight - currentMainContentSize.height;
	windowFrame.origin.y -= heightDifference;
	windowFrame.size.height += heightDifference;
	
	// setting the new width of the window
	float widthDifference = newMainContentSize.width - currentMainContentSize.width;
	windowFrame.size.width += widthDifference;
	
	// resizing the window
	[mainContentBox setContentView:nil];
	[window setFrame:windowFrame display:YES animate:YES];
	[module becomeActiveModule];
	[mainContentBox setContentView:[module contentView]];
	
	// setting the correct minSize values
	NSSize minSize = windowFrame.size;
	float newMinHeight = ((newMainContentMinSize.height > supportContentHeight) ? newMainContentMinSize.height : supportContentHeight);
	heightDifference = newHeight - newMinHeight;
	widthDifference = newMainContentSize.width - newMainContentMinSize.width;
	minSize.height -= heightDifference;
	minSize.width -= widthDifference;
	[window setMinSize:minSize];
	
	// setting the correct maxSize values
	NSSize maxSize = windowFrame.size;
	heightDifference = newMainContentMaxSize.height - newHeight;
	widthDifference = newMainContentMaxSize.width - newMainContentSize.width;
	maxSize.height += heightDifference;
	maxSize.width += widthDifference;
	[window setMaxSize:maxSize];
}

- (void)_showSupportModuleAtIndex:(unsigned)index
{
	if(index == activeSupportModuleIndex)
	{
		return;
	}
	
	// deactivating the old module
	if(activeSupportModuleIndex != UINT_MAX)
	{
		id<XMMainWindowSupportModule> oldModule = [supportModules objectAtIndex:activeSupportModuleIndex];
		[oldModule becomeInactiveModule];
	}
	
	activeSupportModuleIndex = index;
	
	// fetching the relevant data
	id<XMMainWindowSupportModule> module = [supportModules objectAtIndex:activeSupportModuleIndex];
	NSSize currentSupportContentSize = [rightContentBox bounds].size;
	NSSize newSupportContentSize = [module contentViewSize];
	float mainContentHeight;
	if(activeMainModuleIndex != UINT_MAX)
	{
		id<XMMainWindowModule> mainModule = [mainModules objectAtIndex:activeMainModuleIndex];
		mainContentHeight = [mainModule contentViewSize].height;
	}
	else
	{
		mainContentHeight = 0.0;
	}
	NSWindow *window = [self window];
	NSRect windowFrame = [window frame];
	
	// setting the new height of the window frame
	float newHeight = ((mainContentHeight > newSupportContentSize.height) ? mainContentHeight : newSupportContentSize.height);
	float heightDifference = newHeight - currentSupportContentSize.height;
	windowFrame.origin.y -= heightDifference;
	windowFrame.size.height += heightDifference;
	
	// setting the new width of the window frame
	float widthDifference = newSupportContentSize.width - currentSupportContentSize.width;
	windowFrame.size.width += widthDifference;
	
	// changing the autoresizing mask before this resize operation
	[mainContentBox setAutoresizingMask:NSViewMaxXMargin];
	[rightContentBox setAutoresizingMask:NSViewWidthSizable];
	
	// resizing the window
	[rightContentBox setContentView:nil];
	[window setFrame:windowFrame display:YES animate:YES];
	[module becomeActiveModule];
	[rightContentBox setContentView:[module contentView]];
	
	// restoring the autoresizing mask
	[mainContentBox setAutoresizingMask:(NSViewHeightSizable | NSViewWidthSizable)];
	[rightContentBox setAutoresizingMask:(NSViewMinXMargin | NSViewHeightSizable)];

	// adjusting the min size of the window
	NSSize minSize = [window minSize];
	minSize.height += heightDifference;
	minSize.width += widthDifference;
	[window setMinSize:minSize];
	
	// adjusting the max size of the window
	NSSize maxSize = [window maxSize];
	maxSize.height += heightDifference;
	maxSize.width += widthDifference;
	[window setMaxSize:maxSize];
}

- (void)_showAdditionModuleAtIndex:(unsigned)index
{
	if(bottomIsExpanded && index == activeAdditionModuleIndex)
	{
		XMMouseOverButton *button = (XMMouseOverButton *)[additionButtons objectAtIndex:index];
		[button setState:NSOnState];
		return;
	}
	
	// check if this module isn't already displayed in a separate window,
	// moving this window to the front if needed
	if(index != UINT_MAX)
	{
		NSWindow *window = [additionWindows objectAtIndex:index];
		
		if((id)window != (id)[NSNull null])
		{
			XMMouseOverButton *button = (XMMouseOverButton *)[additionButtons objectAtIndex:index];
			[button setState:NSOffState];
			[window makeKeyAndOrderFront:self];
			return;
		}
	}
	
	// deactivating the old module
	if(activeAdditionModuleIndex != UINT_MAX)
	{
		XMMouseOverButton *button = (XMMouseOverButton *)[additionButtons objectAtIndex:activeAdditionModuleIndex];
		[button reset];
		
		id<XMMainWindowAdditionModule> oldModule = [additionModules objectAtIndex:activeAdditionModuleIndex];
		[oldModule becomeInactiveModule];
	}
	
	// fetching the relevant data
	id<XMMainWindowAdditionModule> module;
	float currentAdditionContentHeight = [bottomContentBox bounds].size.height;
	float newAdditionContentHeight;
	NSView *contentView;
	
	if(index != UINT_MAX)
	{
		module = [additionModules objectAtIndex:index];
		newAdditionContentHeight = [module contentViewSize].height;
		contentView = [module contentView];
		bottomIsExpanded = YES;
		
		[module becomeActiveModule];
		activeAdditionModuleIndex = index;
		XMMouseOverButton *button = (XMMouseOverButton *)[additionButtons objectAtIndex:index];
		[button setState:NSOnState];
	}
	else
	{
		module = nil;
		newAdditionContentHeight = 0.0;
		contentView = nil;
		bottomIsExpanded = NO;
	}
	
	[additionContentDisclosure setState:((bottomIsExpanded == YES) ? NSOnState : NSOffState)];
	[separateWindowButton setHidden:!bottomIsExpanded];
	[separateWindowButton setEnabled:bottomIsExpanded];
	if(!bottomIsExpanded)
	{
		[separateWindowButton reset];
	}
	
	NSWindow *window = [self window];
	NSRect windowFrame = [window frame];
	
	// setting the new height of the window frame
	float heightDifference = newAdditionContentHeight - currentAdditionContentHeight;
	windowFrame.origin.y -= heightDifference;
	windowFrame.size.height += heightDifference;
	
	// changing the autoresize mask for this resize operation
	[mainContentBox setAutoresizingMask:NSViewMinYMargin];
	[rightContentBox setAutoresizingMask:NSViewMinYMargin];
	[horizontalSeparator setAutoresizingMask:NSViewMinYMargin];
	[separatorContentBox setAutoresizingMask:NSViewMinYMargin];
	[bottomContentBox setAutoresizingMask:NSViewHeightSizable];
	
	// resizing the window
	[bottomContentBox setContentView:nil];
	[window setFrame:windowFrame display:YES animate:YES];
	[bottomContentBox setContentView:[module contentView]];
	
	// restoring the autoresize mask to its previous value
	[mainContentBox setAutoresizingMask:(NSViewHeightSizable | NSViewWidthSizable)];
	[rightContentBox setAutoresizingMask:(NSViewMinXMargin | NSViewHeightSizable)];
	[horizontalSeparator setAutoresizingMask:(NSViewWidthSizable | NSViewMaxYMargin)];
	[separatorContentBox setAutoresizingMask:(NSViewWidthSizable | NSViewMaxYMargin)];
	[bottomContentBox setAutoresizingMask:(NSViewWidthSizable | NSViewMaxYMargin)];
	
	// adjusting the min size of the window
	NSSize minSize = [window minSize];
	minSize.height += heightDifference;
	[window setMinSize:minSize];
	
	// adjusting the max size of the window
	NSSize maxSize = [window maxSize];
	maxSize.height += heightDifference;
	[window setMaxSize:maxSize];
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
	[additionWindows replaceObjectAtIndex:index withObject:separateWindow];
	
	[separateWindow makeKeyAndOrderFront:self];
	
	// workaround since the state of the button does not automatically
	// return to NSOffState.
	[separateWindowButton setState:NSOffState];
}

@end
