/*
 * $Id: XMMainWindowStatusBarController.m,v 1.2 2005/06/02 08:23:16 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMeeting.h"
#import "XMMainWindowStatusBarController.h"

@interface XMMainWindowStatusBarController (PrivateMethods)

- (void)_setStatusBarString:(NSString *)statusBarString;
- (void)_setStatusBarString:(NSString *)statusBarString timeInterval:(NSTimeInterval)timeInterval;
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
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didStartFetchingExternalAddress:)
												 name:XMNotification_DidStartFetchingExternalAddress object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didEndFetchingExternalAddress:)
												 name:XMNotification_DidEndFetchingExternalAddress object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_registeredAtGatekeeper:)
												 name:XMNotification_RegisteredAtGatekeeper object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_removedGatekeeper:)
												 name:XMNotification_RemovedGatekeeper object:nil];
}

#pragma mark Notification Handling Methods

- (void)_didStartFetchingExternalAddress:(NSNotification *)notif
{
	NSString *displayString = NSLocalizedString(@"Fetching External Address...", @"");
	// we have no time interval for this message since this notification is followed
	// by the _didEndFetchingExternalAddress: notification after no mor than the default
	// ip fetch timeout
	[self _setStatusBarString:displayString timeInterval:0.0];
}

- (void)_didEndFetchingExternalAddress:(NSNotification *)notif
{
	XMUtils *utils = [XMUtils sharedInstance];
	NSString *displayString;
	
	if([utils didSucceedFetchingExternalAddress])
	{
		NSLog(@"abc");
		NSLog([utils externalAddress]);
		displayString = [NSLocalizedString(@"Fetching External Address... Done", @"") retain];
	}
	else
	{
		NSString *displayFormat = NSLocalizedString(@"Fetching External Address... Failed (%@)", @"");
		displayString = [[NSString alloc] initWithFormat:displayFormat, [utils externalAddressFetchFailReason]];
	}
	[self _setStatusBarString:displayString];
	[displayString release];
}

- (void)_registeredAtGatekeeper:(NSNotification *)notif
{
	NSString *displayFormat = NSLocalizedString(@"H.323: Gatekeeper set: %@", @"");
	NSString *displayString = [[NSString alloc] initWithFormat:displayFormat, [[XMCallManager sharedInstance] gatekeeperName]];
	[self _setStatusBarString:displayString];
	[displayString release];
}

- (void)_removedGatekeeper:(NSNotification *)notif
{
	NSString *displayFormat = NSLocalizedString(@"H.323: Removed Gatekeeper %@", @"");
	NSString *displayString = [[NSString alloc] initWithFormat:displayFormat, [[XMCallManager sharedInstance] gatekeeperName]];
	[self _setStatusBarString:displayString];
	[displayString release];
}

#pragma mark Private Methods

- (void)_setStatusBarString:(NSString *)statusBarString
{
	[self _setStatusBarString:statusBarString timeInterval:4.0];
}

- (void)_setStatusBarString:(NSString *)statusBarString timeInterval:(NSTimeInterval)timeInterval
{
	[statusBar setStringValue:statusBarString];
	
	if(displayClearTimer != nil)
	{
		[displayClearTimer invalidate];
		[displayClearTimer release];
	}
	if(timeInterval != 0.0)
	{
		displayClearTimer = [[NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(_clearStatusBar:)
															userInfo:nil repeats:NO] retain];
	}
}

- (void)_clearStatusBar:(NSTimer *)timer
{
	[statusBar setStringValue:@""];
	[displayClearTimer release];
	displayClearTimer = nil;
}

@end
