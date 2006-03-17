/*
 * $Id: XMLocalAudioVideoModule.m,v 1.13 2006/03/17 13:47:09 hfriederich Exp $
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
- (void)_audioInputVolumeDidChange:(NSNotification *)notif;
- (void)_audioOutputVolumeDidChange:(NSNotification *)notif;
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
		[videoDisabledFld setStringValue:@"Video is disabled"];
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
	XMAudioManager *audioManager = [XMAudioManager sharedInstance];
	[audioInputDevicesPopUp removeAllItems];
	[audioInputDevicesPopUp addItemsWithTitles:[audioManager inputDevices]];
	
	[audioInputDevicesPopUp selectItemWithTitle:[audioManager selectedInputDevice]];
	[audioOutputDevicesPopUp removeAllItems];
	[audioOutputDevicesPopUp addItemsWithTitles:[audioManager outputDevices]];
	[audioOutputDevicesPopUp selectItemWithTitle:[audioManager selectedOutputDevice]];
	
	[self _audioInputVolumeDidChange:nil];
	[self _audioOutputVolumeDidChange:nil];
	[self _validateAudioControls];
	
	// registering for notifications
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

	[notificationCenter addObserver:self selector:@selector(_didStartVideoInputDeviceListUpdate:)
							   name:XMNotification_VideoManagerDidStartInputDeviceListUpdate object:nil];
	[notificationCenter addObserver:self selector:@selector(_didUpdateVideoInputDeviceList:)
							   name:XMNotification_VideoManagerDidUpdateInputDeviceList object:nil];
	[notificationCenter addObserver:self selector:@selector(_audioInputVolumeDidChange:)
							   name:XMNotification_AudioManagerInputVolumeDidChange object:nil];
	[notificationCenter addObserver:self selector:@selector(_audioOutputVolumeDidChange:)
							   name:XMNotification_AudioManagerOutputVolumeDidChange object:nil];
	
	[notificationCenter addObserver:self selector:@selector(_activeLocationDidChange:)
							   name:XMNotification_PreferencesManagerDidChangeActiveLocation object:nil];
	
}

#pragma mark Protocol Methods

- (NSString *)name
{
	return @"Local Audio/Video Control";
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
	[self _activeLocationDidChange:nil];
}

- (void)becomeInactiveModule
{
	// simply deactivate both instead of querying which
	// one is active
	[localVideoView stopDisplayingLocalVideo];
	[localVideoView stopDisplayingNoVideo];
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
	
	BOOL settingsButtonIsEnabled = NO;
	if([videoManager deviceHasSettings:device])
	{
		settingsButtonIsEnabled = YES;
	}
	
	[videoDeviceSettingsButton setEnabled:settingsButtonIsEnabled];
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
	
	int state = ([audioManager mutesInputVolume] == YES) ? NSOnState : NSOffState;
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
	
	int state = ([audioManager mutesOutputVolume] == YES) ? NSOnState : NSOffState;
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
	
	if(![audioManager setMutesInputVolume:muteAudio])
	{
		int state = ([audioManager mutesInputVolume] == YES) ? NSOnState : NSOffState;
		[muteAudioInputSwitch setState:state];
	}
}

- (IBAction)toggleMuteAudioOutput:(id)sender
{
	XMAudioManager *audioManager = [XMAudioManager sharedInstance];
	
	BOOL muteAudio = ([muteAudioOutputSwitch state] == NSOnState) ? YES : NO;
	
	if(![audioManager setMutesOutputVolume:muteAudio])
	{
		int state = ([audioManager mutesOutputVolume] == YES) ? NSOnState : NSOffState;
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

- (void)_audioInputVolumeDidChange:(NSNotification *)notif
{
	NSLog(@"volume changed");
	XMAudioManager *audioManager = [XMAudioManager sharedInstance];
	
	[audioInputVolumeSlider setIntValue:[audioManager inputVolume]];
	
	int state = ([audioManager mutesInputVolume] == YES) ? NSOnState : NSOffState;
	[muteAudioInputSwitch setState:state];
}

- (void)_audioOutputVolumeDidChange:(NSNotification *)notif
{
	XMAudioManager *audioManager = [XMAudioManager sharedInstance];
	
	[audioOutputVolumeSlider setIntValue:[audioManager outputVolume]];
	
	int state = ([audioManager mutesOutputVolume] == YES) ? NSOnState : NSOffState;
	[muteAudioOutputSwitch setState:state];
}

- (void)_activeLocationDidChange:(NSNotification *)notif
{
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
	}
	else
	{
		[localVideoView setNoVideoImage:[NSImage imageNamed:@"no_video_screen.tif"]];
		[localVideoView startDisplayingNoVideo];
		
		[videoDevicesPopUp setEnabled:NO];
		[videoDeviceSettingsButton setEnabled:NO];
		[videoDisabledFld setStringValue:@"Video is disabled"];
	}
}

@end
