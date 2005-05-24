/*
 * $Id: XMGeneralPreferencesModule.m,v 1.3 2005/05/24 15:21:02 hfriederich Exp $
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
	return nil;
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
	
	int state = ([prefManager defaultAutoAnswerCalls] == YES) ? NSOnState : NSOffState;
	[autoAnswerCallsSwitch setState:state];
}

- (void)savePreferences
{
	XMPreferencesManager *prefManager = [XMPreferencesManager sharedInstance];
	
	[prefManager setUserName:[userNameField stringValue]];
	
	BOOL flag = ([autoAnswerCallsSwitch state] == NSOnState) ? YES : NO;
	[prefManager setDefaultAutoAnswerCalls:flag];
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
