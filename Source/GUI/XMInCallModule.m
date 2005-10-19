/*
 * $Id: XMInCallModule.m,v 1.8 2005/10/19 22:09:17 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMInCallModule.h"

#import "XMeeting.h"
#import "XMMainWindowController.h"
#import "XMPreferencesManager.h"
#import "XMInCallView.h"

@interface XMInCallModule (PrivateMethods)

- (void)_didEstablishCall:(NSNotification *)notif;
- (void)_didClearCall:(NSNotification *)notif;
- (void)_activeLocationDidChange:(NSNotification *)notif;

@end

@implementation XMInCallModule

- (id)init
{
	[[XMMainWindowController sharedInstance] addMainModule:self];
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	[notificationCenter addObserver:self selector:@selector(_didEstablishCall:)
							   name:XMNotification_CallManagerDidEstablishCall object:nil];
	[notificationCenter addObserver:self selector:@selector(_didClearCall:)
							   name:XMNotification_CallManagerDidClearCall object:nil];
	
	[notificationCenter addObserver:self selector:@selector(_activeLocationDidChange:)
							   name:XMNotification_ActiveLocationDidChange object:nil];
	
	return self;
}

- (void)dealloc
{
	[nibLoader release];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	[self _activeLocationDidChange:nil];
}

- (NSString *)name
{
	return @"InCall";
}

- (NSView *)contentView
{
	if(nibLoader == nil)
	{
		nibLoader = [[NSNib alloc] initWithNibNamed:@"InCallModule" bundle:nil];
		[nibLoader instantiateNibWithOwner:self topLevelObjects:nil];
	}
	
	return contentView;
}

- (NSSize)contentViewSize
{
	return [contentView preferredSize];
}

- (NSSize)contentViewMinSize
{
	return [contentView minimumSize];
}

- (NSSize)contentViewMaxSize
{
	return [contentView maximumSize];
}

- (NSSize)adjustResizeDifference:(NSSize)resizeDifference minimumHeight:(unsigned)minimumHeight
{
	return [contentView adjustResizeDifference:resizeDifference minimumHeight:minimumHeight];
}

- (void)becomeActiveModule
{
	[videoView startDisplayingRemoteVideo];
	
	didClearCall = NO;
}

- (void)becomeInactiveModule
{
	[videoView stopDisplayingRemoteVideo];
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
}

- (void)_activeLocationDidChange:(NSNotification *)notif
{
	BOOL enableVideo = [[[XMPreferencesManager sharedInstance] activeLocation] enableVideo];

	[contentView setShowVideoContent:enableVideo];
}

@end
