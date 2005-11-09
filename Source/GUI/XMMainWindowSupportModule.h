/*
 * $Id: XMMainWindowSupportModule.h,v 1.1 2005/11/09 20:00:27 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_MAIN_WINDOW_SUPPORT_MODULE_H__
#define __XM_MAIN_WINDOW_SUPPORT_MODULE_H__

/**
 * This protocol declares the methods required for a main window support
 * module to ensure proper working. Most methods are similar to the ones
 * found in XMMainWindowModule, but the semantics have changed slightly.
 **/
@protocol XMMainWindowSupportModule <NSObject>

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
 * Returns the  preferred size for this module view. The value of this size may
 * change during the lifetime of this object, altough resizing can be done only
 * programmatically. The width of the size is guaranteed to be the same, while
 * the height may be different. ActualHeight >= heightReturned.
 **/
- (NSSize)contentViewSize;

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

#endif // __XM_MAIN_WINDOW_SUPPORT_MODULE_H__


