/*
 * $Id: XMMainWindowStatusBarController.m,v 1.7 2005/10/17 12:57:54 hfriederich Exp $
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
- (void)_didStartGatekeeperRegistrationProcess:(NSNotification *)notif;
- (void)_didEndGatekeeperRegistrationProcess:(NSNotification *)notif;
- (void)_didRegisterAtGatekeeper:(NSNotification *)notif;
- (void)_didUnregisterFromGatekeeper:(NSNotification *)notif;
- (void)_didStartCallInitiation:(NSNotification *)notif;
- (void)_didStartCalling:(NSNotification *)notif;
- (void)_didNotStartCalling:(NSNotification *)notif;
- (void)_didReceiveIncomingCall:(NSNotification *)notif;
- (void)_didEstablishCall:(NSNotification *)notif;
- (void)_didClearCall:(NSNotification *)notif;

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
	
	// utils notifications
	[notificationCenter addObserver:self selector:@selector(_didStartFetchingExternalAddress:)
							   name:XMNotification_UtilsDidStartFetchingExternalAddress object:nil];
	[notificationCenter addObserver:self selector:@selector(_didEndFetchingExternalAddress:)
							   name:XMNotification_UtilsDidEndFetchingExternalAddress object:nil];
	
	// call manager notifications
	[notificationCenter addObserver:self selector:@selector(_didStartSubsystemSetup:)
							   name:XMNotification_CallManagerDidStartSubsystemSetup object:nil];
	[notificationCenter addObserver:self selector:@selector(_didEndSubsystemSetup:)
							   name:XMNotification_CallManagerDidEndSubsystemSetup object:nil];
	[notificationCenter addObserver:self selector:@selector(_didStartGatekeeperRegistrationProcess:)
							   name:XMNotification_CallManagerDidStartGatekeeperRegistrationProcess object:nil];
	[notificationCenter addObserver:self selector:@selector(_didEndGatekeeperRegistrationProcess:)
							   name:XMNotification_CallManagerDidEndGatekeeperRegistrationProcess object:nil];
	[notificationCenter addObserver:self selector:@selector(_didRegisterAtGatekeeper:)
							   name:XMNotification_CallManagerDidRegisterAtGatekeeper object:nil];
	[notificationCenter addObserver:self selector:@selector(_didUnregisterFromGatekeeper:)
							   name:XMNotification_CallManagerDidUnregisterFromGatekeeper object:nil];
	[notificationCenter addObserver:self selector:@selector(_didStartCallInitiation:)
							   name:XMNotification_CallManagerDidStartCallInitiation object:nil];
	[notificationCenter addObserver:self selector:@selector(_didStartCalling:)
							   name:XMNotification_CallManagerDidStartCalling object:nil];
	[notificationCenter addObserver:self selector:@selector(_didNotStartCalling:)
							   name:XMNotification_CallManagerDidNotStartCalling object:nil];
	[notificationCenter addObserver:self selector:@selector(_didReceiveIncomingCall:)
							   name:XMNotification_CallManagerDidReceiveIncomingCall object:nil];
	[notificationCenter addObserver:self selector:@selector(_didEstablishCall:)
							   name:XMNotification_CallManagerDidEstablishCall object:nil];
	[notificationCenter addObserver:self selector:@selector(_didClearCall:)
							   name:XMNotification_CallManagerDidClearCall object:nil];
	
	// video manager notification
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
	NSString *displayString = NSLocalizedString(@"Configuring the subsystem...", @"");
	[self _setStatusBarString:displayString animation:XM_DO_ANIMATION];
}

- (void)_didEndSubsystemSetup:(NSNotification *)notif
{
	doesSubsystemSetup = NO;
	NSString *displayString = NSLocalizedString(@"Configuring the subsystem... Done.", @"");
	[self _setStatusBarString:displayString animation:XM_NO_ANIMATION];
}

- (void)_didStartGatekeeperRegistrationProcess:(NSNotification *)notif
{
	NSString *displayString = NSLocalizedString(@"H.323: Registering at Gatekeeper...", @"");
	[self _setStatusBarString:displayString];
}

- (void)_didEndGatekeeperRegistrationProcess:(NSNotification *)notif
{
	NSString *displayString;
	
	if([[XMCallManager sharedInstance] isGatekeeperRegistered])
	{
		displayString = NSLocalizedString(@"H.323: Registering at Gatekeeper... Done", @"");
	}
	else
	{
		
		displayString = NSLocalizedString(@"H.323: Registering at Gatekeeper... Failed", @"");
	}
	
	[self _setStatusBarString:displayString];
}

- (void)_didRegisterAtGatekeeper:(NSNotification *)notif
{
	NSString *displayFormat = NSLocalizedString(@"H.323: Gatekeeper set: %@", @"");
	NSString *displayString = [[NSString alloc] initWithFormat:displayFormat, [[XMCallManager sharedInstance] gatekeeperName]];
	[self _setStatusBarString:displayString];
	[displayString release];
}

- (void)_didUnregisterFromGatekeeper:(NSNotification *)notif
{
	NSString *displayFormat = NSLocalizedString(@"H.323: Unregistered from Gatekeeper", @"");
	NSString *displayString = [[NSString alloc] initWithFormat:displayFormat, [[XMCallManager sharedInstance] gatekeeperName]];
	[self _setStatusBarString:displayString];
	[displayString release];
}

- (void)_didStartCallInitiation:(NSNotification *)notif
{
	NSString *displayString = NSLocalizedString(@"Preparing to call...", @"");
	[self _setStatusBarString:displayString animation:XM_DO_ANIMATION];
}

- (void)_didStartCalling:(NSNotification *)notif
{
	NSString *displayString = NSLocalizedString(@"Calling...", @"");
	[self _setStatusBarString:displayString animation:XM_NO_ANIMATION];
}

- (void)_didNotStartCalling:(NSNotification *)notif
{
	NSString *displayString = NSLocalizedString(@"Unable to start calling", @"");
	[self _setStatusBarString:displayString animation:XM_NO_ANIMATION];
}

- (void)_didReceiveIncomingCall:(NSNotification *)notif
{
	NSString *displayString = NSLocalizedString(@"Incoming Call", @"");
	[self _setStatusBarString:displayString];
}

- (void)_didEstablishCall:(NSNotification *)notif
{
	NSString *displayString = NSLocalizedString(@"Call Established", @"");
	[self _setStatusBarString:displayString];
}

- (void)_didClearCall:(NSNotification *)notif
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
	
	if(displayClearTimer != nil)
	{
		[displayClearTimer invalidate];
		[displayClearTimer release];
		displayClearTimer = nil;
	}
}

@end
