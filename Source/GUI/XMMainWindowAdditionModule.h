/*
 * $Id: XMMainWindowAdditionModule.h,v 1.2 2005/08/24 22:29:39 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_MAIN_WINDOW_ADDITION_MODULE_H__
#define __XM_MAIN_WINDOW_ADDITION_MODULE_H__

/**
 * This protocol declares the methods required for a main window addition
 * module to ensure proper working. Most methods are similar to the ones
 * found in XMMainWindowModule, but the semantics have changed slightly.
 **/
@protocol XMMainWindowAdditionModule <NSObject>

/**
 * Returns the name of the module. This name is used to identify the
 * module by name
 **/
- (NSString *)name;

/**
 * Returns a small image for this module. This image is displayed
 * at currently 16x16 pixels, so returning bigger images is not
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
 * Informs the receiver that it's content view is going to be displayed
 * on screen, so that the module can do any necessary preparations
 **/
- (void)becomeActiveModule;

/**
 * Informs the receiver that it's content view is removed from the screen,
 * so that the module can clean up if necessary.
 **/
- (void)becomeInactiveModule;

@end

#endif // __XM_MAIN_WINDOW_ADDITION_MODULE_H__
