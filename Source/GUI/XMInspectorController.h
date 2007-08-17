/*
 * $Id: XMInspectorController.h,v 1.5 2007/08/17 11:36:44 hfriederich Exp $
 *
 * Copyright (c) 2006-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Ivan Guajana. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

typedef enum XMInspectorControllerTag
{
  XMInspectorControllerTag_Inspector,
  XMInspectorControllerTag_Tools,
  XMInspectorControllerTag_Contacts
  
} XMInspectorControllerTag;

@class XMInspectorModule;

/**
 * XMInspectorController presents various modules in a floating window,
 * using a segmented control to choose among the modules
 **/
@interface XMInspectorController : NSObject {
	
@private
  NSArray *modules;
  NSString *name;
  
  //Outlets
  IBOutlet NSBox *contentBox;
  IBOutlet NSSegmentedControl *pageController;
  IBOutlet NSPanel *panel;
  
  XMInspectorModule *activeModule;
  BOOL isFullScreen;

}

+ (XMInspectorController *)inspectorWithTag:(XMInspectorControllerTag)tag;
+ (void)closeAllInspectors;
+ (void)setFullScreen:(BOOL)flag;

/**
 * Sets the modules for this inspector
 **/
- (void)setModules:(NSArray *)modules;

// Action Methods

- (IBAction)changePage:(id)sender;

// Methods for XMInspectorModules

- (void)moduleSizeChanged:(XMInspectorModule *)module;
- (void)moduleStatusChanged:(XMInspectorModule *)module;

/**
 * Causes the inspector to show the window on screen
 **/
- (void)show;

/**
 * Causes the inspector to show the desired module
 **/
- (void)showModule:(XMInspectorModule *)module;

/**
 * Closes the inspector window
 **/
- (void)close;

@end
