/*
 * $Id: XMMainWindowStatusBarController.h,v 1.3 2006/01/23 08:46:16 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
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
	NSTimer *displayClearTimer;
	int animationCounter;
}

@end

#endif // __XM_MAIN_WINDOW_STATUS_BAR_CONTROLLER_H__
