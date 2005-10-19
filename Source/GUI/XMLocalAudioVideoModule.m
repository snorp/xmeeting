/*
 * $Id: XMLocalAudioVideoModule.m,v 1.3 2005/10/19 22:09:17 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMLocalAudioVideoModule.h"

#import "XMeeting.h"
#import "XMMainWindowController.h"
#import "XMPreferencesManager.h"
#import "XMLocalAudioVideoView.h"

@interface XMLocalAudioVideoModule (PrivateMethods)

- (void)_validateControls;
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
	[[XMMainWindowController sharedInstance] addSupportModule:self];
	
	nibLoader = nil;
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

- (void)awakeFromNib
{	
	// we start in expanded state
	[contentView setShowAudioVideoContent:YES];
	[contentDisclosure setState:NSOnState];
	
	// determining wether to initially show the video content or not
	BOOL showVideoContent = [[[XMPreferencesManager sharedInstance] activeLocation] enableVideo];
	[contentView setShowVideoContent:showVideoContent];
	
	// configuring the video content
	[videoDevicesPopUp setEnabled:NO];
	[localVideoView startDisplayingLocalVideo];
	
	// configuring the audio content
	XMAudioManager *audioManager = [XMAudioManager sharedInstance];
	[audioInputDevicesPopUp removeAllItems];
	[audioInputDevicesPopUp addItemsWithTitles:[audioManager inputDevices]];
	
	[audioInputDevicesPopUp selectItemWithTitle:[audioManager selectedInputDevice]];
	[audioOutputDevicesPopUp removeAllItems];
	[audioOutputDevicesPopUp addItemsWithTitles:[audioManager outputDevices]];
	[audioOutputDevicesPopUp selectItemWithTitle:[audioManager selectedOutputDevice]];
	
	[audioInputVolumeSlider setIntValue:[audioManager inputVolume]];
	[audioOutputVolumeSlider setIntValue:[audioManager outputVolume]];
	
	int state = ([audioManager mutesInputVolume] == YES) ? NSOnState : NSOffState;
	[muteAudioInputSwitch setState:state];
	
	state = ([audioManager mutesOutputVolume] == YES) ? NSOnState : NSOffState;
	[muteAudioOutputSwitch setState:state];
	
	[self _validateControls];
	
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
							   name:XMNotification_ActiveLocationDidChange object:nil];
}

#pragma mark Protocol Methods

- (NSString *)name
{
	return @"Local Audio/Video control";
}

- (NSView *)contentView
{
	if(nibLoader == nil)
	{
		nibLoader = [[NSNib alloc] initWithNibNamed:@"LocalAudioVideoModule" bundle:nil];
		[nibLoader instantiateNibWithOwner:self topLevelObjects:nil];
	}
	
	return contentView;
}

- (NSSize)contentViewSize
{
	// if not already done, this triggers the loading of the nib file
	[self contentView];
	
	return [contentView requiredSize];
}

- (void)becomeActiveModule
{
}

- (void)becomeInactiveModule
{
}

#pragma mark Action Methods

- (IBAction)toggleShowContent:(id)sender
{
	int state = [contentDisclosure state];
	
	BOOL showAudioVideoContent = (state == NSOnState) ? YES : NO;
	[contentView setShowAudioVideoContent:showAudioVideoContent];

	[contentView setContentVisible:NO];
	[[XMMainWindowController sharedInstance] noteSizeValuesDidChangeOfSupportModule:self];
	[contentView setContentVisible:YES];
}

- (IBAction)changeVideoDevice:(id)sender
{
	XMVideoManager *videoManager = [XMVideoManager sharedInstance];
	
	NSString *device = [videoDevicesPopUp titleOfSelectedItem];
	
	[videoManager setSelectedInputDevice:device];
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
	
	[self _validateControls];
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
	
	[self _validateControls];
}

- (IBAction)changeAudioInputVolume:(id)sender
{
	XMAudioManager *audioManager = [XMAudioManager sharedInstance];
	
	unsigned volume = (unsigned)[audioInputVolumeSlider intValue];
	
	if(![audioManager setInputVolume:volume])
	{
		[audioInputVolumeSlider setIntValue:[audioManager inputVolume]];
	}
	[self _validateControls];
}

- (IBAction)changeAudioOutputVolume:(id)sender
{
	XMAudioManager *audioManager = [XMAudioManager sharedInstance];
	
	unsigned volume = (unsigned)[audioOutputVolumeSlider intValue];
	
	if(![audioManager setOutputVolume:volume])
	{
		[audioOutputVolumeSlider setIntValue:[audioManager outputVolume]];
	}
	[self _validateControls];
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

#pragma mark Private Methods

- (void)_validateControls
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
}

- (void)_didUpdateVideoInputDeviceList:(NSNotification *)notif
{
	XMVideoManager *videoManager = [XMVideoManager sharedInstance];
	
	[videoDevicesPopUp setEnabled:YES];
	[videoDevicesPopUp removeAllItems];
	[videoDevicesPopUp addItemsWithTitles:[videoManager inputDevices]];
	[videoDevicesPopUp selectItemWithTitle:[videoManager selectedInputDevice]];
}

- (void)_audioInputVolumeDidChange:(NSNotification *)notif
{
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
	[contentView setShowVideoContent:showVideoContent];
	
	[contentView setContentVisible:NO];
	[[XMMainWindowController sharedInstance] noteSizeValuesDidChangeOfSupportModule:self];
	[contentView setContentVisible:YES];
}

@end
