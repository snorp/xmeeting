/*
 * $Id: XMPreferencesWindowController.m,v 1.18 2009/01/11 17:21:48 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#import "XMPreferencesWindowController.h"
#import "XMPreferencesManager.h"
#import "XMPreferencesModule.h"

#import "XMLocationPreferencesModule.h"

#import "XMSetupAssistantManager.h"

NSString *XMKey_PreferencesNibName = @"Preferences";
NSString *XMKey_PreferencesToolbar = @"XMeeting_PreferencesToolbar";
NSString *XMKey_SimpleViewToolbarItemIdentifier = @"XMeeting_SimpleViewToolbarItemIdentifier";
NSString *XMKey_ButtonToolbarItemIdentifier = @"XMeeting_ButtonToolbarItemIdentifier";
NSString *XMKey_PreferencesWindowTopLeftCorner = @"XMeeting_PreferencesWindowTopLeftCorner";
NSString *XMKey_PreferencesEditMode = @"XMeeting_PreferencesEditMode";

enum {
  XMPreferencesEditMode_Simple = 0,
  XMPreferencesEditMode_Detailed = 1,
};

@interface XMPreferencesWindowController (PrivateMethods)

- (id)_init;

  // toolbar delegate methods
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar;
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar;
- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar;

  // misc
- (BOOL)_validateCurrentModule;
- (void)_resizeWindowToSize:(NSSize)newSize contentView:(NSView *)newContentView;
- (void)_alertUnsavedChanges:(SEL)endSelector;
- (void)savePreferencesAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)switchDiscardChangesAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)simpleViewDiscardChangesAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;

@end

@implementation XMPreferencesWindowController

#pragma mark -
#pragma mark Init & Deallocation Methods

+ (XMPreferencesWindowController *)sharedInstance
{
  static XMPreferencesWindowController *sharedInstance = nil;
  
  if (sharedInstance == nil) {
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
  [toolbar release];
  [identifiers release];
  [toolbarItems release];
  [emptyContentView release];
  
  [super dealloc];
}

- (void)windowDidLoad
{
  NSWindow *window = [self window];
  
  // creating the simple view toolbar item
  simpleViewToolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:XMKey_SimpleViewToolbarItemIdentifier];
  [simpleViewToolbarItem setLabel:NSLocalizedString(@"XM_PREFERENCES_SIMPLE_VIEW", @"")];
  [simpleViewToolbarItem setImage:[NSImage imageNamed:@"XMeeting"]];
  [simpleViewToolbarItem setToolTip:NSLocalizedString(@"XM_PREFERENCES_SIMPLE_VIEW", @"")];
  [simpleViewToolbarItem setTarget:self];
  [simpleViewToolbarItem setAction:@selector(switchToSimpleView:)];
  
  // creating the ButtonToolbarItem
  buttonToolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:XMKey_ButtonToolbarItemIdentifier];
  [buttonToolbarItem setView:buttonToolbarView];
  NSSize size = [buttonToolbarView bounds].size;
  [buttonToolbarItem setMinSize:size];
  [buttonToolbarItem setMaxSize:size];
  
  // adding some additional items to the toolbar
  [identifiers insertObject:XMKey_SimpleViewToolbarItemIdentifier atIndex:0];
  [identifiers insertObject:NSToolbarSeparatorItemIdentifier atIndex:1];
  [identifiers addObject:NSToolbarFlexibleSpaceItemIdentifier];
  [identifiers addObject:NSToolbarSeparatorItemIdentifier];
  [identifiers addObject:XMKey_ButtonToolbarItemIdentifier];
  
  // Setting up the toolbar
  toolbar = [[NSToolbar alloc] initWithIdentifier:XMKey_PreferencesToolbar];
  [toolbar setAllowsUserCustomization:NO];
  [toolbar setAutosavesConfiguration:NO];
  [toolbar setDelegate:self];
  
  // putting the first module on screen 
  currentSelectedItem = [toolbarItems objectAtIndex:0];
  [toolbar setSelectedItemIdentifier:(NSString *)[identifiers objectAtIndex:0]];
  id<XMPreferencesModule> module = [modules objectAtIndex:0];
  [window setContentView:[module contentView]];
  float windowWidth = [window frame].size.width;
  [window setContentSize:NSMakeSize(windowWidth, [module contentViewHeight])];
  
  // linking the toolbar to the window
  [window setToolbar:toolbar];
  [window setShowsToolbarButton:NO];
  
  // disable making the apply button in the toolbar
  [applyButton setEnabled:NO];
  
  // store the initial window width
  initialWidth = [[window contentView] bounds].size.width;
}

#pragma mark -
#pragma mark Public Methods

- (void)showPreferencesWindow
{
  NSWindow *window = [self window];
  
  // prepare window content if window is not visible
  if (![window isVisible]) {
    
    unsigned editMode = [[NSUserDefaults standardUserDefaults] integerForKey:XMKey_PreferencesEditMode];
    
    if (editMode == XMPreferencesEditMode_Simple) {
      XMSetupAssistantManager *setupAssistantManager = [XMSetupAssistantManager sharedInstance];
      
      [toolbar setVisible:NO];
      
      [window setContentView:emptyContentView];
      [window setContentSize:[setupAssistantManager contentViewSize]];
      
      [window setDocumentEdited:NO];
      preferencesHaveChanged = NO;
      
      [setupAssistantManager runEditAssistantInWindow:window];
      
    } else {
      // each module has to reload its data so that the values are consistent
      unsigned count = [modules count];
      for (unsigned i = 0; i < count; i++) {
        id<XMPreferencesModule> module = (id<XMPreferencesModule>)[modules objectAtIndex:i];
        [module loadPreferences];
        
        if (i == 0) {
          [[window toolbar] setSelectedItemIdentifier:[module identifier]];
        }
      }
      
      // show first module
      [self toolbarItemAction:[toolbarItems objectAtIndex:0]];
      
      [applyButton setEnabled:NO];
      [[self window] setDocumentEdited:NO];
      preferencesHaveChanged = NO;
    }
    
    NSString *windowTopLeftCornerString = [[NSUserDefaults standardUserDefaults] stringForKey:XMKey_PreferencesWindowTopLeftCorner];
    if (windowTopLeftCornerString != nil) {
      NSPoint windowTopLeftCorner = NSPointFromString(windowTopLeftCornerString);
      NSRect windowFrame = [window frame];
      windowFrame.origin = windowTopLeftCorner;
      windowFrame.origin.y -= windowFrame.size.height;
      [window setFrame:windowFrame display:NO];
    } else {
      [window center];
    }
  }
  
  [self showWindow:self];
}

- (void)closePreferencesWindow
{
  if ([self isWindowLoaded] == NO) {
    return;
  }
  
  if ([[self window] isVisible] && preferencesHaveChanged) {
    /* We first ask the user whether he wants to save the changes made */
    NSAlert *alert = [[NSAlert alloc] init];
    
    [alert setMessageText:NSLocalizedString(@"XM_PREFERENCES_WINDOW_CLOSE", @"")];
    
    [alert addButtonWithTitle:NSLocalizedString(@"Save", @"")];
    [alert addButtonWithTitle:NSLocalizedString(@"Don't Save", @"")];
    
    int result = [alert runModal];
    if (result == NSAlertFirstButtonReturn) {
      if (![self _validateCurrentModule]) {
        return;
      }
      [self applyPreferences:self];
    }
  }
  
  [[self window] orderOut:self];
}

#pragma mark -
#pragma mark Methods for XMPreferencesModules

- (void)notePreferencesDidChange
{
  if (!preferencesHaveChanged) {
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
  unsigned i;
  unsigned count = [modules count];
  unsigned position = [module position];
  for (i = 0; i < count; i++) {
    id<XMPreferencesModule> theModule = (id<XMPreferencesModule>)[modules objectAtIndex:i];
    if ([theModule position] >= position) {
      break;
    }
  }
  
  [modules insertObject:module atIndex:i];
  [identifiers insertObject:identifier atIndex:i];
  [toolbarItems insertObject:toolbarItem atIndex:i];
  
  [toolbarItem release];
}

#pragma mark -
#pragma mark Toolbar Delegate Methods

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
  if ([itemIdentifier isEqualToString:XMKey_SimpleViewToolbarItemIdentifier]) {
    return simpleViewToolbarItem;
  }
  if ([itemIdentifier isEqualToString:XMKey_ButtonToolbarItemIdentifier]) {
    return buttonToolbarItem;
  }
  
  unsigned index = [identifiers indexOfObject:itemIdentifier];
  if (index != NSNotFound) {
    return (NSToolbarItem *)[toolbarItems objectAtIndex:index-2]; // index zero is simple view item, index one is separator
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

#pragma mark -
#pragma mark Interface Action Methods

- (IBAction)toolbarItemAction:(NSToolbarItem *)item
{
  if (item == currentSelectedItem) {
    return;
  }
  
  // if module rejects validation, remain in module
  if (![self _validateCurrentModule]) {
    return;
  }
  
  NSString *identifier = [item itemIdentifier];
  
  unsigned index = [identifiers indexOfObject:identifier];
  if (index != NSNotFound) {
    NSWindow *window = [self window];
    id<XMPreferencesModule> module = (id<XMPreferencesModule>)[modules objectAtIndex:index-2];
    NSView *contentView = [module contentView];
    
    // resize the window
    NSSize newSize = [[window contentView] bounds].size;
    newSize.height = [module contentViewHeight];
    [self _resizeWindowToSize:newSize contentView:contentView];
    
    [module becomeActiveModule];
    
    currentSelectedItem = item;
  }
}

- (IBAction)switchToSimpleView:(id)sender
{
  // ask the user before discarding unsaved changes
  if (preferencesHaveChanged) {
    [self _alertUnsavedChanges:@selector(switchDiscardChangesAlertDidEnd:returnCode:contextInfo:)];
    return;
  }
  
  NSWindow *window = [self window];
  XMSetupAssistantManager *setupAssistantManager = [XMSetupAssistantManager sharedInstance];
  
  // resize the window, hide the toolbar
  [self _resizeWindowToSize:[setupAssistantManager contentViewSize] contentView:emptyContentView];
  [window setDocumentEdited:NO];
  [toolbar setVisible:NO];
  
  // run the setup assistant in this window
  [setupAssistantManager runEditAssistantInWindow:window];
  
  // store state in user defaults
  [[NSUserDefaults standardUserDefaults] setInteger:XMPreferencesEditMode_Simple forKey:XMKey_PreferencesEditMode];
}

- (IBAction)switchToDetailedView:(id)sender
{
  // ask the user before discarding unsaved changes
  if (preferencesHaveChanged) {
    [self _alertUnsavedChanges:@selector(switchDiscardChangesAlertDidEnd:returnCode:contextInfo:)];
    return;
  }
  
  NSWindow *window = [self window];
  
  // cause each module to reload its data so that the values are consistent
  unsigned count = [modules count];
  for (unsigned i = 0; i < count; i++) {
    id<XMPreferencesModule> module = (id<XMPreferencesModule>)[modules objectAtIndex:i];
    [module loadPreferences];
  }
  
  [applyButton setEnabled:NO];
  [window setDocumentEdited:NO];
  preferencesHaveChanged = NO;
  
  id<XMPreferencesModule> module = (id<XMPreferencesModule>)[modules objectAtIndex:0];
  [toolbar setSelectedItemIdentifier:[module identifier]];
  currentSelectedItem = [toolbarItems objectAtIndex:0];
  
  // show the toolbar again
  [window setContentView:emptyContentView];
  [toolbar setVisible:YES];
  
  // resize the window
  NSSize newSize = NSMakeSize(initialWidth, [module contentViewHeight]);
  [self _resizeWindowToSize:newSize contentView:[module contentView]];
  
  [module becomeActiveModule];
  
  // store state in user defaults
  [[NSUserDefaults standardUserDefaults] setInteger:XMPreferencesEditMode_Detailed forKey:XMKey_PreferencesEditMode];
}

- (IBAction)applyPreferences:(id)sender
{
  if (![self _validateCurrentModule]) {
    return;
  }
  
  // Ensure that the locations module is the last one to store it's preferences
  // to preserve location data integrity
  id<XMPreferencesModule> locationsModule = nil;
  
  unsigned count = [modules count]; 
  for (unsigned i = 0; i < count; i++) {
    id<XMPreferencesModule> module = (id<XMPreferencesModule>)[modules objectAtIndex:i];
    if ([[module identifier] isEqualToString:XMKey_LocationPreferencesModuleIdentifier]) {
      locationsModule = module; // The locations have to be saved last
    } else {
      [module savePreferences];
    }
  }
  [locationsModule savePreferences];
  
  [applyButton setEnabled:NO];
  [[self window] setDocumentEdited:NO];
  preferencesHaveChanged = NO;
  
  // finally tell XMPreferencesManager that to save the new preferences and post any notification required
  [[XMPreferencesManager sharedInstance] synchronizeAndNotify];
}

#pragma mark -
#pragma mark Window Delegate Methods

- (BOOL)windowShouldClose:(id)sender
{
  // special handling if in simple edit mode
  if ([[NSUserDefaults standardUserDefaults] integerForKey:XMKey_PreferencesEditMode] == XMPreferencesEditMode_Simple) {
    if (preferencesHaveChanged) {
      [self _alertUnsavedChanges:@selector(simpleViewDiscardChangesAlertDidEnd:returnCode:contextInfo:)];
      return NO;
    }
    return YES;
  }
  if (preferencesHaveChanged) {
    /* We first ask the user whether he wants to save the changes made */
    NSAlert *alert = [[NSAlert alloc] init];
    
    [alert setMessageText:NSLocalizedString(@"XM_PREFERENCES_WINDOW_CLOSE", @"")];
    
    [alert addButtonWithTitle:NSLocalizedString(@"Save", @"")];
    [alert addButtonWithTitle:NSLocalizedString(@"Abort", @"")];
    [alert addButtonWithTitle:NSLocalizedString(@"Don't Save", @"")];
    
    [alert beginSheetModalForWindow:[self window] 
                      modalDelegate:self 
                     didEndSelector:@selector(savePreferencesAlertDidEnd:returnCode:contextInfo:)
                        contextInfo:NULL];
    return NO;
  }
  
  return YES;
}

- (void)windowWillClose:(NSNotification *)aNotification
{
  /* storing the preference window's top left corner */
  NSRect windowFrame = [[self window] frame];
  NSPoint topLeftWindowCorner = windowFrame.origin;
  topLeftWindowCorner.y += windowFrame.size.height;
  NSString *topLeftWindowCornerString = NSStringFromPoint(topLeftWindowCorner);
  [[NSUserDefaults standardUserDefaults] setObject:topLeftWindowCornerString forKey:XMKey_PreferencesWindowTopLeftCorner];
}

- (BOOL)_validateCurrentModule
{
  // ensure the old item's integrity
  if (currentSelectedItem != nil) {
    unsigned index = [identifiers indexOfObject:[currentSelectedItem itemIdentifier]];
    if (index != NSNotFound) { // should not happen
      id<XMPreferencesModule> module = (id<XMPreferencesModule>)[modules objectAtIndex:index-2];
      if (![module validateData]) { // module rejected changes, don't change anything.
        [toolbar setSelectedItemIdentifier:[currentSelectedItem itemIdentifier]];
        return NO;
      }
    }
  }
  return YES;
}

- (void)_resizeWindowToSize:(NSSize)newSize contentView:(NSView *)newContentView
{
  NSWindow *window = [self window];
  NSRect windowFrame = [window frame];
  NSSize oldSize = [[window contentView] bounds].size;
  float widthDifference = (newSize.width - oldSize.width);
  float heightDifference = (newSize.height - oldSize.height);
  windowFrame.size.width = windowFrame.size.width + widthDifference;
  windowFrame.origin.y = windowFrame.origin.y - heightDifference;
  windowFrame.size.height = windowFrame.size.height + heightDifference;
  
  [window setContentView:emptyContentView];
  [window setFrame:windowFrame display:YES animate:YES];
  [window setContentView:newContentView];
}

- (void)_alertUnsavedChanges:(SEL)endSelector
{
  NSAlert *alert = [[NSAlert alloc] init];
  
  [alert setMessageText:NSLocalizedString(@"XM_PREFERENCES_UNSAVED_CHANGES", @"")];
  [alert setInformativeText:@""];
  [alert setAlertStyle:NSWarningAlertStyle];
  [alert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
  [alert addButtonWithTitle:NSLocalizedString(@"Abort", @"")];
  
  [alert beginSheetModalForWindow:[self window] 
                    modalDelegate:self 
                   didEndSelector:endSelector
                      contextInfo:NULL];
}

#pragma mark -
#pragma mark ModalDelegate Methods

- (void)savePreferencesAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
  // memory cleanup
  [alert release];
  
  if (returnCode == NSAlertSecondButtonReturn) { //Abort
    return;
  }
  
  if (returnCode == NSAlertFirstButtonReturn) { // save the preferences
    if (![self _validateCurrentModule]) { // abort
      return;
    }
    // causing the system to save all preferences
    [self applyPreferences:self];
  }
  
  // closing the window
  [[self window] orderOut:self];
}

- (void)switchDiscardChangesAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
  // memory cleanup
  [alert release];
  
  if (returnCode == NSAlertSecondButtonReturn) { // Abort
    [toolbar setSelectedItemIdentifier:[currentSelectedItem itemIdentifier]];
    return;
  }
    
  if (returnCode == NSAlertFirstButtonReturn) { // discard the preferences
    preferencesHaveChanged = NO;
    
    // if in simple mode, simply close the window. Else switch to simple view
    if ([[NSUserDefaults standardUserDefaults] integerForKey:XMKey_PreferencesEditMode] == XMPreferencesEditMode_Simple) {
      [self performSelector:@selector(switchToDetailedView:) withObject:self afterDelay:0.0];
    } else {
      [self performSelector:@selector(switchToSimpleView:) withObject:self afterDelay:0.0];
    }
  }
}

- (void)simpleViewDiscardChangesAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
  // memory cleanup
  [alert release];
  
  if (returnCode == NSAlertSecondButtonReturn) { // Abort
    return;
  }
  
  if (returnCode == NSAlertFirstButtonReturn) { // discard the preferences
    preferencesHaveChanged = NO;
    
    [[self window] performSelector:@selector(performClose:) withObject:self afterDelay:0.0];
  }
}

@end
