/*
 * $Id: XMLocalAudioVideoModule.h,v 1.2 2005/10/06 15:04:42 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_LOCAL_AUDIO_VIDEO_MODULE_H__
#define __XM_LOCAL_AUDIO_VIDEO_MODULE_H__

#import <Cocoa/Cocoa.h>
#import "XMMainWindowSupportModule.h"

@class XMVideoView;

@interface XMLocalAudioVideoModule : NSObject <XMMainWindowSupportModule> {
	
	IBOutlet NSView *contentView;
	NSSize expandedContentViewSize;
	NSSize collapsedContentViewSize;
	
	IBOutlet NSButton *contentDisclosure;
	IBOutlet XMVideoView *localVideoView;
	IBOutlet NSPopUpButton *videoDevicesPopUp;
	IBOutlet NSPopUpButton *audioInputDevicesPopUp;
	IBOutlet NSPopUpButton *audioOutputDevicesPopUp;
	IBOutlet NSSlider *audioInputVolumeSlider;
	IBOutlet NSSlider *audioOutputVolumeSlider;
	IBOutlet NSButton *muteAudioInputSwitch;
	IBOutlet NSButton *muteAudioOutputSwitch;

	NSNib *nibLoader;
	
	BOOL isExpanded;
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
