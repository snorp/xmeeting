/*
 * $Id: XMPreferencesWindowController.m,v 1.1 2005/04/28 20:26:27 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMPreferencesWindowController.h"
#import "XMPreferencesManager.h"
#import "XMPreferencesModule.h"

NSString *XMKey_PreferencesNibName = @"Preferences";
NSString *XMKey_PreferencesToolbar = @"XMeeting_PreferencesToolbar";
NSString *XMKey_ButtonToolbarItemIdentifier = @"XMeeting_ButtonToolbarItemIdentifier";

@interface XMPreferencesWindowController (PrivateMethods)

- (id)_init;

// toolbar delegate methods
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar 
	 itemForItemIdentifier:(NSString *)itemIdentifier 
 willBeInsertedIntoToolbar:(BOOL)flag;
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar;
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar;
- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar;

// action method for the toolbar items
- (IBAction)toolbarItemAction:(NSToolbarItem *)sender;
- (IBAction)revertPreferences:(NSButton *)sender;
- (IBAction)applyPreferences:(id)sender;

// modal sheets modal delegate methods
- (void)savePreferencesAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;

@end

@implementation XMPreferencesWindowController

#pragma mark General Methods

+ (XMPreferencesWindowController *)sharedInstance
{
	static XMPreferencesWindowController *sharedInstance = nil;
	
	if(sharedInstance == nil)
	{
		sharedInstance = [[XMPreferencesWindowController alloc] _init];
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
	self = [super initWithWindowNibName:XMKey_PreferencesNibName owner:self];
	emptyContentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
	
	modules = [[NSMutableArray alloc] initWithCapacity:3];
	identifiers = [[NSMutableArray alloc] initWithCapacity:3];
	toolbarItems = [[NSMutableArray alloc] initWithCapacity:3];
	currentSelectedItem = nil;
	
	return self;
}

- (void)dealloc
{
	[modules release];
	[identifiers release];
	[toolbarItems release];
	[emptyContentView release];
	
	[super dealloc];
}

- (void)windowDidLoad
{
	NSWindow *window = [self window];
	
	// creating the ButtonToolbarItem
	buttonToolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:XMKey_ButtonToolbarItemIdentifier];
	[buttonToolbarItem setView:buttonToolbarView];
	NSSize size = [buttonToolbarView bounds].size;
	[buttonToolbarItem setMinSize:size];
	[buttonToolbarItem setMaxSize:size];
	//[buttonToolbarItem setLabel:NSLocalizedString(@"Edit Preferences", @"ButtonToolbarItemLabel")];
	
	// adding some additional items to the toolbar
	[identifiers addObject:NSToolbarFlexibleSpaceItemIdentifier];
	[identifiers addObject:NSToolbarSeparatorItemIdentifier];
	[identifiers addObject:XMKey_ButtonToolbarItemIdentifier];
	
	
	/* Now, setting up the toolbar */
	NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:XMKey_PreferencesToolbar];
	[toolbar setAllowsUserCustomization:NO];
	[toolbar setAutosavesConfiguration:NO];
	[toolbar setDelegate:self];
	
	/* putting the first module on screen */
	currentSelectedItem = [toolbarItems objectAtIndex:0];
	[toolbar setSelectedItemIdentifier:(NSString *)[identifiers objectAtIndex:0]];
	id<XMPreferencesModule> module = [modules objectAtIndex:0];
	currentSelectedItemHeight = [module contentViewHeight];
	[window setContentView:[module contentView]];
	float windowWidth = [window frame].size.width;
	[window setContentSize:NSMakeSize(windowWidth, currentSelectedItemHeight)];
	
	/* linking the toolbar to the window */
	[window setToolbar:toolbar];
	[toolbar release];
	
	/* making the two buttons in the toolbar disabled */
	[revertButton setEnabled:NO];
	[applyButton setEnabled:NO];
}

- (void)showPreferencesWindow
{
	NSWindow *window = [self window];
	
	/* we always center the preferences window when displaying the preferences anew */
	if(![window isVisible])
	{
		// we cause each module to reload its data so that the values are consistent
		unsigned count = [modules count];
		unsigned i;
		
		for(i = 0; i < count; i++)
		{
			id<XMPreferencesModule> module = (id<XMPreferencesModule>)[modules objectAtIndex:i];
			[module loadPreferences];
		}
		[revertButton setEnabled:NO];
		[applyButton setEnabled:NO];
		[[self window] setDocumentEdited:NO];
		preferencesHaveChanged = NO;
		
		[window center];
	}
	
	[self showWindow:self];
}

#pragma mark Methods for XMPreferencesModules

- (void)notePreferencesDidChange
{
	if(!preferencesHaveChanged)
	{
		[revertButton setEnabled:YES];
		[applyButton setEnabled:YES];
		[[self window] setDocumentEdited:YES];
		preferencesHaveChanged = YES;
	}
}

- (void)addPreferencesModule:(id<XMPreferencesModule>)module
{	
	NSString *identifier = [module identifier];
	NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];
	
	[toolbarItem setLabel:[module toolbarLabel]];
	[toolbarItem setImage:[module toolbarImage]];
	[toolbarItem setToolTip:[module toolTipText]];
	[toolbarItem setTarget:self];
	[toolbarItem setAction:@selector(toolbarItemAction:)];
	
	// iterating over all existing modules, inserting the new module at the correct place
	unsigned count = [modules count];
	unsigned i;
	unsigned position = [module position];
	
	for(i = 0; i < count; i++)
	{
		id<XMPreferencesModule> theModule = (id<XMPreferencesModule>)[modules objectAtIndex:i];
		if([theModule position] >= position)
		{
			break;
		}
	}
	
	[modules insertObject:module atIndex:i];
	[identifiers insertObject:identifier atIndex:i];
	[toolbarItems insertObject:toolbarItem atIndex:i];
	
	[toolbarItem release];
}

#pragma mark Toolbar Delegate Methods

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar 
	 itemForItemIdentifier:(NSString *)itemIdentifier 
 willBeInsertedIntoToolbar:(BOOL)flag
{
	if([itemIdentifier isEqualToString:XMKey_ButtonToolbarItemIdentifier])
	{
		return buttonToolbarItem;
	}
	
	unsigned index = [identifiers indexOfObject:itemIdentifier];
	
	if(index != NSNotFound)
	{
		return (NSToolbarItem *)[toolbarItems objectAtIndex:index];
	}
	
	return nil;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	return identifiers;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	return identifiers;
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
	return identifiers;
}

#pragma mark Interface Action Methods

- (IBAction)toolbarItemAction:(NSToolbarItem *)item
{
	if(item == currentSelectedItem)
	{
		return;
	}
	
	NSString *identifier = [item itemIdentifier];
	
	unsigned index = [identifiers indexOfObject:identifier];
	
	if(index != NSNotFound)
	{
		NSWindow *window = [self window];
		id<XMPreferencesModule> module = (id<XMPreferencesModule>)[modules objectAtIndex:index];
		NSView *contentView = [module contentView];
		
		// adjusting the window's height
		NSRect windowFrame = [window frame];
		float newHeight = [module contentViewHeight];
		float heightDifference = (newHeight - currentSelectedItemHeight);
		windowFrame.origin.y = windowFrame.origin.y - heightDifference;
		windowFrame.size.height = windowFrame.size.height + heightDifference;
		
		// removing the old view, then changing size, refresh the new view and finally adding the new content view
		[window setContentView:emptyContentView];
		[window setFrame:windowFrame display:YES animate:YES];
		[window setContentView:contentView];
		
		currentSelectedItem = item;
		currentSelectedItemHeight = newHeight;
	}
}

- (IBAction)revertPreferences:(NSButton *)sender
{
	unsigned count = [modules count];
	unsigned i;
	
	for(i = 0; i < count; i++)
	{
		id<XMPreferencesModule> module = (id<XMPreferencesModule>)[modules objectAtIndex:i];
		[module revertPreferences];
	}
	
	[revertButton setEnabled:NO];
	[applyButton setEnabled:NO];
	[[self window] setDocumentEdited:NO];
	preferencesHaveChanged = NO;
}

- (IBAction)applyPreferences:(id)sender
{
	unsigned count = [modules count];
	unsigned i;
	
	for(i = 0; i < count; i++)
	{
		id<XMPreferencesModule> module = (id<XMPreferencesModule>)[modules objectAtIndex:i];
		[module savePreferences];
	}
	
	[revertButton setEnabled:NO];
	[applyButton setEnabled:NO];
	[[self window] setDocumentEdited:NO];
	preferencesHaveChanged = NO;
	
	// finally tell XMPreferencesManager that to save the new preferences and post any notification required
	[[XMPreferencesManager sharedInstance] synchronizeAndNotify];
}

#pragma mark Window Delegate Methods

- (BOOL)windowShouldClose:(id)sender
{
	if(preferencesHaveChanged)
	{
		/* We first ask the user whether he wants to save the changes made */
		NSAlert *alert = [[NSAlert alloc] init];
		
		[alert setMessageText:NSLocalizedString(@"Do you want to save the changes before closing?",
												@"PreferencesWindowCloseAlert")];
		
		[alert addButtonWithTitle:NSLocalizedString(@"Save", @"Save")];
		[alert addButtonWithTitle:NSLocalizedString(@"Abort", @"Abort")];
		[alert addButtonWithTitle:NSLocalizedString(@"Don't Save", @"Don't Save")];
		
		[alert beginSheetModalForWindow:[self window] 
						  modalDelegate:self 
						 didEndSelector:@selector(savePreferencesAlertDidEnd:returnCode:contextInfo:)
							contextInfo:NULL];
		return NO;
	}
	
	return YES;
}

#pragma mark ModalDelegate Methods

- (void)savePreferencesAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if(returnCode == NSAlertSecondButtonReturn) //Abort
	{
		return;
	}
	
	if(returnCode == NSAlertFirstButtonReturn) // save the preferences
	{
		// causing the system to save all preferences
		[self applyPreferences:self];
	}
	
	// closing the window
	[[self window] orderOut:self];
}

@end
