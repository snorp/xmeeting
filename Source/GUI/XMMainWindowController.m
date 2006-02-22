/*
 * $Id: XMMainWindowController.m,v 1.9 2006/02/22 16:12:33 zmit Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */


#import "XMMainWindowController.h"
#import "XMMouseOverButton.h"
#import "XMCallManager.h"
#import "XMVideoManager.h"
#import "XMOSDVideoView.h"

#define ADDITION_BUTTONS_X_OFFSET 23
#define ADDITION_BUTTONS_Y_OFFSET 5

NSString *XMKey_MainWindowTopLeftCorner = @"XMeeting_MainWindowTopLeftCorner";
NSString *XMKey_WindowSaveNameFormat = @"XMeeting_BottomModule<%@>WindowFrame";

@interface XMMainWindowController (PrivateMethods)

- (id)_init;

- (void)windowWillClose:(NSNotification *)notif;
- (void)windowDidMove:(NSNotification *)notif;

- (void)_additionButtonAction:(id)sender;

- (void)_showNoCallModule:(id<XMMainWindowModule>)m;
- (void)_showMainModuleAtIndex:(unsigned)index;
- (void)_showSupportModuleAtIndex:(unsigned)index;
- (void)_showAdditionModuleAtIndex:(unsigned)index deactivatePreviousModule:(BOOL)deactivateFlag;
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
	//additionButtons = [[NSMutableArray alloc] initWithCapacity:3];
	additionWindows = [[NSMutableArray alloc] initWithCapacity:3];
	
	activeMainModuleIndex = UINT_MAX;
	activeSupportModuleIndex = UINT_MAX;
	activeAdditionModuleIndex = 0;
	
	bottomIsExpanded = NO;
	selfViewShown = NO;
	
	return self;
}

- (void)dealloc
{
	[mainModules release];
	[supportModules release];
	[additionModules release];
	[additionButtons release];
	[additionWindows release];
	if (selfView) [selfView release];
	[super dealloc];
}

- (void)awakeFromNib
{
	
	/* making sure that the gui looks properly when displayed the first time */
	if([mainModules count] != 0)
	{
		//[self _showNoCallModule:nil];
		[self _showMainModuleAtIndex:0];
	}
	
	if([supportModules count] != 0)
	{
		[self _showSupportModuleAtIndex:0];
	}
	
	[self _showAdditionModuleAtIndex:UINT_MAX deactivatePreviousModule:NO];
	
	
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

	selfView = nil;
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
	
	NSWindow *window = [self window];
	NSRect windowFrame = [window frame];

	// calculating the new height
	int newHeight = newSize.height;
	int heightDifference = newHeight - (int)currentSize.height;
	windowFrame.origin.y -= heightDifference;
	windowFrame.size.height += heightDifference + 29;

	// calculating the new width
	int widthDifference = (int)newSize.width - (int)currentSize.width;
	windowFrame.size.width += widthDifference;
	
	// resizing the window
	[window setFrame:windowFrame display:YES animate:YES];
	
	// calculating the new window min size
	NSSize minSize = windowFrame.size;
	float newMinHeight = newMinSize.height;
	heightDifference = newHeight - newMinHeight;
	widthDifference = newSize.width - (int)newMinSize.width;
	minSize.height -= heightDifference;
	minSize.width -= widthDifference;
	[window setMinSize:minSize];
	
	NSSize maxSize = windowFrame.size;
	heightDifference = (int)newMaxSize.height - newHeight;
	widthDifference = (int)newMaxSize.width - (int)newSize.width;
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
	NSSize newSize = [module contentViewSize];
	int mainContentHeight;
	int mainContentMinHeight;
	
	if(activeMainModuleIndex != UINT_MAX)
	{
		id<XMMainWindowModule> mainModule = [mainModules objectAtIndex:activeMainModuleIndex];
		mainContentHeight = (int)[mainModule contentViewSize].height;
		mainContentMinHeight = (int)[mainModule contentViewMinSize].height;
	}
	else
	{
		mainContentHeight = 0;
		mainContentMinHeight = 0;
	}
	
	NSWindow *window = [self window];
	NSRect windowFrame = [window frame];
	
	// calculating the new height
	int newHeight = ((mainContentHeight > (int)newSize.height) ? mainContentHeight : (int)newSize.height);
	int heightDifference = newHeight;
	windowFrame.origin.y -= heightDifference;
	windowFrame.size.height += heightDifference;
	
	// calculating the new width
	int widthDifference = (int)newSize.width;
	windowFrame.size.width += widthDifference;
	
	// changing the autoresizing mask before this resize operation
	[mainContentBox setAutoresizingMask:(NSViewMaxXMargin | NSViewHeightSizable)];
	//[rightContentBox setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
	
	// resizing the window
	[window setFrame:windowFrame display:YES animate:YES];
	
	// restoring the autoresizing mask
	[mainContentBox setAutoresizingMask:(NSViewHeightSizable | NSViewWidthSizable)];
	//[rightContentBox setAutoresizingMask:(NSViewMinXMargin | NSViewHeightSizable)];
	
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
	[self _showAdditionModuleAtIndex:index deactivatePreviousModule:YES];
}

- (id<XMMainWindowAdditionModule>)activeAdditionModule
{
	if(activeAdditionModuleIndex != UINT_MAX)
	{
		return (id<XMMainWindowAdditionModule>)[additionModules objectAtIndex:activeAdditionModuleIndex];
	}
	return nil;
}

- (void)noteSizeValuesDidChangeOfAdditionModule:(id<XMMainWindowAdditionModule>)module{
NSLog(@"noteSizeValuesDidChangeOfAdditionModule called!");
	BOOL isActiveModule = NO;
	NSWindow *windowToResize = nil;
	int oldHeight;
	
	
	if(isActiveModule == NO)
	{
		int moduleIndex = [additionModules indexOfObject:module];
		
		if(moduleIndex == UINT_MAX)
		{
			return;
		}
		
		id window = [additionWindows objectAtIndex:moduleIndex];
		
		if(window == [NSNull null])
		{
			// module not active
			return;
		}
		
		windowToResize = (NSWindow *)window;
		oldHeight = [[windowToResize contentView] frame].size.height;
	}
	
	int newHeight = [module contentViewSize].height;
	NSRect windowFrame = [windowToResize frame];
	
	int heightDifference = newHeight - oldHeight;
	windowFrame.origin.y -= heightDifference;
	windowFrame.size.height += heightDifference;
	
	if(isActiveModule == YES)
	{
		// changing the autoresize mask for this resize operation
		[mainContentBox setAutoresizingMask:NSViewMinYMargin];
	}
	
	[windowToResize setFrame:windowFrame display:YES animate:YES];
	
	if(isActiveModule == YES)
	{
		// restoring the autoresize mask to its previous value
		[mainContentBox setAutoresizingMask:(NSViewHeightSizable | NSViewWidthSizable)];
		
		// adjusting the min size of the window
		NSSize minSize = [windowToResize minSize];
		minSize.height += heightDifference;
		[windowToResize setMinSize:minSize];
		
		// adjusting the max size of the window
		NSSize maxSize = [windowToResize maxSize];
		maxSize.height += heightDifference;
		[windowToResize setMaxSize:maxSize];
	}
}

#pragma mark Action Methods

- (IBAction)showSelfView:(id)sender{
	NSRect originalWindowRect = [[self window] frame];
	NSRect newFrame = originalWindowRect;
	
	if (selfView == nil){
		selfView = [[XMOSDVideoView alloc] init];
		float width = originalWindowRect.size.width - 6.0;
		float height = 3.0/4.0 * width;
		[selfView setFrame:NSMakeRect(0.0, 0.0, width, height)];
		[selfView setShouldDisplayOSD:NO];
	}

	if (!selfViewShown){
		newFrame.size.height += [selfView frame].size.height;
		newFrame.origin.y -= [selfView frame].size.height;
		[[self window] setFrame:newFrame display:YES animate:YES];	

		[[[self window] contentView] addSubview:selfView];

		NSPoint origin = NSMakePoint((newFrame.size.width - [selfView frame].size.width) / 2.0, [[mainModules objectAtIndex:0] contentViewSize].height + 15.0);
		[selfView setFrameOrigin:origin];
						
		[selfView startDisplayingLocalVideo];
	
		selfViewShown = YES;
	}
	else
	{
		[selfView removeFromSuperviewWithoutNeedingDisplay];
		[selfView stopDisplayingVideo];
		newFrame.size.height -= [selfView frame].size.height;
		newFrame.origin.y += [selfView frame].size.height;
		[[self window] setFrame:newFrame display:YES animate:YES];
		
		selfViewShown = NO;
	}	
	

}

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
	[self _showAdditionModuleAtIndex:index deactivatePreviousModule:YES];
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
			[self _showAdditionModuleAtIndex:i deactivatePreviousModule:NO];
			return;
		}
	}
	
	[self _showAdditionModuleAtIndex:UINT_MAX deactivatePreviousModule:NO];
}

#pragma mark NSWindow Delegate Methods

- (BOOL)windowShouldZoom:(NSWindow *)sender toFrame:(NSRect)newFrame{
	return NO;
}

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
		
		if (activeMainModuleIndex == 1) //In call module
			[[XMCallManager sharedInstance] clearActiveCall];
		
		[NSApp terminate:self];
	}
	else
	{
		unsigned index = [additionWindows indexOfObject:windowToClose];
	
		if(index == NSNotFound)
		{
			return;
		}
	
		id<XMMainWindowAdditionModule> moduleToClose = [additionModules objectAtIndex:index];
		[moduleToClose becomeInactiveModule];
		
		[additionWindows replaceObjectAtIndex:index withObject:[NSNull null]];
	
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

- (NSSize)windowWillResize:(NSWindow *)window toSize:(NSSize)newSize
{
	if(window == [self window])
	{
		NSSize currentSize = [window frame].size;
		
		NSSize resizeDifference = NSMakeSize(newSize.width - currentSize.width, newSize.height - currentSize.height);
		
		id<XMMainWindowModule> module = [mainModules objectAtIndex:activeMainModuleIndex];
		
		int minimumHeight = 0;
		resizeDifference = [module adjustResizeDifference:resizeDifference minimumHeight:minimumHeight];
		
		currentSize.width += resizeDifference.width;
		currentSize.height += resizeDifference.height+20;
		
		newSize = currentSize;
	}
	
	return newSize;
}	

#pragma mark Private Methods

- (void)_additionButtonAction:(id)sender
{
	unsigned index = (unsigned)[sender tag];
	
	[self _showAdditionModuleAtIndex:index deactivatePreviousModule:YES];
}

- (void)_showNoCallModule:(id<XMMainWindowModule>)m
{
	id<XMMainWindowModule> module;
	// fetching the relevant data
	if (!m)
		 module = [mainModules objectAtIndex:0];
	else
		module = m;
	// resizing the window
	[mainContentBox setContentView:nil];
	[mainContentBox setContentView:[module contentView]];
}

- (void)_showMainModuleAtIndex:(unsigned)index
{
	if(index == activeMainModuleIndex)
	{
		return;
	}
	
	if (selfViewShown){
		[self showSelfView:self]; //close it
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
	NSSize currentMainContentSize = [mainContentBox frame].size;
	NSSize newMainContentSize = [module contentViewSize];
	NSSize newMainContentMinSize = [module contentViewMinSize];
	NSSize newMainContentMaxSize = [module contentViewMaxSize];

	
	NSWindow *window = [self window];
	NSRect windowFrame = [window frame];

	// setting the new height of the window
	int newHeight = newMainContentSize.height;
	int heightDifference = newHeight - (int)currentMainContentSize.height;
		
	windowFrame.origin.y -= heightDifference;
	windowFrame.size.height += heightDifference;

	// setting the new width of the window
	int widthDifference = (int)newMainContentSize.width - (int)currentMainContentSize.width;
	windowFrame.size.width += widthDifference;

	// resizing the window
	[mainContentBox setContentView:nil];
	[window setFrame:windowFrame display:YES animate:YES];
	[module becomeActiveModule];
	[mainContentBox setContentView:[module contentView]];
	
	// setting the correct minSize values
	NSSize minSize = windowFrame.size;
	int newMinHeight = newMainContentMinSize.height;
	heightDifference = newHeight - newMinHeight;
	widthDifference = (int)newMainContentSize.width - (int)newMainContentMinSize.width;
	minSize.height -= heightDifference;
	minSize.width -= widthDifference;
	[window setMinSize:minSize];
	
	// setting the correct maxSize values
	NSSize maxSize = windowFrame.size;
	int newMaxHeight = newMainContentMaxSize.height;
	heightDifference = newMaxHeight - newHeight;
	widthDifference = (int)newMainContentMaxSize.width - (int)newMainContentSize.width;
	maxSize.height += heightDifference;
	maxSize.width += widthDifference;
	[window setMaxSize:maxSize];
	
	// displaying the resize indicator if needed
	BOOL windowIsResizable = ((minSize.width != maxSize.width) || (minSize.height != maxSize.height));
	[window setShowsResizeIndicator:windowIsResizable];
}

- (void)_showSupportModuleAtIndex:(unsigned)index
{
//	if(index == activeSupportModuleIndex)
//	{
//		return;
//	}
//	
//	// deactivating the old module
//	if(activeSupportModuleIndex != UINT_MAX)
//	{
//		id<XMMainWindowSupportModule> oldModule = [supportModules objectAtIndex:activeSupportModuleIndex];
//		[oldModule becomeInactiveModule];
//	}
//	
//	activeSupportModuleIndex = index;
//	
//	// fetching the relevant data
//	id<XMMainWindowSupportModule> module = [supportModules objectAtIndex:activeSupportModuleIndex];
//	NSSize currentSupportContentSize = [rightContentBox bounds].size;
//	NSSize newSupportContentSize = [module contentViewSize];
//	int mainContentHeight;
//	if(activeMainModuleIndex != UINT_MAX)
//	{
//		id<XMMainWindowModule> mainModule = [mainModules objectAtIndex:activeMainModuleIndex];
//		mainContentHeight = [mainModule contentViewSize].height;
//	}
//	else
//	{
//		mainContentHeight = 0;
//	}
//	NSWindow *window = localVideoWindow;
//	NSRect windowFrame = [window frame];
//	
//	// setting the new height of the window frame
//	int newHeight = ((mainContentHeight > (int)newSupportContentSize.height) ? mainContentHeight : newSupportContentSize.height);
//	int heightDifference = newHeight - (int)currentSupportContentSize.height;
//	windowFrame.origin.y -= heightDifference;
//	windowFrame.size.height += heightDifference;
//	
//	// setting the new width of the window frame
//	int widthDifference = (int)newSupportContentSize.width - (int)currentSupportContentSize.width;
//	windowFrame.size.width += widthDifference;
//	
//	// changing the autoresizing mask before this resize operation
//	//[mainContentBox setAutoresizingMask:(NSViewMaxXMargin | NSViewHeightSizable)];
//	//[rightContentBox setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
//
//	// resizing the window
//	[rightContentBox setContentView:nil];
//	[window setFrame:windowFrame display:YES animate:YES];
//	[module becomeActiveModule];
//	[rightContentBox setContentView:[module contentView]];
//	
//	// restoring the autoresizing mask
//	//[mainContentBox setAutoresizingMask:(NSViewHeightSizable | NSViewWidthSizable)];
//	//[rightContentBox setAutoresizingMask:(NSViewMinXMargin | NSViewHeightSizable)];
//
//	// adjusting the min size of the window
//	NSSize minSize = [window minSize];
//	minSize.height += heightDifference;
//	minSize.width += widthDifference;
//	[window setMinSize:minSize];
//	
//	// adjusting the max size of the window
//	NSSize maxSize = [window maxSize];
//	maxSize.height += heightDifference;
//	maxSize.width += widthDifference;
//	[window setMaxSize:maxSize];
}

- (void)_showAdditionModuleAtIndex:(unsigned)index deactivatePreviousModule:(BOOL)deactivateFlag
{
	// check if this module isn't already displayed in a separate window,
	// moving this window to the front if needed
	if(index != UINT_MAX)
	{
		NSWindow *window = [additionWindows objectAtIndex:index];
		
		if((id)window != (id)[NSNull null])
		{
			[window makeKeyAndOrderFront:self];
			return;
		}
	}
	
	// deactivating the old module
	if(activeAdditionModuleIndex != UINT_MAX)
	{
		if(deactivateFlag == YES)
		{
			id<XMMainWindowAdditionModule> oldModule = [additionModules objectAtIndex:activeAdditionModuleIndex];
			[oldModule becomeInactiveModule];
		}
	}
	
	// fetching the relevant data
	id<XMMainWindowAdditionModule> module;
	int newAdditionContentHeight;
	NSView *contentView;
	
	if(index != UINT_MAX)
	{
		module = [additionModules objectAtIndex:index];
		contentView = [module contentView];
		
		[module becomeActiveModule];
		activeAdditionModuleIndex = index;
	}
	else
	{
		module = nil;
		newAdditionContentHeight = 0;
		contentView = nil;
	}
	

	if (module != nil){
		NSRect mainRect = [[self window] frame];
		NSWindow *additionWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(mainRect.origin.x, mainRect.origin.y,10,100) styleMask:NSTitledWindowMask|NSResizableWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask backing:NSBackingStoreBuffered defer:NO];
		[additionWindow setContentView:contentView];
		NSRect frame = [additionWindow frame];
		NSSize moduleSize = [module contentViewSize];
		moduleSize.width += 20;
		moduleSize.height += 28;
		frame.size = moduleSize;
		[additionWindow setFrame:frame display:NO];
		[additionWindow setMinSize:moduleSize];
		[additionWindow setReleasedWhenClosed:YES];
		[additionWindow setTitle:@"AddressBook"];
		
		[additionWindows insertObject:additionWindow atIndex:index];
		[additionWindow makeKeyAndOrderFront:self];
		
		//[additionWindow release];
		//[NSApp beginSheet:additionWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
	}

	
}

- (void)_showSeparateWindowWithAdditionModuleAtIndex:(unsigned)index
{
	id<XMMainWindowAdditionModule> module = (id<XMMainWindowAdditionModule>)[additionModules objectAtIndex:index];
	NSView *contentView = [module contentView];
	NSSize contentSize = [module contentViewSize];
	NSRect contentRect = NSMakeRect(0, 0, contentSize.width, contentSize.height);
	
	// RMF Changed  AddressBook, and Log & Call history separate windows to be resizable.. 
	//  call stats should not beresizable. Other module not resizeable? 
	unsigned int mask = (NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask);
	if([module isResizableWhenInSeparateWindow])
	{
		mask |= NSResizableWindowMask;
	}
	
	NSWindow *separateWindow = [[NSWindow alloc] initWithContentRect:contentRect
														   styleMask:mask
															 backing:NSBackingStoreBuffered
															   defer:NO];
	
	[separateWindow setContentMinSize:contentSize];	// RMF: don't allow resize smaller then default view size.
	
	[separateWindow setTitle:[module name]];
	[separateWindow setContentView:contentView];
	
	NSString *windowSaveName = [[NSString alloc] initWithFormat:XMKey_WindowSaveNameFormat, [module name]];
	if(![separateWindow setFrameUsingName:windowSaveName force:YES])
	{
		[separateWindow center];
		[separateWindow saveFrameUsingName:windowSaveName];
	}
	else
	{
		// in case the window size did change since the last save, update width and height again
		[separateWindow setContentSize:contentSize];
	}
	[separateWindow setDelegate:self];
	[additionWindows replaceObjectAtIndex:index withObject:separateWindow];
	
	[separateWindow makeKeyAndOrderFront:self];
	
}

@end
