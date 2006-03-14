/*
 * $Id: XMSetupAssistantManager.h,v 1.3 2006/03/14 23:06:09 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_SETUP_ASSISTANT_MANAGER_H__
#define __XM_SETUP_ASSISTANT_MANAGER_H__

#import <Cocoa/Cocoa.h>

@class XMLocation;

@interface XMSetupAssistantManager : NSWindowController {
	
	int mode;
	int viewTag;
	
	XMLocation *location;
	NSDictionary *locationImportData;
	NSString *locationFilePath;
	unsigned currentKeysToAskIndex;
	NSWindow *modalWindow;
	id delegate;
	SEL didEndSelector;
	
	IBOutlet NSButton *continueButton;
	IBOutlet NSButton *goBackButton;
	IBOutlet NSButton *cancelButton;
	
	IBOutlet NSBox *contentBox;
	
	IBOutlet NSView *flIntroductionView;
	IBOutlet NSView *flGeneralSettingsView;
	IBOutlet NSView *flLocationView;
	IBOutlet NSView *flNewLocationView;
	IBOutlet NSView *flCompletedView;
	
	IBOutlet NSView *liInfoView;
	IBOutlet NSView *liCompletedView;
	
	IBOutlet NSView *networkSettingsView;
	IBOutlet NSView *h323SettingsView;
	IBOutlet NSView *gatekeeperSettingsView;
	IBOutlet NSView *videoSettingsView;
	
	// flGeneralSettings objects
	IBOutlet NSTextField *userNameField;
	NSString *userName;
	
	// flLocation objects
	IBOutlet NSMatrix *locationRadioButtons;
	
	// flNewLocation objects
	IBOutlet NSTextField *locationNameField;
	
	// liInfo objects
	IBOutlet NSTextField *infoField;
	
	// networkSettings objects
	IBOutlet NSPopUpButton *bandwidthLimitPopUp;
	IBOutlet NSButton *useIPAddressTranslationSwitch;
	IBOutlet NSTextField *externalAddressField;
	IBOutlet NSButton *updateExternalAddressButton;
	IBOutlet NSButton *automaticallyGetExternalAddressSwitch;
	BOOL externalAddressIsValid;
	
	// h323Settings objects
	IBOutlet NSMatrix *useGatekeeperRadioButtons;
	
	// gatekeeperSettings objects
	IBOutlet NSTextField *gkHostField;
	IBOutlet NSTextField *gkUsernameField;
	IBOutlet NSTextField *gkPhoneNumberField;
	IBOutlet NSTextField *gkPasswordField;
	NSString *gkPassword;
	
	// videoSettings objects
	IBOutlet NSMatrix *enableVideoRadioButtons;

}

+ (XMSetupAssistantManager *)sharedInstance;

/**
 * Runs the assistant in the first application launch mode. When the
 * assistant has finished, didEndSelector is invoked. This selector
 * should have the form -assistantDidEndWithLocations:(NSArray *)locations,
 * locations contains the created location or zero elements in case the
 * user canceled.
 **/
- (void)runFirstApplicationLaunchAssistantWithDelegate:(id)delegate
										didEndSelector:(SEL)didEndSelector;

/**
 * Runs the assistant to import locations. When the assistant
 * has finished, didEndSelector is invoked. This selector should
 * have the form -assistantDidEndWithLocations:(NSArray *)locations,
 * locations contains the imported locations or zero elements in
 * case the user canceled.
 **/
- (void)runImportLocationsAssistantModalForWindow:(NSWindow *)window
									modalDelegate:(id)modalDelegate
								   didEndSelector:(SEL)didEndSelector;

- (IBAction)cancelAssistant:(id)sender;
- (IBAction)continueAssistant:(id)sender;
- (IBAction)goBackAssistant:(id)sender;

// Action methods for Address Translation
- (IBAction)validateAddressTranslationInterface:(id)sender;
- (IBAction)updateExternalAddress:(id)sender;

@end

#endif // __XM_SETUP_ASSISTANT_MANAGER_H__
