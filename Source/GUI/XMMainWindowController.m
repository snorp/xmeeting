/*
 * $Id: XMMainWindowController.m,v 1.17 2006/05/16 21:33:08 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */


#import "XMMainWindowController.h"

#import "XMWindow.h"

#import "XMLocalVideoView.h"

NSString *XMKey_MainWindowTopLeftCorner = @"XMeeting_MainWindowTopLeftCorner";

@interface XMMainWindowController (PrivateMethods)

- (id)_init;

- (void)windowWillClose:(NSNotification *)notif;

- (void)_showModuleAtIndex:(unsigned)index fullScreen:(BOOL)fullscreen;
- (void)_setMinAndMaxWindowSizes;
- (void)_applicationWillTerminate:(NSNotification *)notif;

- (void)_setupIsFullScreen:(BOOL)flag;

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
	
	modules = nil;
	
	activeModuleIndex = UINT_MAX;
	
	selfViewShown = NO;
	
	fullScreenWindow = nil;
	isFullScreen = NO;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationWillTerminate:)
												 name:NSApplicationWillTerminateNotification object:nil];
	
	return self;
}

- (void)dealloc
{
	[modules release];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	/* making sure that the gui looks properly when displayed the first time */
	if([modules count] != 0)
	{
		[self _showModuleAtIndex:0 fullScreen:NO];
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

- (BOOL)beginFullScreen
{
	[self _showModuleAtIndex:activeModuleIndex fullScreen:YES];
	
	return isFullScreen;
}

- (void)endFullScreen
{
	[self _showModuleAtIndex:activeModuleIndex fullScreen:NO];
}

- (BOOL)isFullScreen
{
	return isFullScreen;
}

#pragma mark Module Methods

- (void)setModules:(NSArray *)theModules
{
	modules = [theModules copy];
}

- (void)showModule:(id<XMMainWindowModule>)module fullScreen:(BOOL)fullScreen
{
	unsigned index = [modules indexOfObject:module];
	
	if(index == NSNotFound)
	{
		return;
	}
	[self _showModuleAtIndex:index fullScreen:fullScreen];
}

- (id<XMMainWindowModule>)activeModule
{
	if(activeModuleIndex != UINT_MAX)
	{
		return (id<XMMainWindowModule>)[modules objectAtIndex:activeModuleIndex];
	}
	return nil;
}

- (void)noteSizeValuesDidChangeOfModule:(id<XMMainWindowModule>)module
{
	id<XMMainWindowModule> activeModule = [modules objectAtIndex:activeModuleIndex];
	
	if(activeModule != module)
	{
		return;
	}
	
	// fetching the size values
	NSWindow *window = [self window];
	NSSize currentSize = [[window contentView] frame].size;
	NSSize newSize = [module contentViewSize];
	
	NSRect windowFrame = [window frame];

	// calculating the new height
	int heightDifference = (int)newSize.height - (int)currentSize.height;
	windowFrame.origin.y -= heightDifference;
	windowFrame.size.height += heightDifference;

	// calculating the new width
	int widthDifference = (int)newSize.width - (int)currentSize.width;
	windowFrame.size.width += widthDifference;
	
	// resizing the window
	[window setFrame:windowFrame display:YES animate:YES];
	
	[self _setMinAndMaxWindowSizes];	
}

#pragma mark Action Methods

- (IBAction)showSelfView:(id)sender{
	/*NSRect originalWindowRect = [[self window] frame];
	NSRect newFrame = originalWindowRect;
	
	if (selfView == nil){
		selfView = [[XMLocalVideoView alloc] init];

		float width = originalWindowRect.size.width - 6.0;
		float height = XMGetVideoHeightForWidth(width);
				
		[selfView setFrame:NSMakeRect(0.0, 0.0, width, height)];
		//[selfView setShouldDisplayOSD:NO];
	}

	if (!selfViewShown){
		newFrame.size.height += [selfView frame].size.height;
		newFrame.origin.y -= [selfView frame].size.height;
		[[self window] setFrame:newFrame display:YES animate:YES];	
		[[[self window] contentView] addSubview:selfView];

		NSPoint origin = NSMakePoint((newFrame.size.width - [selfView frame].size.width) / 2.0, [[mainModules objectAtIndex:0] contentViewSize].height + 15.0);
		[selfView setFrameOrigin:origin];
		
		if([[[XMPreferencesManager sharedInstance] activeLocation] enableVideo] == YES)
		{
			[selfView startDisplayingLocalVideo];
		}
	
		selfViewShown = YES;
	}
	else
	{
		[selfView removeFromSuperviewWithoutNeedingDisplay];
		[selfView stopDisplayingLocalVideo];
		newFrame.size.height -= [selfView frame].size.height;
		newFrame.origin.y += [selfView frame].size.height;
		[[self window] setFrame:newFrame display:YES animate:YES];
		selfViewShown = NO;
	}	
	[[self window] setMinSize:NSMakeSize(newFrame.size.width, newFrame.size.height - 20.0)];
	[[self window] setMaxSize:NSMakeSize(newFrame.size.width, newFrame.size.height - 20.0)];
*/
}

#pragma mark NSWindow Delegate Methods

- (BOOL)windowShouldZoom:(NSWindow *)sender toFrame:(NSRect)newFrame
{
	return NO;
}

- (void)windowWillClose:(NSNotification *)notif
{
	[NSApp terminate:self];
}

- (NSSize)windowWillResize:(NSWindow *)window toSize:(NSSize)newSize
{
	NSSize currentSize = [window frame].size;
		
	NSSize resizeDifference = NSMakeSize(newSize.width - currentSize.width, newSize.height - currentSize.height);
		
	id<XMMainWindowModule> module = [modules objectAtIndex:activeModuleIndex];
		
	int minimumHeight = 0;
	resizeDifference = [module adjustResizeDifference:resizeDifference minimumHeight:minimumHeight];
		
	currentSize.width += resizeDifference.width;
	currentSize.height += resizeDifference.height;
		
	newSize = currentSize;
	
	return newSize;
}	

#pragma mark Private Methods

- (void)_showModuleAtIndex:(unsigned)index fullScreen:(BOOL)fullScreenFlag
{
	if(index == activeModuleIndex && isFullScreen == fullScreenFlag)
	{
		return;
	}
	
	// deactivating the old module
	if(activeModuleIndex != UINT_MAX)
	{
		id<XMMainWindowModule> oldModule = [modules objectAtIndex:activeModuleIndex];
		[oldModule becomeInactiveModule];
	}
	
	activeModuleIndex = index;
	
	if(isFullScreen != fullScreenFlag)
	{
		[self _setupIsFullScreen:fullScreenFlag];
	}
	
	id<XMMainWindowModule> module = [modules objectAtIndex:index];
	
	if(isFullScreen == NO)
	{
		NSWindow *window = [self window];
		
		// fetching the relevant data
		NSSize currentContentSize = [[window contentView] frame].size;
		NSSize newContentSize = [module contentViewSize];
		NSRect windowFrame = [window frame];

		// setting the new height of the window
		int newHeight = newContentSize.height;
		int heightDifference = newHeight - (int)currentContentSize.height;
		
		windowFrame.origin.y -= heightDifference;
		windowFrame.size.height += heightDifference;

		// setting the new width of the window
		int widthDifference = (int)newContentSize.width - (int)currentContentSize.width;
		windowFrame.size.width += widthDifference;
		
		// resizing the window
		[window setContentView:nil];
		[window setFrame:windowFrame display:YES animate:YES];
		[window setContentView:[module contentView]];
	}
	else
	{
		NSView *contentView = [module contentView];
		
		[fullScreenWindow setContentView:contentView];
		[fullScreenWindow makeKeyAndOrderFront:self];
	}
	
	[module becomeActiveModule];
	
	if(isFullScreen == NO)
	{
		[self _setMinAndMaxWindowSizes];
	}
}

- (void)_setMinAndMaxWindowSizes
{
	NSWindow *window = [self window];
	NSRect windowFrame = [window frame];
	id<XMMainWindowModule> module = [modules objectAtIndex:activeModuleIndex];
	NSSize currentContentSize = [module contentViewSize];
	NSSize newMinContentSize = [module contentViewMinSize];
	NSSize newMaxContentSize = [module contentViewMaxSize];
	
	// setting the correct minSize values
	NSSize minSize = windowFrame.size;
	int heightDifference = (int)currentContentSize.height - (int)newMinContentSize.height;
	int widthDifference = (int)currentContentSize.width - (int)newMinContentSize.width;
	minSize.height -= heightDifference;
	minSize.width -= widthDifference;
	[window setMinSize:minSize];
	
	// setting the correct maxSize values
	NSSize maxSize = windowFrame.size;
	heightDifference = (int)newMaxContentSize.height - (int)currentContentSize.height;
	widthDifference = (int)newMaxContentSize.width - (int)currentContentSize.width;
	maxSize.height += heightDifference;
	maxSize.width += widthDifference;
	[window setMaxSize:maxSize];
	
	// displaying the resize indicator if needed
	BOOL windowIsResizable = ((minSize.width != maxSize.width) || (minSize.height != maxSize.height));
	[window setShowsResizeIndicator:windowIsResizable];
}

- (void)_applicationWillTerminate:(NSNotification *)notif
{
	// storing the preference window's top left corner
	NSRect windowFrame = [[self window] frame];
	NSPoint topLeftWindowCorner = windowFrame.origin;
	topLeftWindowCorner.y += windowFrame.size.height;
	NSString *topLeftWindowCornerString = NSStringFromPoint(topLeftWindowCorner);
	[[NSUserDefaults standardUserDefaults] setObject:topLeftWindowCornerString
											  forKey:XMKey_MainWindowTopLeftCorner];
}

- (void)_setupIsFullScreen:(BOOL)flag
{
	if(flag == YES)
	{
		unsigned i;
		unsigned count = [modules count];
	
		for(i = 0; i < count; i++)
		{
			id<XMMainWindowModule> module = (id<XMMainWindowModule>)[modules objectAtIndex:i];
			[module beginFullScreen];
		}
	
		if(fullScreenWindow == nil)
		{
			fullScreenWindow = [[XMFullScreenWindow alloc] init];
		}
		
		isFullScreen = YES;
	}
	else
	{
		[fullScreenWindow orderOut:self];
		
		unsigned i;
		unsigned count = [modules count];
		
		for(i = 0; i < count; i++)
		{
			id<XMMainWindowModule> module = (id<XMMainWindowModule>)[modules objectAtIndex:i];
			[module endFullScreen];
		}
		
		isFullScreen = NO;
	}
}

@end
