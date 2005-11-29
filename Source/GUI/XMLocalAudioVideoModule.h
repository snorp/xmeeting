/*
 * $Id: XMLocalAudioVideoModule.h,v 1.4 2005/11/29 18:56:29 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_LOCAL_AUDIO_VIDEO_MODULE_H__
#define __XM_LOCAL_AUDIO_VIDEO_MODULE_H__

#import <Cocoa/Cocoa.h>
#import "XMMainWindowSupportModule.h"

@class XMSimpleVideoView, XMLocalAudioVideoView;

@interface XMLocalAudioVideoModule : NSObject <XMMainWindowSupportModule> {
	
	IBOutlet XMLocalAudioVideoView *contentView;
	
	IBOutlet NSButton *contentDisclosure;
	IBOutlet XMSimpleVideoView *localVideoView;
	IBOutlet NSPopUpButton *videoDevicesPopUp;
	IBOutlet NSPopUpButton *audioInputDevicesPopUp;
	IBOutlet NSPopUpButton *audioOutputDevicesPopUp;
	IBOutlet NSSlider *audioInputVolumeSlider;
	IBOutlet NSSlider *audioOutputVolumeSlider;
	IBOutlet NSButton *muteAudioInputSwitch;
	IBOutlet NSButton *muteAudioOutputSwitch;

	NSNib *nibLoader;
}

- (IBAction)toggleShowContent:(id)sender;

- (IBAction)changeVideoDevice:(id)sender;
- (IBAction)changeAudioInputDevice:(id)sender;
- (IBAction)changeAudioOutputDevice:(id)sender;

- (IBAction)changeAudioInputVolume:(id)sender;
- (IBAction)changeAudioOutputVolume:(id)sender;

- (IBAction)toggleMuteAudioInput:(id)sender;
- (IBAction)toggleMuteAudioOutput:(id)sender;

@end

#endif // __XM_LOCAL_AUDIO_VIDEO_CONTROLLER_H__
