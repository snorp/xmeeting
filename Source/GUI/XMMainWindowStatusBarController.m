/*
 * $Id: XMMainWindowStatusBarController.m,v 1.6 2005/10/06 15:04:42 hfriederich Exp $
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
- (void)_didStartGatekeeperRegistration:(NSNotification *)notif;
- (void)_gatekeeperRegistration:(NSNotification *)notif;
- (void)_gatekeeperUnregistration:(NSNotification *)notif;
- (void)_gatekeeperRegistrationFailure:(NSNotification *)notif;
- (void)_didStartCalling:(NSNotification *)notif;
- (void)_incomingCall:(NSNotification *)notif;
- (void)_callEstablished:(NSNotification *)notif;
- (void)_callCleared:(NSNotification *)notif;
- (void)_didStartVideoInputDeviceListUpdate:(NSNotification *)notif;
- (void)_didUpdateVideoInputDeviceList:(NSNotification *)notif;

- (void)_setStatusBarString:(NSString *)statusBarString;

#define XM_ANIMATION_TYPE int
#define XM_NO_ANIMATION -1
#define XM_KEEP_ANIMATION_TYPE 0
#define XM_DO_ANIMATION 1
- (void)_setStatusBarString:(NSString *)statusBarString animation:(XM_ANIMATION_TYPE)animationType;

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
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	[notificationCenter addObserver:self selector:@selector(_didStartFetchingExternalAddress:)
							   name:XMNotification_UtilsDidStartFetchingExternalAddress object:nil];
	[notificationCenter addObserver:self selector:@selector(_didEndFetchingExternalAddress:)
							   name:XMNotification_UtilsDidEndFetchingExternalAddress object:nil];
	[notificationCenter addObserver:self selector:@selector(_didStartSubsystemSetup:)
							   name:XMNotification_CallManagerDidStartSubsystemSetup object:nil];
	[notificationCenter addObserver:self selector:@selector(_didEndSubsystemSetup:)
							   name:XMNotification_CallManagerDidEndSubsystemSetup object:nil];
	[notificationCenter addObserver:self selector:@selector(_didStartGatekeeperRegistration:)
							   name:XMNotification_CallManagerDidStartGatekeeperRegistration object:nil];
	[notificationCenter addObserver:self selector:@selector(_gatekeeperRegistration:)
							   name:XMNotification_CallManagerGatekeeperRegistration object:nil];
	[notificationCenter addObserver:self selector:@selector(_gatekeeperUnregistration:)
							   name:XMNotification_CallManagerGatekeeperUnregistration object:nil];
	[notificationCenter addObserver:self selector:@selector(_didStartCalling:)
							   name:XMNotification_CallManagerDidStartCalling object:nil];
	[notificationCenter addObserver:self selector:@selector(_incomingCall:)
							   name:XMNotification_CallManagerIncomingCall object:nil];
	[notificationCenter addObserver:self selector:@selector(_callEstablished:)
							   name:XMNotification_CallManagerCallEstablished object:nil];
	[notificationCenter addObserver:self selector:@selector(_callCleared:)
							   name:XMNotification_CallManagerCallCleared object:nil];
	[notificationCenter addObserver:self selector:@selector(_didStartVideoInputDeviceListUpdate:)
							   name:XMNotification_VideoManagerDidStartInputDeviceListUpdate object:nil];
	[notificationCenter addObserver:self selector:@selector(_didUpdateVideoInputDeviceList:)
							   name:XMNotification_VideoManagerDidUpdateInputDeviceList object:nil];
}

#pragma mark Notification Handling Methods

- (void)_didStartFetchingExternalAddress:(NSNotification *)notif
{
	if(doesSubsystemSetup == NO)
	{
		NSString *displayString = NSLocalizedString(@"Fetching External Address...", @"");
		[self _setStatusBarString:displayString animation:XM_DO_ANIMATION];
	}
}

- (void)_didEndFetchingExternalAddress:(NSNotification *)notif
{
	if(doesSubsystemSetup == NO)
	{
		XMUtils *utils = [XMUtils sharedInstance];
		NSString *displayString;
	
		if([utils didSucceedFetchingExternalAddress])
		{
			displayString = [NSLocalizedString(@"Fetching External Address... Done", @"") retain];
		}
		else
		{
			NSString *displayFormat = NSLocalizedString(@"Fetching External Address... Failed (%@)", @"");
			displayString = [[NSString alloc] initWithFormat:displayFormat, [utils externalAddressFetchFailReason]];
		}
		[self _setStatusBarString:displayString animation:XM_NO_ANIMATION];
		[displayString release];
	}
}

- (void)_didStartSubsystemSetup:(NSNotification *)notif
{
	doesSubsystemSetup = YES;
	NSString *displayString = NSLocalizedString(@"Setting up the subsystem...", @"");
	[self _setStatusBarString:displayString animation:XM_DO_ANIMATION];
}

- (void)_didEndSubsystemSetup:(NSNotification *)notif
{
	doesSubsystemSetup = NO;
	NSString *displayString = NSLocalizedString(@"Setting up the subsystem... Done.", @"");
	[self _setStatusBarString:displayString animation:XM_NO_ANIMATION];
}

- (void)_didStartGatekeeperRegistration:(NSNotification *)notif
{
	NSString *displayString = NSLocalizedString(@"H.323: Registering at Gatekeeper", @"");
	[self _setStatusBarString:displayString];
}

- (void)_gatekeeperRegistration:(NSNotification *)notif
{
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

- (void)_didStartVideoInputDeviceListUpdate:(NSNotification *)notif
{
	NSString *displayString = NSLocalizedString(@"Updating Video Input Device List...", @"");
	[self _setStatusBarString:displayString animation:XM_DO_ANIMATION];
}

- (void)_didUpdateVideoInputDeviceList:(NSNotification *)notif
{
	NSString *displayString = NSLocalizedString(@"Updating Video Input Device List... Done", @"");
	[self _setStatusBarString:displayString animation:XM_NO_ANIMATION];
}

#pragma mark Private Methods

- (void)_setStatusBarString:(NSString *)statusBarString
{
	[self _setStatusBarString:statusBarString animation:XM_KEEP_ANIMATION_TYPE];
}

- (void)_setStatusBarString:(NSString *)statusBarString animation:(XM_ANIMATION_TYPE)animationType
{
	[statusBar setStringValue:statusBarString];
	
	NSTimeInterval timeInterval;
	
	switch(animationType)
	{
		case XM_NO_ANIMATION:
			[progressIndicator stopAnimation:self];
			progressIndicatorDoesAnimate = NO;
			timeInterval = 4.0;
			break;
		case XM_KEEP_ANIMATION_TYPE:
			if(progressIndicatorDoesAnimate)
			{
				timeInterval = 0.0;
			}
			else
			{
				timeInterval = 4.0;
			}
			break;
		case XM_DO_ANIMATION:
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
