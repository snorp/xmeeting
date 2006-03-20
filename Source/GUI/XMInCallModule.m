/*
 * $Id: XMInCallModule.m,v 1.18 2006/03/20 21:47:29 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMInCallModule.h"

#import "XMeeting.h"
#import "XMMainWindowController.h"
#import "XMPreferencesManager.h"
#import "XMOSDVideoView.h"

#define VIDEO_INSET 5

@interface XMInCallModule (PrivateMethods)

- (void)_didEstablishCall:(NSNotification *)notif;
- (void)_didClearCall:(NSNotification *)notif;
- (void)_didStartReceivingVideo:(NSNotification *)notif;

- (void)_activeLocationDidChange:(NSNotification *)notif;

@end

@implementation XMInCallModule

- (id)init
{
	self = [super init];
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	[notificationCenter addObserver:self selector:@selector(_didEstablishCall:)
							   name:XMNotification_CallManagerDidEstablishCall object:nil];
	[notificationCenter addObserver:self selector:@selector(_didClearCall:)
							   name:XMNotification_CallManagerDidClearCall object:nil];
	[notificationCenter addObserver:self selector:@selector(_didStartReceivingVideo:)
							   name:XMNotification_VideoManagerDidStartReceivingVideo object:nil];
	
	[notificationCenter addObserver:self selector:@selector(_activeLocationDidChange:)
							   name:XMNotification_PreferencesManagerDidChangeActiveLocation object:nil];
	
	return self;
}

- (void)dealloc
{	
	[super dealloc];
}

- (void)awakeFromNib
{
	contentViewMinSize = [contentView bounds].size;
	contentViewSize = contentViewMinSize;
	
	[self _activeLocationDidChange:nil];
}

- (NSString *)name
{
	return @"InCall";
}

- (NSView *)contentView
{
	if(contentView == nil)
	{
		[NSBundle loadNibNamed:@"InCallModule" owner:self];
	}
	
	return contentView;
}

- (NSSize)contentViewSize
{
	[self contentView];

	return contentViewSize;
}

- (NSSize)contentViewMinSize
{
	[self contentView];
	
	return contentViewMinSize;
}

- (NSSize)contentViewMaxSize
{
	return NSMakeSize(5000, 5000);
}

- (NSSize)adjustResizeDifference:(NSSize)resizeDifference minimumHeight:(unsigned)minimumHeight
{
	NSSize size = [contentView bounds].size;
	
	// minimum height is height minus height of minimum picture
	unsigned usedHeight = contentViewMinSize.height - 288.0;
	
	int minimumVideoHeight = contentViewMinSize.height - usedHeight;
	int currentVideoHeight = (int)size.height - usedHeight;
	
	int availableWidth = (int)size.width + (int)resizeDifference.width - 2*VIDEO_INSET;
	int newHeight = currentVideoHeight + (int)resizeDifference.height;
	
	// BOGUS: Adjust for different aspect ratios
	int calculatedWidthFromHeight = (int)XMGetVideoWidthForHeight(newHeight, XMVideoSize_CIF);
	int calculatedHeightFromWidth = (int)XMGetVideoHeightForWidth(availableWidth, XMVideoSize_CIF);
	
	if(calculatedHeightFromWidth <= minimumVideoHeight)
	{
		// set the height to the minimum height
		resizeDifference.height = minimumVideoHeight - currentVideoHeight;
	}
	else
	{
		if(calculatedWidthFromHeight < availableWidth)
		{
			// the height value takes precedence
			int widthDifference = availableWidth - calculatedWidthFromHeight;
			resizeDifference.width -= widthDifference;
		}
		else
		{
			// the width value takes precedence
			int heightDifference = newHeight - calculatedHeightFromWidth;
			resizeDifference.height -= heightDifference;
		}
	}
	
	return resizeDifference;
}

- (void)becomeActiveModule
{
	[self contentView];
	
	[videoView startDisplayingRemoteVideo];
	
	[videoView setShouldDisplayOSD:YES];
	
	didClearCall = NO;
}

- (void)becomeInactiveModule
{
	[videoView stopDisplayingVideo];
	[videoView setShouldDisplayOSD:NO];
	[videoView moduleWasDeactivated:self];
}

#pragma mark User Interface Methods

- (void)clearCall:(id)sender
{
	NSLog(@"didClearCall");
	if(didClearCall == YES)
	{
		return;
	}
	didClearCall = YES;
	[[XMCallManager sharedInstance] clearActiveCall];
}

#pragma mark Private Methods

- (void)_didEstablishCall:(NSNotification *)notif
{
	//loading the nib file if not already done
	[self contentView];
	
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];	
	BOOL isVideoEnabled = [[[preferencesManager locations] objectAtIndex:[preferencesManager indexOfActiveLocation]] enableVideo]; 

	if (!isVideoEnabled){
		[videoView stopDisplayingVideo]; //display 'NO VIDEO' picture
		[self _didStartReceivingVideo:nil];
	}
	
	NSString *remoteName = [[[XMCallManager sharedInstance] activeCall] remoteName];
	[remotePartyField setStringValue:remoteName];
	
}

- (void)_didClearCall:(NSNotification *)notif
{
	[remotePartyField setStringValue:@""];
	
	//[contentView setVideoSize:XMVideoSize_QCIF];
}

- (void)_didStartReceivingVideo:(NSNotification *)notif
{
	XMVideoSize videoSize = [[XMVideoManager sharedInstance] remoteVideoSize];
	
	//[contentView setVideoSize:videoSize];
	
	[[XMMainWindowController sharedInstance] noteSizeValuesDidChangeOfModule:self];

	[videoView mouseEntered:[NSApp currentEvent]];

}

- (void)_activeLocationDidChange:(NSNotification *)notif
{
	BOOL enableVideo = [[[XMPreferencesManager sharedInstance] activeLocation] enableVideo];

	//[contentView setShowVideoContent:enableVideo];
}

@end
