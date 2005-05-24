/*
 * $Id: XMMainWindowBottomModule.h,v 1.1 2005/05/24 15:21:02 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_MAIN_WINDOW_BOTTOM_MODULE_H__
#define __XM_MAIN_WINDOW_BOTTOM_MODULE_H__

#import "XMMainWindowController.h"

/**
 * This protocol declares the methods required for a main window bottom
 * module to ensure proper working. Most methods are similar to the ones
 * found in XMMainWindowModule, but the semantics have changed slightly.
 **/
@protocol XMMainWindowBottomModule <NSObject>

/**
 * Returns the name of the module. This name is used to identify the
 * module by name
 **/
- (NSString *)name;

/**
 * Returns a small image for this module. This image is displayed
 * at currently 10x10 pixels, so returning bigger images is not
 * necessary
 **/
- (NSImage *)image;

/**
 * Returns the actual content view for this module.
 * The view's height is fixed and the value from -contentViewHeight
 * is used. The view's width may vary, though (user resizing)
 **/
- (NSView *)contentView;

/**
 * Returns the size of the module's content view. Note that
 * the height is fixed and does not change. The width may
 * vary, return the preferred width here.
 **/
- (NSSize)contentViewSize;

/**
 * Informs the module that it's content view is going to be displayed
 **/
- (void)prepareForDisplay;

@end

/**
 * Declares the methods implemented by XMMainWindowController
 * to ensure proper two-way communication between module and
 * main window controller.
 **/
@interface XMMainWindowController (BottomModuleMethods)

/**
 * Adds module to the list of main window bottom modules of
 * the receiver.
 **/
- (void)addBottomModule:(id<XMMainWindowBottomModule>)module;

@end

#endif // __XM_MAIN_WINDOW_BOTTOM_MODULE_H__