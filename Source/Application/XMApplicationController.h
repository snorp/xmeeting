/*
 * $Id: XMApplicationController.h,v 1.12 2006/03/17 13:20:49 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_APPLICATION_CONTROLLER_H__
#define __XM_APPLICATION_CONTROLLER_H__

#import <Cocoa/Cocoa.h>

@class XMNoCallModule, XMInCallModule;
@class XMInfoModule, XMStatisticsModule, XMCallHistoryModule;
@class XMLocalAudioVideoModule;
@class XMAddressBookModule;

/**
 * XMApplicationController is responsible for the main menu and
 * is the NSApplication's delegate. In addition, this class
 * manages the application initialization and termination and controls
 * the appearance of various GUI elements on screen.
 * (windows, alert panels)
 **/
@interface XMApplicationController : NSObject {
	
	XMNoCallModule *noCallModule;
	XMInCallModule *inCallModule;
	
	XMInfoModule *infoModule;
	XMStatisticsModule *statisticsModule;
	XMCallHistoryModule *callHistoryModule;
	
	XMLocalAudioVideoModule *localAudioVideoModule;
	
	XMAddressBookModule *addressBookModule;
	//XMZeroConfModule *zeroConfModule;
	//XMDialPadModule *dialPadModule;
	//XMTextChatModule *textChatModule;
	
	NSAlert *incomingCallAlert;
}

/**
 * Causes the Preferences window to be shown on screen
 **/
- (IBAction)showPreferences:(id)sender;

- (IBAction)updateDeviceLists:(id)sender;
- (IBAction)retryEnableH323:(id)sender;
- (IBAction)retryGatekeeperRegistration:(id)sender;
- (IBAction)retryEnableSIP:(id)sender;
- (IBAction)retrySIPRegistration:(id)sender;

- (IBAction)showInspector:(id)sender;
- (IBAction)showTools:(id)sender;
- (IBAction)showContacts:(id)sender;

@end

#endif // __XM_APPLICATION_CONTROLLER_H__