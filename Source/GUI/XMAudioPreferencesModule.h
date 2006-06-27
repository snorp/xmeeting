/*
 * $Id: XMAudioPreferencesModule.h,v 1.1 2006/06/27 18:06:48 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_AUDIO_PREFERENCES_MODULE_H__
#define __XM_AUDIO_PREFERENCES_MODULE_H__

#import <Cocoa/Cocoa.h>

#import "XMPreferencesModule.h"

extern NSString *XMKey_AudioPreferencesModuleIdentifier;

@interface XMAudioPreferencesModule : NSObject <XMPreferencesModule> {

	XMPreferencesWindowController *prefWindowController;
	float contentViewHeight;
	IBOutlet NSView *contentView;
	
	IBOutlet NSPopUpButton *preferredOutputDevicePopUp;
	IBOutlet NSPopUpButton *preferredInputDevicePopUp;
}

- (IBAction)preferredOutputDeviceSelectionDidChange:(id)sender;
- (IBAction)preferredInputDeviceSelectionDidChange:(id)sender;

@end

#endif // __XM_AUDIO_PREFERENCES_MODULE_H__
