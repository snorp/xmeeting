/*
 * $Id: XMLocalAudioVideoModule.m,v 1.24 2006/08/14 18:33:37 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMeeting.h"

#import "XMLocalAudioVideoModule.h"

#import "XMPreferencesManager.h"
#import "XMMainWindowController.h"
#import "XMLocalVideoView.h"

@interface XMLocalAudioVideoModule (PrivateMethods)

- (void)_validateAudioControls;
- (void)_didStartVideoInputDeviceListUpdate:(NSNotification *)notif;
- (void)_didUpdateVideoInputDeviceList:(NSNotification *)notif;
- (void)_didStartVideoInputDeviceChange:(NSNotification *)notif;
- (void)_didChangeSelectedVideoInputDevice:(NSNotification *)notif;
- (void)_audioInputVolumeDidChange:(NSNotification *)notif;
- (void)_audioOutputVolumeDidChange:(NSNotification *)notif;
- (void)_didUpdateAudioDeviceLists:(NSNotification *)notif;
- (void)_preferencesDidChange:(NSNotification *)notif;
- (void)_activeLocationDidChange:(NSNotification *)notif;

@end

@implementation XMLocalAudioVideoModule

#pragma mark Init & Deallocation Methods

- (id)init
{
	self = [super init];
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	contentViewSize = [contentView bounds].size;
	
	// configuring the video content
	XMVideoManager *videoManager = [XMVideoManager sharedInstance];
	NSArray *devices = [videoManager inputDevices];
	
	[videoDevicesPopUp setEnabled:NO];
	[videoDeviceSettingsButton setEnabled:NO];
	
	if(devices != nil)
	{
		[self _didUpdateVideoInputDeviceList:nil];
	}

	// done here to prevent flashing of controls after window is on screen
	if([[[XMPreferencesManager sharedInstance] activeLocation] enableVideo] == NO)
	{
		[videoDevicesPopUp setEnabled:NO];
		[videoDeviceSettingsButton setEnabled:NO];
		[videoDisabledFld setStringValue:NSLocalizedString(@"XM_AUDIO_VIDEO_MODULE_VIDEO_DISABLED", @"")];
	}
	else
	{
		[videoDevicesPopUp setEnabled:YES];
		
		NSString *device = [videoManager selectedInputDevice];
		if([videoManager deviceHasSettings:device] == YES)
		{
			[videoDeviceSettingsButton setEnabled:YES];
		}
		
		[videoDisabledFld setStringValue:@""];
	}
	
	// configuring the audio content
	[self _didUpdateAudioDeviceLists:nil];
	[self _validateAudioControls];
	
	// registering for notifications
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

	[notificationCenter addObserver:self selector:@selector(_didStartVideoInputDeviceListUpdate:)
							   name:XMNotification_VideoManagerDidStartInputDeviceListUpdate object:nil];
	[notificationCenter addObserver:self selector:@selector(_didUpdateVideoInputDeviceList:)
							   name:XMNotification_VideoManagerDidUpdateInputDeviceList object:nil];
	[notificationCenter addObserver:self selector:@selector(_didStartVideoInputDeviceChange:)
							   name:XMNotification_VideoManagerDidStartSelectedInputDeviceChange object:nil];
	[notificationCenter addObserver:self selector:@selector(_didChangeSelectedVideoInputDevice:)
							   name:XMNotification_VideoManagerDidChangeSelectedInputDevice object:nil];
	[notificationCenter addObserver:self selector:@selector(_audioInputVolumeDidChange:)
							   name:XMNotification_AudioManagerInputVolumeDidChange object:nil];
	[notificationCenter addObserver:self selector:@selector(_audioOutputVolumeDidChange:)
							   name:XMNotification_AudioManagerOutputVolumeDidChange object:nil];
	[notificationCenter addObserver:self selector:@selector(_didUpdateAudioDeviceLists:)
							   name:XMNotification_AudioManagerDidUpdateDeviceLists object:nil];
	[notificationCenter addObserver:self selector:@selector(_didUpdateAudioInputLevel:)
							   name:XMNotification_AudioManagerDidUpdateInputLevel object:nil];
	
	[notificationCenter addObserver:self selector:@selector(_preferencesDidChange:)
							   name:XMNotification_PreferencesManagerDidChangePreferences object:nil];
	[notificationCenter addObserver:self selector:@selector(_activeLocationDidChange:)
							   name:XMNotification_PreferencesManagerDidChangeActiveLocation object:nil];
	
	/* InterfaceBuilder uses the levelIndicator with a fixed height of 18px.
	   Instead of building our own level indicator, the height is set to 8px
	   here to get the desired effect */
	NSRect frame = [audioInputLevelIndicator frame];
	frame.size.height = 8;
	[audioInputLevelIndicator setFrame:frame];
	
}

#pragma mark Protocol Methods

- (NSString *)name
{
	return NSLocalizedString(@"XM_AUDIO_VIDEO_MODULE_NAME", @"");
}

- (NSView *)contentView
{
	if(contentView == nil)
	{
		[NSBundle loadNibNamed:@"LocalAudioVideoModule" owner:self];
	}
	
	return contentView;
}

- (NSSize)contentViewSize
{
	// if not already done, this triggers the loading of the nib file
	[self contentView];
	
	return contentViewSize;
}

- (void)becomeActiveModule
{
	isActive = YES;
	[self _activeLocationDidChange:nil];
	
	[[XMAudioManager sharedInstance] setDoesMeasureSignalLevels:YES];
}

- (void)becomeInactiveModule
{
	// simply deactivate both instead of querying which
	// one is active
	[localVideoView stopDisplayingLocalVideo];
	[localVideoView stopDisplayingNoVideo];
	isActive = NO;
	
	[[XMAudioManager sharedInstance] setDoesMeasureSignalLevels:NO];
}

#pragma mark Action Methods

- (IBAction)updateDeviceLists:(id)sender
{
	[[NSApp delegate] updateDeviceLists:self];
}

- (IBAction)changeVideoDevice:(id)sender
{
	XMVideoManager *videoManager = [XMVideoManager sharedInstance];
	
	NSString *device = [videoDevicesPopUp titleOfSelectedItem];
	
	[videoManager setSelectedInputDevice:device];
}

- (IBAction)showVideoDeviceSettings:(id)sender
{
	XMVideoManager *videoManager = [XMVideoManager sharedInstance];
	
	NSString *device = [videoDevicesPopUp titleOfSelectedItem];
	
	NSView *settingsView = [videoManager settingsViewForDevice:device];
	
	NSRect panelFrame = [videoDeviceSettingsPanel frame];
	
	NSRect settingsViewFrame = [settingsView frame];
	NSRect currentSettingsViewFrame = [videoDeviceSettingsBox frame];
	
	panelFrame.size.width += (settingsViewFrame.size.width - currentSettingsViewFrame.size.width);
	panelFrame.size.height += (settingsViewFrame.size.height - currentSettingsViewFrame.size.height);
	
	[videoDeviceSettingsPanel setFrame:panelFrame display:NO];
	
	[videoDeviceSettingsBox setContentView:settingsView];
	
	[NSApp beginSheet:videoDeviceSettingsPanel modalForWindow:[contentView window] modalDelegate:self didEndSelector:nil contextInfo:NULL];
	
	[videoDeviceSettingsView startDisplayingLocalVideo];
	
	BOOL mirrorSelfView = [[XMPreferencesManager sharedInstance] showSelfViewMirrored];
	[videoDeviceSettingsView setLocalVideoMirrored:mirrorSelfView];
}

- (IBAction)changeAudioInputDevice:(id)sender
{
	XMAudioManager *audioManager = [XMAudioManager sharedInstance];
	
	NSString *device = [audioInputDevicesPopUp titleOfSelectedItem];
	
	if(![audioManager setSelectedInputDevice:device])
	{
		[audioInputDevicesPopUp selectItemWithTitle:[audioManager selectedInputDevice]];
	}
	
	[audioInputVolumeSlider setIntValue:[audioManager inputVolume]];
	
	int state = ([audioManager mutesInput] == YES) ? NSOnState : NSOffState;
	[muteAudioInputSwitch setState:state];
	
	[self _validateAudioControls];
}

- (IBAction)changeAudioOutputDevice:(id)sender
{
	XMAudioManager *audioManager = [XMAudioManager sharedInstance];
	
	NSString *device = [audioOutputDevicesPopUp titleOfSelectedItem];
	
	if(![audioManager setSelectedOutputDevice:device])
	{
		[audioOutputDevicesPopUp selectItemWithTitle:[audioManager selectedOutputDevice]];
	}
	
	[audioOutputVolumeSlider setIntValue:[audioManager outputVolume]];
	
	int state = ([audioManager mutesOutput] == YES) ? NSOnState : NSOffState;
	[muteAudioOutputSwitch setState:state];
	
	[self _validateAudioControls];
}

- (IBAction)changeAudioInputVolume:(id)sender
{
	XMAudioManager *audioManager = [XMAudioManager sharedInstance];
	
	unsigned volume = (unsigned)[audioInputVolumeSlider intValue];
	
	if(![audioManager setInputVolume:volume])
	{
		[audioInputVolumeSlider setIntValue:[audioManager inputVolume]];
	}
	[self _validateAudioControls];
}

- (IBAction)changeAudioOutputVolume:(id)sender
{
	XMAudioManager *audioManager = [XMAudioManager sharedInstance];
	
	unsigned volume = (unsigned)[audioOutputVolumeSlider intValue];
	
	if(![audioManager setOutputVolume:volume])
	{
		[audioOutputVolumeSlider setIntValue:[audioManager outputVolume]];
	}
	[self _validateAudioControls];
}

- (IBAction)toggleMuteAudioInput:(id)sender
{
	XMAudioManager *audioManager = [XMAudioManager sharedInstance];
	
	BOOL muteAudio = ([muteAudioInputSwitch state] == NSOnState) ? YES : NO;
	
	if(![audioManager setMutesInput:muteAudio])
	{
		int state = ([audioManager mutesInput] == YES) ? NSOnState : NSOffState;
		[muteAudioInputSwitch setState:state];
	}
}

- (IBAction)toggleMuteAudioOutput:(id)sender
{
	XMAudioManager *audioManager = [XMAudioManager sharedInstance];
	
	BOOL muteAudio = ([muteAudioOutputSwitch state] == NSOnState) ? YES : NO;
	
	if(![audioManager setMutesOutput:muteAudio])
	{
		int state = ([audioManager mutesOutput] == YES) ? NSOnState : NSOffState;
		[muteAudioOutputSwitch setState:state];
	}
}

- (IBAction)restoreDefaultSettings:(id)sender
{
	XMVideoManager *videoManager = [XMVideoManager sharedInstance];
	
	NSString *device = [videoDevicesPopUp titleOfSelectedItem];
	
	[videoManager setDefaultSettingsForDevice:device];
}

- (IBAction)closeVideoDeviceSettingsPanel:(id)sender
{
	[NSApp endSheet:videoDeviceSettingsPanel returnCode:NSOKButton];
	[videoDeviceSettingsPanel orderOut:self];
	
	[videoDeviceSettingsView stopDisplayingLocalVideo];
	
	[videoDeviceSettingsBox setContentView:nil];
}

#pragma mark Private Methods

- (void)_validateAudioControls
{
	XMAudioManager *audioManager = [XMAudioManager sharedInstance];
	
	BOOL enableControls = [audioManager canAlterInputVolume];
	[audioInputVolumeSlider setEnabled:enableControls];
	[muteAudioInputSwitch setEnabled:enableControls];
	
	enableControls = [audioManager canAlterOutputVolume];
	[audioOutputVolumeSlider setEnabled:enableControls];
	[muteAudioOutputSwitch setEnabled:enableControls];
}

- (void)_didStartVideoInputDeviceListUpdate:(NSNotification *)notif
{
	[videoDevicesPopUp setEnabled:NO];
	[videoDeviceSettingsButton setEnabled:NO];
}

- (void)_didUpdateVideoInputDeviceList:(NSNotification *)notif
{
	XMVideoManager *videoManager = [XMVideoManager sharedInstance];
	
	NSString *device = [videoManager selectedInputDevice];
	
	[videoDevicesPopUp removeAllItems];
	[videoDevicesPopUp addItemsWithTitles:[videoManager inputDevices]];
	[videoDevicesPopUp selectItemWithTitle:device];
		
	if([[[XMPreferencesManager sharedInstance] activeLocation] enableVideo] == YES)
	{
		[videoDevicesPopUp setEnabled:YES];
	
		BOOL settingsButtonIsEnabled = NO;
		if([videoManager deviceHasSettings:device])
		{
			settingsButtonIsEnabled = YES;
		}
	
		[videoDeviceSettingsButton setEnabled:settingsButtonIsEnabled];
	}
}

- (void)_didStartVideoInputDeviceChange:(NSNotification *)notif
{
	[videoDevicesPopUp setEnabled:NO];
	[videoDeviceSettingsButton setEnabled:NO];
}

- (void)_didChangeSelectedVideoInputDevice:(NSNotification *)notif
{
	XMVideoManager *videoManager = [XMVideoManager sharedInstance];
	
	NSString *device = [videoManager selectedInputDevice];
	
	[videoDevicesPopUp selectItemWithTitle:device];
	[videoDevicesPopUp setEnabled:YES];
	
	BOOL settingsButtonIsEnabled = NO;
	if([videoManager deviceHasSettings:device])
	{
		settingsButtonIsEnabled = YES;
	}
	
	[videoDeviceSettingsButton setEnabled:settingsButtonIsEnabled];
	
	if([videoManager requiresSettingsDialogWhenDeviceIsSelected:device])
	{
		[self showVideoDeviceSettings:nil];
	}
}

- (void)_audioInputVolumeDidChange:(NSNotification *)notif
{
	XMAudioManager *audioManager = [XMAudioManager sharedInstance];
	
	[audioInputVolumeSlider setIntValue:[audioManager inputVolume]];
	
	int state = ([audioManager mutesInput] == YES) ? NSOnState : NSOffState;
	[muteAudioInputSwitch setState:state];
}

- (void)_audioOutputVolumeDidChange:(NSNotification *)notif
{
	XMAudioManager *audioManager = [XMAudioManager sharedInstance];
	
	[audioOutputVolumeSlider setIntValue:[audioManager outputVolume]];
	
	int state = ([audioManager mutesOutput] == YES) ? NSOnState : NSOffState;
	[muteAudioOutputSwitch setState:state];
}

- (void)_didUpdateAudioDeviceLists:(NSNotification *)notif
{
	XMAudioManager *audioManager = [XMAudioManager sharedInstance];
	[audioInputDevicesPopUp removeAllItems];
	[audioInputDevicesPopUp addItemsWithTitles:[audioManager inputDevices]];
	[audioInputDevicesPopUp selectItemWithTitle:[audioManager selectedInputDevice]];
	
	[audioOutputDevicesPopUp removeAllItems];
	[audioOutputDevicesPopUp addItemsWithTitles:[audioManager outputDevices]];
	[audioOutputDevicesPopUp selectItemWithTitle:[audioManager selectedOutputDevice]];
	
	[self _audioInputVolumeDidChange:nil];
	[self _audioOutputVolumeDidChange:nil];
}

- (void)_preferencesDidChange:(NSNotification *)notif
{
	// this takes into account that
	// - video may get disabled
	// - video may become mirrored
	// - video devices may become inactive
	// The easiest solution is to close the sheet in this case
	if([videoDeviceSettingsPanel isVisible] == YES)
	{
		[self closeVideoDeviceSettingsPanel:self];
	}
	
	BOOL mirrorLocalVideo = [[XMPreferencesManager sharedInstance] showSelfViewMirrored];
	[localVideoView setLocalVideoMirrored:mirrorLocalVideo];
}

- (void)_activeLocationDidChange:(NSNotification *)notif
{
	if(isActive == NO)
	{
		return;
	}
	
	XMLocation *location = [[XMPreferencesManager sharedInstance] activeLocation];
	
	BOOL showVideoContent = [location enableVideo];
	
	if(showVideoContent == YES)
	{
		XMVideoManager *videoManager = [XMVideoManager sharedInstance];
		
		[localVideoView startDisplayingLocalVideo];
		
		[videoDevicesPopUp setEnabled:YES];
			
		NSString *device = [videoManager selectedInputDevice];
		if([videoManager deviceHasSettings:device] == YES)
		{
			[videoDeviceSettingsButton setEnabled:YES];
		}
		
		[videoDisabledFld setStringValue:@""];
		
		BOOL mirrorLocalVideo = [[XMPreferencesManager sharedInstance] showSelfViewMirrored];
		[localVideoView setLocalVideoMirrored:mirrorLocalVideo];
	}
	else
	{
		[localVideoView setNoVideoImage:[NSImage imageNamed:@"no_video_screen.tif"]];
		[localVideoView startDisplayingNoVideo];
		
		[videoDevicesPopUp setEnabled:NO];
		[videoDeviceSettingsButton setEnabled:NO];
		[videoDisabledFld setStringValue:NSLocalizedString(@"XM_AUDIO_VIDEO_MODULE_VIDEO_DISABLED", @"")];
	}
}

- (void)_didUpdateAudioInputLevel:(NSNotification *)notif
{
	XMAudioManager *audioManager = [XMAudioManager sharedInstance];
	double level = [audioManager inputLevel];
	
	[audioInputLevelIndicator setDoubleValue:(22.0 * level)];
}

@end
