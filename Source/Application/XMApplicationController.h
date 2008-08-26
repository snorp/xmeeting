/*
 * $Id: XMApplicationController.h,v 1.23 2008/08/26 08:14:06 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_APPLICATION_CONTROLLER_H__
#define __XM_APPLICATION_CONTROLLER_H__

#import <Cocoa/Cocoa.h>

#import "XMPreferencesManager.h"

@class XMNoCallModule, XMInCallModule;
@class XMInfoModule, XMStatisticsModule, XMCallHistoryModule;
@class XMLocalAudioVideoModule, XMDialPadModule, XMCallRecorderModule;
@class XMAddressBookModule;
@class XMIncomingCallAlert;

/**
 * XMApplicationController is responsible for the main menu and
 * is the NSApplication's delegate. In addition, this class
 * manages the application initialization and termination and controls
 * the appearance of various GUI elements on screen.
 * (windows, alert panels)
 **/
@interface XMApplicationController : NSObject {
  
@private
  XMNoCallModule *noCallModule;
  XMInCallModule *inCallModule;
  
  XMInfoModule *infoModule;
  XMStatisticsModule *statisticsModule;
  XMCallHistoryModule *callHistoryModule;
  
  XMLocalAudioVideoModule *localAudioVideoModule;
  XMDialPadModule *dialPadModule;
  XMCallRecorderModule *callRecorderModule;
  
  XMAddressBookModule *addressBookModule;
  //XMZeroConfModule *zeroConfModule;
  //XMTextChatModule *textChatModule;
  
  BOOL isFullScreen;
  
  NSObject *activeAlert;
  NSSound *incomingCallSound;
  XMIncomingCallAlertType alertType;
  
  NSString *calledAddress;
}

/**
 * Causes the Preferences window to be shown on screen
 **/
- (IBAction)showPreferences:(id)sender;

- (IBAction)updateDeviceLists:(id)sender;
- (IBAction)updateNetworkInformation:(id)sender;

- (IBAction)showMainWindow:(id)sender;
- (IBAction)showInspector:(id)sender;
- (IBAction)showTools:(id)sender;
- (IBAction)showContacts:(id)sender;

- (IBAction)enterFullScreen:(id)sender;
- (void)exitFullScreen;
- (BOOL)isFullScreen;

- (void)showInfoInspector;
- (void)showStatisticsInspector;
- (void)showCallHistoryInspector;

@end

#endif // __XM_APPLICATION_CONTROLLER_H__