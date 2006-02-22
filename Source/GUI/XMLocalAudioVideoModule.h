/*
 * $Id: XMLocalAudioVideoModule.h,v 1.6 2006/02/22 16:12:33 zmit Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_LOCAL_AUDIO_VIDEO_MODULE_H__
#define __XM_LOCAL_AUDIO_VIDEO_MODULE_H__

#import <Cocoa/Cocoa.h>
#import "XMMainWindowSupportModule.h"

@class XMSimpleVideoView, XMOSDVideoView, XMLocalAudioVideoView;

@interface XMLocalAudioVideoModule : NSObject <XMMainWindowSupportModule> {
	
	IBOutlet XMLocalAudioVideoView *contentView;
	
	IBOutlet XMOSDVideoView *localVideoView;
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

	NSNib *nibLoader;
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
