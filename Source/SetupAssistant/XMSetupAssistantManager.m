/*
 * $Id: XMSetupAssistantManager.m,v 1.3 2006/02/28 18:37:21 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMSetupAssistantManager.h"

#import "XMeeting.h"
#import "XMPreferencesManager.h"
#import "XMLocation.h"

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
#define XM_FL_COMPLETED_VIEW_TAG 5

#define XM_LI_START_VIEW_TAG 11
#define XM_LI_INFO_VIEW_TAG 12
#define XM_LI_COMPLETED_VIEW_TAG 13

#define XM_NETWORK_SETTINGS_VIEW_TAG 21
#define XM_H323_SETTINGS_VIEW_TAG 22
#define XM_GATEKEEPER_SETTINGS_VIEW_TAG 23
#define XM_VIDEO_SETTINGS_VIEW_TAG 24

#define XMKey_SetupAssistantNibName @"SetupAssistant"

#define XMKey_KeysToAsk @"XMeeting_KeysToAsk"
#define XMKey_AppliesTo @"XMeeting_AppliesTo"
#define XMKey_Description @"XMeeting_Description"
#define XMKey_Keys @"XMeeting_Keys"
#define XMKey_GatekeeperPassword @"XMeeting_GatekeeperPassword"

@interface XMSetupAssistantManager (PrivateMethods)

- (id)_init;

- (void)_setupButtons;

- (void)_showNextViewForFirstApplicationLaunchMode;
- (void)_showPreviousViewForFirstApplicationLaunchMode;
- (void)_returnFromFirstApplicationLaunchAssistant:(int)returnCode;

- (NSView *)_prepareFLGeneralSettings;
- (void)_finishFLGeneralSettings;

- (void)_prepareFLLocationSettings;
- (void)_finishFLLocationSettings;

- (NSView *)_prepareFLNewLocationSettings;
- (void)_finishFLNewLocationSettings;

- (void)_prepareFLNetworkSettings;
- (void)_finishFLNetworkSettings;

- (void)_prepareFLH323Settings;
- (void)_finishFLH323Settings;

- (NSView *)_prepareFLGatekeeperSettings;
- (void)_finishFLGatekeeperSettings;

- (void)_prepareFLVideoSettings;
- (void)_finishFLVideoSettings;

- (void)_beginFLLocationImport;
- (void)_flLocationImportOpenPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (NSDictionary *)_parseFile:(NSString *)file errorDescription:(NSString **)errorDescription;

- (void)_showNextViewForImportLocationModes;
- (void)_showPreviousViewForImportLocationModes;

- (void)_liLocationImportOpenPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (void)_prepareLIInfoSettings;
- (void)_finishLIInfoSettings;

- (void)_prepareLINetworkSettings;
- (void)_finishLINetworkSettings;

- (NSView *)_prepareLIGatekeeperSettings;
- (void)_finishLIGatekeeperSettings;

- (void)_didEndFetchingExternalAddress:(NSNotification *)notif;

@end

@implementation XMSetupAssistantManager

#pragma mark Class Methods

+ (XMSetupAssistantManager *)sharedInstance
{
	static XMSetupAssistantManager *sharedInstance = nil;
	
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

- (void)runFirstApplicationLaunchAssistantWithDelegate:(id)theDelegate
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
	[contentBox setContentView:flIntroductionView];
	[self _setupButtons];
	
	// creating an empty location
	location = (XMLocation *)[[[preferencesManager locations] objectAtIndex:0] retain];
	
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
	
	if(gkPassword != nil)
	{
		[gkPassword release];
	}
	gkPassword = nil;
	
	[[self window] center];
	[self showWindow:self];
}

- (void)runImportLocationsAssistantModalForWindow:(NSWindow *)window 
									modalDelegate:(id)theModalDelegate
								   didEndSelector:(SEL)theDidEndSelector
{
	modalWindow = window;
	delegate = theModalDelegate;
	didEndSelector = theDidEndSelector;
	
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
		NSArray *array = [[NSArray alloc] init];
		[delegate performSelector:didEndSelector withObject:array];
		[array release];
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

// implementing to allow the application termination even
// when inside this modal loop
- (IBAction)terminate:(id)sender
{
	[NSApp terminate:sender];
}

- (IBAction)validateAddressTranslationInterface:(id)sender
{
	BOOL flag = ([useIPAddressTranslationSwitch state] == NSOnState) ? YES : NO;
	
	[updateExternalAddressButton setEnabled:flag];
	[automaticallyGetExternalAddressSwitch setEnabled:flag];
	
	if(flag == YES)
	{
		flag = ([automaticallyGetExternalAddressSwitch state] == NSOffState) ? YES : NO;
		[externalAddressField setEnabled:flag];
		
		if(flag == NO)
		{
			XMUtils *utils = [XMUtils sharedInstance];
			NSString *externalAddress = [utils externalAddress];
			NSString *displayString;
			
			if(externalAddress == nil)
			{
				if([utils isFetchingExternalAddress] == YES)
				{
					displayString = NSLocalizedString(@"Fetching...", @"");
				}
				else
				{
					displayString = NSLocalizedString(@"<Not available>", @"");
				}
				externalAddressIsValid = NO;
			}
			else
			{
				displayString = externalAddress;
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
		}
	}
	else
	{
		[externalAddressField setEnabled:NO];
	}
}

- (IBAction)updateExternalAddress:(id)sender
{
	[[XMUtils sharedInstance] startFetchingExternalAddress];
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
	
	if(isContinueButton == YES)
	{
		[continueButton setTitle:NSLocalizedString(@"Continue", @"")];
		[continueButton setKeyEquivalent:@""];
	}
	else
	{
		[continueButton setTitle:NSLocalizedString(@"Finish", @"")];
		[continueButton setKeyEquivalent:@"\r"];
	}
	
	[goBackButton setEnabled:enableGoBackButton];
}

- (void)_showNextViewForFirstApplicationLaunchMode
{
	NSView *nextView = nil;
	NSView *firstResponder = nil;

	switch(viewTag)
	{
		case XM_FL_INTRODUCTION_VIEW_TAG:
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
			nextView = h323SettingsView;
			viewTag = XM_H323_SETTINGS_VIEW_TAG;
			[self _prepareFLH323Settings];
			break;
			
		case XM_H323_SETTINGS_VIEW_TAG:
			[self _finishFLH323Settings];
			if([location useGatekeeper] == YES)
			{
				nextView = gatekeeperSettingsView;
				viewTag = XM_GATEKEEPER_SETTINGS_VIEW_TAG;
				firstResponder = [self _prepareFLGatekeeperSettings];
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
			nextView = videoSettingsView;
			viewTag = XM_VIDEO_SETTINGS_VIEW_TAG;
			[self _prepareFLVideoSettings];
			break;
			
		case XM_VIDEO_SETTINGS_VIEW_TAG:
			[self _finishFLVideoSettings];
			nextView = flCompletedView;
			viewTag = XM_FL_COMPLETED_VIEW_TAG;
			break;
			
		case XM_FL_COMPLETED_VIEW_TAG:
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
			
		case XM_H323_SETTINGS_VIEW_TAG:
			[self _finishFLH323Settings];
			nextView = networkSettingsView;
			viewTag = XM_NETWORK_SETTINGS_VIEW_TAG;
			[self _prepareFLNetworkSettings];
			break;
			
		case XM_GATEKEEPER_SETTINGS_VIEW_TAG:
			[self _finishFLGatekeeperSettings];
			nextView = h323SettingsView;
			viewTag = XM_H323_SETTINGS_VIEW_TAG;
			[self _prepareFLH323Settings];
			break;
			
		case XM_VIDEO_SETTINGS_VIEW_TAG:
			[self _finishFLVideoSettings];
			if([location useGatekeeper] == YES)
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
			break;
			
		case XM_FL_COMPLETED_VIEW_TAG:
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
	
	if(returnCode == NSRunAbortedResponse)
	{
		[location release];
		location = nil;
		
		if(locationImportData != nil)
		{
			[locationImportData release];
			locationImportData = nil;
		}
		
		[preferencesManager clearTemporaryPasswords];
		
		[delegate performSelector:didEndSelector withObject:[NSArray array]];
		return;
	}
	
	[preferencesManager setUserName:userName];
	
	NSArray *locationsArray = nil;
	
	if(mode == XM_FIRST_APPLICATION_LAUNCH_MODE)
	{
		if(gkPassword != nil && [location useGatekeeper] == YES)
		{
			[preferencesManager setTemporaryGatekeeperPassword:gkPassword forLocation:location];
		}
		
		[location setEnableH323:YES];
		
		locationsArray = [NSArray arrayWithObject:location];
		
		[location release];
		location = nil;
	}
	else
	{
		locationsArray = [[[locationImportData objectForKey:XMKey_Locations] retain] autorelease];
	}
	
	[preferencesManager saveTemporaryPasswords];
	[preferencesManager clearTemporaryPasswords];
	
	[delegate performSelector:didEndSelector withObject:locationsArray];
}

- (NSView *)_prepareFLGeneralSettings
{
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
	[locationNameField setStringValue:[location name]];
	return locationNameField;
}

- (void)_finishFLNewLocationSettings
{
	[location setName:[locationNameField stringValue]];
}

- (void)_prepareFLNetworkSettings
{
	int state;
	
	XMUtils *utils = [XMUtils sharedInstance];
	
	if([utils externalAddress] == nil && [utils didSucceedFetchingExternalAddress] == YES)
	{
		[utils startFetchingExternalAddress];
	}
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(validateAddressTranslationInterface:)
							   name:XMNotification_UtilsDidStartFetchingExternalAddress object:nil];
	[notificationCenter addObserver:self selector:@selector(_didEndFetchingExternalAddress:)
							   name:XMNotification_UtilsDidEndFetchingExternalAddress object:nil];
	
	[bandwidthLimitPopUp selectItemWithTag:[location bandwidthLimit]];
	
	state = ([location useAddressTranslation] == YES) ? NSOnState : NSOffState;
	[useIPAddressTranslationSwitch setState:state];
	
	NSString *externalAddress = [location externalAddress];
	if(externalAddress == nil)
	{
		state = NSOnState;
		externalAddress = @"";
	}
	else
	{
		state = NSOffState;
	}
	[externalAddressField setStringValue:externalAddress];
	[automaticallyGetExternalAddressSwitch setState:state];
	
	[self validateAddressTranslationInterface:nil];
}

- (void)_finishFLNetworkSettings
{
	[location setBandwidthLimit:[[bandwidthLimitPopUp selectedItem] tag]];
	
	BOOL flag = ([useIPAddressTranslationSwitch state] == NSOnState) ? YES : NO;
	[location setUseAddressTranslation:flag];
	
	flag = ([automaticallyGetExternalAddressSwitch state] == NSOnState) ? YES : NO;
	if(flag == YES)
	{
		[location setExternalAddress:nil];
	}
	else
	{
		[location setExternalAddress:[externalAddressField stringValue]];
	}
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter removeObserver:self name:XMNotification_UtilsDidStartFetchingExternalAddress object:nil];
	[notificationCenter removeObserver:self name:XMNotification_UtilsDidEndFetchingExternalAddress object:nil];
}

- (void)_prepareFLH323Settings
{
	int tag = ([location useGatekeeper] == YES) ? 0 : 1;
	[useGatekeeperRadioButtons selectCellWithTag:tag];
}

- (void)_finishFLH323Settings
{
	int tag = [[useGatekeeperRadioButtons selectedCell] tag];
	BOOL useGatekeeper = (tag == 0) ? YES : NO;
	[location setUseGatekeeper:useGatekeeper];
}

- (NSView *)_prepareFLGatekeeperSettings
{
	NSString *gatekeeperAddress = [location gatekeeperAddress];
	NSString *gatekeeperUsername = [location gatekeeperUsername];
	NSString *gatekeeperPhoneNumber = [location gatekeeperPhoneNumber];
	NSString *gatekeeperPassword = gkPassword;
	
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
	
	[location setGatekeeperAddress:gatekeeperAddress];
	[location setGatekeeperUsername:gatekeeperUsername];
	[location setGatekeeperPhoneNumber:gatekeeperPhoneNumber];
	
	if(gkPassword != nil)
	{
		[gkPassword release];
	}
	gkPassword = gatekeeperPassword;
	if(gkPassword != nil)
	{
		[gkPassword retain];
	}
	
	[continueButton setEnabled:YES];
}

- (void)_prepareFLVideoSettings
{
	int tag = ([location enableVideo] == YES) ? 0 : 1;
	[enableVideoRadioButtons selectCellWithTag:tag];
}

- (void)_finishFLVideoSettings
{
	int tag = [[enableVideoRadioButtons selectedCell] tag];
	BOOL enableVideo = (tag == 0) ? YES : NO;
	[location setEnableVideo:enableVideo];
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
			
			[alert setMessageText:@"Location import failed"];
			[alert setInformativeText:errorDescription];
			[alert setAlertStyle:NSWarningAlertStyle];
			[alert addButtonWithTitle:@"OK"];
			
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
		return nil;
	}
	
	if([propertyList isKindOfClass:[NSDictionary class]])
	{
		NSArray *locationDicts = [propertyList objectForKey:XMKey_Locations];
		
		if((locationDicts != nil) && ([locationDicts isKindOfClass:[NSArray class]]))
		{
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
				
				XMLocation *locationInstance = [[XMLocation alloc] initWithDictionary:dict];
				if(locationInstance != nil)
				{
					[parsedLocations addObject:locationInstance];
					[locationInstance release];
				}
			}
			
			count = [parsedLocations count];
			
			[propertyList setObject:parsedLocations forKey:XMKey_Locations];
			[parsedLocations release];
			
			if(count != 0)
			{
				return propertyList;
			}
		}
	}
	
	*errorDescription = @"File does not contain valid data";
	return nil;
}

- (void)_showNextViewForImportLocationModes
{
	NSView *nextView = nil;
	NSView *firstResponder = nil;
	
	if(viewTag == XM_FL_COMPLETED_VIEW_TAG)
	{
		[NSApp stopModal];
		return;
	}
	else if(viewTag == XM_LI_COMPLETED_VIEW_TAG)
	{
		[self close];
		[NSApp endSheet:[self window]];
		
		NSArray *importedLocations = [locationImportData objectForKey:XMKey_Locations];
		[delegate performSelector:didEndSelector withObject:importedLocations];
		return;
	}
	
	NSArray *keysToAsk = [locationImportData objectForKey:XMKey_KeysToAsk];
	if(keysToAsk == nil ||
	   ![keysToAsk isKindOfClass:[NSArray class]] ||
	   [keysToAsk count] == 0)
	{
		if(mode == XM_FIRST_APPLICATION_LAUNCH_IMPORT_LOCATIONS_MODE)
		{
			nextView = flCompletedView;
			viewTag = XM_FL_COMPLETED_VIEW_TAG;
		}
		else
		{
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
				if(description != nil)
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
				
				if([keys containsObject:XMKey_PreferencesBandwidthLimit] ||
				   [keys containsObject:XMKey_PreferencesUseAddressTranslation] ||
				   [keys containsObject:XMKey_PreferencesExternalAddress])
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
				
				if([keys containsObject:XMKey_PreferencesGatekeeperUsername] ||
				   [keys containsObject:XMKey_PreferencesGatekeeperPhoneNumber] ||
				   [keys containsObject:XMKey_GatekeeperPassword])
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
				
				if([keysToAsk count] == (currentKeysToAskIndex + 1))
				{
					if(mode == XM_FIRST_APPLICATION_LAUNCH_IMPORT_LOCATIONS_MODE)
					{
						nextView = flCompletedView;
						viewTag = XM_FL_COMPLETED_VIEW_TAG;
					}
					else
					{
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
				
				if([keys containsObject:XMKey_PreferencesGatekeeperUsername] ||
				   [keys containsObject:XMKey_PreferencesGatekeeperPhoneNumber] ||
				   [keys containsObject:XMKey_GatekeeperPassword])
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
				
				if([keys containsObject:XMKey_PreferencesBandwidthLimit] ||
				   [keys containsObject:XMKey_PreferencesUseAddressTranslation] ||
				   [keys containsObject:XMKey_PreferencesExternalAddress])
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
				}
				
				NSString *description = [currentKeySet objectForKey:XMKey_Description];
				if(description != nil)
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
		NSArray *array = [[NSArray alloc] init];
		[delegate performSelector:didEndSelector withObject:array];
		[array release];
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
			
			[alert setMessageText:@"Location import failed"];
			[alert setInformativeText:errorDescription];
			[alert setAlertStyle:NSWarningAlertStyle];
			[alert addButtonWithTitle:@"OK"];
			
			[alert runModal];
			
			NSArray *array = [[NSArray alloc] init];
			[delegate performSelector:didEndSelector withObject:array];
			[array release];
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
			[delegate performSelector:didEndSelector withObject:[dict objectForKey:XMKey_Locations]];
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
	NSString *description = [[[locationImportData objectForKey:XMKey_KeysToAsk] 
								objectAtIndex:currentKeysToAskIndex] objectForKey:XMKey_Description];
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
	
	XMLocation *theLocation = (XMLocation *)[locations objectAtIndex:[[locationIndexes objectAtIndex:0] unsignedIntValue]];
	
	[bandwidthLimitPopUp selectItemWithTag:[theLocation bandwidthLimit]];
	
	BOOL enableBandwidthLimit = NO;
	if([keys containsObject:XMKey_PreferencesBandwidthLimit])
	{
		enableBandwidthLimit = YES;
	}
	[bandwidthLimitPopUp setEnabled:enableBandwidthLimit];
	[bandwidthLimitPopUp selectItemWithTag:[theLocation bandwidthLimit]];
	
	int state = ([theLocation useAddressTranslation] == YES) ? NSOnState : NSOffState;
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
		if([utils externalAddress] == nil && [utils didSucceedFetchingExternalAddress] == YES)
		{
			[utils startFetchingExternalAddress];
		}
		
		NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
		[notificationCenter addObserver:self selector:@selector(validateAddressTranslationInterface:)
								   name:XMNotification_UtilsDidStartFetchingExternalAddress object:nil];
		[notificationCenter addObserver:self selector:@selector(_didEndFetchingExternalAddress:)
								   name:XMNotification_UtilsDidEndFetchingExternalAddress object:nil];
		
		[self validateAddressTranslationInterface:nil];
	}
	else
	{
		[useIPAddressTranslationSwitch setEnabled:NO];
		[externalAddressField setEnabled:NO];
		[automaticallyGetExternalAddressSwitch setEnabled:NO];
		[updateExternalAddressButton setEnabled:NO];
	}
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
		
		if([keys containsObject:XMKey_PreferencesExternalAddress])
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
		}
	}

	if([keys containsObject:XMKey_PreferencesUseAddressTranslation])
	{
		NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
		[notificationCenter removeObserver:self name:XMNotification_UtilsDidStartFetchingExternalAddress object:nil];
		[notificationCenter removeObserver:self name:XMNotification_UtilsDidEndFetchingExternalAddress object:nil];
	}
	
	[bandwidthLimitPopUp setEnabled:YES];
	[useIPAddressTranslationSwitch setEnabled:YES];
	[externalAddressField setEnabled:YES];
	[automaticallyGetExternalAddressSwitch setEnabled:YES];
	[updateExternalAddressButton setEnabled:YES];
}

- (NSView *)_prepareLIGatekeeperSettings
{
	NSArray *locations = [locationImportData objectForKey:XMKey_Locations];
	NSDictionary *currentKeys = [[locationImportData objectForKey:XMKey_KeysToAsk] objectAtIndex:currentKeysToAskIndex];
	NSArray *locationIndexes = [currentKeys objectForKey:XMKey_AppliesTo];
	NSArray *keys = [currentKeys objectForKey:XMKey_Keys];
	NSView *firstResponder = gkUsernameField;
	
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	
	XMLocation *theLocation = (XMLocation *)[locations objectAtIndex:[[locationIndexes objectAtIndex:0] unsignedIntValue]];
	
	NSString *gkAddress = [theLocation gatekeeperAddress];
	if(gkAddress == nil)
	{
		gkAddress = @"";
	}

	NSString *gkUsername = [theLocation gatekeeperUsername];
	if(gkUsername == nil)
	{
		gkUsername = @"";
	}
	
	NSString *gkPhoneNumber = [theLocation gatekeeperPhoneNumber];
	if(gkPhoneNumber == nil)
	{
		gkPhoneNumber = @"";
	}
	
	NSString *gkPwd = [preferencesManager temporaryGatekeeperPasswordForLocation:theLocation];
	if(gkPwd == nil)
	{
		gkPwd = @"";
	}
	
	[gkHostField setStringValue:gkAddress];
	[gkUsernameField setStringValue:gkUsername];
	[gkPhoneNumberField setStringValue:gkPhoneNumber];
	[gkPasswordField setStringValue:gkPwd];
	
	[gkHostField setEnabled:NO];
	
	if(![keys containsObject:XMKey_PreferencesGatekeeperUsername])
	{
		[gkUsernameField setEnabled:NO];
		firstResponder = gkPhoneNumberField;
	}
	if(![keys containsObject:XMKey_PreferencesGatekeeperPhoneNumber])
	{
		[gkPhoneNumberField setEnabled:NO];
		if(firstResponder == gkPhoneNumberField)
		{
			firstResponder = gkPasswordField;
		}
	}
	if(![keys containsObject:XMKey_GatekeeperPassword])
	{
		[gkPasswordField setEnabled:NO];
	}
	
	return firstResponder;
}

- (void)_finishLIGatekeeperSettings
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
		
		if([keys containsObject:XMKey_PreferencesGatekeeperUsername])
		{
			NSString *gkUsername = [gkUsernameField stringValue];
			if([gkUsername isEqualToString:@""])
			{
				gkUsername = nil;
			}
			[locationToChange setGatekeeperUsername:gkUsername];
		}
		if([keys containsObject:XMKey_PreferencesGatekeeperPhoneNumber])
		{
			NSString *gkPhoneNumber = [gkPhoneNumberField stringValue];
			if([gkPhoneNumber isEqualToString:@""])
			{
				gkPhoneNumber = nil;
			}
			[locationToChange setGatekeeperPhoneNumber:gkPhoneNumber];
		}
	}
	
	if([keys containsObject:XMKey_GatekeeperPassword])
	{
		XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
		NSString *gkPwd = [gkPasswordField stringValue];
		if([gkPwd isEqualToString:@""])
		{
			gkPwd = nil;
		}
		[preferencesManager setTemporaryGatekeeperPassword:gkPwd forLocation:[locations objectAtIndex:0]];
	}
	
	[gkHostField setEnabled:YES];
	[gkUsernameField setEnabled:YES];
	[gkPhoneNumberField setEnabled:YES];
	[gkPasswordField setEnabled:YES];
}

- (void)_didEndFetchingExternalAddress:(NSNotification *)notif
{
	NSString *externalAddress = [[XMUtils sharedInstance] externalAddress];
	if(externalAddress != nil)
	{
		[externalAddressField setStringValue:externalAddress];
	}
	[self validateAddressTranslationInterface:nil];
}

@end