/*
 * $Id: XMGeneralPreferencesModule.h,v 1.5 2006/04/06 23:15:32 hfriederich Exp $
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
	IBOutlet NSButton *generateDebugLogSwitch;
	IBOutlet NSTextField *debugLogFilePathField;
	IBOutlet NSButton *chooseDebugLogFilePathButton;
	
	IBOutlet NSButton *automaticallyEnterFullScreenSwitch;
	IBOutlet NSButton *showSelfViewMirroredSwitch;
	IBOutlet NSButton *automaticallyHideInCallControlsSwitch;
	IBOutlet NSPopUpButton *inCallControlsHideAndShowEffectPopUp;
}

- (IBAction)defaultAction:(id)sender;

- (IBAction)toggleGenerateDebugLogFile:(id)sender;
- (IBAction)chooseDebugFilePath:(id)sender;

- (IBAction)toggleAutomaticallyHideInCallControls:(id)sender;

@end

#endif // __XM_GENERAL_PREFERENCES_MODULE_H__
