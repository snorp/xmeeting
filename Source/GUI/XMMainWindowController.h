/*
 * $Id: XMMainWindowController.h,v 1.1 2005/05/24 15:21:02 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_MAIN_WINDOW_CONTROLLER_H__
#define __XM_MAIN_WINDOW_CONTROLLER_H__

#import <Cocoa/Cocoa.h>

/**
 * XMMainWindowController manages the content of the main
 * window. This is done by using modules as defined
 * in the two interfaces XMMaindWindowModule and
 * XMMainWindowBottomModule.
 * XMMainWindowModule instances are displayed in the upper,
 * "normal" part of the window. They can be resized (depending
 * on their settings) and the window is resized with both
 * width and height when changing the displayed module.
 * XMMainWindowBottomModule instances are displayed in the
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
	IBOutlet NSButton *showModuleInSeparateWindowButton;
	
	NSMutableArray *mainModules;
	NSMutableArray *bottomModules;
	NSMutableArray *bottomButtons;
	NSMutableArray *displayedBottomButtons;
	NSMutableArray *separateWindows;
	NSMutableArray *separateWindowModuleIndexes;
	
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
 * User Interface action methods
 **/
- (IBAction)toggleShowBottomContentView:(id)sender;
- (IBAction)bottomContentButtonAction:(id)sender;
- (IBAction)showBottomModuleInSeparateWindow:(id)sender;

@end

#endif // __XM_MAIN_WINDOW_CONTROLLER_H__
