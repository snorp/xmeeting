/*
 * $Id: XMMainWindowModule.h,v 1.3 2005/08/24 22:29:39 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_MAIN_WINDOW_MODULE_H__
#define __XM_MAIN_WINDOW_MODULE_H__

/**
 * This protocol declares the necessary methods required for a 
 * main window module. These methods include informations
 * about name, content view and content view size, as well as
 * notification methods such as -becomeActiveModule, which informs
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
 * If the receiver allows resizing, this method should return the minimum size for 
 * the content view. This value may change through the lifetime of the object.
 * If the receiver does not allow resizing, return the same size as 
 * -contentViewSize here.
 **/
- (NSSize)contentViewMinSize;

/**
 * If the receiver allows resizing, this method should return the maximum allowed size
 * for the content view. This value may change through the lifetime of the object.
 * If the receiver does not allow resizing, return the same size as
 * -contentViewSize here.
 **/
- (NSSize)contentViewMaxSize;

/**
 * Informs the module that it's content view is going to be displayed on screen,
 * so that the module can update it's views
 **/
- (void)becomeActiveModule;

/**
 * Informs the receiver that the content view is removed from the screen and
 * the module can be considered inactive.
 **/
- (void)becomeInactiveModule;

@end

#endif // __XM_MAIN_WINDOW_MODULE_H__

