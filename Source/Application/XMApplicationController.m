/*
 * $Id: XMApplicationController.m,v 1.2 2005/05/24 15:21:01 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMeeting.h"
#import "XMApplicationController.h"
#import "XMMainWindowController.h"
#import "XMPreferencesWindowController.h"
#import "XMNoCallModule.h"
#import "XMInCallModule.h"
#import "XMAddressBookModule.h"
#import "XMZeroConfModule.h"
#import "XMDialPadModule.h"
#import "XMTextChatModule.h"
#import "XMStatisticsModule.h"
#import "XMCallHistoryModule.h"

@implementation XMApplicationController

- (void)awakeFromNib
{
	[[XMNoCallModule alloc] init];
	[[XMInCallModule alloc] init];
	[[XMAddressBookModule alloc] init];
	[[XMZeroConfModule alloc] init];
	[[XMDialPadModule alloc] init];
	[[XMTextChatModule alloc] init];
	[[XMStatisticsModule alloc] init];
	[[XMCallHistoryModule alloc] init];
	[[XMMainWindowController sharedInstance] showMainWindow];
}

- (IBAction)showPreferences:(id)sender
{
	[[XMPreferencesWindowController sharedInstance] showPreferencesWindow];
}

@end
