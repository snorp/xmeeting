/*
 * $Id: XMLocationPreferencesModule.h,v 1.10 2006/04/06 23:15:32 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_LOCATION_PREFERENCES_MODULE_H__
#define __XM_LOCATION_PREFERENCES_MODULE_H__

#import <Cocoa/Cocoa.h>

#import "XMPreferencesModule.h"

extern NSString *XMKey_LocationPreferencesModuleIdentifier;

@class XMPreferencesWindowController, XMAccountPreferencesModule, XMLocation;

@interface XMLocationPreferencesModule : NSObject <XMPreferencesModule> {
	
	XMPreferencesWindowController *prefWindowController;
	NSMutableArray *locations;
	XMLocation *currentLocation;
	IBOutlet NSView *contentView;
	float contentViewHeight;
	
	/* connection to the account modules */
	IBOutlet XMAccountPreferencesModule *accountModule;
	
	/* outlets for the locations GUI */
	
	//main outlets
	IBOutlet NSTableView *locationsTableView;
	IBOutlet NSButton *newLocationButton;
	IBOutlet NSButton *deleteLocationButton;
	IBOutlet NSPopUpButton *actionPopup;
	IBOutlet NSButton *actionButton;
	IBOutlet NSTabView *sectionsTab;
	
	// general outlets
	IBOutlet NSPopUpButton *bandwidthLimitPopUp;
	IBOutlet NSButton *useIPAddressTranslationSwitch;
	IBOutlet NSTextField *externalAddressField;
	IBOutlet NSButton *getExternalAddressButton;
	IBOutlet NSButton *autoGetExternalAddressSwitch;
	IBOutlet NSTextField *minTCPPortField;
	IBOutlet NSTextField *maxTCPPortField;
	IBOutlet NSTextField *minUDPPortField;
	IBOutlet NSTextField *maxUDPPortField;
	BOOL externalAddressIsValid;
	BOOL isFetchingExternalAddress;
	
	// h323 outlets
	IBOutlet NSButton *enableH323Switch;
	IBOutlet NSButton *enableH245TunnelSwitch;
	IBOutlet NSButton *enableFastStartSwitch;
	IBOutlet NSPopUpButton *h323AccountsPopUp;
	IBOutlet NSTextField *gatekeeperHostField;
	IBOutlet NSTextField *gatekeeperUserAliasField;
	IBOutlet NSTextField *gatekeeperPhoneNumberField;
	
	// SIP outlets
	IBOutlet NSButton *enableSIPSwitch;
	IBOutlet NSPopUpButton *sipAccountsPopUp;
	IBOutlet NSTextField *registrarHostField;
	IBOutlet NSTextField *registrarUsernameField;
	IBOutlet NSTextField *registrarAuthorizationUsernameField;
	
	// Audio outlets
	IBOutlet NSSlider *audioBufferSizeSlider;
	IBOutlet NSTableView *audioCodecPreferenceOrderTableView;
	IBOutlet NSButton *moveAudioCodecUpButton;
	IBOutlet NSButton *moveAudioCodecDownButton;
	
	// Video outlets
	IBOutlet NSButton *enableVideoSwitch;
	IBOutlet NSTextField *videoFrameRateField;
	IBOutlet NSTableView *videoCodecPreferenceOrderTableView;
	IBOutlet NSButton *moveVideoCodecUpButton;
	IBOutlet NSButton *moveVideoCodecDownButton;
	IBOutlet NSButton *enableH264LimitedModeSwitch;
	
	// Outlets for the newLocation Sheet
	IBOutlet NSPanel *newLocationSheet;
	IBOutlet NSTextField *newLocationNameField;
	IBOutlet NSButton *newLocationOKButton;
	IBOutlet NSButton *newLocationCancelButton;
}

// action methos for dealing with locations
- (IBAction)createNewLocation:(id)sender;
- (IBAction)importLocations:(id)sender;
- (IBAction)duplicateLocation:(id)sender;
- (IBAction)deleteLocation:(id)sender;
- (IBAction)renameLocation:(id)sender;
- (IBAction)actionButton:(id)sender;

// default action method.
- (IBAction)defaultAction:(id)sender;

// General action methods
- (IBAction)toggleUseAddressTranslation:(id)sender;
- (IBAction)getExternalAddress:(id)sender;
- (IBAction)toggleAutoGetExternalAddress:(id)sender;

// H.323 action methods
- (IBAction)toggleEnableH323:(id)sender;
- (IBAction)gatekeeperAccountSelected:(id)sender;

// SIP action methods
- (IBAction)toggleEnableSIP:(id)sender;
- (IBAction)sipAccountSelected:(id)sender;

// Audio action methods
- (IBAction)moveAudioCodec:(id)sender;

// Video action methods
- (IBAction)toggleEnableVideo:(id)sender;
- (IBAction)moveVideoCodec:(id)sender;

// Action methods for the newLocation Sheet
- (IBAction)endNewLocationSheet:(id)sender;

// Infom when the accounts change
- (void)noteAccountsDidChange;

@end

#endif // __XM_LOCATION_PREFRENCES_MODULE_H__
