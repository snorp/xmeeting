/*
 * $Id: XMMainWindowStatusBarController.m,v 1.1 2005/06/01 21:20:21 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMeeting.h"
#import "XMMainWindowStatusBarController.h"

@interface XMMainWindowStatusBarController (PrivateMethods)

- (void)_setupDisplayClearTimer;
- (void)_clearStatusBar:(NSTimer *)timer;

@end

@implementation XMMainWindowStatusBarController

#pragma mark Init & Deallocation Methods

- (id)init
{
	displayClearTimer = nil;
	return self;
}

- (void)dealloc
{
	[displayClearTimer release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_registeredAtGatekeeper:)
												 name:XMNotification_RegisteredAtGatekeeper object:nil];
}

#pragma mark Notification Handling Methods

- (void)_registeredAtGatekeeper:(NSNotification *)notif
{
	NSString *displayFormat = NSLocalizedString(@"H.323: Gatekeeper set: %@", @"");
	NSString *displayString = [[NSString alloc] initWithFormat:displayFormat, [[XMCallManager sharedInstance] gatekeeperName]];
	[statusBar setStringValue:displayString];
	[displayString release];
	
	[self _setupDisplayClearTimer];
}

#pragma mark Private Methods

- (void)_setupDisplayClearTimer
{
	if(displayClearTimer != nil)
	{
		[displayClearTimer invalidate];
		[displayClearTimer release];
	}
	displayClearTimer = [[NSTimer scheduledTimerWithTimeInterval:4.0 target:self selector:@selector(_clearStatusBar:)
														userInfo:nil repeats:NO] retain];
}

- (void)_clearStatusBar:(NSTimer *)timer
{
	[statusBar setStringValue:@""];
	[displayClearTimer release];
	displayClearTimer = nil;
}

@end
