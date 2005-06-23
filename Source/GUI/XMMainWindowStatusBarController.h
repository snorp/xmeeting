/*
 * $Id: XMMainWindowStatusBarController.h,v 1.2 2005/06/23 12:35:57 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_MAIN_WINDOW_STATUS_BAR_CONTROLLER_H__
#define __XM_MAIN_WINDOW_STATUS_BAR_CONTROLLER_H__

#import <Cocoa/Cocoa.h>

/**
 * This class is entirely devoted to filling the main window's
 * status bar with content. This is done by registering
 * for notifications and print an appropriate message in the
 * status bar.
 **/
@interface XMMainWindowStatusBarController : NSObject {

	IBOutlet NSTextField *statusBar;
	IBOutlet NSProgressIndicator *progressIndicator;
	BOOL doesSubsystemSetup;
	BOOL progressIndicatorDoesAnimate;
	NSTimer *displayClearTimer;
}

@end

#endif // __XM_MAIN_WINDOW_STATUS_BAR_CONTROLLER_H__
