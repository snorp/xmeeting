/*
 * $Id: XMWindow.h,v 1.2 2006/03/14 23:06:00 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_WINDOW_H__
#define __XM_WINDOW_H__

#import <Cocoa/Cocoa.h>

extern NSString *XMNotification_WindowWillMinimize;

/**
 * This class implements a couple of modifications to the normal
 * NSWindow methods which allows better interactions for OpenGL
 * based drawing when the window minimizes.
 **/
@interface XMWindow : NSWindow {

}

@end

#endif // __XM_WINDOW_H__
