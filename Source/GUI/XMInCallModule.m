/*
 * $Id: XMInCallModule.m,v 1.7 2005/10/17 12:57:54 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMeeting.h"
#import "XMInCallModule.h"
#import "XMMainWindowController.h"

@interface XMInCallModule (PrivateMethods)

- (void)_didEstablishCall:(NSNotification *)notif;
- (void)_didClearCall:(NSNotification *)notif;

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
	
	return self;
}

- (void)dealloc
{
	[nibLoader release];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	contentViewMinSize = [contentView frame].size;
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
	return [[self contentView] bounds].size;
}

- (NSSize)contentViewMinSize
{
	// if not already done, this triggers the loading of the nib file
	[self contentView];
	
	return contentViewMinSize;
}

- (NSSize)contentViewMaxSize
{
	// we do not return FLT_MAX since this might cause overflow
	// and wrong results
	return NSMakeSize(20000.0, 20000.0);
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

@end
