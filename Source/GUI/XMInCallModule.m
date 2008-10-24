/*
 * $Id: XMInCallModule.m,v 1.27 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
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

#define NO_VIDEO_WIDTH 290
#define NO_VIDEO_HEIGHT 65

NSString *XMKey_VideoViewSettings = @"XMeeting_VideoViewSettings";

@interface XMInCallModule (PrivateMethods)

- (void)_didEstablishCall:(NSNotification *)notif;
- (void)_didClearCall:(NSNotification *)notif;

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
	
	float videoHeight = [videoView frame].size.height;
	
	noVideoContentViewSize.width = NO_VIDEO_WIDTH;
	noVideoContentViewSize.height = (contentViewSize.height + NO_VIDEO_HEIGHT - videoHeight);
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
	
	if([[[XMPreferencesManager sharedInstance] activeLocation] enableVideo] == YES)
	{
		return contentViewSize;
	}
	else
	{
		return noVideoContentViewSize;
	}
}

- (NSSize)contentViewMinSize
{
	[self contentView];
	
	if([[[XMPreferencesManager sharedInstance] activeLocation] enableVideo] == YES)
	{
		return contentViewMinSize;
	}
	else
	{
		return noVideoContentViewSize;
	}
}

- (NSSize)contentViewMaxSize
{
	[self contentView];
	
	if([[[XMPreferencesManager sharedInstance] activeLocation] enableVideo] == YES)
	{
		return NSMakeSize(5000, 5000);
	}
	else
	{
		return noVideoContentViewSize;
	}
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
	
	// Aspect ratios other than CIF / QCIF are handled within
	// the OSD video view
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
	XMLocation *activeLocation = [preferencesManager activeLocation];
	BOOL enableVideo = [activeLocation enableVideo];
	
	NSString *settings = [[NSUserDefaults standardUserDefaults] stringForKey:XMKey_VideoViewSettings];
	if(settings != nil)
	{
		[videoView setSettings:settings];
	}
	
	if(enableVideo == YES)
	{
		// Check whether QuartzExtreme is enabled or not to hide some functions
		// wich don't work well on non quartz-extreme machines
		// For simplicity, we consider only the main display
		BOOL enableComplexModes = CGDisplayUsesOpenGLAcceleration(CGMainDisplayID());
		[videoView setEnableComplexPinPModes:enableComplexModes];
		
		BOOL mirrorLocalVideo = [preferencesManager showSelfViewMirrored];
		[videoView setLocalVideoMirrored:mirrorLocalVideo];
		
		[videoView startDisplayingVideo];
	}
	else
	{
		//[videoView setNoVideoImage:[NSImage imageNamed:@"no_video_screen"]];
		[videoView setNoVideoImage:nil];
		[videoView startDisplayingNoVideo];
	}
	
	if([preferencesManager automaticallyHideInCallControls] && enableVideo == YES)
	{
		[videoView setOSDDisplayMode:XMOSDDisplayMode_AutomaticallyHiding];
	}
	else
	{
		[videoView setOSDDisplayMode:XMOSDDisplayMode_AlwaysVisible];
	}
	
	XMInCallControlHideAndShowEffect effect = [preferencesManager inCallControlHideAndShowEffect];
	[videoView setOSDOpeningEffect:(XMOpeningEffect)effect];
	[videoView setOSDClosingEffect:(XMClosingEffect)effect];
	
	if(isFullScreen == YES && enableVideo == YES)
	{
		[[videoView window] makeFirstResponder:videoView];
	}
}

- (void)becomeInactiveModule
{
	[videoView setOSDDisplayMode:XMOSDDisplayMode_NoOSD];
	[videoView stopDisplayingVideo];
	
	// storing some settings of the video view
	NSString *settings = [videoView settings];
	[[NSUserDefaults standardUserDefaults] setObject:settings forKey:XMKey_VideoViewSettings];
	
	if([[[XMPreferencesManager sharedInstance] activeLocation] enableVideo] == YES)
	{
		contentViewSize = [contentView bounds].size;
	}
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
