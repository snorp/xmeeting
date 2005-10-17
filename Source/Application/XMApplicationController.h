/*
 * $Id: XMApplicationController.h,v 1.6 2005/10/17 12:57:53 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_APPLICATION_CONTROLLER_H__
#define __XM_APPLICATION_CONTROLLER_H__

#import <Cocoa/Cocoa.h>

@class XMNoCallModule, XMInCallModule, XMLocalAudioVideoModule;
@class XMAddressBookModule, XMZeroConfModule, XMDialPadModule;
@class XMTextChatModule, XMStatisticsModule, XMCallHistoryModule;

/**
 * XMApplicationController is responsible for the main menu and
 * is the NSApplication's delegate. In addition, this class
 * manages the application initialization and termination.
 **/
@interface XMApplicationController : NSObject {
	
	XMNoCallModule *noCallModule;
	XMInCallModule *inCallModule;
	
	XMLocalAudioVideoModule *localAudioVideoModule;
	
	XMAddressBookModule *addressBookModule;
	XMZeroConfModule *zeroConfModule;
	XMDialPadModule *dialPadModule;
	XMTextChatModule *textChatModule;
	XMStatisticsModule *statisticsModule;
	XMCallHistoryModule *callHistoryModule;
	
	NSAlert *incomingCallAlert;
}

/**
 * Causes the Preferences window to be shown on screen
 **/
- (IBAction)showPreferences:(id)sender;

- (IBAction)updateDeviceLists:(id)sender;

@end

#endif // __XM_APPLICATION_CONTROLLER_H__