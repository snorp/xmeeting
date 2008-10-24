/*
 * $Id: XMPreferencesWindowController.h,v 1.8 2008/10/24 12:22:02 hfriederich Exp $
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
  
  NSToolbarItem *buttonToolbarItem;
  IBOutlet NSView *buttonToolbarView;
  IBOutlet NSButton *applyButton;
  
  NSToolbarItem *currentSelectedItem;
  float currentSelectedItemHeight;
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

@end

#endif // __XM_PREFERENCES_WINDOW_CONTROLLER_H__
