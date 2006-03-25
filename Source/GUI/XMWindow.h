/*
 * $Id: XMWindow.h,v 1.5 2006/03/25 10:41:57 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_WINDOW_H__
#define __XM_WINDOW_H__

#import <Cocoa/Cocoa.h>

extern NSString *XMNotification_WindowWillMiniaturize;

/**
 * This class implements a couple of modifications to the normal
 * NSWindow methods which allows better interactions for OpenGL
 * based drawing when the window minimizes.
 **/
@interface XMWindow : NSWindow {

}

@end

/**
 * This class implements a couple of modifications to the default
 * NSWindow methods which allows this window to be used as a child
 * window to the main window while the controls remain active
 **/
@interface XMChildWindow : NSWindow {
	
}

@end

/**
 * This class implements a window that will be displayed covering the
 * whole screen (Full screen)
 **/
@interface XMFullScreenWindow : NSWindow {

}

@end

#endif // __XM_WINDOW_H__
