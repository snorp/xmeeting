/*
 * $Id: XMGeneralPreferencesModule.m,v 1.5 2006/02/22 16:12:33 zmit Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMGeneralPreferencesModule.h"
#import "XMPreferencesWindowController.h"
#import "XMPreferencesManager.h"

NSString *XMKey_GeneralPreferencesModuleIdentifier = @"XMeeting_GeneralPreferencesModule";

@implementation XMGeneralPreferencesModule

- (id)init
{
	prefWindowController = [[XMPreferencesWindowController sharedInstance] retain];
	
	return self;
}

- (void)awakeFromNib
{
	contentViewHeight = [contentView frame].size.height;
	[prefWindowController addPreferencesModule:self];
}

- (void)dealloc
{
	[prefWindowController release];

	[super dealloc];
}

- (unsigned)position
{
	return 0;
}

- (NSString *)identifier
{
	return XMKey_GeneralPreferencesModuleIdentifier;
}

- (NSString *)toolbarLabel
{
	return NSLocalizedString(@"General", @"GeneralPreferencesModuleLabel");
}

- (NSImage *)toolbarImage
{
	return [NSImage imageNamed:@"generalPreferences.tif"];
}

- (NSString *)toolTipText
{
	return NSLocalizedString(@"General Purpose Preferences", @"GeneralPreferencesModuleToolTip");
}

- (NSView *)contentView
{
	return contentView;
}

- (float)contentViewHeight
{
	return contentViewHeight;
}

- (void)loadPreferences
{
	XMPreferencesManager *prefManager = [XMPreferencesManager sharedInstance];
	
	[userNameField setStringValue:[prefManager userName]];
	
	int state = ([prefManager defaultAutomaticallyAcceptIncomingCalls] == YES) ? NSOnState : NSOffState;
	[automaticallyAcceptIncomingCallsSwitch setState:state];
}

- (void)savePreferences
{
	XMPreferencesManager *prefManager = [XMPreferencesManager sharedInstance];
	
	[prefManager setUserName:[userNameField stringValue]];
	
	BOOL flag = ([automaticallyAcceptIncomingCallsSwitch state] == NSOnState) ? YES : NO;
	[prefManager setDefaultAutomaticallyAcceptIncomingCalls:flag];
}

#pragma mark Action & Delegate Methods

- (IBAction)defaultAction:(id)sender
{
	[prefWindowController notePreferencesDidChange];
}

- (void)controlTextDidChange:(NSNotification *)notif
{
	[self defaultAction:self];
}

@end
