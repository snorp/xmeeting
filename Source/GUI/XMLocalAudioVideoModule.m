/*
 * $Id: XMLocalAudioVideoModule.m,v 1.1 2005/08/24 22:29:39 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMeeting.h"
#import "XMLocalAudioVideoModule.h"
#import "XMMainWindowController.h"

#define COLLAPSED_CONTENT_WIDTH 20.0

@interface XMLocalAudioVideoModule (PrivateMethods)

- (void)_validateControls;
- (void)_audioInputVolumeDidChange:(NSNotification *)notif;
- (void)_audioOutputVolumeDidChange:(NSNotification *)notif;

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
	expandedContentViewSize = [contentView frame].size;
	collapsedContentViewSize = NSMakeSize(COLLAPSED_CONTENT_WIDTH, expandedContentViewSize.height);
	isExpanded = YES;
	[contentDisclosure setState:NSOnState];
	
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
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	[notificationCenter addObserver:self selector:@selector(_audioInputVolumeDidChange:)
							   name:XMNotification_AudioManagerInputVolumeDidChange object:nil];
	[notificationCenter addObserver:self selector:@selector(_audioOutputVolumeDidChange:)
							   name:XMNotification_AudioManagerOutputVolumeDidChange object:nil];
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
	
	if(isExpanded)
	{
		return expandedContentViewSize;
	}
	else
	{
		return collapsedContentViewSize;
	}
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
	isExpanded = !isExpanded;
	
	[[XMMainWindowController sharedInstance] noteSizeValuesDidChangeOfSupportModule:self];
}

- (IBAction)changeVideoDevice:(id)sender
{
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

@end
