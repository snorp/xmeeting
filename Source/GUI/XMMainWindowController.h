/*
 * $Id: XMMainWindowController.h,v 1.10 2006/03/23 10:04:49 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_MAIN_WINDOW_CONTROLLER_H__
#define __XM_MAIN_WINDOW_CONTROLLER_H__

#import <Cocoa/Cocoa.h>
#import "XMMainWindowModule.h"

@class XMFullScreenWindow;

/**
 * XMMainWindowController manages the content of the main
 * window. This is done by using modules as defined
 * in the interface XMMaindWindowModule.
 **/
@interface XMMainWindowController : NSWindowController {
	
	NSArray *modules;
	unsigned activeModuleIndex;
	
	BOOL selfViewShown;
	
	XMFullScreenWindow *fullScreenWindow;
	IBOutlet id test;
	BOOL isFullScreen;
}

/**
 * Returns the shared singleton instance of this
 * class
 **/
+ (XMMainWindowController *)sharedInstance;

/**
 * Shows the main window on screen, moving it to front if necessary
 **/
- (void)showMainWindow;

/**
 * Shows the current active module in a full screen window
 * Returns the success of this operation
 **/
- (BOOL)beginFullScreen;

/**
 * Ends the full screen mode
 **/
- (void)endFullScreen;

/**
 * Returns whether we're showing full screen or not
 **/
- (BOOL)isFullScreen;

/**
 * Sets the modules of the receiver
 **/
- (void)setModules:(NSArray *)modules;

/**
 * Displays the desired module on screen.
 * Does nothing if module is not contained in the
 * module list of the receiver
 **/
- (void)showModule:(id<XMMainWindowModule>)module fullScreen:(BOOL)showFullscreen;

/**
 * Returns the module which is currently active
 * (displayed on screen)
 **/
- (id<XMMainWindowModule>)activeModule;

/**
 * Informs the receiver that some size values of the sending module
 * have changed. This may cause the main window to be resized
 **/
- (void)noteSizeValuesDidChangeOfModule:(id<XMMainWindowModule>)module;

/**
 * User Interface action methods
 **/
- (IBAction)showSelfView:(id)sender;

@end

#endif // __XM_MAIN_WINDOW_CONTROLLER_H__
