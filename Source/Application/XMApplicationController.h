/*
 * $Id: XMApplicationController.h,v 1.9 2006/02/27 19:53:13 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_APPLICATION_CONTROLLER_H__
#define __XM_APPLICATION_CONTROLLER_H__

#import <Cocoa/Cocoa.h>

@class XMNoCallModule, XMInCallModule, XMBusyModule, XMLocalAudioVideoModule;
@class XMAddressBookModule, XMZeroConfModule, XMDialPadModule;
@class XMTextChatModule, XMStatisticsModule, XMCallHistoryModule;
@class XMInfoModule;

/**
 * XMApplicationController is responsible for the main menu and
 * is the NSApplication's delegate. In addition, this class
 * manages the application initialization and termination.
 **/
@interface XMApplicationController : NSObject {
	
	XMNoCallModule *noCallModule;
	XMInCallModule *inCallModule;
	XMBusyModule *busyModule;
	
	XMLocalAudioVideoModule *localAudioVideoModule;
	
	XMAddressBookModule *addressBookModule;
	XMZeroConfModule *zeroConfModule;
	XMDialPadModule *dialPadModule;
	XMTextChatModule *textChatModule;
	XMStatisticsModule *statisticsModule;
	XMCallHistoryModule *callHistoryModule;
	XMInfoModule *infoModule;
	
	NSAlert *incomingCallAlert;
	
}

/**
 * Causes the Preferences window to be shown on screen
 **/
- (IBAction)showPreferences:(id)sender;

- (IBAction)updateDeviceLists:(id)sender;

- (IBAction)retryGatekeeperRegistration:(id)sender;

- (IBAction)showInspector:(id)sender;

- (IBAction)showTools:(id)sender;

//Get&Set
- (XMAddressBookModule*)addressBookModule;

@end

#endif // __XM_APPLICATION_CONTROLLER_H__