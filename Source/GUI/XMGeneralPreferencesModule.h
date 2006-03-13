/*
 * $Id: XMGeneralPreferencesModule.h,v 1.4 2006/03/13 23:46:26 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_GENERAL_PREFERENCES_MODULE_H__
#define __XM_GENERAL_PREFERENCES_MODULE_H__

#import <Cocoa/Cocoa.h>

#import "XMPreferencesModule.h"

extern NSString *XMKey_GeneralPreferencesModuleIdentifier;

@class XMPreferencesWindowController;

@interface XMGeneralPreferencesModule : NSObject <XMPreferencesModule> {

	XMPreferencesWindowController *prefWindowController;
	float contentViewHeight;
	IBOutlet NSView *contentView;
	IBOutlet NSTextField *userNameField;
	IBOutlet NSButton *automaticallyAcceptIncomingCallsSwitch;
}

- (IBAction)defaultAction:(id)sender;

@end

#endif // __XM_GENERAL_PREFERENCES_MODULE_H__
