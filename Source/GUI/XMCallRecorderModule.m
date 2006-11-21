/*
 * $Id: XMCallRecorderModule.m,v 1.4 2006/11/21 10:08:11 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMeeting.h"
#import "XMCallRecorderModule.h"
#import "XMMainWindowController.h"
#import "XMWindow.h"

NSString *XMKey_RecordAudio = @"XMeeting_RecordAudio";
NSString *XMKey_RecordVideo = @"XMeeting_RecordVideo";
NSString *XMKey_RecordVideoMode = @"XMeeting_RecordVideoMode";
NSString *XMKey_RecordVideoSource = @"XMeeting_RecordVideoSource";
NSString *XMKey_RecordVideoCodec = @"XMeeting_RecordVideoCodec";
NSString *XMKey_RecordVideoQuality = @"XMeeting_RecordVideoQuality";
NSString *XMKey_RecordVideoEnableBandwidthLimit = @"XMeeting_RecordVideoEnableBandwidthLimit";
NSString *XMKey_RecordVideoBandwidthLimit = @"XMeeting_RecordVideoBandwidthLimit";
NSString *XMKey_RecordVideoLowPriority = @"XMeeting_RecordVideoLowPriority";

#define XM_MIXED_MODE 0
#define XM_REMOTE_ONLY_MODE 1
#define XM_LOCAL_ONLY_MODE 2

#define XM_BOTH_SOURCES 0
#define XM_REMOTE_SOURCE 1
#define XM_LOCAL_SOURCE 2

@interface XMCallRecorderModule (PrivateMethods)

- (void)_validateGUI;
- (void)_savePanelDidEnd:(NSSavePanel *)savePanel returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)_callRecorderDidEndRecording:(NSNotification *)notif;
- (void)_displayRecording:(NSString *)filePath;
- (void)_setupRecorderWindow;
- (void)_showRecorderWindow;
- (void)_hideRecorderWindow;
- (void)_mainWindowDidResize:(NSNotification *)notif;
- (void)_didBeginFullScreen:(NSNotification *)notif;
- (void)_didEndFullScreen:(NSNotification *)notif;
- (void)_preferencesDidChange:(NSNotification *)notif;
- (void)_adjustRecorderWindow;

@end

@implementation XMCallRecorderModule

#pragma mark Init & Deallocation Methods

- (id)init
{
	self = [super init];
	
	recorderWindow = nil;
	
	return self;
}

- (void)awakeFromNib
{
	contentViewSize = [contentView frame].size;
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	BOOL enableAudio = [userDefaults boolForKey:XMKey_RecordAudio];
	BOOL enableVideo = [userDefaults boolForKey:XMKey_RecordVideo];
	unsigned videoMode = [userDefaults integerForKey:XMKey_RecordVideoMode];
	unsigned videoSourceMode = [userDefaults integerForKey:XMKey_RecordVideoSource];
	XMCodecIdentifier codecIdentifier = (XMCodecIdentifier)[userDefaults integerForKey:XMKey_RecordVideoCodec];
	unsigned videoQuality = (unsigned)[userDefaults integerForKey:XMKey_RecordVideoQuality];
	BOOL enableBWLimit = [userDefaults boolForKey:XMKey_RecordVideoEnableBandwidthLimit];
	unsigned bwLimit = (unsigned)[userDefaults integerForKey:XMKey_RecordVideoBandwidthLimit];
	BOOL lowPriorityRecording = [userDefaults boolForKey:XMKey_RecordVideoLowPriority];
	
	if(codecIdentifier == XMCodecIdentifier_UnknownCodec)
	{
		codecIdentifier = XMCodecIdentifier_MPEG4;
	}
	if(videoQuality == 0) {
		videoQuality = 3;
	}
	
	int state = (enableAudio == YES) ? NSOnState : NSOffState;
	[recordAudioSwitch setState:state];
	state = (enableVideo == YES) ? NSOnState : NSOffState;
	[recordVideoSwitch setState:state];
	
	[videoModePopUp selectItemWithTag:videoMode];
	
	[videoSourceMatrix selectCellWithTag:videoSourceMode];
	
	[videoCodecPopUp selectItemWithTag:(int)codecIdentifier];
	
	[videoQualitySlider setIntValue:videoQuality];
	
	state = (enableBWLimit == YES) ? NSOnState : NSOffState;
	[dataRateLimitSwitch setState:state];
	
	if(bwLimit == 0) 
	{
		bwLimit = 1420;
	}
	[dataRateLimitField setIntValue:bwLimit];
	bwLimitString = [[dataRateLimitField stringValue] retain];
	
	state = (lowPriorityRecording == YES) ? NSOnState : NSOffState;
	[lowPrioritySwitch setState:state];
	
	[self _validateGUI];
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(_callRecorderDidEndRecording:)
							   name:XMNotification_CallRecorderDidEndRecording object:nil];
	[notificationCenter addObserver:self selector:@selector(_mainWindowDidResize:)
							   name:NSWindowDidResizeNotification object:[[XMMainWindowController sharedInstance] window]];
	[notificationCenter addObserver:self selector:@selector(_didBeginFullScreen:)
							   name:XMNotification_DidBeginFullScreenMode object:nil];
	[notificationCenter addObserver:self selector:@selector(_didEndFullScreen:)
							   name:XMNotification_DidEndFullScreenMode object:nil];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[bwLimitString release];
	[recorderWindow release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Module Methods

- (NSString *)identifier
{
	return @"Call Recorder";
}

- (NSString *)name
{
	return NSLocalizedString(@"XM_CALL_RECORDER_MODULE_NAME", @"");
}

- (NSImage *)image
{
	return nil;
}

- (NSView *)contentView
{
	if(contentView == nil)
	{
		[NSBundle loadNibNamed:@"CallRecorderModule" owner:self];
	}
	
	return contentView;
}

- (NSSize)contentViewSize
{
	// if not already done, causing the nib file to load
	[self contentView];
	
	return contentViewSize;
}

- (void)becomeActiveModule
{
}

- (void)becomeInactiveModule
{
}

#pragma mark -
#pragma mark Action Methods

- (IBAction)toggleRecording:(id)sender
{
	XMCallRecorder *recorder = [XMCallRecorder sharedInstance];
	
	if([recorder isRecording]) 
	{
		[recorder stopRecording];
	}
	else
	{
		NSSavePanel *savePanel = [NSSavePanel savePanel];
		[savePanel beginSheetForDirectory:nil file:nil modalForWindow:[contentView window]
							modalDelegate:self didEndSelector:@selector(_savePanelDidEnd:returnCode:contextInfo:)
							  contextInfo:NULL];
	}
}

- (IBAction)toggleRecordAudio:(id)sender
{
	BOOL enabled = ([recordAudioSwitch state] == NSOnState) ? YES : NO;
	[[NSUserDefaults standardUserDefaults] setBool:enabled forKey:XMKey_RecordAudio];
	[self _validateGUI];
}

- (IBAction)toggleRecordVideo:(id)sender
{
	BOOL enabled = ([recordVideoSwitch state] == NSOnState) ? YES : NO;
	[[NSUserDefaults standardUserDefaults] setBool:enabled forKey:XMKey_RecordVideo];
	[self _validateGUI];
}

- (IBAction)videoModeSelected:(id)sender
{
	int tag = [[videoModePopUp selectedItem] tag];
	[[NSUserDefaults standardUserDefaults] setInteger:tag forKey:XMKey_RecordVideoMode];
	[self _validateGUI];
}

- (IBAction)videoSourceSelected:(id)sender
{
	int tag = [[videoSourceMatrix selectedCell] tag];
	[[NSUserDefaults standardUserDefaults] setInteger:tag forKey:XMKey_RecordVideoSource];
	[self _validateGUI];
	
	BOOL recordLocalVideo = NO;
	BOOL recordRemoteVideo = NO;
	
	if(tag == XM_BOTH_SOURCES)
	{
		recordLocalVideo = YES;
		recordRemoteVideo = YES;
	}
	else if(tag == XM_REMOTE_SOURCE)
	{
		recordRemoteVideo = YES;
	}
	else
	{
		recordLocalVideo = YES;
	}
	
	[[XMCallRecorder sharedInstance] setRecordLocalVideo:recordLocalVideo recordRemoteVideo:recordRemoteVideo];
}

- (IBAction)videoCodecSelected:(id)sender
{
	int tag = [[videoCodecPopUp selectedItem] tag];
	[[NSUserDefaults standardUserDefaults] setInteger:tag forKey:XMKey_RecordVideoCodec];
	[self _validateGUI];
}

- (IBAction)videoQualitySelected:(id)sender
{
	int value = [videoQualitySlider intValue];
	[[NSUserDefaults standardUserDefaults] setInteger:value forKey:XMKey_RecordVideoQuality];
}

- (IBAction)toggleEnableVideoBandwidthLimit:(id)sender
{
	BOOL enabled = ([dataRateLimitSwitch state] == NSOnState) ? YES : NO;
	[[NSUserDefaults standardUserDefaults] setBool:enabled forKey:XMKey_RecordVideoEnableBandwidthLimit];
	[self _validateGUI];
}

- (IBAction)toggleLowPriorityRecording:(id)sender
{
	BOOL enabled = ([lowPrioritySwitch state] == NSOnState) ? YES : NO;
	[[NSUserDefaults standardUserDefaults] setBool:enabled forKey:XMKey_RecordVideoLowPriority];
}

- (void)controlTextDidChange:(NSNotification *)notif
{
	NSString *string = [dataRateLimitField stringValue];
	NSScanner *scanner = [[NSScanner alloc] initWithString:string];
	int value;
	
	if([scanner isAtEnd] || ([scanner scanInt:&value] && [scanner isAtEnd]))
	{
		[bwLimitString release];
		bwLimitString = [string retain];
		[[NSUserDefaults standardUserDefaults] setInteger:value forKey:XMKey_RecordVideoBandwidthLimit];
	}
	else
	{
		[dataRateLimitField setStringValue:bwLimitString];
	}
	
	[scanner release];
}

#pragma mark -
#pragma mark Private Methods

- (void)_validateGUI
{
	BOOL enableRecordButton = YES;
	BOOL enableAudioVideoSwitches = NO;
	BOOL enableVideoModePopUp = NO;
	BOOL enableSourceMatrix = NO;
	BOOL enableLowPrioritySwitch = NO;
	BOOL enableVideoDetails = NO;
	BOOL enableBWSwitch = NO;
	BOOL enableBWTextField = NO;
	
	BOOL isRecording = [[XMCallRecorder sharedInstance] isRecording];
	int recordAudioSwitchState = [recordAudioSwitch state];
	int recordVideoSwitchState = [recordVideoSwitch state];
	int videoModeTag = [[videoModePopUp selectedItem] tag];
	
	if(recordAudioSwitchState == NSOffState && recordVideoSwitchState == NSOffState)
	{
		enableRecordButton = NO;
	}
	
	if(isRecording == NO)
	{
		enableAudioVideoSwitches = YES;
	
		if(recordVideoSwitchState == NSOnState)
		{
			enableVideoModePopUp = YES;
			int tag = [[videoCodecPopUp selectedItem] tag];
			
			if(videoModeTag == XM_MIXED_MODE)
			{
				enableLowPrioritySwitch = YES;
			}
			if(videoModeTag != XM_REMOTE_ONLY_MODE)
			{
				enableVideoDetails = YES;
				if([[XMCallRecorder sharedInstance] videoCodecSupportsDataRateControl:(XMCodecIdentifier)tag])
				{
					enableBWSwitch = YES;
					int state = [dataRateLimitSwitch state];
					if(state == NSOnState)
					{
						enableBWTextField = YES;
					}
				}
			}
		}
	}
	
	if(recordVideoSwitchState == NSOnState && videoModeTag == XM_MIXED_MODE)
	{
		enableSourceMatrix = YES;
	}
	
	[recordButton setEnabled:enableRecordButton];
	
	[recordAudioSwitch setEnabled:enableAudioVideoSwitches];
	[recordVideoSwitch setEnabled:enableAudioVideoSwitches];
	
	[videoModePopUp setEnabled:enableVideoModePopUp];
	[videoSourceMatrix setEnabled:enableSourceMatrix];
	[videoCodecPopUp setEnabled:enableVideoDetails];
	[videoQualitySlider setEnabled:enableVideoDetails];
	[lowPrioritySwitch setEnabled:enableLowPrioritySwitch];
	
	[dataRateLimitSwitch setEnabled:enableBWSwitch];
	
	[dataRateLimitField setEnabled:enableBWTextField];
}

- (void)_savePanelDidEnd:(NSSavePanel *)savePanel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if(returnCode == NSOKButton)
	{
		NSString *filePath = [savePanel filename];
		
		XMCodecIdentifier audioCodec = XMCodecIdentifier_UnknownCodec;
		if([recordAudioSwitch state] == NSOnState) 
		{
			audioCodec = XMCodecIdentifier_LinearPCM;
		}
		XMCodecIdentifier videoCodec = XMCodecIdentifier_UnknownCodec;
		if([recordVideoSwitch state] == NSOnState) 
		{
			int videoMode = [[videoModePopUp selectedItem] tag];
			
			int videoSource = [[videoSourceMatrix selectedCell] tag];
			
			videoCodec = (XMCodecIdentifier)[[videoCodecPopUp selectedItem] tag];
			int quality = [videoQualitySlider intValue];
			XMCodecQuality codecQuality;
			
			switch(quality)
			{
				case 1:
					codecQuality = XMCodecQuality_Min;
					break;
				case 2:
					codecQuality = XMCodecQuality_Low;
					break;
				case 3:
					codecQuality = XMCodecQuality_Normal;
					break;
				case 4:
					codecQuality = XMCodecQuality_High;
					break;
				case 5:
					codecQuality = XMCodecQuality_Max;
					break;
				default: // Should not happen
					codecQuality = XMCodecQuality_Normal;
					break;
			}
			
			unsigned dataRateLimit = 0;
			if([dataRateLimitSwitch state] == NSOnState)
			{
				dataRateLimit = [dataRateLimitField intValue];
				if(dataRateLimit < 64)
				{
					dataRateLimit = 64;
				}
			}
			dataRateLimit *= 1000; // get data rate in bit/s
			
			BOOL lowPriorityRecording = NO;
			if([lowPrioritySwitch state] == NSOnState)
			{
				lowPriorityRecording = YES;
			}
			
			BOOL result;
			if(videoMode == XM_MIXED_MODE)
			{
				BOOL recordLocalVideo = NO;
				BOOL recordRemoteVideo = NO;
				if(videoSource == XM_BOTH_SOURCES)
				{
					recordLocalVideo = YES;
					recordRemoteVideo = YES;
				}
				else if(videoSource == XM_LOCAL_SOURCE)
				{
					recordLocalVideo = YES;
				}
				else
				{
					recordRemoteVideo = YES;
				}
				result = [[XMCallRecorder sharedInstance] startRecordingInRecompressionModeToFile:filePath
																			 videoCodecIdentifier:videoCodec
																				videoCodecQuality:codecQuality
																					videoDataRate:dataRateLimit
																				 recordLocalVideo:recordLocalVideo
																				recordRemoteVideo:recordRemoteVideo
																			 audioCodecIdentifier:audioCodec
																			 lowPriorityRecording:lowPriorityRecording];
			}
			else if(videoMode == XM_LOCAL_ONLY_MODE)
			{
				result = [[XMCallRecorder sharedInstance] startRecordingInLocalVideoModeToFile:filePath
																		  videoCodecIdentifier:videoCodec
																			 videoCodecQuality:codecQuality
																				 videoDataRate:dataRateLimit
																		  audioCodecIdentifier:audioCodec];
			}
			else
			{
				result = [[XMCallRecorder sharedInstance] startRecordingInRemoteVideoModeToFile:filePath
																		   audioCodecIdentifier:audioCodec];
			}
			if(result == YES)
			{
				[self _displayRecording:filePath];
			}
		}
		else
		{
			BOOL result = [[XMCallRecorder sharedInstance] startRecordingInAudioOnlyModeToFile:filePath
																		  audioCodecIdentifier:audioCodec];
			if(result == YES)
			{
				[self _displayRecording:filePath];
			}
		}
	}
}

- (void)_callRecorderDidEndRecording:(NSNotification *)notif
{
	[recordButton setTitle:NSLocalizedString(@"XM_CALL_RECORDER_MODULE_START_RECORDING", @"")];
	[filePathTextField setStringValue:@""];
	[self _validateGUI];
	[self _hideRecorderWindow];
}

- (void)_displayRecording:(NSString *)filePath
{
	[recordButton setTitle:NSLocalizedString(@"XM_CALL_RECORDER_MODULE_STOP_RECORDING", @"")];
	[filePathTextField setStringValue:filePath];
	[self _validateGUI];
	
	if(recorderWindow == nil)
	{
		[self _setupRecorderWindow];
	}
	
	[self _showRecorderWindow];
}

- (void)_setupRecorderWindow
{
	NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 12, 12)];
	[imageView setImage:[NSImage imageNamed:@"recording.gif"]];
	[imageView setImageFrameStyle:NSImageFrameNone];
	[imageView setImageScaling:NSScaleToFit];
	[imageView setEditable:NO];
	[imageView setAnimates:YES];
	
	recorderWindow = [[XMChildWindow alloc] initWithContentRect:NSMakeRect(0, 0, 12, 12)
													  styleMask:NSBorderlessWindowMask
														backing:NSBackingStoreBuffered
														  defer:NO];
	[recorderWindow setOpaque:NO];
	[recorderWindow setBackgroundColor:[NSColor clearColor]];
	[recorderWindow setContentView:imageView];
	[imageView release];
}

- (void)_showRecorderWindow
{
	[(NSImageView *)[recorderWindow contentView] setAnimates:YES];
	
	XMMainWindowController *mainWindowController = [XMMainWindowController sharedInstance];
	NSWindow *window;
	if([mainWindowController isFullScreen])
	{
		window = [mainWindowController fullScreenWindow];
	}
	else
	{
		window = [mainWindowController window];
	}
	[self _adjustRecorderWindow];
	[window addChildWindow:recorderWindow ordered:NSWindowAbove];
	
	[recorderWindow orderFront:self];
}

- (void)_hideRecorderWindow
{
	XMMainWindowController *mainWindowController = [XMMainWindowController sharedInstance];
	NSWindow *window;
	if([mainWindowController isFullScreen])
	{
		window = [mainWindowController fullScreenWindow];
	}
	else
	{
		window = [mainWindowController window];
	}
	[window removeChildWindow:recorderWindow];
	[recorderWindow orderOut:self];
	
	[(NSImageView *)[recorderWindow contentView] setAnimates:NO];
}

- (void)_mainWindowDidResize:(NSNotification *)notif
{
	if(recorderWindow != nil && [recorderWindow isVisible])
	{
		[self _adjustRecorderWindow];
	}
}

- (void)_didBeginFullScreen:(NSNotification *)notif
{
	if(recorderWindow != nil && [recorderWindow isVisible])
	{
		XMMainWindowController *mainWindowController = [XMMainWindowController sharedInstance];
		NSWindow *mainWindow = [mainWindowController window];
		NSWindow *fullScreenWindow = [mainWindowController fullScreenWindow];
		
		[mainWindow removeChildWindow:recorderWindow];
		[self _adjustRecorderWindow];
		[fullScreenWindow addChildWindow:recorderWindow ordered:NSWindowAbove];
	}
}

- (void)_didEndFullScreen:(NSNotification *)notif
{
	if(recorderWindow != nil && [recorderWindow isVisible])
	{
		XMMainWindowController *mainWindowController = [XMMainWindowController sharedInstance];
		NSWindow *mainWindow = [mainWindowController window];
		NSWindow *fullScreenWindow = [mainWindowController fullScreenWindow];
		
		[recorderWindow orderOut:self];
		[fullScreenWindow removeChildWindow:recorderWindow];
		
		[mainWindow addChildWindow:recorderWindow ordered:NSWindowAbove];
		[self _adjustRecorderWindow];
		[recorderWindow orderFront:self];
	}
}

- (void)_adjustRecorderWindow
{
	NSWindow *window;
	XMMainWindowController *mainWindowController = [XMMainWindowController sharedInstance];
	int offset;
	if([mainWindowController isFullScreen])
	{
		window = [mainWindowController fullScreenWindow];
		offset = 20;
	}
	else
	{
		window = [mainWindowController window];
		offset = 7;
	}
	NSRect frame = [window frame];
	frame.origin.x = frame.origin.x + frame.size.width - 12 - offset;
	frame.origin.y = frame.origin.y + frame.size.height - 12 - offset;
	frame.size.width = 12;
	frame.size.height = 12;
	[recorderWindow setFrame:frame display:NO];
}

@end
