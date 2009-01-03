/*
 * $Id: XMPreferencesWindowController.h,v 1.10 2009/01/03 20:07:38 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_PREFERENCES_WINDOW_CONTROLLER_H__
#define __XM_PREFERENCES_WINDOW_CONTROLLER_H__

#import <Cocoa/Cocoa.h>

/**
 * The XMPreferencesWindowController singleton class manages the appearance
 * of the preferences window, the associated toolbar and the display & control
 * of the preferences modules.
 * All interaction with the preferences is handled directly by this class
 * or the associated XMPreferencesModule instances.
 **/
@interface XMPreferencesWindowController : NSWindowController {
	
@private
  BOOL preferencesHaveChanged;
  
  NSMutableArray *modules;
  NSMutableArray *identifiers;
  NSMutableArray *toolbarItems;
  NSView *emptyContentView;
  
  NSToolbar *toolbar;
  NSToolbarItem *simpleViewToolbarItem;
  NSToolbarItem *buttonToolbarItem;
  IBOutlet NSView *buttonToolbarView;
  IBOutlet NSButton *applyButton;
  
  NSToolbarItem *currentSelectedItem;
  
  float initialWidth;
}

/**
 * Returns the shared singleton instance
 **/
+ (XMPreferencesWindowController *)sharedInstance;

/**
 * Presents the preferences window on screen
 **/
- (void)showPreferencesWindow;

/**
 * Closes the preferences window, asking the user whether to save the data or not
 **/
- (void)closePreferencesWindow;

/**
 * Action Methods
 **/
- (IBAction)toolbarItemAction:(NSToolbarItem *)sender;
- (IBAction)switchToSimpleView:(id)sender;
- (IBAction)switchToDetailedView:(id)sender;
- (IBAction)applyPreferences:(id)sender;

@end

#endif // __XM_PREFERENCES_WINDOW_CONTROLLER_H__
