/*
 * $Id: XMMainWindowController.h,v 1.7 2006/02/22 16:12:33 zmit Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_MAIN_WINDOW_CONTROLLER_H__
#define __XM_MAIN_WINDOW_CONTROLLER_H__

#import <Cocoa/Cocoa.h>
#import "XMMainWindowModule.h"
#import "XMMainWindowSupportModule.h"
#import "XMMainWindowAdditionModule.h"

@class XMMouseOverButton, XMOSDVideoView;

/**
 * XMMainWindowController manages the content of the main
 * window. This is done by using modules as defined
 * in the thre interfaces XMMaindWindowModule,
 * XMMainWindowSupportModule and XMMainWindowAdditionModule.
 * XMMainWindowModule instances are displayed in the main window.
 * XMMainWindowSupportModule instances are displayed in the right
 * region of the main window.

 * XMMainWindowAdditionModule instances are displayed in the
 * inspector window. 
 **/
@interface XMMainWindowController : NSWindowController {
	
	IBOutlet NSBox *mainContentBox;
	
	XMOSDVideoView *selfView;
	
	NSMutableArray *mainModules;		// contains the main modules
	NSMutableArray *supportModules;		// contains the support modules
	NSMutableArray *additionModules;	// contains the addition modules
	NSMutableArray *additionButtons;	// contains the buttons corresponding to the addition modules
	NSMutableArray *additionWindows;	// contains the windows or NSNull if the module is not displayed in a separate window
	
	unsigned activeMainModuleIndex;
	unsigned activeSupportModuleIndex;
	unsigned activeAdditionModuleIndex;
	
	BOOL bottomIsExpanded;
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
 * Adds module to the main window module list of the 
 * receiver
 **/
- (void)addMainModule:(id<XMMainWindowModule>)module;

/**
 * Displays the specified main window module in the main window
 **/
- (void)showMainModule:(id<XMMainWindowModule>)module;

/**
 * Returns the main module which is currently active (displayed on screen)
 **/
- (id<XMMainWindowModule>)activeMainModule;

/**
 * Informs the receiver that some size values of the sending module
 * have changed. This may cause the main window to be resized
 **/
- (void)noteSizeValuesDidChangeOfMainModule:(id<XMMainWindowModule>)module;

/**
 * Adds module to the support module list of the receiver
 **/
- (void)addSupportModule:(id<XMMainWindowSupportModule>)module;

/**
 * Displays the specified support module in the main window
 **/
- (void)showSupportModule:(id<XMMainWindowSupportModule>)module;

/**
 * Returns the support module which is currently active (displayed
 * on screen)
 **/
- (id<XMMainWindowSupportModule>)activeSupportModule;

/**
 * Informs the receiver that the size of its content view did change,
 * causing the main window to be resized
 **/
- (void)noteSizeValuesDidChangeOfSupportModule:(id<XMMainWindowSupportModule>)module;

/**
 * Adds module to the list of addition modules of
 * the receiver.
 **/
- (void)addAdditionModule:(id<XMMainWindowAdditionModule>)module;

/**
 * Ensures that module is displayed on screen, either within the main window
 * or as a separate window, depending on the context of the actual state
 * of the receiver
 **/
- (void)showAdditionModule:(id<XMMainWindowAdditionModule>)module;

/**
 * Returns the module which is currently active (visible as part of the main
 * window) or nil, if no addition module is displayed within the main window.
 **/
- (id<XMMainWindowAdditionModule>)activeAdditionModule;

/**
 * Informs the receiver that the size of the module's content view did change,
 * causing the main window to be resized
 **/
- (void)noteSizeValuesDidChangeOfAdditionModule:(id<XMMainWindowAdditionModule>)module;

/**
 * User Interface action methods
 **/
- (IBAction)toggleShowAdditionContent:(id)sender;
- (IBAction)showAdditionModuleInSeparateWindow:(id)sender;
- (IBAction)showSelfView:(id)sender;
@end

#endif // __XM_MAIN_WINDOW_CONTROLLER_H__
