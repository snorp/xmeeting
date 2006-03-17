/*
 * $Id: XMMainWindowController.h,v 1.9 2006/03/17 13:20:52 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_MAIN_WINDOW_CONTROLLER_H__
#define __XM_MAIN_WINDOW_CONTROLLER_H__

#import <Cocoa/Cocoa.h>
#import "XMMainWindowModule.h"

@class XMMouseOverButton, XMLocalVideoView;

/**
 * XMMainWindowController manages the content of the main
 * window. This is done by using modules as defined
 * in the interface XMMaindWindowModule.
 **/
@interface XMMainWindowController : NSWindowController {
	
	XMLocalVideoView *selfView;
	
	NSArray *modules;
	unsigned activeModuleIndex;
	
	BOOL selfViewShown;
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

#pragma mark Module Methods

/**
 * Sets the modules of the receiver
 **/
- (void)setModules:(NSArray *)modules;

/**
 * Displays the desired module on screen.
 * Does nothing if module is not contained in the
 * module list of the receiver
 **/
- (void)showModule:(id<XMMainWindowModule>)module;

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
