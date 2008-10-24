/*
 * $Id: XMInspectorModule.h,v 1.5 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2006-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2008 Hannes Friederich, Ivan Guajana. All rights reserved.
 */

#ifndef __XM_INSPECTOR_MODULE_H__
#define __XM_INSPECTOR_MODULE_H__

#import <Cocoa/Cocoa.h>

#import "XMInspectorController.h"

/**
 * This class defines the methods required to implement for
 * modules that will be shown as part of an inspector window
 **/
@interface XMInspectorModule : NSObject {
	
@private
  XMInspectorControllerTag tag;
  BOOL isEnabled;
	
}

/**
 * Designated initializer for this class
 **/
- (id)init;

/**
 * Sets the inspector controller to which this module belongs
 * Subclasses should not override this method.
 **/
- (void)setTag:(XMInspectorControllerTag)tag;

/**
 * Returns whether this module is enabled or not.
 * Subclasses should not override this method.
 **/
- (BOOL)isEnabled;

/**
 * Sets the module in an enabled / disabled state.
 * Subclasses should not override this method
 **/
- (void)setEnabled:(BOOL)flag;

/**
 * Method that subclasses can call to achieve correct resizing of the module
 **/
- (void)resizeContentView;

/**
 * Unique identifier for this module. In contrast to -name
 * not localized
 * Subclasses must override this method
 **/
- (NSString *)identifier;

/**
 * Returns the name of the module. This is used to identify
 * the module by name
 * Subclasses must override this method.
 **/
- (NSString *)name;

/**
 * Returns the image of the module. Return nil if no image should be used
 * The default behaviour is to return nil
 **/
- (NSImage *)image;

/**
 * Returns the view to display for this module.
 * Subclasses must override this method
 **/
- (NSView *)contentView;

/**
 * Returns the  preferred size for this module view. The value of this size may
 * change during the lifetime of this object.
 * Subclasses must override this method
 **/
- (NSSize)contentViewSize;

/**
 * Returns the minimum size for this module view. If the view isn't made resizable,
 * return the same size as -contentViewSize. This is also the default behaviour
 **/
- (NSSize)contentViewMinSize;

/**
 * Returns the maximum size for this module view. If the view isn't made resizable,
 * return the same size as -contentViewSize. This is also the default behaviour
 **/
- (NSSize)contentViewMaxSize;

/**
 * Informs the module that it's content view is going to be displayed on screen,
 * so that the module can update it's views.
 **/
- (void)becomeActiveModule;

/**
 * Informs the receiver that the content view is removed from the screen and
 * the module can be considered inactive.
 **/
- (void)becomeInactiveModule;

@end

#endif // __XM_INSPECTOR_MODULE_H__


