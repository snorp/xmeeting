/*
 * $Id: XMApplicationController.m,v 1.4 2005/06/02 08:23:08 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMeeting.h"
#import "XMApplicationController.h"
#import "XMAddressBookCallAddressProvider.h"

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
	[[XMAddressBookCallAddressProvider sharedInstance] setActiveCallAddressProvider:YES];
	[[XMNoCallModule alloc] init];
	[[XMInCallModule alloc] init];
	[[XMAddressBookModule alloc] init];
	[[XMZeroConfModule alloc] init];
	[[XMDialPadModule alloc] init];
	[[XMTextChatModule alloc] init];
	[[XMStatisticsModule alloc] init];
	[[XMCallHistoryModule alloc] init];
	[[XMMainWindowController sharedInstance] showMainWindow];
	
	[[XMUtils sharedInstance] startFetchingExternalAddress];
}

- (IBAction)showPreferences:(id)sender
{
	[[XMPreferencesWindowController sharedInstance] showPreferencesWindow];
}

@end
