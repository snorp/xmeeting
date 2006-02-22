/*
 * $Id: XMLocationPreferencesModule.h,v 1.8 2006/02/22 16:12:33 zmit Exp $
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

@class XMPreferencesWindowController, XMLocation;

@interface XMLocationPreferencesModule : NSObject <XMPreferencesModule> {
	
	XMPreferencesWindowController *prefWindowController;
	NSMutableArray *locations;
	XMLocation *currentLocation;
	IBOutlet NSView *contentView;
	float contentViewHeight;
	
	/* outlets for the locations GUI */
	
	//main outlets
	IBOutlet NSTableView *locationsTableView;
	IBOutlet NSButton *newLocationButton;
	IBOutlet NSButton *importLocationsButton;
	IBOutlet NSButton *duplicateLocationButton;
	IBOutlet NSButton *deleteLocationButton;
	IBOutlet NSButton *renameLocationButton;
	
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
	IBOutlet NSButton *useGatekeeperSwitch;
	IBOutlet NSTextField *gatekeeperHostField;
	IBOutlet NSTextField *gatekeeperIDField;
	IBOutlet NSTextField *gatekeeperUserAliasField;
	IBOutlet NSTextField *gatekeeperPhoneNumberField;
	IBOutlet NSTextField *gatekeeperPasswordField;
	
	// SIP outlets
	// have yet to come
	
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
	
	//other outlets
	IBOutlet NSPopUpButton *actionPopup;
	IBOutlet NSButton *actionButton;
}

// action methos for dealing with locations
- (IBAction)createNewLocation:(id)sender;
- (IBAction)importLocations:(id)sender;
- (IBAction)duplicateLocation:(id)sender;
- (IBAction)deleteLocation:(id)sender;
- (IBAction)renameLocation:(id)sender;

// default action method.
- (IBAction)defaultAction:(id)sender;

// General action methods
- (IBAction)toggleUseAddressTranslation:(id)sender;
- (IBAction)getExternalAddress:(id)sender;
- (IBAction)toggleAutoGetExternalAddress:(id)sender;

// H.323 action methods
- (IBAction)toggleEnableH323:(id)sender;
- (IBAction)toggleUseGatekeeper:(id)sender;

// SIP action methods
// none at present

// Audio action methods
- (IBAction)moveAudioCodec:(id)sender;

// Video action methods
- (IBAction)toggleEnableVideo:(id)sender;
- (IBAction)moveVideoCodec:(id)sender;

// Action methods for the newLocation Sheet
- (IBAction)endNewLocationSheet:(id)sender;

//Other
- (IBAction)actionButton:(id)sender;

@end

#endif // __XM_LOCATION_PREFRENCES_MODULE_H__
