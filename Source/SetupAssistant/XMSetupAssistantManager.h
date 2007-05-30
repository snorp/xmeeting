/*
 * $Id: XMSetupAssistantManager.h,v 1.6 2007/05/30 08:41:17 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_SETUP_ASSISTANT_MANAGER_H__
#define __XM_SETUP_ASSISTANT_MANAGER_H__

#import <Cocoa/Cocoa.h>

#import "XMeeting.h"

@class XMLocation;
@class XMH323Account;
@class XMSIPAccount;

/**
 * Keys that are understood when importing locations:
 *
 * XMKey_PreferencesBandwidthLimit
 * XMKey_H323AccountUsername
 * XMKey_H323AccountPhoneNumber
 * XMKey_H323AccountPassword
 * XMKey_SIPAccountUsername
 * XMKey_SIPAccountAuthorizationUsername
 * XMKey_SIPAccountPassword
 **/

@interface XMSetupAssistantManager : NSWindowController {
	
	int mode;
	int viewTag;
	
	XMLocation *location;
	XMH323Account *h323Account;
	XMSIPAccount *sipAccount;
	NSDictionary *locationImportData;
	NSString *locationFilePath;
	unsigned currentKeysToAskIndex;
	NSWindow *modalWindow;
	NSObject *delegate;
	SEL didEndSelector;
	
	IBOutlet NSButton *continueButton;
	IBOutlet NSButton *goBackButton;
	IBOutlet NSButton *cancelButton;
	
	IBOutlet NSTextField *titleField;
	IBOutlet NSImageView *cornerImage;
	IBOutlet NSBox *contentBox;
	
	IBOutlet NSView *flIntroductionView;
	IBOutlet NSView *flGeneralSettingsView;
	IBOutlet NSView *flLocationView;
	IBOutlet NSView *flNewLocationView;
	IBOutlet NSView *flNATDetectionView;
	IBOutlet NSView *flProtocolsView;
	IBOutlet NSView *flCompletedView;
	
	IBOutlet NSView *liInfoView;
	IBOutlet NSView *liCompletedView;
	
	IBOutlet NSView *networkSettingsView;
	IBOutlet NSView *natSettingsView;
	IBOutlet NSView *h323SettingsView;
	IBOutlet NSView *gatekeeperSettingsView;
	IBOutlet NSView *sipSettingsView;
	IBOutlet NSView *registrationSettingsView;
	IBOutlet NSView *videoSettingsView;
	
	// flGeneralSettings objects
	IBOutlet NSTextField *userNameField;
	NSString *userName;
	
	// flLocation objects
	IBOutlet NSMatrix *locationRadioButtons;
	
	// flNewLocation objects
	IBOutlet NSTextField *locationNameField;
	
	// flNATDetection objects
	IBOutlet NSBox *natDetectionBox;
	IBOutlet NSBox *natTypeBox;
	IBOutlet NSProgressIndicator *natDetectionProgressIndicator;
	IBOutlet NSTextField *natTypeField;
	IBOutlet NSTextField *natTypeExplanationField;
	IBOutlet NSButton *continueNATSettingsButton;
	XMNATType detectedNATType;
	
	// flProtocol objects;
	IBOutlet NSButton *enableH323Switch;
	IBOutlet NSButton *enableSIPSwitch;
	
	// liInfo objects
	IBOutlet NSTextField *infoField;
	
	// networkSettings objects
	IBOutlet NSPopUpButton *bandwidthLimitPopUp;
	
	// natSettings object
	IBOutlet NSButton *useSTUNRadioButton;
	IBOutlet NSComboBox *stunServerField;
	IBOutlet NSButton *useIPAddressTranslationRadioButton;
	IBOutlet NSTextField *externalAddressField;
	IBOutlet NSButton *updateExternalAddressButton;
	IBOutlet NSButton *automaticallyGetExternalAddressSwitch;
	BOOL externalAddressIsValid;
	IBOutlet NSButton *noneRadioButton;
	
	// h323Settings objects
	IBOutlet NSMatrix *useGatekeeperRadioButtons;
	
	// gatekeeperSettings objects
	IBOutlet NSTextField *gkHostField;
	IBOutlet NSTextField *gkUsernameField;
	IBOutlet NSTextField *gkPhoneNumberField;
	IBOutlet NSTextField *gkPasswordField;
	
	// sipSettings objects
	IBOutlet NSMatrix *useRegistrationRadioButtons;
	
	// registrationSettings object
	IBOutlet NSTextField *registrationDomainField;
	IBOutlet NSTextField *registrationUsernameField;
	IBOutlet NSTextField *registrationAuthUsernameField;
	IBOutlet NSTextField *registrationPasswordField;
	
	// videoSettings objects
	IBOutlet NSMatrix *enableVideoRadioButtons;

}

+ (XMSetupAssistantManager *)sharedInstance;

/**
 * Runs the assistant in the first application launch mode. When the
 * assistant has finished, didEndSelector is invoked. This selector
 * should have the form 
 * -assistantDidEndWithLocations:(NSArray *)locations 
 *					h323Accounts:(NSArray *)h323Accounts
 *					 sipAccounts:(NSArray *)sipAccounts
 *
 * locations contains the created location or zero elements in case the
 * user canceled.
 * h323Accounts contains any H.323 accounts created by this assistant
 * sipAccounts contains any SIP accounts created by this assistant
 **/
- (void)runFirstApplicationLaunchAssistantWithDelegate:(NSObject *)delegate
										didEndSelector:(SEL)didEndSelector;

/**
 * Runs the assistant to import locations. When the assistant
 * has finished, didEndSelector is invoked. This selector should
 * have the form 
 * -assistantDidEndWithLocations:(NSArray *)locations
 *					h323Accounts:(NSArray *)h323Accounts
 *					 sipAccounts:(NSArray *)sipAccounts
 *
 * locations contains the imported locations or zero elements in
 * case the user canceled.
 * h323Accounts contains any H.323 accounts created by this assistant
 * sipAccounts contains any SIP accounts created by this assistant
 **/
- (void)runImportLocationsAssistantModalForWindow:(NSWindow *)window
									modalDelegate:(NSObject *)modalDelegate
								   didEndSelector:(SEL)didEndSelector;

// action methods
- (IBAction)cancelAssistant:(id)sender;
- (IBAction)continueAssistant:(id)sender;
- (IBAction)goBackAssistant:(id)sender;

// Action methods for NAT Detection
- (IBAction)updateNATType:(id)sender;
- (IBAction)continueNATSettings:(id)sender;

// Action methods for NAT Traversal
- (IBAction)toggleNATMethod:(id)sender;
- (IBAction)getExternalAddress:(id)sender;
- (IBAction)toggleAutoGetExternalAddress:(id)sender;

// Action methods for protocol activation
- (IBAction)protocolSwitchToggled:(id)sender;

@end

#endif // __XM_SETUP_ASSISTANT_MANAGER_H__
