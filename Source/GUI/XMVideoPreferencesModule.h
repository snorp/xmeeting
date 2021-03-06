/*
 * $Id: XMVideoPreferencesModule.h,v 1.5 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2006-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2008 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_VIDEO_PREFERENCES_MODULE_H__
#define __XM_VIDEO_PREFERENCES_MODULE_H__

#import <Cocoa/Cocoa.h>

#import "XMPreferencesModule.h"

extern NSString *XMKey_VideoPreferencesModuleIdentifier;

@interface XMVideoPreferencesModule : NSObject <XMPreferencesModule> {
	
@private
  XMPreferencesWindowController *prefWindowController;
  float contentViewHeight;
  IBOutlet NSView *contentView;
  IBOutlet NSPopUpButton *preferredVideoDevicePopUp;
  IBOutlet NSTableView *videoModulesTableView;
  
  IBOutlet NSPanel *videoModuleSettingsPanel;
  IBOutlet NSBox *videoModuleSettingsBox;
  
  NSMutableArray *disabledVideoModules;

}

- (IBAction)preferredVideoDeviceSelectionDidChange:(id)sender;

- (IBAction)restoreDefaultVideoModuleSettings:(id)sender;
- (IBAction)closeVideoModuleSettingsPanel:(id)sender;

@end

#endif // __XM_VIDEO_PREFERENCES_MODULE_H__
