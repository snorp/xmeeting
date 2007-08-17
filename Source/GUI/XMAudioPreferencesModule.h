/*
 * $Id: XMAudioPreferencesModule.h,v 1.4 2007/08/17 11:36:43 hfriederich Exp $
 *
 * Copyright (c) 2006-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_AUDIO_PREFERENCES_MODULE_H__
#define __XM_AUDIO_PREFERENCES_MODULE_H__

#import <Cocoa/Cocoa.h>

#import "XMPreferencesModule.h"

extern NSString *XMKey_AudioPreferencesModuleIdentifier;

@interface XMAudioPreferencesModule : NSObject <XMPreferencesModule> {

@private
  XMPreferencesWindowController *prefWindowController;
  float contentViewHeight;
  IBOutlet NSView *contentView;
  
  IBOutlet NSPopUpButton *preferredOutputDevicePopUp;
  IBOutlet NSPopUpButton *preferredInputDevicePopUp;
}

- (IBAction)preferredOutputDeviceSelectionDidChange:(id)sender;
- (IBAction)preferredInputDeviceSelectionDidChange:(id)sender;
- (IBAction)defaultAction:(id)sender;

@end

#endif // __XM_AUDIO_PREFERENCES_MODULE_H__
