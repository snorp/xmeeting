/*
 * $Id: XMSetupAssistantManager.m,v 1.17 2007/09/27 21:13:12 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#import "XMSetupAssistantManager.h"

#import "XMeeting.h"
#import "XMPreferencesManager.h"
#import "XMLocation.h"
#import "XMH323Account.h"
#import "XMSIPAccount.h"
#import "XMApplicationFunctions.h"

#define XM_QUIT_APPLICATION UINT_MAX

#define XM_NO_MODE 0
#define XM_FIRST_APPLICATION_LAUNCH_MODE 1
#define XM_FIRST_APPLICATION_LAUNCH_IMPORT_LOCATIONS_MODE 2
#define XM_IMPORT_LOCATIONS_MODE 3

#define XM_NO_VIEW_TAG 0

#define XM_FL_INTRODUCTION_VIEW_TAG 1
#define XM_FL_GENERAL_SETTINGS_VIEW_TAG 2
#define XM_FL_LOCATION_VIEW_TAG 3
#define XM_FL_NEW_LOCATION_VIEW_TAG 4
#define XM_FL_PROTOCOLS_VIEW_TAG 5
#define XM_FL_COMPLETED_VIEW_TAG 6

#define XM_LI_START_VIEW_TAG 11
#define XM_LI_INFO_VIEW_TAG 12
#define XM_LI_COMPLETED_VIEW_TAG 13

#define XM_NETWORK_SETTINGS_VIEW_TAG 21
#define XM_NAT_SETTINGS_VIEW_TAG 22
#define XM_H323_SETTINGS_VIEW_TAG 23
#define XM_GATEKEEPER_SETTINGS_VIEW_TAG 24
#define XM_SIP_SETTINGS_VIEW_TAG 25
#define XM_REGISTRATION_SETTINGS_VIEW_TAG 26
#define XM_VIDEO_SETTINGS_VIEW_TAG 27

#define XMKey_SetupAssistantNibName @"SetupAssistant"

#define XMKey_KeysToAsk @"XMeeting_KeysToAsk"
#define XMKey_AppliesTo @"XMeeting_AppliesTo"
#define XMKey_Description @"XMeeting_Description"
#define XMKey_Title @"XMeeting_Title"
#define XMKey_Keys @"XMeeting_Keys"
#define XMKey_GatekeeperPassword @"XMeeting_GatekeeperPassword"
#define XMKey_Locations @"XMeeting_Locations"
#define XMKey_H323Accounts @"XMeeting_H323Accounts"
#define XMKey_SIPAccounts @"XMeeting_SIPAccounts"

@interface XMSetupAssistantManager (PrivateMethods)

- (id)_init;

- (void)_setupButtons;

- (void)_setTitle:(NSString *)title;
- (void)_setShowCornerImage:(BOOL)flag;

- (void)_showNextViewForFirstApplicationLaunchMode;
- (void)_showPreviousViewForFirstApplicationLaunchMode;
- (void)_returnFromFirstApplicationLaunchAssistant:(int)returnCode;

- (void)_prepareFLIntroductionSettings;
- (void)_finishFLIntroductionSettings;

- (NSView *)_prepareFLGeneralSettings;
- (void)_finishFLGeneralSettings;

- (void)_prepareFLLocationSettings;
- (void)_finishFLLocationSettings;

- (NSView *)_prepareFLNewLocationSettings;
- (void)_finishFLNewLocationSettings;

- (void)_prepareFLNetworkSettings;
- (void)_finishFLNetworkSettings;

- (void)_prepareFLProtocolSettings;
- (void)_finishFLProtocolSettings;

- (void)_prepareFLNATSettings;
- (void)_finishFLNATSettings;

- (void)_prepareFLH323Settings;
- (void)_finishFLH323Settings;

- (NSView *)_prepareFLGatekeeperSettings;
- (void)_finishFLGatekeeperSettings;

- (void)_prepareFLSIPSettings;
- (void)_finishFLSIPSettings;

- (NSView *)_prepareFLRegistrationSettings;
- (void)_finishFLRegistrationSettings;

- (void)_prepareFLVideoSettings;
- (void)_finishFLVideoSettings;

- (void)_prepareFLCompletedSettings;
- (void)_finishFLCompletedSettings;

- (void)_beginFLLocationImport;
- (void)_flLocationImportOpenPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (NSDictionary *)_parseFile:(NSString *)file errorDescription:(NSString **)errorDescription;
- (void)_returnFromLocationImportAssistant:(int)returnCode;

- (void)_showNextViewForImportLocationModes;
- (void)_showPreviousViewForImportLocationModes;

- (void)_liLocationImportOpenPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (void)_prepareLIInfoSettings;
- (void)_finishLIInfoSettings;

- (void)_prepareLINetworkSettings;
- (void)_finishLINetworkSettings;

- (NSView *)_prepareLIGatekeeperSettings;
- (void)_finishLIGatekeeperSettings;

- (NSView *)_prepareLIRegistrationSettings;
- (void)_finishLIRegistrationSettings;

- (void)_prepareLICompletedSettings;
- (void)_finishLICompletedSettings;

- (void)_didStartFetchingExternalAddress:(NSNotification *)notif;
- (void)_didEndFetchingExternalAddress:(NSNotification *)notif;
- (void)_didUpdateSTUNInformation:(NSNotification *)notif;
- (void)_setupNATTypeView;

- (void)_validateSTUNUserInterface;
- (void)_validateAddressTranslationUserInterface;
- (void)_validateExternalAddressUserInterface;

@end

@implementation XMSetupAssistantManager

#pragma mark Class Methods

static XMSetupAssistantManager *sharedInstance = nil;

+ (XMSetupAssistantManager *)sharedInstance
{	
	if(sharedInstance == nil)
	{
		sharedInstance = [[XMSetupAssistantManager alloc] _init];
	}
	
	return sharedInstance;
}

#pragma mark Init & Deallocation Methods

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	return nil;
}

- (id)_init
{
	self = [super initWithWindowNibName:XMKey_SetupAssistantNibName owner:self];
	
	mode = XM_NO_MODE;
	viewTag = XM_NO_VIEW_TAG;
	
	location = nil;
	h323Account = nil;
	sipAccount = nil;
	locationImportData = nil;
	currentKeysToAskIndex = 0;
	
	userName = nil;
	
	return self;
}

- (void)dealloc
{
	if(location != nil)
	{
		[location release];
	}
	if(locationImportData != nil)
	{
		[locationImportData release];
	}
	if(userName != nil)
	{
		[userName release];
	}
	
	[super dealloc];
}

#pragma mark Public Methods

- (void)runFirstApplicationLaunchAssistantWithDelegate:(NSObject *)theDelegate
										didEndSelector:(SEL)theDidEndSelector
{
	delegate = theDelegate;
	didEndSelector = theDidEndSelector;
	
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	
	// triggering the nib loading if necessary
	[self window];
	
	// preparing the view
	mode = XM_FIRST_APPLICATION_LAUNCH_MODE;
	viewTag = XM_FL_INTRODUCTION_VIEW_TAG;
	[self _prepareFLIntroductionSettings];
	[contentBox setContentView:flIntroductionView];
	[self _setupButtons];
	
	// creating an empty location
	location = (XMLocation *)[[[preferencesManager locations] objectAtIndex:0] retain];
	h323Account = [[XMH323Account alloc] init];
	[h323Account setName:NSLocalizedString(@"XM_SETUP_ASSISTANT_DEFAULT_GK", @"")];
	sipAccount = [[XMSIPAccount alloc] init];
	[sipAccount setName:NSLocalizedString(@"XM_SETUP_ASSISTANT_DEFAULT_REG", @"")];
	
	if(locationImportData != nil)
	{
		[locationImportData release];
		locationImportData = nil;
	}
	
	currentKeysToAskIndex = 0;
	
	// preparing the general (non-location) settings
	if(userName != nil)
	{
		[userName release];
	}
	userName = [[preferencesManager userName] retain];
	
	if(locationFilePath != nil)
	{
		[locationFilePath release];
		locationFilePath = nil;
	}
	
	// changing some default settings of location
	[location setEnableVideo:YES];
	[location setBandwidthLimit:512000];
	[location setEnableH323:YES];
	[location setEnableSIP:YES];
	[location setSIPAccountTag:[sipAccount tag]];
	//[location setSIPProxyMode:XMSIPProxyMode_UseSIPAccount];
	
	detectedNATType = XMNATType_Error;
	
	[[self window] center];
	[self showWindow:self];
}

- (IBAction)showWindow:(id)sender
{
	[super showWindow:sender];
}

- (void)runImportLocationsAssistantModalForWindow:(NSWindow *)window 
									modalDelegate:(NSObject *)theModalDelegate
								   didEndSelector:(SEL)theDidEndSelector
{
	modalWindow = window;
	delegate = theModalDelegate;
	didEndSelector = theDidEndSelector;
	
	currentKeysToAskIndex = 0;
	
	if(locationFilePath != nil)
	{
		[locationFilePath release];
		locationFilePath = nil;
	}
	
	mode = XM_IMPORT_LOCATIONS_MODE;
	viewTag = XM_LI_START_VIEW_TAG;
	
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setResolvesAliases:YES];
	[openPanel setAllowsMultipleSelection:NO];
	
	[openPanel beginSheetForDirectory:nil file:nil types:nil modalForWindow:modalWindow
						modalDelegate:self didEndSelector:@selector(_liLocationImportOpenPanelDidEnd:returnCode:contextInfo:)
						  contextInfo:NULL];
}

#pragma mark Action Methods

- (IBAction)cancelAssistant:(id)sender
{
	if(mode == XM_FIRST_APPLICATION_LAUNCH_MODE ||
	   mode == XM_FIRST_APPLICATION_LAUNCH_IMPORT_LOCATIONS_MODE)
	{
		[self _returnFromFirstApplicationLaunchAssistant:NSRunAbortedResponse];
	}
	else
	{
		[self close];
		[NSApp endSheet:[self window]];
		
		[self _returnFromLocationImportAssistant:NSRunAbortedResponse];
	}
}

- (IBAction)continueAssistant:(id)sender
{
	if(mode == XM_FIRST_APPLICATION_LAUNCH_MODE)
	{
		[self _showNextViewForFirstApplicationLaunchMode];
	}
	else
	{
		[self _showNextViewForImportLocationModes];
	}
}

- (IBAction)goBackAssistant:(id)sender
{
	if(mode == XM_FIRST_APPLICATION_LAUNCH_MODE)
	{
		[self _showPreviousViewForFirstApplicationLaunchMode];
	}
	else
	{
		[self _showPreviousViewForImportLocationModes];
	}
}

- (IBAction)updateNATType:(id)sender
{
	detectedNATType = XMNATType_Error;
	[self _prepareFLNATSettings];
}

- (IBAction)continueNATSettings:(id)sender
{
	[stunServerField removeAllItems];
	[stunServerField addItemsWithObjectValues:XMDefaultSTUNServers()];
		
	int state = ([location useSTUN] == YES) ? NSOnState : NSOffState;
	[useSTUNRadioButton setState:state];
	
	if(state == NSOffState)
	{
		state = ([location useAddressTranslation] == YES) ? NSOnState : NSOffState;
		[useIPAddressTranslationRadioButton setState:state];
		
		if(state == NSOffState)
		{
			[noneRadioButton setState:NSOnState];
		}
		else
		{
			[noneRadioButton setState:NSOffState];
		}
	}
	else
	{
		[useIPAddressTranslationRadioButton setState:NSOffState];
		[noneRadioButton setState:NSOffState];
	}
	
	NSString *string = [location stunServer];
	if(string == nil)
	{
		string = @"";
	}
	[stunServerField setStringValue:string];
	
	string = [location externalAddress];
	if(string == nil)
	{
		state = NSOnState;
		string = @"";
	}
	else
	{	
		state = NSOffState;
	}
	[externalAddressField setStringValue:string];
	[automaticallyGetExternalAddressSwitch setState:state];
	
	[self _validateSTUNUserInterface];
	[self _validateAddressTranslationUserInterface];
	
	[contentBox setContentView:natSettingsView];
	
	[continueButton setEnabled:YES];
	[goBackButton setEnabled:YES];
	[cancelButton setEnabled:YES];	
}

- (IBAction)toggleNATMethod:(id)sender
{
	if(sender == useSTUNRadioButton)
	{
		[useIPAddressTranslationRadioButton setState:NSOffState];
		[noneRadioButton setState:NSOffState];
	}
	else if(sender == useIPAddressTranslationRadioButton)
	{
		[useSTUNRadioButton setState:NSOffState];
		[noneRadioButton setState:NSOffState];
	}
	else
	{
		[useSTUNRadioButton setState:NSOffState];
		[useIPAddressTranslationRadioButton setState:NSOffState];
	}
	
	[self _validateSTUNUserInterface];
	[self _validateAddressTranslationUserInterface];
}

- (IBAction)getExternalAddress:(id)sender
{
	XMUtils *utils = [XMUtils sharedInstance];
	
	[utils startFetchingCheckipExternalAddress];
	
	[externalAddressField setStringValue:NSLocalizedString(@"XM_FETCHING_EXTERNAL_ADDRESS", @"")];
	[externalAddressField setEnabled:NO];
	externalAddressIsValid = NO;
}

- (IBAction)toggleAutoGetExternalAddress:(id)sender
{
	[self _validateExternalAddressUserInterface];
}

// implementing to allow the application termination even
// when inside this modal loop
- (IBAction)terminate:(id)sender
{
	[NSApp terminate:sender];
}

- (IBAction)protocolSwitchToggled:(id)sender
{
	BOOL enableNextButton = ([enableH323Switch state] == NSOnState ||
							 [enableSIPSwitch state] == NSOnState);
	[continueButton setEnabled:enableNextButton];
}

#pragma mark Delegate Methods

- (void)controlTextDidChange:(NSNotification *)notif
{
	if([notif object] == gkHostField)
	{
		NSString *text = [gkHostField stringValue];
		
		BOOL enableContinueButton = YES;
		if([text isEqualToString:@""])
		{
			enableContinueButton = NO;
		}
		
		[continueButton setEnabled:enableContinueButton];
	}
	else if([notif object] == registrationDomainField)
	{
		NSString *text = [registrationDomainField stringValue];
		
		BOOL enableContinueButton = YES;
		if([text isEqualToString:@""])
		{
			enableContinueButton = NO;
		}
		
		[continueButton setEnabled:enableContinueButton];
	}
}

#pragma mark Private Methods

- (void)_setupButtons
{
	BOOL isContinueButton = YES;
	BOOL enableGoBackButton = YES;
	
	switch(viewTag)
	{
		case XM_FL_INTRODUCTION_VIEW_TAG:
			enableGoBackButton = NO;
			break;
		case XM_LI_INFO_VIEW_TAG:
			if(mode == XM_IMPORT_LOCATIONS_MODE)
			{
				if(currentKeysToAskIndex == 0)
				{
					enableGoBackButton = NO;
				}
			}
			break;
		case XM_FL_COMPLETED_VIEW_TAG:
		case XM_LI_COMPLETED_VIEW_TAG:
			isContinueButton = NO;
			break;
		default:
			break;
	}
	
	if([contentBox contentView] == flNATDetectionView)
	{
		enableGoBackButton = NO;
	}
	
	if(isContinueButton == YES)
	{
		[continueButton setTitle:NSLocalizedString(@"XM_SETUP_ASSISTANT_CONTINUE", @"")];
		[continueButton setKeyEquivalent:@""];
	}
	else
	{
		[continueButton setTitle:NSLocalizedString(@"XM_SETUP_ASSISTANT_FINISH", @"")];
		[continueButton setKeyEquivalent:@"\r"];
	}
	
	[goBackButton setEnabled:enableGoBackButton];
}

- (void)_setTitle:(NSString *)title
{
	[titleField setStringValue:title];
}

- (void)_setShowCornerImage:(BOOL)flag
{
	[cornerImage setHidden:!flag];
}

- (void)_showNextViewForFirstApplicationLaunchMode
{
	NSView *nextView = nil;
	NSView *firstResponder = nil;

	switch(viewTag)
	{
		case XM_FL_INTRODUCTION_VIEW_TAG:
			[self _finishFLIntroductionSettings];
			nextView = flGeneralSettingsView;
			viewTag = XM_FL_GENERAL_SETTINGS_VIEW_TAG;
			firstResponder = [self _prepareFLGeneralSettings];
			break;
			
		case XM_FL_GENERAL_SETTINGS_VIEW_TAG:
			[self _finishFLGeneralSettings];
			nextView = flLocationView;
			viewTag = XM_FL_LOCATION_VIEW_TAG;
			[self _prepareFLLocationSettings];
			break;
			
		case XM_FL_LOCATION_VIEW_TAG:
			[self _finishFLLocationSettings];
			if(mode == XM_FIRST_APPLICATION_LAUNCH_MODE)
			{
				nextView = flNewLocationView;
				viewTag = XM_FL_NEW_LOCATION_VIEW_TAG;
				firstResponder = [self _prepareFLNewLocationSettings];
			}
			else
			{
				viewTag = XM_LI_START_VIEW_TAG;
				[self _beginFLLocationImport];
				return;
			}
			break;
			
		case XM_FL_NEW_LOCATION_VIEW_TAG:
			[self _finishFLNewLocationSettings];
			nextView = networkSettingsView;
			viewTag = XM_NETWORK_SETTINGS_VIEW_TAG;
			[self _prepareFLNetworkSettings];
			break;
			
		case XM_NETWORK_SETTINGS_VIEW_TAG:
			[self _finishFLNetworkSettings];
			nextView = flNATDetectionView;
			viewTag = XM_NAT_SETTINGS_VIEW_TAG;
			[self _prepareFLNATSettings];
			break;
			
		case XM_NAT_SETTINGS_VIEW_TAG:
			[self _finishFLNATSettings];
			nextView = flProtocolsView;
			viewTag = XM_FL_PROTOCOLS_VIEW_TAG;
			[self _prepareFLProtocolSettings];
			break;
			
		case XM_FL_PROTOCOLS_VIEW_TAG:
			[self _finishFLProtocolSettings];
			if([location enableH323])
			{
				nextView = h323SettingsView;
				viewTag = XM_H323_SETTINGS_VIEW_TAG;
				[self _prepareFLH323Settings];
			}
			else if([location enableSIP])
			{
				nextView = sipSettingsView;
				viewTag = XM_SIP_SETTINGS_VIEW_TAG;
				[self _prepareFLSIPSettings];
			}
			break;
			
		case XM_H323_SETTINGS_VIEW_TAG:
			[self _finishFLH323Settings];
			if([location h323AccountTag] != 0)
			{
				nextView = gatekeeperSettingsView;
				viewTag = XM_GATEKEEPER_SETTINGS_VIEW_TAG;
				firstResponder = [self _prepareFLGatekeeperSettings];
			}
			else if([location enableSIP] == YES)
			{
				nextView = sipSettingsView;
				viewTag = XM_SIP_SETTINGS_VIEW_TAG;
				[self _prepareFLSIPSettings];
			}
			else
			{
				nextView = videoSettingsView;
				viewTag = XM_VIDEO_SETTINGS_VIEW_TAG;
				[self _prepareFLVideoSettings];
			}
			break;
			
		case XM_GATEKEEPER_SETTINGS_VIEW_TAG:
			[self _finishFLGatekeeperSettings];
			if([location enableSIP] == YES)
			{
				nextView = sipSettingsView;
				viewTag = XM_SIP_SETTINGS_VIEW_TAG;
				[self _prepareFLSIPSettings];
			}
			else
			{
				nextView = videoSettingsView;
				viewTag = XM_VIDEO_SETTINGS_VIEW_TAG;
				[self _prepareFLVideoSettings];
			}
			break;
			
		case XM_SIP_SETTINGS_VIEW_TAG:
			[self _finishFLSIPSettings];
			if([location sipAccountTag] != 0)
			{
				nextView = registrationSettingsView;
				viewTag = XM_REGISTRATION_SETTINGS_VIEW_TAG;
				firstResponder = [self _prepareFLRegistrationSettings];
			}
			else
			{
				nextView = videoSettingsView;
				viewTag = XM_VIDEO_SETTINGS_VIEW_TAG;
				[self _prepareFLVideoSettings];
			}
			break;
			
		case XM_REGISTRATION_SETTINGS_VIEW_TAG:
			[self _finishFLRegistrationSettings];
			nextView = videoSettingsView;
			viewTag = XM_VIDEO_SETTINGS_VIEW_TAG;
			[self _prepareFLVideoSettings];
			break;
			
		case XM_VIDEO_SETTINGS_VIEW_TAG:
			[self _finishFLVideoSettings];
			nextView = flCompletedView;
			viewTag = XM_FL_COMPLETED_VIEW_TAG;
			[self _prepareFLCompletedSettings];
			break;
			
		case XM_FL_COMPLETED_VIEW_TAG:
			[self _finishFLCompletedSettings];
			[self _returnFromFirstApplicationLaunchAssistant:NSRunStoppedResponse];
			
		default:
			return;
	}
	
	[contentBox setContentView:nextView];
	
	[[self window] makeFirstResponder:firstResponder];
	
	[self _setupButtons];
}

- (void)_showPreviousViewForFirstApplicationLaunchMode
{
	NSView *nextView = nil;
	NSView *firstResponder = nil;
	
	switch(viewTag)
	{
		case XM_FL_GENERAL_SETTINGS_VIEW_TAG:
			[self _finishFLGeneralSettings];
			nextView = flIntroductionView;
			viewTag = XM_FL_INTRODUCTION_VIEW_TAG;
			[self _prepareFLIntroductionSettings];
			break;
			
		case XM_FL_LOCATION_VIEW_TAG:
			[self _finishFLLocationSettings];
			nextView = flGeneralSettingsView;
			viewTag = XM_FL_GENERAL_SETTINGS_VIEW_TAG;
			firstResponder = [self _prepareFLGeneralSettings];
			break;
			
		case XM_FL_NEW_LOCATION_VIEW_TAG:
			[self _finishFLNewLocationSettings];
			nextView = flLocationView;
			viewTag = XM_FL_LOCATION_VIEW_TAG;
			[self _prepareFLLocationSettings];
			break;
			
		case XM_NETWORK_SETTINGS_VIEW_TAG:
			[self _finishFLNetworkSettings];
			nextView = flNewLocationView;
			viewTag = XM_FL_NEW_LOCATION_VIEW_TAG;
			firstResponder = [self _prepareFLNewLocationSettings];
			break;
			
		case XM_NAT_SETTINGS_VIEW_TAG:
			[self _finishFLNATSettings];
			nextView = networkSettingsView;
			viewTag = XM_NETWORK_SETTINGS_VIEW_TAG;
			[self _prepareFLNetworkSettings];
			break;
			
		case XM_FL_PROTOCOLS_VIEW_TAG:
			[self _finishFLProtocolSettings];
			nextView = flNATDetectionView;
			viewTag = XM_NAT_SETTINGS_VIEW_TAG;
			[self _prepareFLNATSettings];
			break;
			
		case XM_H323_SETTINGS_VIEW_TAG:
			[self _finishFLH323Settings];
			nextView = flProtocolsView;
			viewTag = XM_FL_PROTOCOLS_VIEW_TAG;
			[self _prepareFLProtocolSettings];
			break;
			
		case XM_GATEKEEPER_SETTINGS_VIEW_TAG:
			[self _finishFLGatekeeperSettings];
			nextView = h323SettingsView;
			viewTag = XM_H323_SETTINGS_VIEW_TAG;
			[self _prepareFLH323Settings];
			break;
			
		case XM_SIP_SETTINGS_VIEW_TAG:
			[self _finishFLSIPSettings];
			if([location enableH323] == YES)
			{
				if([location h323AccountTag] != 0)
				{
					nextView = gatekeeperSettingsView;
					viewTag = XM_GATEKEEPER_SETTINGS_VIEW_TAG;
					firstResponder = [self _prepareFLGatekeeperSettings];
				}
				else
				{
					nextView = h323SettingsView;
					viewTag = XM_H323_SETTINGS_VIEW_TAG;
					[self _prepareFLH323Settings];
				}
			}
			else
			{
				nextView = flProtocolsView;
				viewTag = XM_FL_PROTOCOLS_VIEW_TAG;
				[self _prepareFLProtocolSettings];
			}
			break;
			
		case XM_REGISTRATION_SETTINGS_VIEW_TAG:
			[self _finishFLRegistrationSettings];
			nextView = sipSettingsView;
			viewTag = XM_SIP_SETTINGS_VIEW_TAG;
			[self _prepareFLSIPSettings];
			break;
			
		case XM_VIDEO_SETTINGS_VIEW_TAG:
			[self _finishFLVideoSettings];
			if([location enableSIP] == YES)
			{
				if([location sipAccountTag] != 0)
				{
					nextView = registrationSettingsView;
					viewTag = XM_REGISTRATION_SETTINGS_VIEW_TAG;
					firstResponder = [self _prepareFLRegistrationSettings];
				}
				else
				{
					nextView = sipSettingsView;
					viewTag = XM_SIP_SETTINGS_VIEW_TAG;
					[self _prepareFLSIPSettings];
				}
			}
			else if([location enableH323] == YES)
			{
				if([location h323AccountTag] != 0)
				{
					nextView = gatekeeperSettingsView;
					viewTag = XM_GATEKEEPER_SETTINGS_VIEW_TAG;
					firstResponder = [self _prepareFLGatekeeperSettings];
				}
				else
				{
					nextView = h323SettingsView;
					viewTag = XM_H323_SETTINGS_VIEW_TAG;
					[self _prepareFLH323Settings];
				}
			}

			break;
			
		case XM_FL_COMPLETED_VIEW_TAG:
			[self _finishFLCompletedSettings];
			nextView = videoSettingsView;
			viewTag = XM_VIDEO_SETTINGS_VIEW_TAG;
			[self _prepareFLVideoSettings];
			break;
		default:
			return;
	}
	
	[contentBox setContentView:nextView];
	
	[[self window] makeFirstResponder:firstResponder];
	
	[self _setupButtons];
}

- (void)_returnFromFirstApplicationLaunchAssistant:(int)returnCode
{
	[self close];
	
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	
	NSArray *locations = nil;
	NSArray *h323Accounts = nil;
	NSArray *sipAccounts = nil;
	
	if(returnCode == NSRunAbortedResponse)
	{		
		NSArray *array = [NSArray array];
		locations = array;
		h323Accounts = nil;
		sipAccounts = nil;
	}
	else
	{
		[preferencesManager setUserName:userName];
	
		if(mode == XM_FIRST_APPLICATION_LAUNCH_MODE)
		{
			if([location enableH323] == YES && [location h323AccountTag] != 0)
			{
				h323Accounts = [NSArray arrayWithObject:h323Account];
			}
			else
			{
				[location setH323AccountTag:0];
				h323Accounts = nil;
			}
			
			if([location enableSIP] == YES && [location sipAccountTag] != 0)
			{
				sipAccounts = [NSArray arrayWithObject:sipAccount];
			}
			else
			{
				[location setSIPAccountTag:0];
				sipAccounts = nil;
			}
			
			locations = [NSArray arrayWithObject:location];
		}
		else
		{
			locations = [[[locationImportData objectForKey:XMKey_Locations] retain] autorelease];
			h323Accounts = [[[locationImportData objectForKey:XMKey_H323Accounts] retain] autorelease];
			sipAccounts = [[[locationImportData objectForKey:XMKey_SIPAccounts] retain] autorelease];
			
			// check for duplicate names
			unsigned count = [locations count];
			unsigned i;
			for(i = 0; i < count; i++)
			{
				XMLocation *theLocation = (XMLocation *)[locations objectAtIndex:i];
				NSString *name = [theLocation name];
				
				unsigned j;
				for(j = 0; j < i; j++)
				{
					XMLocation *otherLocation = (XMLocation *)[locations objectAtIndex:j];
					
					if([[otherLocation name] isEqualToString:name])
					{
						name = [name stringByAppendingString:@" 1"];
						[theLocation setName:name];
						
						j = 0;
					}
				}
			}
			
			count = [h323Accounts count];
			for(i = 0; i < count; i++)
			{
				XMH323Account *account = (XMH323Account *)[h323Accounts objectAtIndex:i];
				NSString *name = [account name];
				
				unsigned j;
				for(j = 0; j < i; j++)
				{
					XMH323Account *otherAccount = (XMH323Account *)[h323Accounts objectAtIndex:j];
					
					if([[otherAccount name] isEqualToString:name])
					{
						name = [name stringByAppendingString:@" 1"];
						[account setName:name];
						
						j = 0;
					}
				}
			}
			
			count = [sipAccounts count];
			for(i = 0; i < count; i++)
			{
				XMSIPAccount *account = (XMSIPAccount *)[sipAccounts objectAtIndex:i];
				NSString *name = [account name];
				
				unsigned j;
				for(j = 0; j < i; j++)
				{
					XMSIPAccount *otherAccount = (XMSIPAccount *)[sipAccounts objectAtIndex:j];
					
					if([[otherAccount name] isEqualToString:name])
					{
						name = [name stringByAppendingString:@" 1"];
						[account setName:name];
						
						j = 0;
					}
				}
			}
		}
	}
	
	NSMethodSignature *methodSignature = [delegate methodSignatureForSelector:didEndSelector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
	
	[invocation setTarget:delegate];
	[invocation setSelector:didEndSelector];
	[invocation setArgument:&locations atIndex:2];
	[invocation setArgument:&h323Accounts atIndex:3];
	[invocation setArgument:&sipAccounts atIndex:4];
	
	[invocation invoke];
	
	[location release];
	location = nil;
	[h323Account release];
	h323Account = nil;
	[sipAccount release];
	sipAccount = nil;
	[locationImportData release];
	locationImportData = nil;
	
	// workaround to prevent the setup manager window from popping up if there
	// is an incoming call. Still don't know why such things happen...
	[self release];
	sharedInstance = nil;
}

- (void)_prepareFLIntroductionSettings
{
	[self _setTitle:NSLocalizedString(@"XM_SETUP_ASSISTANT_WELCOME", @"")];
	[self _setShowCornerImage:NO];
}

- (void)_finishFLIntroductionSettings
{
	[self _setShowCornerImage:YES];
}

- (NSView *)_prepareFLGeneralSettings
{
	[self _setTitle:NSLocalizedString(@"XM_SETUP_ASSISTANT_PI", @"")];
	[userNameField setStringValue:userName];
	return userNameField;
}

- (void)_finishFLGeneralSettings
{
	[userName release];
	
	userName = [[userNameField stringValue] retain];
}

- (void)_prepareFLLocationSettings
{
	[self _setTitle:NSLocalizedString(@"XM_SETUP_ASSISTANT_LOCATIONS", @"")];
	int tag = (mode == XM_FIRST_APPLICATION_LAUNCH_MODE) ? 0 : 1;
	[locationRadioButtons selectCellWithTag:tag];
}

- (void)_finishFLLocationSettings
{
	int tag = [[locationRadioButtons selectedCell] tag];
	mode = (tag == 0) ? XM_FIRST_APPLICATION_LAUNCH_MODE : XM_FIRST_APPLICATION_LAUNCH_IMPORT_LOCATIONS_MODE;
}

- (NSView *)_prepareFLNewLocationSettings
{
	[self _setTitle:NSLocalizedString(@"XM_SETUP_ASSISTANT_NEW_LOCATION", @"")];
	[locationNameField setStringValue:[location name]];
	return locationNameField;
}

- (void)_finishFLNewLocationSettings
{
	[location setName:[locationNameField stringValue]];
}

- (void)_prepareFLNetworkSettings
{
	NSString *titleString = [NSString stringWithFormat:NSLocalizedString(@"XM_SETUP_ASSISTANT_LOCATION", @""), [location name]];
	[self _setTitle:titleString];
	
	[bandwidthLimitPopUp selectItemWithTag:[location bandwidthLimit]];
}

- (void)_finishFLNetworkSettings
{
	[location setBandwidthLimit:[[bandwidthLimitPopUp selectedItem] tag]];
	
	/*BOOL flag = ([useIPAddressTranslationSwitch state] == NSOnState) ? YES : NO;
	[location setUseAddressTranslation:flag];*/
	
	/*flag = ([automaticallyGetExternalAddressSwitch state] == NSOnState) ? YES : NO;
	if(flag == YES)
	{
		[location setExternalAddress:nil];
	}
	else
	{
		[location setExternalAddress:[externalAddressField stringValue]];
	}*/
}

- (void)_prepareFLNATSettings
{
	NSString *titleString = [NSString stringWithFormat:NSLocalizedString(@"XM_SETUP_ASSISTANT_LOCATION", @""), [location name]];
	[self _setTitle:titleString];
	
	XMUtils *utils = [XMUtils sharedInstance];
	
	if([utils checkipExternalAddress] == nil && [utils didSucceedFetchingCheckipExternalAddress] == YES)
	{
		[utils startFetchingCheckipExternalAddress];
	}
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	/*[notificationCenter addObserver:self selector:@selector(_didStartFetchingExternalAddress:)
							   name:XMNotification_UtilsDidStartFetchingCheckipExternalAddress object:nil];
	[notificationCenter addObserver:self selector:@selector(_didEndFetchingExternalAddress:)
							   name:XMNotification_UtilsDidEndFetchingCheckipExternalAddress object:nil];*/
	
	[continueButton setEnabled:NO];
	[goBackButton setEnabled:NO];
	[cancelButton setEnabled:NO];
	
	if(detectedNATType == XMNATType_Error)
	{
		[natTypeBox setHidden:YES];
		[natDetectionBox setHidden:NO];
		[natTypeField setStringValue:@""];
		[continueNATSettingsButton setEnabled:NO];
		
		[natDetectionProgressIndicator startAnimation:self];
		
		/*[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didUpdateSTUNInformation:)
													 name:XMNotification_UtilsDidUpdateSTUNInformation object:nil];*/
		
		XMPreferences *preferences = [[XMPreferences alloc] init];
		[preferences setUseSTUN:YES];
		NSArray *array = XMDefaultSTUNServers();
		[preferences setSTUNServer:(NSString *)[array objectAtIndex:0]];
		
		[[XMCallManager sharedInstance] setActivePreferences:preferences];
		[preferences release];
	}
	else
	{
		[self _setupNATTypeView];
	}
}

- (void)_finishFLNATSettings
{
	BOOL flag = ([useSTUNRadioButton state] == NSOnState) ? YES : NO;
	[location setUseSTUN:flag];
	
	NSString *string = [stunServerField stringValue];
	if([string isEqualToString:@""])
	{
		string = nil;
	}
	[location setSTUNServer:string];
	
	flag = ([useIPAddressTranslationRadioButton state] == NSOnState) ? YES : NO;
	[location setUseAddressTranslation:flag];
	
	string = [externalAddressField stringValue];
	if([string isEqualToString:@""] || [automaticallyGetExternalAddressSwitch state] == NSOnState)
	{
		string = nil;
	}
	[location setExternalAddress:string];
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	//[notificationCenter removeObserver:self name:XMNotification_UtilsDidStartFetchingCheckipExternalAddress object:nil];
	//[notificationCenter removeObserver:self name:XMNotification_UtilsDidEndFetchingCheckipExternalAddress object:nil];
}

- (void)_prepareFLProtocolSettings
{
	NSString *titleString = [NSString stringWithFormat:NSLocalizedString(@"XM_SETUP_ASSISTANT_LOCATION", @""), [location name]];
	[self _setTitle:titleString];
	
	int state = ([location enableH323] == YES) ? NSOnState : NSOffState;
	[enableH323Switch setState:state];
	
	state = ([location enableSIP] == YES) ? NSOnState : NSOffState;
	[enableSIPSwitch setState:state];
	
	[self protocolSwitchToggled:nil];
}

- (void)_finishFLProtocolSettings
{
	BOOL flag = ([enableH323Switch state] == NSOnState) ? YES : NO;
	[location setEnableH323:flag];
	
	flag = ([enableSIPSwitch state] == NSOnState) ? YES : NO;
	[location setEnableSIP:flag];
}

- (void)_prepareFLH323Settings
{
	NSString *titleString = [NSString stringWithFormat:NSLocalizedString(@"XM_SETUP_ASSISTANT_LOCATION", @""), [location name]];
	[self _setTitle:titleString];
	
	int tag = ([location h323AccountTag] != 0) ? 0 : 1;
	[useGatekeeperRadioButtons selectCellWithTag:tag];
}

- (void)_finishFLH323Settings
{
	int tag = [[useGatekeeperRadioButtons selectedCell] tag];
	if(tag == 0)
	{
		[location setH323AccountTag:[h323Account tag]];
	}
	else
	{
		[location setH323AccountTag:0];
	}
}

- (NSView *)_prepareFLGatekeeperSettings
{
	NSString *titleString = [NSString stringWithFormat:NSLocalizedString(@"XM_SETUP_ASSISTANT_LOCATION", @""), [location name]];
	[self _setTitle:titleString];
	
	NSString *gatekeeperAddress = [h323Account gatekeeper];
	NSString *gatekeeperUsername = [h323Account username];
	NSString *gatekeeperPhoneNumber = [h323Account phoneNumber];
	NSString *gatekeeperPassword = [h323Account password];
	
	BOOL enableContinueButton = YES;
	
	if(gatekeeperAddress == nil)
	{
		enableContinueButton = NO;
		gatekeeperAddress = @"";
	}
	if(gatekeeperUsername == nil)
	{
		gatekeeperUsername = @"";
	}
	if(gatekeeperPhoneNumber == nil)
	{
		gatekeeperPhoneNumber = @"";
	}
	if(gatekeeperPassword == nil)
	{
		gatekeeperPassword = @"";
	}
	
	[gkHostField setStringValue:gatekeeperAddress];
	[gkUsernameField setStringValue:gatekeeperUsername];
	[gkPhoneNumberField setStringValue:gatekeeperPhoneNumber];
	[gkPasswordField setStringValue:gatekeeperPassword];
	
	[continueButton setEnabled:enableContinueButton];
	
	return gkHostField;
}

- (void)_finishFLGatekeeperSettings
{
	NSString *gatekeeperAddress = [gkHostField stringValue];
	NSString *gatekeeperUsername = [gkUsernameField stringValue];
	NSString *gatekeeperPhoneNumber = [gkPhoneNumberField stringValue];
	NSString *gatekeeperPassword = [gkPasswordField stringValue];
	
	if([gatekeeperAddress isEqualToString:@""])
	{
		gatekeeperAddress = nil;
	}
	if([gatekeeperUsername isEqualToString:@""])
	{
		gatekeeperUsername = nil;
	}
	if([gatekeeperPhoneNumber isEqualToString:@""])
	{
		gatekeeperPhoneNumber = nil;
	}
	if([gatekeeperPassword isEqualToString:@""])
	{
		gatekeeperPassword = nil;
	}
	
	[h323Account setGatekeeper:gatekeeperAddress];
	[h323Account setUsername:gatekeeperUsername];
	[h323Account setPhoneNumber:gatekeeperPhoneNumber];
	[h323Account setPassword:gatekeeperPassword];
	
	[continueButton setEnabled:YES];
}

- (void)_prepareFLSIPSettings
{
	NSString *titleString = [NSString stringWithFormat:NSLocalizedString(@"XM_SETUP_ASSISTANT_LOCATION", @""), [location name]];
	[self _setTitle:titleString];
	
	int tag = ([location sipAccountTag] != 0) ? 0 : 1;
	[useRegistrationRadioButtons selectCellWithTag:tag];
}

- (void)_finishFLSIPSettings
{
	int tag = [[useRegistrationRadioButtons selectedCell] tag];
	if(tag == 0)
	{
		[location setSIPAccountTag:[sipAccount tag]];
	}
	else
	{
		[location setSIPAccountTag:0];
	}
	
}

- (NSView *)_prepareFLRegistrationSettings
{
	NSString *titleString = [NSString stringWithFormat:NSLocalizedString(@"XM_SETUP_ASSISTANT_LOCATION", @""), [location name]];
	[self _setTitle:titleString];
	
	NSString *registrationDomain = [sipAccount domain];
	NSString *registrationUsername = [sipAccount username];
	NSString *registrationAuthUsername = [sipAccount authorizationUsername];
	NSString *registrationPassword = [sipAccount password];
	
	BOOL enableContinueButton = YES;
	
	if(registrationDomain == nil)
	{
		enableContinueButton = NO;
		registrationDomain = @"";
	}
	if(registrationUsername == nil)
	{
		registrationUsername = @"";
	}
	if(registrationAuthUsername == nil)
	{
		registrationAuthUsername = @"";
	}
	if(registrationPassword == nil)
	{
		registrationPassword = @"";
	}
	
	[registrationDomainField setStringValue:registrationDomain];
	[registrationUsernameField setStringValue:registrationUsername];
	[registrationAuthUsernameField setStringValue:registrationAuthUsername];
	[registrationPasswordField setStringValue:registrationPassword];
	
	[continueButton setEnabled:enableContinueButton];
	
	return registrationDomainField;
}

- (void)_finishFLRegistrationSettings
{
	NSString *registrationDomain = [registrationDomainField stringValue];
	NSString *registrationUsername = [registrationUsernameField stringValue];
	NSString *registrationAuthUsername = [registrationAuthUsernameField stringValue];
	NSString *registrationPassword = [registrationPasswordField stringValue];
	
	if([registrationDomain isEqualToString:@""])
	{
		registrationDomain = nil;
	}
	if([registrationUsername isEqualToString:@""])
	{
		registrationUsername = nil;
	}
	if([registrationAuthUsername isEqualToString:@""])
	{
		registrationAuthUsername = nil;
	}
	if([registrationPassword isEqualToString:@""])
	{
		registrationPassword = nil;
	}
	
	[sipAccount setDomain:registrationDomain];
	[sipAccount setUsername:registrationUsername];
	[sipAccount setAuthorizationUsername:registrationAuthUsername];
	[sipAccount setPassword:registrationPassword];
	
	[continueButton setEnabled:YES];
}

- (void)_prepareFLVideoSettings
{
	NSString *titleString = [NSString stringWithFormat:NSLocalizedString(@"XM_SETUP_ASSISTANT_LOCATION", @""), [location name]];
	[self _setTitle:titleString];
	
	int tag = ([location enableVideo] == YES) ? 0 : 1;
	[enableVideoRadioButtons selectCellWithTag:tag];
}

- (void)_finishFLVideoSettings
{
	int tag = [[enableVideoRadioButtons selectedCell] tag];
	BOOL enableVideo = (tag == 0) ? YES : NO;
	[location setEnableVideo:enableVideo];
}

- (void)_prepareFLCompletedSettings
{
	[self _setTitle:@"Completed"];
}

- (void)_finishFLCompletedSettings
{
}

- (void)_beginFLLocationImport
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setResolvesAliases:YES];
	[openPanel setAllowsMultipleSelection:NO];
	
	NSString *directory = nil;
	NSString *filename = nil;
	if(locationFilePath != nil)
	{
		directory = [locationFilePath stringByDeletingLastPathComponent];
		filename = [locationFilePath lastPathComponent];
	}
	
	[openPanel beginSheetForDirectory:directory file:filename types:nil modalForWindow:[self window]
						modalDelegate:self didEndSelector:@selector(_flLocationImportOpenPanelDidEnd:returnCode:contextInfo:)
						  contextInfo:NULL];
}

- (void)_flLocationImportOpenPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if(returnCode == NSCancelButton)
	{
		mode = XM_FIRST_APPLICATION_LAUNCH_MODE;
	}
	else
	{
		NSString *path = (NSString *)[[sheet filenames] objectAtIndex:0];
		
		if(locationFilePath != nil)
		{
			if([locationFilePath isEqualToString:path])
			{
				[self _showNextViewForImportLocationModes];
				return;
			}
			[locationFilePath release];
		}
		locationFilePath = [path copy];
		
		NSString *errorDescription = nil;
		
		NSDictionary *dict = [self _parseFile:locationFilePath errorDescription:&errorDescription];
		
		if(dict == nil)
		{
			NSAlert *alert = [[NSAlert alloc] init];
			
			[alert setMessageText:NSLocalizedString(@"XM_SETUP_ASSISTANT_LOC_IMPORT_FAILURE", @"")];
			[alert setInformativeText:errorDescription];
			[alert setAlertStyle:NSWarningAlertStyle];
			[alert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
			
			[alert runModal];
			mode = XM_FIRST_APPLICATION_LAUNCH_MODE;
			return;
		}
		
		if(locationImportData != nil)
		{
			[locationImportData release];
		}
		locationImportData = [dict retain];
		
		[self _showNextViewForImportLocationModes];
	}
}

- (NSDictionary *)_parseFile:(NSString *)file errorDescription:(NSString **)errorDescription
{
	NSData *locationsData = [[NSData alloc] initWithContentsOfFile:file];
	NSMutableDictionary *propertyList = [NSPropertyListSerialization propertyListFromData:locationsData 
																		 mutabilityOption:NSPropertyListMutableContainers
																				   format:NULL
																		 errorDescription:errorDescription];
	[locationsData release];
	
	if(propertyList == nil)
	{
		*errorDescription = NSLocalizedString(@"XM_SETUP_ASSISTANT_INVALID_FILE", @"");
		return nil;
	}
	
	if(![propertyList isKindOfClass:[NSDictionary class]])
	{
		*errorDescription = NSLocalizedString(@"XM_SETUP_ASSISTANT_INVALID_FILE", @"");
		return nil;
	}
	
	NSArray *locationDicts = [propertyList objectForKey:XMKey_Locations];
	
	if((locationDicts == nil) || (![locationDicts isKindOfClass:[NSArray class]]))
	{
		*errorDescription = NSLocalizedString(@"XM_SETUP_ASSISTANT_INVALID_FILE", @"");
		return nil;
	}
	
	NSArray *h323AccountDicts = [propertyList objectForKey:XMKey_H323Accounts];
	
	if(h323AccountDicts != nil)
	{
		if(![h323AccountDicts isKindOfClass:[NSArray class]])
		{
			*errorDescription = NSLocalizedString(@"XM_SETUP_ASSISTANT_INVALID_FILE", @"");
			return nil;
		}

		unsigned count = [h323AccountDicts count];
		
		if(count == 0)
		{
			*errorDescription = NSLocalizedString(@"XM_SETUP_ASSISTANT_INVALID_FILE", @"");
			return nil;
		}
		
		unsigned i;
		NSMutableArray *parsedAccounts = [[NSMutableArray alloc] initWithCapacity:count];
		
		for(i = 0; i < count; i++)
		{
			NSDictionary *dict = [h323AccountDicts objectAtIndex:i];
			
			if(![dict isKindOfClass:[NSDictionary class]])
			{
				continue;
			}
			
			XMH323Account *accountInstance = [[XMH323Account alloc] initWithDictionary:dict];
			if(accountInstance != nil)
			{
				[parsedAccounts addObject:accountInstance];
				[accountInstance release];
			}
		}
		
		count = [parsedAccounts count];
		
		if(count == 0)
		{
			[parsedAccounts release];
			
			*errorDescription = NSLocalizedString(@"XM_SETUP_ASSISTANT_INVALID_FILE", @"");
			return nil;
		}
		
		[propertyList setObject:parsedAccounts forKey:XMKey_H323Accounts];
		[parsedAccounts release];
	}
	
	NSArray *sipAccountDicts = [propertyList objectForKey:XMKey_SIPAccounts];
	
	if(sipAccountDicts != nil)
	{
		if(![sipAccountDicts isKindOfClass:[NSArray class]])
		{
			*errorDescription = NSLocalizedString(@"XM_SETUP_ASSISTANT_INVALID_FILE", @"");
			return nil;
		}
		
		unsigned count = [sipAccountDicts count];
		
		if(count == 0)
		{
			*errorDescription = NSLocalizedString(@"XM_SETUP_ASSISTANT_INVALID_FILE", @"");
			return nil;
		}
		
		unsigned i;
		NSMutableArray *parsedAccounts = [[NSMutableArray alloc] initWithCapacity:count];
		
		for(i = 0; i < count; i++)
		{
			NSDictionary *dict = [sipAccountDicts objectAtIndex:i];
			
			if(![dict isKindOfClass:[NSDictionary class]])
			{
				continue;
			}
			
			XMSIPAccount *accountInstance = [[XMSIPAccount alloc] initWithDictionary:dict];
			if(accountInstance != nil)
			{
				[parsedAccounts addObject:accountInstance];
				[accountInstance release];
			}
		}
		
		count = [parsedAccounts count];
		
		if(count == 0)
		{
			[parsedAccounts release];
			
			*errorDescription = NSLocalizedString(@"XM_SETUP_ASSISTANT_INVALID_FILE", @"");
			return nil;
		}
		
		[propertyList setObject:parsedAccounts forKey:XMKey_SIPAccounts];
		[parsedAccounts release];
	}
		
	unsigned count = [locationDicts count];
	unsigned i;
	NSMutableArray *parsedLocations = [[NSMutableArray alloc] initWithCapacity:count];
	
	for(i = 0; i < count; i++)
	{
		NSDictionary *dict = [locationDicts objectAtIndex:i];
			
		if(![dict isKindOfClass:[NSDictionary class]])
		{
			continue;
		}
				
		XMLocation *locationInstance = [[XMLocation alloc] initWithDictionary:dict 
																 h323Accounts:[propertyList objectForKey:XMKey_H323Accounts]
																  sipAccounts:[propertyList objectForKey:XMKey_SIPAccounts]];
		if(locationInstance != nil)
		{
			[parsedLocations addObject:locationInstance];
			[locationInstance release];
		}
	}
			
	count = [parsedLocations count];
			
	[propertyList setObject:parsedLocations forKey:XMKey_Locations];
	[parsedLocations release];
			
	if(count == 0)
	{
		*errorDescription = NSLocalizedString(@"XM_SETUP_ASSISTANT_INVALID_FILE", @"");
		return nil;
	}

	return propertyList;
}

- (void)_returnFromLocationImportAssistant:(int)returnCode
{	
	NSArray *locations = nil;
	NSArray *h323Accounts = nil;
	NSArray *sipAccounts = nil;
	
	if(returnCode == NSRunAbortedResponse)
	{		
		NSArray *array = [NSArray array];
		locations = array;
		h323Accounts = array;
		sipAccounts = array;
	}
	else
	{
		locations = [[[locationImportData objectForKey:XMKey_Locations] retain] autorelease];
		h323Accounts = [[[locationImportData objectForKey:XMKey_H323Accounts] retain] autorelease];
		sipAccounts = [[[locationImportData objectForKey:XMKey_SIPAccounts] retain] autorelease];
	}
	
	NSMethodSignature *methodSignature = [delegate methodSignatureForSelector:didEndSelector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
	
	[invocation setTarget:delegate];
	[invocation setSelector:didEndSelector];
	[invocation setArgument:&locations atIndex:2];
	[invocation setArgument:&h323Accounts atIndex:3];
	[invocation setArgument:&sipAccounts atIndex:4];
	
	// calling the callback of the receiver
	[invocation invoke];
	
	[location release];
	location = nil;
	[h323Account release];
	h323Account = nil;
	[sipAccount release];
	sipAccount = nil;
	[locationImportData release];
	locationImportData = nil;
}

- (void)_showNextViewForImportLocationModes
{
	NSView *nextView = nil;
	NSView *firstResponder = nil;
	
	if(viewTag == XM_FL_COMPLETED_VIEW_TAG)
	{
		[self _finishFLCompletedSettings];
		[self _returnFromFirstApplicationLaunchAssistant:NSRunStoppedResponse];
		return;
	}
	else if(viewTag == XM_LI_COMPLETED_VIEW_TAG)
	{
		[self close];
		[NSApp endSheet:[self window]];
		
		[self _finishLICompletedSettings];
		[self _returnFromLocationImportAssistant:NSRunStoppedResponse];
		return;
	}
	
	NSArray *keysToAsk = [locationImportData objectForKey:XMKey_KeysToAsk];
	if(keysToAsk == nil ||
	   ![keysToAsk isKindOfClass:[NSArray class]] ||
	   [keysToAsk count] == 0)
	{
		if(mode == XM_FIRST_APPLICATION_LAUNCH_IMPORT_LOCATIONS_MODE)
		{
			[self _prepareFLCompletedSettings];
			nextView = flCompletedView;
			viewTag = XM_FL_COMPLETED_VIEW_TAG;
		}
		else
		{
			[self _prepareLICompletedSettings];
			nextView = liCompletedView;
			viewTag = XM_LI_COMPLETED_VIEW_TAG;
		}
	}
	else
	{
		NSDictionary *currentKeySet = [keysToAsk objectAtIndex:currentKeysToAskIndex];
		NSArray *keys = [currentKeySet objectForKey:XMKey_Keys];
		if(keys == nil)
		{
			keys = [NSArray array];
		}
		BOOL didFinishCurrentSettings = NO;
	
		switch(viewTag)
		{
			case XM_FL_INTRODUCTION_VIEW_TAG:
			case XM_FL_GENERAL_SETTINGS_VIEW_TAG:
			case XM_FL_LOCATION_VIEW_TAG:
				[self _showNextViewForFirstApplicationLaunchMode];
				return;
				
			case XM_LI_START_VIEW_TAG:
				didFinishCurrentSettings = YES;
				
				NSString *description = [currentKeySet objectForKey:XMKey_Description];
				if(description != nil && [description isKindOfClass:[NSString class]])
				{
					nextView = liInfoView;
					viewTag = XM_LI_INFO_VIEW_TAG;
					[self _prepareLIInfoSettings];
					break;
				}
					
			case XM_LI_INFO_VIEW_TAG:
				if(didFinishCurrentSettings == NO)
				{
					[self _finishLIInfoSettings];
					didFinishCurrentSettings = YES;
				}
				
				if([keys containsObject:XMKey_PreferencesBandwidthLimit])
				{
					nextView = networkSettingsView;
					viewTag = XM_NETWORK_SETTINGS_VIEW_TAG;
					[self _prepareLINetworkSettings];
					break;
				}
				
			case XM_NETWORK_SETTINGS_VIEW_TAG:
				if(didFinishCurrentSettings == NO)
				{
					[self _finishLINetworkSettings];
					didFinishCurrentSettings = YES;
				}
				
				if([keys containsObject:XMKey_H323AccountTerminalAlias1] ||
				   [keys containsObject:XMKey_H323AccountTerminalAlias2] ||
				   [keys containsObject:XMKey_H323AccountPassword])
				{
					nextView = gatekeeperSettingsView;
					viewTag = XM_GATEKEEPER_SETTINGS_VIEW_TAG;
					firstResponder = [self _prepareLIGatekeeperSettings];
					break;
				}
				
			case XM_GATEKEEPER_SETTINGS_VIEW_TAG:
				if(didFinishCurrentSettings == NO)
				{
					[self _finishLIGatekeeperSettings];
					didFinishCurrentSettings = YES;
				}
				
				if([keys containsObject:XMKey_SIPAccountUsername] ||
				   [keys containsObject:XMKey_SIPAccountAuthorizationUsername] ||
				   [keys containsObject:XMKey_SIPAccountPassword])
				{
					nextView = registrationSettingsView;
					viewTag = XM_REGISTRATION_SETTINGS_VIEW_TAG;
					firstResponder = [self _prepareLIRegistrationSettings];
					break;
				}
				
			case XM_REGISTRATION_SETTINGS_VIEW_TAG:
				if(didFinishCurrentSettings == NO)
				{
					[self _finishLIRegistrationSettings];
					didFinishCurrentSettings = YES;
				}
				
				if([keysToAsk count] == (currentKeysToAskIndex + 1))
				{
					if(mode == XM_FIRST_APPLICATION_LAUNCH_IMPORT_LOCATIONS_MODE)
					{
						[self _prepareFLCompletedSettings];
						nextView = flCompletedView;
						viewTag = XM_FL_COMPLETED_VIEW_TAG;
					}
					else
					{
						[self _prepareLICompletedSettings];
						nextView = liCompletedView;
						viewTag = XM_LI_COMPLETED_VIEW_TAG;
					}
					break;
				}
				
				currentKeysToAskIndex++;
				viewTag = XM_LI_START_VIEW_TAG;
				[self _showNextViewForImportLocationModes];
				return;
			
			default:
				return;
		}
	}
	
	[contentBox setContentView:nextView];
	
	[[self window] makeFirstResponder:firstResponder];
	
	[self _setupButtons];
}

- (void)_showPreviousViewForImportLocationModes
{
	NSView *nextView = nil;
	NSView *firstResponder = nil;
	
	NSArray *keysToAsk = [locationImportData objectForKey:XMKey_KeysToAsk];
	if(keysToAsk == nil ||
	   ![keysToAsk isKindOfClass:[NSArray class]] ||
	   [keysToAsk count] == 0)
	{
		if(mode == XM_FIRST_APPLICATION_LAUNCH_IMPORT_LOCATIONS_MODE)
		{
			[self _prepareFLLocationSettings];
			nextView = flLocationView;
			viewTag = XM_FL_LOCATION_VIEW_TAG;
			mode = XM_FIRST_APPLICATION_LAUNCH_MODE;
		}
		else
		{
			// should not happen
			return;
		}
	}
	else
	{
		NSDictionary *currentKeySet = [keysToAsk objectAtIndex:currentKeysToAskIndex];
		NSArray *keys = [currentKeySet objectForKey:XMKey_Keys];
		if(keys == nil)
		{
			keys = [NSArray array];
		}
		BOOL didFinishCurrentSettings = NO;

		switch(viewTag)
		{
			case XM_FL_COMPLETED_VIEW_TAG:
			case XM_LI_COMPLETED_VIEW_TAG:
				didFinishCurrentSettings = YES;
				
				if([keys containsObject:XMKey_SIPAccountUsername] ||
				   [keys containsObject:XMKey_SIPAccountAuthorizationUsername] ||
				   [keys containsObject:XMKey_SIPAccountPassword])
				{
					nextView = registrationSettingsView;
					viewTag = XM_REGISTRATION_SETTINGS_VIEW_TAG;
					firstResponder = [self _prepareLIRegistrationSettings];
					break;
				}
					
			case XM_REGISTRATION_SETTINGS_VIEW_TAG:
				if(didFinishCurrentSettings == NO)
				{
					[self _finishLIRegistrationSettings];
					didFinishCurrentSettings = YES;
				}
				
				if([keys containsObject:XMKey_H323AccountTerminalAlias1] ||
				   [keys containsObject:XMKey_H323AccountTerminalAlias2] ||
				   [keys containsObject:XMKey_H323AccountPassword])
				{
					nextView = gatekeeperSettingsView;
					viewTag = XM_GATEKEEPER_SETTINGS_VIEW_TAG;
					firstResponder = [self _prepareLIGatekeeperSettings];
					break;
				}
			
			case XM_GATEKEEPER_SETTINGS_VIEW_TAG:
				if(didFinishCurrentSettings == NO)
				{
					[self _finishLIGatekeeperSettings];
					didFinishCurrentSettings = YES;
				}
				
				if([keys containsObject:XMKey_PreferencesBandwidthLimit])
				{
					nextView = networkSettingsView;
					viewTag = XM_NETWORK_SETTINGS_VIEW_TAG;
					[self _prepareLINetworkSettings];
					break;
				}
				
			case XM_NETWORK_SETTINGS_VIEW_TAG:
				if(didFinishCurrentSettings == NO)
				{
					[self _finishLINetworkSettings];
					didFinishCurrentSettings = YES;
				}
				
				NSString *description = [currentKeySet objectForKey:XMKey_Description];
				if(description != nil && [description isKindOfClass:[NSString class]])
				{
					nextView = liInfoView;
					viewTag = XM_LI_INFO_VIEW_TAG;
					[self _prepareLIInfoSettings];
					break;
				}
				
			case XM_LI_INFO_VIEW_TAG:
				if(didFinishCurrentSettings == NO)
				{
					[self _finishLIInfoSettings];
					didFinishCurrentSettings = YES;
				}
				
				if(currentKeysToAskIndex == 0)
				{
					if(mode == XM_FIRST_APPLICATION_LAUNCH_IMPORT_LOCATIONS_MODE)
					{
						nextView = flLocationView;
						viewTag = XM_FL_LOCATION_VIEW_TAG;
						mode = XM_FIRST_APPLICATION_LAUNCH_MODE;
						[self _prepareFLLocationSettings];
						break;
					}
					else
					{
						// should not happen
						return;
					}
				}
				
				currentKeysToAskIndex--;
				viewTag = XM_FL_COMPLETED_VIEW_TAG;
				[self _showPreviousViewForImportLocationModes];
				return;
				
			case XM_FL_INTRODUCTION_VIEW_TAG:
			case XM_FL_GENERAL_SETTINGS_VIEW_TAG:
			case XM_FL_LOCATION_VIEW_TAG:
				[self _showPreviousViewForFirstApplicationLaunchMode];
				return;
				
			default:
				return;
		}
	}
	
	[contentBox setContentView:nextView];
	
	[[self window] makeFirstResponder:firstResponder];
	
	[self _setupButtons];
}

- (void)_liLocationImportOpenPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if(returnCode == NSCancelButton)
	{
		[self _returnFromLocationImportAssistant:NSRunAbortedResponse];
		return;
	}
	else
	{
		NSString *path = (NSString *)[[sheet filenames] objectAtIndex:0];
		
		NSString *errorDescription = nil;
		
		NSDictionary *dict = [self _parseFile:path errorDescription:&errorDescription];
		
		if(dict == nil)
		{
			NSAlert *alert = [[NSAlert alloc] init];
			
			[alert setMessageText:NSLocalizedString(@"XM_SETUP_ASSISTANT_LOC_IMPORT_FAILURE", @"")];
			[alert setInformativeText:errorDescription];
			[alert setAlertStyle:NSWarningAlertStyle];
			[alert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
			
			[alert runModal];
			
			[self _returnFromLocationImportAssistant:NSRunAbortedResponse];

			return;
		}
		
		if(locationImportData != nil)
		{
			[locationImportData release];
		}
		
		if([dict objectForKey:XMKey_KeysToAsk] != nil)
		{
			locationImportData = [dict retain];
			[self performSelector:@selector(_startLISheet) withObject:nil afterDelay:0.0];
		}
		else
		{
			[self _returnFromLocationImportAssistant:NSRunStoppedResponse];
		}
	}
}

- (void)_startLISheet
{
	// triggering the nib load if needed
	[self window];
	
	viewTag = XM_LI_START_VIEW_TAG;
	[self _showNextViewForImportLocationModes];
	[NSApp beginSheet:[self window] modalForWindow:modalWindow modalDelegate:self didEndSelector:nil contextInfo:NULL];
}

- (void)_prepareLIInfoSettings
{
	NSDictionary *dict = [[locationImportData objectForKey:XMKey_KeysToAsk] objectAtIndex:currentKeysToAskIndex];
	
	NSString *title = [dict objectForKey:XMKey_Title];
	if(title != nil && [title isKindOfClass:[NSString class]])
	{
		[self _setTitle:title];
	}
	else
	{
		[self _setTitle:NSLocalizedString(@"XM_SETUP_ASSISTANT_IMPORT", @"")];
	}
	
	NSString *description = [dict objectForKey:XMKey_Description];
	[infoField setStringValue:description];
}

- (void)_finishLIInfoSettings
{
	[infoField setStringValue:@""];
}

- (void)_prepareLINetworkSettings
{
	NSArray *locations = [locationImportData objectForKey:XMKey_Locations];
	NSDictionary *currentKeys = [[locationImportData objectForKey:XMKey_KeysToAsk] objectAtIndex:currentKeysToAskIndex];
	NSArray *locationIndexes = [currentKeys objectForKey:XMKey_AppliesTo];
	NSArray *keys = [currentKeys objectForKey:XMKey_Keys];
	
	NSString *title = [currentKeys objectForKey:XMKey_Title];
	if(title != nil && [title isKindOfClass:[NSString class]])
	{
		[self _setTitle:title];
	}
	else
	{
		[self _setTitle:NSLocalizedString(@"XM_SETUP_ASSISTANT_IMPORT", @"")];
	}
	
	XMLocation *theLocation = (XMLocation *)[locations objectAtIndex:[[locationIndexes objectAtIndex:0] unsignedIntValue]];
	
	[bandwidthLimitPopUp selectItemWithTag:[theLocation bandwidthLimit]];
	
	BOOL enableBandwidthLimit = NO;
	if([keys containsObject:XMKey_PreferencesBandwidthLimit])
	{
		enableBandwidthLimit = YES;
	}
	[bandwidthLimitPopUp setEnabled:enableBandwidthLimit];
	[bandwidthLimitPopUp selectItemWithTag:[theLocation bandwidthLimit]];
	
	/*int state = ([theLocation useAddressTranslation] == YES) ? NSOnState : NSOffState;
	[useIPAddressTranslationSwitch setState:state];
	
	NSString *externalAddress = [theLocation externalAddress];
	if(externalAddress == nil)
	{
		[automaticallyGetExternalAddressSwitch setState:NSOnState];
		[externalAddressField setStringValue:@""];
	}
	else
	{
		[automaticallyGetExternalAddressSwitch setState:NSOffState];
		[externalAddressField setStringValue:externalAddress];
	}
	
	if([keys containsObject:XMKey_PreferencesExternalAddress])
	{
		[useIPAddressTranslationSwitch setEnabled:NO];
		[automaticallyGetExternalAddressSwitch setEnabled:NO];
		[updateExternalAddressButton setEnabled:NO];
	}
	else if([keys containsObject:XMKey_PreferencesUseAddressTranslation])
	{
		XMUtils *utils = [XMUtils sharedInstance];
		if([utils checkipExternalAddress] == nil && [utils didSucceedFetchingCheckipExternalAddress] == YES)
		{
			[utils startFetchingCheckipExternalAddress];
		}
		
		NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
		[notificationCenter addObserver:self selector:@selector(validateAddressTranslationInterface:)
								   name:XMNotification_UtilsDidStartFetchingCheckipExternalAddress object:nil];
		[notificationCenter addObserver:self selector:@selector(_didEndFetchingExternalAddress:)
								   name:XMNotification_UtilsDidEndFetchingCheckipExternalAddress object:nil];
		
		[self validateAddressTranslationInterface:nil];
	}
	else
	{
		[useIPAddressTranslationSwitch setEnabled:NO];
		[externalAddressField setEnabled:NO];
		[automaticallyGetExternalAddressSwitch setEnabled:NO];
		[updateExternalAddressButton setEnabled:NO];
	}*/
}

- (void)_finishLINetworkSettings
{
	NSArray *locations = [locationImportData objectForKey:XMKey_Locations];
	NSDictionary *currentKeys = [[locationImportData objectForKey:XMKey_KeysToAsk] objectAtIndex:currentKeysToAskIndex];
	NSArray *locationIndexes = [currentKeys objectForKey:XMKey_AppliesTo];
	NSArray *keys = [currentKeys objectForKey:XMKey_Keys];
	
	unsigned count = [locationIndexes count];
	unsigned i;
	
	for(i = 0; i < count; i++)
	{
		NSNumber *number = [locationIndexes objectAtIndex:i];
		XMLocation *locationToChange = (XMLocation *)[locations objectAtIndex:[number unsignedIntValue]];
		
		if([keys containsObject:XMKey_PreferencesBandwidthLimit])
		{
			[locationToChange setBandwidthLimit:[[bandwidthLimitPopUp selectedItem] tag]];
		}
		
		/*if([keys containsObject:XMKey_PreferencesExternalAddress])
		{
			[locationToChange setExternalAddress:[externalAddressField stringValue]];
		}
		else if([keys containsObject:XMKey_PreferencesUseAddressTranslation])
		{
			BOOL flag = ([useIPAddressTranslationSwitch state] == NSOnState) ? YES : NO;
			[locationToChange setUseAddressTranslation:flag];
			
			flag = ([automaticallyGetExternalAddressSwitch state] == NSOnState) ? YES : NO;
			if(flag == YES)
			{
				[locationToChange setExternalAddress:nil];
			}
			else
			{
				[locationToChange setExternalAddress:[externalAddressField stringValue]];
			}
		}*/
	}

	/*if([keys containsObject:XMKey_PreferencesUseAddressTranslation])
	{
		NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
		[notificationCenter removeObserver:self name:XMNotification_UtilsDidStartFetchingCheckipExternalAddress object:nil];
		[notificationCenter removeObserver:self name:XMNotification_UtilsDidEndFetchingCheckipExternalAddress object:nil];
	}*/
	
	[bandwidthLimitPopUp setEnabled:YES];
	//[useIPAddressTranslationSwitch setEnabled:YES];
	//[externalAddressField setEnabled:YES];
	//[automaticallyGetExternalAddressSwitch setEnabled:YES];
	//[updateExternalAddressButton setEnabled:YES];
}

- (NSView *)_prepareLIGatekeeperSettings
{
	NSArray *h323Accounts = [locationImportData objectForKey:XMKey_H323Accounts];
	NSDictionary *currentKeys = [[locationImportData objectForKey:XMKey_KeysToAsk] objectAtIndex:currentKeysToAskIndex];
	NSArray *accountIndexes = [currentKeys objectForKey:XMKey_AppliesTo];
	NSArray *keys = [currentKeys objectForKey:XMKey_Keys];
	NSView *firstResponder = gkUsernameField;
	
	NSString *title = [currentKeys objectForKey:XMKey_Title];
	if(title != nil && [title isKindOfClass:[NSString class]])
	{
		[self _setTitle:title];
	}
	else
	{
		[self _setTitle:NSLocalizedString(@"XM_SETUP_ASSISTANT_IMPORT", @"")];
	}
	
	XMH323Account *theH323Account = (XMH323Account *)[h323Accounts objectAtIndex:[[accountIndexes objectAtIndex:0] unsignedIntValue]];
	
	NSString *gkAddress = [theH323Account gatekeeper];
	if(gkAddress == nil)
	{
		gkAddress = @"";
	}

	NSString *gkUsername = [theH323Account username];
	if(gkUsername == nil)
	{
		gkUsername = @"";
	}
	
	NSString *gkPhoneNumber = [theH323Account phoneNumber];
	if(gkPhoneNumber == nil)
	{
		gkPhoneNumber = @"";
	}
	
	NSString *gkPwd = @"";
	
	[gkHostField setStringValue:gkAddress];
	[gkUsernameField setStringValue:gkUsername];
	[gkPhoneNumberField setStringValue:gkPhoneNumber];
	[gkPasswordField setStringValue:gkPwd];
	
	[gkHostField setEnabled:NO];
	
	if(![keys containsObject:XMKey_H323AccountTerminalAlias1])
	{
		[gkUsernameField setEnabled:NO];
		firstResponder = gkPhoneNumberField;
	}
	if(![keys containsObject:XMKey_H323AccountTerminalAlias2])
	{
		[gkPhoneNumberField setEnabled:NO];
		if(firstResponder == gkPhoneNumberField)
		{
			firstResponder = gkPasswordField;
		}
	}
	if(![keys containsObject:XMKey_H323AccountPassword])
	{
		[gkPasswordField setEnabled:NO];
	}
	
	return firstResponder;
}

- (void)_finishLIGatekeeperSettings
{
	NSArray *h323Accounts = [locationImportData objectForKey:XMKey_H323Accounts];
	NSDictionary *currentKeys = [[locationImportData objectForKey:XMKey_KeysToAsk] objectAtIndex:currentKeysToAskIndex];
	NSArray *accountIndexes = [currentKeys objectForKey:XMKey_AppliesTo];
	NSArray *keys = [currentKeys objectForKey:XMKey_Keys];
	
	unsigned count = [accountIndexes count];
	unsigned i;
	
	for(i = 0; i < count; i++)
	{
		NSNumber *number = [accountIndexes objectAtIndex:i];
		XMH323Account *accountToChange = (XMH323Account *)[h323Accounts objectAtIndex:[number unsignedIntValue]];
		
		if([keys containsObject:XMKey_H323AccountTerminalAlias1])
		{
			NSString *gkUsername = [gkUsernameField stringValue];
			if([gkUsername isEqualToString:@""])
			{
				gkUsername = nil;
			}
			[accountToChange setTerminalAlias1:gkUsername];
		}
		if([keys containsObject:XMKey_H323AccountTerminalAlias2])
		{
			NSString *gkPhoneNumber = [gkPhoneNumberField stringValue];
			if([gkPhoneNumber isEqualToString:@""])
			{
				gkPhoneNumber = nil;
			}
			[accountToChange setTerminalAlias2:gkPhoneNumber];
		}
		if([keys containsObject:XMKey_H323AccountPassword])
		{
			NSString *gkPassword = [gkPasswordField stringValue];
			if([gkPassword isEqualToString:@""])
			{
				gkPassword = nil;
			}
			[accountToChange setPassword:gkPassword];
		}
	}
	
	[gkHostField setEnabled:YES];
	[gkUsernameField setEnabled:YES];
	[gkPhoneNumberField setEnabled:YES];
	[gkPasswordField setEnabled:YES];
}

- (NSView *)_prepareLIRegistrationSettings
{
	NSArray *sipAccounts = [locationImportData objectForKey:XMKey_SIPAccounts];
	NSDictionary *currentKeys = [[locationImportData objectForKey:XMKey_KeysToAsk] objectAtIndex:currentKeysToAskIndex];
	NSArray *accountIndexes = [currentKeys objectForKey:XMKey_AppliesTo];
	NSArray *keys = [currentKeys objectForKey:XMKey_Keys];
	NSView *firstResponder = registrationUsernameField;
	
	NSString *title = [currentKeys objectForKey:XMKey_Title];
	if(title != nil && [title isKindOfClass:[NSString class]])
	{
		[self _setTitle:title];
	}
	else
	{
		[self _setTitle:NSLocalizedString(@"XM_SETUP_ASSISTANT_IMPORT", @"")];
	}
	
	XMSIPAccount *theSIPAccount = (XMSIPAccount *)[sipAccounts objectAtIndex:[[accountIndexes objectAtIndex:0] unsignedIntValue]];
	
	NSString *registrationDomain = [theSIPAccount domain];
	if(registrationDomain == nil)
	{
		registrationDomain = @"";
	}
	
	NSString *registrationUsername = [theSIPAccount username];
	if(registrationUsername == nil)
	{
		registrationUsername = @"";
	}
	
	NSString *registrationAuthUsername = [theSIPAccount authorizationUsername];
	if(registrationAuthUsername == nil)
	{
		registrationAuthUsername = @"";
	}
	
	NSString *registrationPwd = @"";
	
	[registrationDomainField setStringValue:registrationDomain];
	[registrationUsernameField setStringValue:registrationUsername];
	[registrationAuthUsernameField setStringValue:registrationAuthUsername];
	[registrationPasswordField setStringValue:registrationPwd];
	
	[registrationDomainField setEnabled:NO];
	
	if(![keys containsObject:XMKey_SIPAccountUsername])
	{
		[registrationUsernameField setEnabled:NO];
		firstResponder = registrationAuthUsernameField;
	}
	if(![keys containsObject:XMKey_SIPAccountAuthorizationUsername])
	{
		[registrationAuthUsernameField setEnabled:NO];
		if(firstResponder == registrationAuthUsernameField)
		{
			firstResponder = registrationPasswordField;
		}
	}
	if(![keys containsObject:XMKey_SIPAccountPassword])
	{
		[registrationPasswordField setEnabled:NO];
	}
	
	return firstResponder;
}

- (void)_finishLIRegistrationSettings
{
	NSArray *sipAccounts = [locationImportData objectForKey:XMKey_SIPAccounts];
	NSDictionary *currentKeys = [[locationImportData objectForKey:XMKey_KeysToAsk] objectAtIndex:currentKeysToAskIndex];
	NSArray *accountIndexes = [currentKeys objectForKey:XMKey_AppliesTo];
	NSArray *keys = [currentKeys objectForKey:XMKey_Keys];
	
	unsigned count = [accountIndexes count];
	unsigned i;
	
	for(i = 0; i < count; i++)
	{
		NSNumber *number = [accountIndexes objectAtIndex:i];
		XMSIPAccount *accountToChange = (XMSIPAccount *)[sipAccounts objectAtIndex:[number unsignedIntValue]];
		
		if([keys containsObject:XMKey_SIPAccountUsername])
		{
			NSString *registrationUsername = [registrationUsernameField stringValue];
			if([registrationUsername isEqualToString:@""])
			{
				registrationUsername = nil;
			}
			[accountToChange setUsername:registrationUsername];
		}
		if([keys containsObject:XMKey_SIPAccountAuthorizationUsername])
		{
			NSString *registrationAuthUsername = [registrationAuthUsernameField stringValue];
			if([registrationAuthUsername isEqualToString:@""])
			{
				registrationAuthUsername = nil;
			}
			[accountToChange setAuthorizationUsername:registrationAuthUsername];
		}
		if([keys containsObject:XMKey_SIPAccountPassword])
		{
			NSString *registrationPassword = [registrationPasswordField stringValue];
			if([registrationPassword isEqualToString:@""])
			{
				registrationPassword = nil;
			}
			[accountToChange setPassword:registrationPassword];
		}
	}
	
	[registrationDomainField setEnabled:YES];
	[registrationUsernameField setEnabled:YES];
	[registrationAuthUsernameField setEnabled:YES];
	[registrationPasswordField setEnabled:YES];
}

- (void)_prepareLICompletedSettings
{
	[self _setTitle:NSLocalizedString(@"XM_SETUP_ASSISTANT_COMPLETED", @"")];
}

- (void)_finishLICompletedSettings
{
}

- (void)_didStartFetchingExternalAddress:(NSNotification *)notif
{
	[self _validateAddressTranslationUserInterface];
}

- (void)_didEndFetchingExternalAddress:(NSNotification *)notif
{
	NSString *externalAddress = [[XMUtils sharedInstance] checkipExternalAddress];
	if(externalAddress != nil)
	{
		[externalAddressField setStringValue:externalAddress];
	}
	[self _validateAddressTranslationUserInterface];
}

- (void)_didUpdateSTUNInformation:(NSNotification *)notif
{
	XMUtils *utils = [XMUtils sharedInstance];
	
	detectedNATType = [utils natType];
	[self _setupNATTypeView];
	
	//[[NSNotificationCenter defaultCenter] removeObserver:self name:XMNotification_UtilsDidUpdateSTUNInformation object:nil];
}

- (void)_setupNATTypeView
{
	[natDetectionProgressIndicator stopAnimation:self];
	
	[natDetectionBox setHidden:YES];
	[natTypeBox setHidden:NO];
	[continueNATSettingsButton setEnabled:YES];
	
	[natTypeField setStringValue:XMNATTypeString(detectedNATType)];
	
	NSString *explanationString = @"";
	switch(detectedNATType)
	{
		case XMNATType_Error:
			explanationString = NSLocalizedString(@"XM_SETUP_ASSISTANT_NAT_ERROR", @"");
			break;
		case XMNATType_NoNAT:
			explanationString = NSLocalizedString(@"XM_SETUP_ASSISTANT_NO_NAT", @"");
			break;
		case XMNATType_SymmetricNAT:
		case XMNATType_BlockedNAT:
			explanationString = [NSString stringWithFormat:NSLocalizedString(@"XM_SETUP_ASSISTANT_SYMMETRIC_NAT", @""), XMNATTypeString(detectedNATType)];
			break;
		default:
			explanationString = NSLocalizedString(@"XM_SETUP_ASSISTANT_DEFAULT_NAT", @"");
			break;
	}
	
	[natTypeExplanationField setStringValue:explanationString];
}

- (void)_validateSTUNUserInterface
{
	BOOL flag = ([useSTUNRadioButton state] == NSOnState) ? YES : NO;
	
	[stunServerField setEnabled:flag];
}

- (void)_validateAddressTranslationUserInterface
{
	BOOL flag = ([useIPAddressTranslationRadioButton state] == NSOnState) ? YES : NO;
	
	[automaticallyGetExternalAddressSwitch setEnabled:flag];
	[updateExternalAddressButton setEnabled:flag];
	
	if(flag)
	{
		[self _validateExternalAddressUserInterface];
	}
	else
	{
		[externalAddressField setEnabled:NO];
	}
}

- (void)_validateExternalAddressUserInterface
{
	BOOL flag = ([automaticallyGetExternalAddressSwitch state] == NSOffState) ? YES : NO;
	[externalAddressField setEnabled:flag];
	
	NSColor *textColor;
	
	if(flag == NO)
	{
		XMUtils *utils = [XMUtils sharedInstance];
		NSString *externalAddress = [utils checkipExternalAddress];
		NSString *displayString;
		
		if(externalAddress == nil)
		{
			if([utils isFetchingCheckipExternalAddress])
			{
				displayString = NSLocalizedString(@"XM_FETCHING_EXTERNAL_ADDRESS", @"");
			}
			else
			{
				displayString = NSLocalizedString(@"XM_EXTERNAL_ADDRESS_NOT_AVAILABLE", @"");
			}
			textColor = [NSColor controlTextColor];
			externalAddressIsValid = NO;
		}
		else
		{
			displayString = externalAddress;
			textColor = [NSColor controlTextColor];
			externalAddressIsValid = YES;
		}
		
		[externalAddressField setStringValue:displayString];
	}
	else
	{
		if(!externalAddressIsValid)
		{
			[externalAddressField setStringValue:@""];
		}
		textColor = [NSColor controlTextColor];
	}
	
	[externalAddressField setTextColor:textColor];
}

@end