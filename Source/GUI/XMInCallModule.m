/*
 * $Id: XMInCallModule.m,v 1.20 2006/03/25 10:41:57 hfriederich Exp $
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

#define VIDEO_INSET_TOP 27.0
#define VIDEO_INSET_LEFT 5.0
#define VIDEO_INSET_RIGHT 5.0
#define VIDEO_INSET_BOTTOM 25.0

@interface XMInCallModule (PrivateMethods)

- (void)_didEstablishCall:(NSNotification *)notif;
- (void)_didClearCall:(NSNotification *)notif;
- (void)_didStartReceivingVideo:(NSNotification *)notif;

@end

@implementation XMInCallModule

- (id)init
{
	self = [super init];
	
	isFullScreen = NO;
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	[notificationCenter addObserver:self selector:@selector(_didEstablishCall:)
							   name:XMNotification_CallManagerDidEstablishCall object:nil];
	[notificationCenter addObserver:self selector:@selector(_didClearCall:)
							   name:XMNotification_CallManagerDidClearCall object:nil];
	
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
	
	[videoView setOSDOpeningEffect:XMOpeningEffect_FadeIn];
	[videoView setOSDClosingEffect:XMClosingEffect_FadeOut];
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
	
	if(isFullScreen == YES)
	{
		return videoView;
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
	
	int availableWidth = (int)size.width + (int)resizeDifference.width - VIDEO_INSET_LEFT - VIDEO_INSET_RIGHT;
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
	
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	if([[preferencesManager activeLocation] enableVideo] == YES)
	{
		[videoView startDisplayingVideo];
	}
	else
	{
		[videoView startDisplayingNoVideo];
	}
	
	[videoView setOSDDisplayMode:XMOSDDisplayMode_AutomaticallyHiding];
	
	if(isFullScreen == YES)
	{
		[[videoView window] makeFirstResponder:videoView];
	}
}

- (void)becomeInactiveModule
{
	[videoView setOSDDisplayMode:XMOSDDisplayMode_NoOSD];
	[videoView stopDisplayingVideo];
	
	contentViewSize = [contentView bounds].size;
}

- (void)beginFullScreen
{
	isFullScreen = YES;
	
	[self contentView];
	
	[videoView removeFromSuperviewWithoutNeedingDisplay];
	[videoView setFullScreen:YES];
}

- (void)endFullScreen
{
	isFullScreen = NO;
	
	[self contentView];
	
	NSRect frame = [contentView bounds];
	
	frame.origin.x += VIDEO_INSET_LEFT;
	frame.origin.y += VIDEO_INSET_BOTTOM;
	frame.size.width -= (VIDEO_INSET_LEFT + VIDEO_INSET_RIGHT);
	frame.size.height -= (VIDEO_INSET_TOP + VIDEO_INSET_BOTTOM);
	
	[contentView addSubview:videoView];
	[videoView setFrame:frame];
	
	[videoView setFullScreen:NO];
}

#pragma mark User Interface Methods

- (void)clearCall:(id)sender
{
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
	
	NSString *remoteName = [[[XMCallManager sharedInstance] activeCall] remoteName];
	[remotePartyField setStringValue:remoteName];
	
}

- (void)_didClearCall:(NSNotification *)notif
{
	[remotePartyField setStringValue:@""];
	
	[videoView releaseOSD];
}

@end
