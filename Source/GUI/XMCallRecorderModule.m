/*
 * $Id: XMCallRecorderModule.m,v 1.1 2006/09/17 10:22:32 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMeeting.h"
#import "XMCallRecorderModule.h"

NSString *XMKey_RecordAudio = @"XMeeting_RecordAudio";
NSString *XMKey_RecordVideo = @"XMeeting_RecordVideo";
NSString *XMKey_RecordVideoCodec = @"XMeeting_RecordVideoCodec";
NSString *XMKey_RecordVideoQuality = @"XMeeting_RecordVideoQuality";
NSString *XMKey_RecordVideoEnableBandwidthLimit = @"XMeeting_RecordVideoEnableBandwidthLimit";
NSString *XMKey_RecordVideoBandwidthLimit = @"XMeeting_RecordVideoBandwidthLimit";
NSString *XMKey_RecordVideoLowPriority = @"XMeeting_RecordVideoLowPriority";

@interface XMCallRecorderModule (PrivateMethods)

- (void)_validateGUI;
- (void)_savePanelDidEnd:(NSSavePanel *)savePanel returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)_callRecorderDidEndRecording:(NSNotification *)notif;
- (void)_displayRecording:(NSString *)filePath;

@end

@implementation XMCallRecorderModule

#pragma mark Init & Deallocation Methods

- (id)init
{
	self = [super init];
	
	return self;
}

- (void)awakeFromNib
{
	contentViewSize = [contentView frame].size;
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	BOOL enableAudio = [userDefaults boolForKey:XMKey_RecordAudio];
	BOOL enableVideo = [userDefaults boolForKey:XMKey_RecordVideo];
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
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_callRecorderDidEndRecording:)
												 name:XMNotification_CallRecorderDidEndRecording object:nil];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[bwLimitString release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Module Methods

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
	BOOL enableVideoControls = NO;
	BOOL enableBWSwitch = NO;
	BOOL enableBWTextField = NO;
	
	if([recordAudioSwitch state] == NSOffState && [recordVideoSwitch state] == NSOffState)
	{
		enableRecordButton = NO;
	}
	
	if([[XMCallRecorder sharedInstance] isRecording] == NO)
	{
		enableAudioVideoSwitches = YES;
	
		int state = [recordVideoSwitch state];
		if(state == NSOnState)
		{
			enableVideoControls = YES;
			int tag = [[videoCodecPopUp selectedItem] tag];
			if([[XMCallRecorder sharedInstance] videoCodecSupportsDataRateControl:(XMCodecIdentifier)tag])
			{
				enableBWSwitch = YES;
				state = [dataRateLimitSwitch state];
				if(state == NSOnState)
				{
					enableBWTextField = YES;
				}
			}
		}
	}
	
	[recordButton setEnabled:enableRecordButton];
	
	[recordAudioSwitch setEnabled:enableAudioVideoSwitches];
	[recordVideoSwitch setEnabled:enableAudioVideoSwitches];
	
	[videoCodecPopUp setEnabled:enableVideoControls];
	[videoQualitySlider setEnabled:enableVideoControls];
	[lowPrioritySwitch setEnabled:enableVideoControls];
	
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
			
			BOOL result = [[XMCallRecorder sharedInstance] startRecordingInRecompressionModeToFile:filePath
																			  videoCodecIdentifier:videoCodec
																				 videoCodecQuality:codecQuality
																					 videoDataRate:dataRateLimit
																			  audioCodecIdentifier:audioCodec
																			  lowPriorityRecording:lowPriorityRecording];
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
}

- (void)_displayRecording:(NSString *)filePath
{
	[recordButton setTitle:NSLocalizedString(@"XM_CALL_RECORDER_MODULE_STOP_RECORDING", @"")];
	[filePathTextField setStringValue:filePath];
	[self _validateGUI];
}

@end
