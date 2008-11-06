/*
 * $Id: XMDebugPreferencesModule.h,v 1.1 2008/11/06 08:41:46 hfriederich Exp $
 *
 * Copyright (c) 2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2008 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_DEBUG_PREFERENCES_MODULE_H__
#define __XM_DEBUG_PREFERENCES_MODULE_H__

#import <Cocoa/Cocoa.h>

#import "XMPreferencesModule.h"

extern NSString *XMKey_DebugPreferencesModuleIdentifier;

@class XMPreferencesWindowController;

@interface XMDebugPreferencesModule : NSObject <XMPreferencesModule> {
  
@private
  XMPreferencesWindowController *prefWindowController;
  float contentViewHeight;
  IBOutlet NSView *contentView;
  
  IBOutlet NSButton *generateDebugLogSwitch;
  IBOutlet NSTextField *debugLogFilePathField;
  IBOutlet NSButton *chooseDebugLogFilePathButton;
}

- (IBAction)defaultAction:(id)sender;

- (IBAction)toggleGenerateDebugLogFile:(id)sender;
- (IBAction)chooseDebugFilePath:(id)sender;

@end

#endif // __XM_DEBUG_PREFERENCES_MODULE_H__
