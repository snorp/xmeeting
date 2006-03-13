/*
 * $Id: XMPreferencesWindowController.h,v 1.5 2006/03/13 23:46:26 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
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

@end

#endif // __XM_PREFERENCES_WINDOW_CONTROLLER_H__
