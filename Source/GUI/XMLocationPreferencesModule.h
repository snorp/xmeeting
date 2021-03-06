/*
 * $Id: XMLocationPreferencesModule.h,v 1.26 2009/01/11 19:20:37 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_LOCATION_PREFERENCES_MODULE_H__
#define __XM_LOCATION_PREFERENCES_MODULE_H__

#import <Cocoa/Cocoa.h>

#import "XMPreferencesModule.h"
#import "XMLocation.h"

extern NSString *XMKey_LocationPreferencesModuleIdentifier;

@class XMPreferencesWindowController, XMAccountPreferencesModule, XMMultipleLocationsWrapper;

@interface XMLocationPreferencesModule : NSObject <XMPreferencesModule> {
	
@private
  XMPreferencesWindowController *prefWindowController;
  NSMutableArray *locations;
  XMLocation *currentLocation;
  XMMultipleLocationsWrapper *multipleLocationsWrapper;
  IBOutlet NSView *contentView;
  float contentViewHeight;
  
  /* connection to the account modules */
  IBOutlet XMAccountPreferencesModule *accountModule;
  
  /* outlets for the locations GUI */
  
  //main outlets
  IBOutlet NSTableView *locationsTableView;
  IBOutlet NSButton *newLocationButton;
  IBOutlet NSButton *deleteLocationButton;
  IBOutlet NSButton *selectAllButton;
  IBOutlet NSPopUpButton *actionPopup;
  IBOutlet NSButton *actionButton;
  IBOutlet NSTabView *sectionsTab;
  
  // network outlets
  IBOutlet NSPopUpButton *bandwidthLimitPopUp;
  IBOutlet NSTextField *publicAddressField;
  IBOutlet NSButton *autoGetExternalAddressSwitch;
  IBOutlet NSTabView *stunServersTab;
  IBOutlet NSTableView *stunServersTable;
  NSMutableArray * stunServers;
  IBOutlet NSButton *removeSTUNServerButton;
  IBOutlet NSButton *moveSTUNServerUpButton;
  IBOutlet NSButton *moveSTUNServerDownButton;
  IBOutlet NSTextField *minTCPPortField;
  IBOutlet NSTextField *maxTCPPortField;
  IBOutlet NSTextField *minUDPPortField;
  IBOutlet NSTextField *maxUDPPortField;
  
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
  IBOutlet NSTabView *sipAccountsTab;
  IBOutlet NSTableView *sipAccountsTable;
  NSMutableArray * sipAccounts;
  unsigned defaultSIPAccountIndex;
  IBOutlet NSButton *makeDefaultSIPAccountButton;
  IBOutlet NSPopUpButton *sipProxyPopUp;
  IBOutlet NSTextField *sipProxyHostField;
  IBOutlet NSTextField *sipProxyUsernameField;
  IBOutlet NSTextField *sipProxyPasswordField;
  BOOL sipProxyPasswordDidChange;
  
  // Audio outlets
  IBOutlet NSTabView *audioCodecsTab;
  IBOutlet NSTableView *audioCodecPreferenceOrderTableView;
  NSMutableArray *audioCodecs;
  IBOutlet NSButton *moveAudioCodecUpButton;
  IBOutlet NSButton *moveAudioCodecDownButton;
  IBOutlet NSButton *enableSilenceSuppressionSwitch;
  IBOutlet NSButton *enableEchoCancellationSwitch;
  IBOutlet NSPopUpButton *audioPacketTimePopUp;
  
  // Video outlets
  IBOutlet NSButton *enableVideoSwitch;
  IBOutlet NSTextField *videoFrameRateField;
  IBOutlet NSTabView *videoCodecsTab;
  IBOutlet NSTableView *videoCodecPreferenceOrderTableView;
  NSMutableArray *videoCodecs;
  IBOutlet NSButton *moveVideoCodecUpButton;
  IBOutlet NSButton *moveVideoCodecDownButton;
  IBOutlet NSButton *enableH264LimitedModeSwitch;
  
  // Misc outlets
  IBOutlet NSTextField *internationalDialingPrefixField;
  
  // Outlets for the newLocation Sheet
  IBOutlet NSPanel *newLocationSheet;
  IBOutlet NSTextField *newLocationNameField;
  IBOutlet NSButton *newLocationOKButton;
  IBOutlet NSButton *newLocationCancelButton;
  
  BOOL locationLoaded;
  BOOL doAlertNoPublicAddress;
}

// action methos for dealing with locations
- (IBAction)createNewLocation:(id)sender;
- (IBAction)importLocations:(id)sender;
- (IBAction)duplicateLocation:(id)sender;
- (IBAction)deleteLocation:(id)sender;
- (IBAction)selectAllLocations:(id)sender;
- (IBAction)renameLocation:(id)sender;
- (IBAction)actionButton:(id)sender;

// default action method.
- (IBAction)defaultAction:(id)sender;

// Network action methods
- (IBAction)toggleAutoGetExternalAddress:(id)sender;
- (IBAction)addSTUNServer:(id)sender;
- (IBAction)removeSTUNServer:(id)sender;
- (IBAction)moveSTUNServerUp:(id)sender;
- (IBAction)moveSTUNServerDown:(id)sender;
- (IBAction)overwriteSTUNServers:(id)sender;

// H.323 action methods
- (IBAction)toggleEnableH323:(id)sender;
- (IBAction)gatekeeperAccountSelected:(id)sender;

// SIP action methods
- (IBAction)toggleEnableSIP:(id)sender;
- (IBAction)makeDefaultSIPAccount:(id)sender;
- (IBAction)overwriteSIPAccounts:(id)sender;
- (IBAction)sipProxySelected:(id)sender;

// Audio action methods
- (IBAction)moveAudioCodec:(id)sender;
- (IBAction)overwriteAudioCodecs:(id)sender;

// Video action methods
- (IBAction)toggleEnableVideo:(id)sender;
- (IBAction)moveVideoCodec:(id)sender;
- (IBAction)overwriteVideoCodecs:(id)sender;

// Action methods for the newLocation Sheet
- (IBAction)endNewLocationSheet:(id)sender;

// Infom when the accounts change
- (void)noteAccountsDidChange;

@end

#endif // __XM_LOCATION_PREFRENCES_MODULE_H__
