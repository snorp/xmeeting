/*
 * $Id: XMLocalAudioVideoModule.h,v 1.10 2006/03/17 13:20:52 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_LOCAL_AUDIO_VIDEO_MODULE_H__
#define __XM_LOCAL_AUDIO_VIDEO_MODULE_H__

#import <Cocoa/Cocoa.h>

#import "XMInspectorModule.h"

@class XMLocalVideoView, XMLocalAudioVideoView;

@interface XMLocalAudioVideoModule : XMInspectorModule {
	
	IBOutlet NSView *contentView;
	NSSize contentViewSize;
	
	IBOutlet XMLocalVideoView *localVideoView;
	IBOutlet NSPopUpButton *videoDevicesPopUp;
	IBOutlet NSButton *videoDeviceSettingsButton;
	IBOutlet NSPopUpButton *audioInputDevicesPopUp;
	IBOutlet NSPopUpButton *audioOutputDevicesPopUp;
	IBOutlet NSSlider *audioInputVolumeSlider;
	IBOutlet NSSlider *audioOutputVolumeSlider;
	IBOutlet NSButton *muteAudioInputSwitch;
	IBOutlet NSButton *muteAudioOutputSwitch;	
	IBOutlet NSTextField *videoDisabledFld;	
	
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

@end

#endif // __XM_LOCAL_AUDIO_VIDEO_CONTROLLER_H__
