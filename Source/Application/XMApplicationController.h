/*
 * $Id: XMApplicationController.h,v 1.2 2005/05/24 15:21:01 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_APPLICATION_CONTROLLER_H__
#define __XM_APPLICATION_CONTROLLER_H__

#import <Cocoa/Cocoa.h>

@class XMLocalVideoView;

/**
 * XMApplicationController is responsible for the main menu and
 * is the NSApplication's delegate. In addition, this class
 * manages the application initialization and termination.
 **/
@interface XMApplicationController : NSObject {
	
}

/**
 * Causes the Preferences window to be shown on screen
 **/
- (IBAction)showPreferences:(id)sender;

@end

#endif // __XM_APPLICATION_CONTROLLER_H__