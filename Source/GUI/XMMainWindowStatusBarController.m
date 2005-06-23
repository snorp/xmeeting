/*
 * $Id: XMMainWindowStatusBarController.m,v 1.4 2005/06/23 12:35:57 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMeeting.h"
#import "XMMainWindowStatusBarController.h"

@interface XMMainWindowStatusBarController (PrivateMethods)

- (void)_didStartFetchingExternalAddress:(NSNotification *)notif;
- (void)_didEndFetchingExternalAddress:(NSNotification *)notif;
- (void)_didStartSubsystemSetup:(NSNotification *)notif;
- (void)_didEndSubsystemSetup:(NSNotification *)notif;
- (void)_gatekeeperRegistration:(NSNotification *)notif;
- (void)_gatekeeperUnregistration:(NSNotification *)notif;
- (void)_gatekeeperRegistrationFailure:(NSNotification *)notif;
- (void)_didStartCalling:(NSNotification *)notif;
- (void)_incomingCall:(NSNotification *)notif;
- (void)_callEstablished:(NSNotification *)notif;
- (void)_callCleared:(NSNotification *)notif;

- (void)_setStatusBarString:(NSString *)statusBarString;
// animationType: -1: noAnimation, 0 same as before, 1:animation
- (void)_setStatusBarString:(NSString *)statusBarString animation:(int)animationType;

- (void)_clearStatusBar:(NSTimer *)timer;

@end

@implementation XMMainWindowStatusBarController

#pragma mark Init & Deallocation Methods

- (id)init
{
	displayClearTimer = nil;
	progressIndicatorDoesAnimate = NO;
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
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didStartSubsystemSetup:)
												 name:XMNotification_DidStartSubsystemSetup object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didEndSubsystemSetup:)
												 name:XMNotification_DidEndSubsystemSetup object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_gatekeeperRegistration:)
												 name:XMNotification_GatekeeperRegistration object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_gatekeeperUnregistration:)
												 name:XMNotification_GatekeeperUnregistration object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_gatekeeperRegistrationFailure:)
												 name:XMNotification_GatekeeperRegistrationFailure object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didStartCalling:)
												 name:XMNotification_DidStartCalling object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_incomingCall:)
												 name:XMNotification_IncomingCall object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_callEstablished:)
												 name:XMNotification_CallEstablished object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_callCleared:)
												 name:XMNotification_CallCleared object:nil];
}

#pragma mark Notification Handling Methods

- (void)_didStartFetchingExternalAddress:(NSNotification *)notif
{
	if(doesSubsystemSetup == NO)
	{
		NSString *displayString = NSLocalizedString(@"Fetching External Address...", @"");
		[self _setStatusBarString:displayString animation:1];
	}
}

- (void)_didEndFetchingExternalAddress:(NSNotification *)notif
{
	if(doesSubsystemSetup == NO)
	{
		XMUtils *utils = [XMUtils sharedInstance];
		NSString *displayString;
		int animationType;
	
		if([utils didSucceedFetchingExternalAddress])
		{
			displayString = [NSLocalizedString(@"Fetching External Address... Done", @"") retain];
		}
		else
		{
			NSString *displayFormat = NSLocalizedString(@"Fetching External Address... Failed (%@)", @"");
			displayString = [[NSString alloc] initWithFormat:displayFormat, [utils externalAddressFetchFailReason]];
		}
		[self _setStatusBarString:displayString animation:-1];
		[displayString release];
	}
}

- (void)_didStartSubsystemSetup:(NSNotification *)notif
{
	NSLog(@"a");
	doesSubsystemSetup = YES;
	NSString *displayString = NSLocalizedString(@"Setting up the subsystem...", @"");
	[self _setStatusBarString:displayString animation:1];
}

- (void)_didEndSubsystemSetup:(NSNotification *)notif
{
	NSLog(@"b");
	doesSubsystemSetup = NO;
	NSString *displayString = NSLocalizedString(@"Setting up the subsystem done", @"");
	[self _setStatusBarString:displayString animation:-1];
}

- (void)_gatekeeperRegistration:(NSNotification *)notif
{
	NSLog(@"gatekeeper registered");
	NSString *displayFormat = NSLocalizedString(@"H.323: Gatekeeper set: %@", @"");
	NSString *displayString = [[NSString alloc] initWithFormat:displayFormat, [[XMCallManager sharedInstance] gatekeeperName]];
	[self _setStatusBarString:displayString];
	[displayString release];
}

- (void)_gatekeeperUnregistration:(NSNotification *)notif
{
	NSString *displayFormat = NSLocalizedString(@"H.323: Removed Gatekeeper %@", @"");
	NSString *displayString = [[NSString alloc] initWithFormat:displayFormat, [[XMCallManager sharedInstance] gatekeeperName]];
	[self _setStatusBarString:displayString];
	[displayString release];
}

- (void)_gatekeeperRegistrationFailure:(NSNotification *)notif
{
	NSString *displayString = NSLocalizedString(@"H.323: Gatekeeper registration failed", @"");
	[self _setStatusBarString:displayString];
}

- (void)_didStartCalling:(NSNotification *)notif
{
	NSString *displayString = NSLocalizedString(@"Calling...", @"");
	[self _setStatusBarString:displayString];
}

- (void)_incomingCall:(NSNotification *)notif
{
	NSString *displayString = NSLocalizedString(@"Incoming Call", @"");
	[self _setStatusBarString:displayString];
}

- (void)_callEstablished:(NSNotification *)notif
{
	NSString *displayString = NSLocalizedString(@"Call Established", @"");
	[self _setStatusBarString:displayString];
}

- (void)_callCleared:(NSNotification *)notif
{
	NSString *displayString = NSLocalizedString(@"Call Ended", @"");
	[self _setStatusBarString:displayString];
}

#pragma mark Private Methods

- (void)_setStatusBarString:(NSString *)statusBarString
{
	[self _setStatusBarString:statusBarString animation:0];
}

- (void)_setStatusBarString:(NSString *)statusBarString animation:(int)animationType
{
	[statusBar setStringValue:statusBarString];
	
	NSTimeInterval timeInterval;
	
	switch(animationType)
	{
		case -1:
			[progressIndicator stopAnimation:self];
			progressIndicatorDoesAnimate = NO;
			timeInterval = 4.0;
			break;
		case 0:
			if(progressIndicatorDoesAnimate)
			{
				timeInterval = 0.0;
			}
			else
			{
				timeInterval = 4.0;
			}
			break;
		case 1:
			[progressIndicator startAnimation:self];
			progressIndicatorDoesAnimate = YES;
			timeInterval = 0.0;
		default:
			break;
	}
	
	if(displayClearTimer != nil)
	{
		[displayClearTimer invalidate];
		[displayClearTimer release];
		displayClearTimer = nil;
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
