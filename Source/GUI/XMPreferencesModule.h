/*
 * $Id: XMPreferencesModule.h,v 1.5 2007/08/13 00:36:34 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_PREFERENCES_MODULE_H__
#define __XM_PREFERENCES_MODULE_H__

#import <Cocoa/Cocoa.h>

#import "XMPreferencesWindowController.h"

/**
 * This protocol defines the interface for preferences modules so that
 * XMPreferencesWindowController can corectly manage the preferences
 * GUI.
 **/
@protocol XMPreferencesModule <NSObject>

/**
 * Returns at which position in a list this module should appear
 * If multiple modules return the same position, the outcoming order
 * is not defined
 **/
- (unsigned)position;

/**
 * This method should return the Identifier for this module
 **/
- (NSString *)identifier;

/**
 * This method returns the label for this module (presented in the toolbar)
 **/
- (NSString *)toolbarLabel;

/**
 * This method returns the image for the toolbar
 **/
- (NSImage *)toolbarImage;

/**
 * This method returns the toolTip text for this module
 **/
- (NSString *)toolTipText;

/**
 * This method should return the contentView for this module
 **/
- (NSView *)contentView;

/**
 * The width of the preferences window is fixed to currently 700 pixels.
 * This method returns the height of its contentView, so that
 * the window height is adjusted accordingly
 **/
- (float)contentViewHeight;

/**
 * this method instructs the receiver to prepare it's
 * content view according to the preferences from
 * XMPreferencesManager
 **/
- (void)loadPreferences;

/**
 * This method instructs the receiver to save the changes made
 * to XMPreferencesManager
 **/
- (void)savePreferences;

/**
 * Callback to inform that the contentView became visible
 **/
- (void)becomeActiveModule;

@end


@interface XMPreferencesWindowController (ModuleMethods)

/**
* Informs XMPreferencesWindowController that some preferences
 * have changed
 **/
- (void)notePreferencesDidChange;

/**
 * Adds this module to XMPreferencesWindowController
 **/
- (void)addPreferencesModule:(id<XMPreferencesModule>)module;

@end

#endif // __XM_PREFERENCES_MODULE_H__
