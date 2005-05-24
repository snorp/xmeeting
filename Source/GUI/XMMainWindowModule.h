/*
 * $Id: XMMainWindowModule.h,v 1.1 2005/05/24 15:21:02 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_MAIN_WINDOW_MODULE_H__
#define __XM_MAIN_WINDOW_MODULE_H__

#import "XMMainWindowController.h"

/**
 * This protocol declares the necessary methods required for a 
 * main window module. These methods include informations
 * about name, content view and content view size, as well as
 * notification methods such as -prepareForDisplay, which informs
 * the receiver that it's content view is about to be displayed on screen.
 **/
@protocol XMMainWindowModule <NSObject>

/**
 * Returns the name of the module. This is used to identify
 * the module by name
 **/
- (NSString *)name;

/**
 * Returns the view to display for this module
 **/
- (NSView *)contentView;

/**
 * Returns the  preferred size for this module view. This value may change
 * through the lifetime of the object
 **/
- (NSSize)contentViewSize;

/**
 * If the receiver allows resizing, this tells the minimum size for the content view.
 * This value may change through the lifetime of the object.
 **/
- (NSSize)contentViewMinSize;

/**
 * Returns whether this module's view is resizable or not
 **/
- (BOOL)allowsContentViewResizing;

/**
 * Informs the module that it's content view is going to be displayed on screen
 **/
- (void)prepareForDisplay;

@end

/**
 * Declares the methods implemented by XMMainWindowController
 * to ensure proper two-way communication between the module
 * and the main window controller.
 **/
@interface XMMainWindowController (MainModuleMethods)

/**
 * Adds module to the main window module list of the 
 * receiver
 **/
- (void)addMainModule:(id<XMMainWindowModule>)module;

@end

#endif // __XM_MAIN_WINDOW_MODULE_H__
