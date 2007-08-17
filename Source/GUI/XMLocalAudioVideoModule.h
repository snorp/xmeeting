/*
 * $Id: XMLocalAudioVideoModule.h,v 1.14 2007/08/17 11:36:44 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_LOCAL_AUDIO_VIDEO_MODULE_H__
#define __XM_LOCAL_AUDIO_VIDEO_MODULE_H__

#import <Cocoa/Cocoa.h>

#import "XMInspectorModule.h"

@class XMLocalVideoView, XMLocalAudioVideoView;

@interface XMLocalAudioVideoModule : XMInspectorModule {
  
@private
  IBOutlet NSView *contentView;
  NSSize contentViewSize;
  BOOL isActive;
  
  IBOutlet XMLocalVideoView *localVideoView;
  IBOutlet NSPopUpButton *videoDevicesPopUp;
  IBOutlet NSButton *videoDeviceSettingsButton;
  IBOutlet NSPopUpButton *audioInputDevicesPopUp;
  IBOutlet NSPopUpButton *audioOutputDevicesPopUp;
  IBOutlet NSSlider *audioInputVolumeSlider;
  IBOutlet NSSlider *audioOutputVolumeSlider;
  IBOutlet NSButton *muteAudioInputSwitch;
  IBOutlet NSButton *muteAudioOutputSwitch;
  IBOutlet NSLevelIndicator *audioInputLevelIndicator;
  IBOutlet NSTextField *videoDisabledFld;	
  
  IBOutlet NSButton *audioTestButton;
  IBOutlet NSPopUpButton *audioTestDelayPopUp;
  
  IBOutlet NSPanel *videoDeviceSettingsPanel;
  IBOutlet NSBox *videoDeviceSettingsBox;
  IBOutlet XMLocalVideoView *videoDeviceSettingsView;
}

- (IBAction)changeVideoDevice:(id)sender;
- (IBAction)showVideoDeviceSettings:(id)sender;

- (IBAction)changeAudioInputDevice:(id)sender;
- (IBAction)changeAudioOutputDevice:(id)sender;

- (IBAction)changeAudioInputVolume:(id)sender;
- (IBAction)changeAudioOutputVolume:(id)sender;

- (IBAction)toggleMuteAudioInput:(id)sender;
- (IBAction)toggleMuteAudioOutput:(id)sender;

- (IBAction)restoreDefaultSettings:(id)sender;
- (IBAction)closeVideoDeviceSettingsPanel:(id)sender;

- (IBAction)updateDeviceLists:(id)sender;

- (IBAction)toggleAudioTest:(id)sender;
- (IBAction)toggleAudioDelay:(id)sender;

@end

#endif // __XM_LOCAL_AUDIO_VIDEO_CONTROLLER_H__
