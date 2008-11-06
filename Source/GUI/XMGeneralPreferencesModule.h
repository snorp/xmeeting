/*
 * $Id: XMGeneralPreferencesModule.h,v 1.9 2008/11/06 08:41:46 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_GENERAL_PREFERENCES_MODULE_H__
#define __XM_GENERAL_PREFERENCES_MODULE_H__

#import <Cocoa/Cocoa.h>

#import "XMPreferencesModule.h"

extern NSString *XMKey_GeneralPreferencesModuleIdentifier;

@class XMPreferencesWindowController;

@interface XMGeneralPreferencesModule : NSObject <XMPreferencesModule> {
  
@private
  XMPreferencesWindowController *prefWindowController;
  float contentViewHeight;
  IBOutlet NSView *contentView;
  
  IBOutlet NSTextField *userNameField;
  IBOutlet NSButton *automaticallyAcceptIncomingCallsSwitch;
}

- (IBAction)defaultAction:(id)sender;

@end

#endif // __XM_GENERAL_PREFERENCES_MODULE_H__
