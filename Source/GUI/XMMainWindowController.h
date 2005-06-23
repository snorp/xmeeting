/*
 * $Id: XMMainWindowController.h,v 1.3 2005/06/23 12:35:57 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_MAIN_WINDOW_CONTROLLER_H__
#define __XM_MAIN_WINDOW_CONTROLLER_H__

#import <Cocoa/Cocoa.h>
#import "XMMainWindowModule.h"
#import "XMMainWindowAdditionModule.h"

@class XMMouseOverButton;

/**
 * XMMainWindowController manages the content of the main
 * window. This is done by using modules as defined
 * in the two interfaces XMMaindWindowModule and
 * XMMainWindowAdditionModule.
 * XMMainWindowModule instances are displayed in the upper,
 * "normal" part of the window. They can be resized (depending
 * on their settings) and the window is resized with both
 * width and height when changing the displayed module.
 * XMMainWindowAdditionModule instances are displayed in the
 * bottom region of the main window. This bottom region
 * can be hidden or shown. The height of these modules is
 * fixed whereas the widht does vary, depending on the width of
 * the currently active XMMainWindowModule instance. In addition,
 * these modules also be shown in a separate window, allowing it
 * to display more than one module on screen at a time.
 **/
@interface XMMainWindowController : NSWindowController {
	
	IBOutlet NSBox *mainContentBox;
	IBOutlet NSBox *separatorContentBox;
	IBOutlet NSBox *bottomContentBox;
	
	IBOutlet NSButton *bottomContentDisclosure;
	IBOutlet XMMouseOverButton *showModuleInSeparateWindowButton;
	
	IBOutlet NSButton *localAudioVideoDisclosure;
	IBOutlet NSDrawer *localAudioVideoDrawer;
	
	NSMutableArray *mainModules;		// contains the main modules
	NSMutableArray *additionModules;	// contains the bottom modules
	NSMutableArray *bottomButtons;		// contains the buttons corresponding to the bottom modules
	NSMutableArray *separateWindows;	// contains the windows or NSNull if the module is not displayed in a separate window
	NSMutableArray *windowLocations;
	
	unsigned currentSelectedMainModuleIndex;
	unsigned currentSelectedBottomModuleIndex;
	BOOL bottomIsExpanded;
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
 * Adds module to the main window module list of the 
 * receiver
 **/
- (void)addMainModule:(id<XMMainWindowModule>)module;

/**
 * Displays the specified main window module in the main window
 **/
- (void)showMainModule:(id<XMMainWindowModule>)module;

/**
 * Adds module to the list of main window bottom modules of
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
 * User Interface action methods
 **/
- (IBAction)toggleShowAdditionContentView:(id)sender;
- (IBAction)additionContentButtonAction:(id)sender;
- (IBAction)showAdditionModuleInSeparateWindow:(id)sender;

- (IBAction)toggleShowLocalAudioVideoDrawer:(id)sender;

@end

#endif // __XM_MAIN_WINDOW_CONTROLLER_H__
