/*
 * $Id: XMLocationPreferencesModule.m,v 1.25 2006/06/13 20:27:18 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMLocationPreferencesModule.h"

#import "XMeeting.h"
#import "XMPreferencesWindowController.h"
#import "XMPreferencesManager.h"
#import "XMAccountPreferencesModule.h"
#import "XMH323Account.h"
#import "XMSIPAccount.h"
#import "XMLocation.h"
#import "XMApplicationFunctions.h"
#import "XMSetupAssistantManager.h"
#import "XMBooleanCell.h"

NSString *XMKey_LocationPreferencesModuleIdentifier = @"XMeeting_LocationPreferencesModule";

NSString *XMKey_InitialNameIdentifier = @"Name";
NSString *XMKey_InitialBandwidthIdentifier = @"Bandwidth";
NSString *XMKey_InitialQualityIdentifier = @"Quality";
NSString *XMKey_EnabledIdentifier = @"Enabled";

@interface XMLocationPreferencesModule (PrivateMethods)

// delegate methods
- (void)controlTextDidChange:(NSNotification *)notif;

// adding new locations
- (void)_addLocation:(XMLocation *)location;

// loading and saving the current selected location
- (void)_loadCurrentLocation;
- (void)_saveCurrentLocation;

// user interface validation methods
- (void)_validateLocationButtonUserInterface;
- (void)_validateSTUNUserInterface;
- (void)_validateAddressTranslationUserInterface;
- (void)_validateExternalAddressUserInterface;
- (void)_validateH323UserInterface;
- (void)_validateSIPUserInterface;
- (void)_validateAudioOrderUserInterface;
- (void)_validateVideoUserInterface;
- (void)_validateVideoOrderUserInterface;

// table view data source & delegate methods
- (int)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)column row:(int)rowIndex;
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (void)tableViewSelectionDidChange:(NSNotification *)notif;
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)tableColumn row:(int)rowIndex;

// modal delegate methods
- (void)_newLocationSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode context:(void *)context;
- (void)_deleteLocationAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode context:(void *)context;

// notification responding
- (void)_didEndFetchingExternalAddress:(NSNotification *)notif;

- (void)_importLocationsAssistantDidEndWithLocations:(NSArray *)locations
										h323Accounts:(NSArray *)h323Accounts
										 sipAccounts:(NSArray *)sipAccounts;

// Misc.
- (void)_alertLocationName;
- (void)_alertNoProtocolEnabled:(XMLocation *)location;

@end

@implementation XMLocationPreferencesModule

#pragma mark -
#pragma mark Init & Deallocation Methods

- (id)init
{
	prefWindowController = [[XMPreferencesWindowController sharedInstance] retain];
	
	locations = [[NSMutableArray alloc] initWithCapacity:3];
	
	externalAddressIsValid = YES;
	isFetchingExternalAddress = NO;
	
	return self;
}

- (void)awakeFromNib
{
	contentViewHeight = [contentView frame].size.height;
	[prefWindowController addPreferencesModule:self];
	
	// setting the default list of STUN servers
	[stunServerField addItemsWithObjectValues:XMDefaultSTUNServers()];
	
	// replacing the table column identifiers with better ones
	NSTableColumn *tableColumn;
	
	tableColumn = [audioCodecPreferenceOrderTableView tableColumnWithIdentifier:XMKey_InitialNameIdentifier];
	[tableColumn setIdentifier:XMKey_CodecName];
	
	tableColumn = [audioCodecPreferenceOrderTableView tableColumnWithIdentifier:XMKey_InitialBandwidthIdentifier];
	[tableColumn setIdentifier:XMKey_CodecBandwidth];
	
	tableColumn = [audioCodecPreferenceOrderTableView tableColumnWithIdentifier:XMKey_InitialQualityIdentifier];
	[tableColumn setIdentifier:XMKey_CodecQuality];
	
	tableColumn = [videoCodecPreferenceOrderTableView tableColumnWithIdentifier:XMKey_InitialNameIdentifier];
	[tableColumn setIdentifier:XMKey_CodecName];
	
	tableColumn = [videoCodecPreferenceOrderTableView tableColumnWithIdentifier:XMKey_InitialBandwidthIdentifier];
	[tableColumn setIdentifier:XMKey_CodecBandwidth];
	
	tableColumn = [videoCodecPreferenceOrderTableView tableColumnWithIdentifier:XMKey_InitialQualityIdentifier];
	[tableColumn setIdentifier:XMKey_CodecQuality];
	
	// adjusting the autoresizing behaviour of the two codec tables
	[audioCodecPreferenceOrderTableView setColumnAutoresizingStyle:NSTableViewLastColumnOnlyAutoresizingStyle];
	[videoCodecPreferenceOrderTableView setColumnAutoresizingStyle:NSTableViewLastColumnOnlyAutoresizingStyle];
	
	// making the table view use a XMBoolean cell for the "enabled" column
	XMBooleanCell *booleanCell = [[XMBooleanCell alloc] init];
	
	NSTableColumn *column = [audioCodecPreferenceOrderTableView tableColumnWithIdentifier:XMKey_EnabledIdentifier];
	[column setDataCell:booleanCell];
	[audioCodecPreferenceOrderTableView setRowHeight:16];
	
	column = [videoCodecPreferenceOrderTableView tableColumnWithIdentifier:XMKey_EnabledIdentifier];
	[column setDataCell:booleanCell];
	[videoCodecPreferenceOrderTableView setRowHeight:16];
	[booleanCell release];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didStartFetchingExternalAddress:)
												 name:XMNotification_UtilsDidStartFetchingCheckipExternalAddress object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didEndFetchingExternalAddress:)
												 name:XMNotification_UtilsDidEndFetchingCheckipExternalAddress object:nil];

	XMUtils *utils = [XMUtils sharedInstance];
	if([utils didSucceedFetchingCheckipExternalAddress] && [utils checkipExternalAddress] == nil)
	{
		// in this case, the external address has not yet been fetched, thus
		// we start fetching the address
		[utils startFetchingCheckipExternalAddress];
		isFetchingExternalAddress = YES;
	}
	
	[actionButton sendActionOn:NSLeftMouseDownMask];
	[actionPopup selectItem: nil];

}

- (void)dealloc
{
	[prefWindowController release];
	[locations release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark XMPreferencesModule methdos

- (unsigned)position
{
	return 3;
}

- (NSString *)identifier
{
	return XMKey_LocationPreferencesModuleIdentifier;
}

- (NSString *)toolbarLabel
{
	return NSLocalizedString(@"XM_LOCATION_PREFERENCES_NAME", @"");
}

- (NSImage *)toolbarImage
{
	return [NSImage imageNamed:@"locationPreferences.tif"];
}

- (NSString *)toolTipText
{
	return NSLocalizedString(@"XM_LOCATION_PREFERENCES_TOOLTIP", @"");
}

- (NSView *)contentView
{
	return contentView;
}

- (float)contentViewHeight
{
	return contentViewHeight;
}

- (void)loadPreferences
{	
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	
	// replacing the locations with a fresh set
	[locations removeAllObjects];
	[locations addObjectsFromArray:[preferencesManager locations]];
	
	// adjusting SIP proxy passwords if needed
	unsigned i;
	unsigned count = [locations count];
	
	for(i = 0; i < count; i++)
	{
		XMLocation *location = (XMLocation *)[locations objectAtIndex:i];
		
		if([location sipProxyMode] == XMSIPProxyMode_CustomProxy)
		{
			NSString *password = [[XMPreferencesManager sharedInstance] passwordForServiceName:[location sipProxyHost] 
																				   accountName:[location sipProxyUsername]];
			[location setSIPProxyPassword:password];
		}
	}
	
	// making sure that there is no wrong data saved
	currentLocation = nil;
	
	// preparing the h323 and SIP account pop up buttons
	[self noteAccountsDidChange];
	
	// causing the table view to reload its data and select the first item
	NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:0];
	[locationsTableView selectRowIndexes:indexSet byExtendingSelection:NO];
	[locationsTableView reloadData];
	
	currentLocation = (XMLocation *)[locations objectAtIndex:0];
	[self _loadCurrentLocation];
	
	// validating the location buttons
	[self _validateLocationButtonUserInterface];
	
	// displaying the first tab item at the start
	[sectionsTab selectFirstTabViewItem:self];
}

- (void)savePreferences
{
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	
	// in case that the locations table view is editing a location's name,
	// we have to stor that value as well
	unsigned index = [locationsTableView editedRow];
	if(index != -1)
	{
		NSCell *cell = [locationsTableView selectedCell];
		NSText *text = [locationsTableView currentEditor];
		[cell endEditing:text];
	}
	
	// first, save the current location
	[self _saveCurrentLocation];
	
	// store any passwords needed
	unsigned i;
	unsigned count = [locations count];
	for(i = 0; i < count; i++)
	{
		XMLocation *location = (XMLocation *)[locations objectAtIndex:i];
		
		if([location sipProxyMode] == XMSIPProxyMode_CustomProxy)
		{
			[preferencesManager setPassword:[location sipProxyPassword]
							 forServiceName:[location sipProxyHost]
								accountName:[location sipProxyUsername]];
		}
	}
	
	// pass the changed locations to the preferences manager
	[preferencesManager setLocations:locations];
}

#pragma mark -
#pragma mark Action Methods

- (IBAction)createNewLocation:(id)sender
{
	[newLocationNameField setStringValue:NSLocalizedString(@"XM_LOCATION_PREFERENCES_NEW_LOCATION", @"")];
	[newLocationNameField selectText:self];
	
	// we obtain the window through the NSView's -window method
	[NSApp beginSheet:newLocationSheet modalForWindow:[sectionsTab window] modalDelegate:self
	   didEndSelector:@selector(_newLocationSheetDidEnd:returnCode:context:) contextInfo:NULL];
}

- (IBAction)importLocations:(id)sender
{
	[[XMSetupAssistantManager sharedInstance] 
			runImportLocationsAssistantModalForWindow:[contentView window]
										modalDelegate:self
									   didEndSelector:@selector(_importLocationsAssistantDidEndWithLocations:
																h323Accounts:sipAccounts:)];
}

- (IBAction)duplicateLocation:(id)sender
{
	unsigned index = [locations count];
	
	NSString *currentLocationName = [currentLocation name];
	NSString *newName = [currentLocationName stringByAppendingString:NSLocalizedString(@"XM_LOCATION_PREFERENCES_COPY_SUFFIX", @"")];
	XMLocation *duplicate = [currentLocation duplicateWithName:newName];
	
	[self _addLocation:duplicate];
	[duplicate release];
	
	[locationsTableView editColumn:0 row:index withEvent:nil select:YES];
}

- (IBAction)deleteLocation:(id)sender
{
	unsigned index = [locations indexOfObject:currentLocation];
	
	// removing the location from the list and taking the first location as the current one.
	[locations removeObjectAtIndex:index];
	currentLocation = nil;
	
	// validate the GUI
	NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:0];
	[locationsTableView selectRowIndexes:indexSet byExtendingSelection:NO];
	[locationsTableView reloadData];
	[self _validateLocationButtonUserInterface];
	
	[sectionsTab selectFirstTabViewItem:self];
	
	// triggering the defaultAction
	[self defaultAction:self];
	
	// in case of index == 0, we have to manually set the new active location
	if(index == 0)
	{
		currentLocation = (XMLocation *)[locations objectAtIndex:0];
	}
}

- (IBAction)renameLocation:(id)sender
{
	unsigned index = [locations indexOfObject:currentLocation];
	[locationsTableView editColumn:0 row:index withEvent:nil select:YES];
}

- (IBAction)actionButton:(id)sender
{
    [[actionPopup cell] performClickWithFrame:[sender frame] inView:[sender superview]];    
	[actionPopup selectItem: nil];
}

- (IBAction)defaultAction:(id)sender
{
	[prefWindowController notePreferencesDidChange];
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
	[self defaultAction:self];
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
	[self defaultAction:self];
}

- (IBAction)toggleEnableH323:(id)sender
{
	[self _validateH323UserInterface];
	[self defaultAction:self];
}

- (IBAction)gatekeeperAccountSelected:(id)sender
{
	unsigned index = [h323AccountsPopUp indexOfSelectedItem];
	
	if(index == 0)
	{
		[gatekeeperHostField setStringValue:@""];
		[gatekeeperUserAliasField setStringValue:@""];
		[gatekeeperPhoneNumberField setStringValue:@""];
	}
	else
	{
		index -= 2;
		
		XMH323Account *h323Account = [accountModule h323AccountAtIndex:index];
		
		NSString *gkHost = [h323Account gatekeeper];
		NSString *gkUsername = [h323Account username];
		NSString *gkPhoneNumber = [h323Account phoneNumber];
		
		if(gkHost == nil)
		{
			gkHost = @"";
		}
		if(gkUsername == nil)
		{
			gkUsername = @"";
		}
		if(gkPhoneNumber == nil)
		{
			gkPhoneNumber = @"";
		}
		[gatekeeperHostField setStringValue:gkHost];
		[gatekeeperUserAliasField setStringValue:gkUsername];
		[gatekeeperPhoneNumberField setStringValue:gkPhoneNumber];
	}
	
	[self defaultAction:self];
}

- (IBAction)toggleEnableSIP:(id)sender
{
	[self _validateSIPUserInterface];
	[self defaultAction:self];
}

- (IBAction)sipAccountSelected:(id)sender
{
	unsigned index = [sipAccountsPopUp indexOfSelectedItem];
	
	BOOL enableSIPAccountProxy = NO;
	
	if(index == 0)
	{
		[registrarHostField setStringValue:@""];
		[registrarUsernameField setStringValue:@""];
		[registrarAuthorizationUsernameField setStringValue:@""];
	}
	else
	{
		index -= 2;
		
		XMSIPAccount *sipAccount = [accountModule sipAccountAtIndex:index];
		
		NSString *host = [sipAccount registrar];
		if(host == nil)
		{
			host = @"";
		}
		NSString *username = [sipAccount username];
		if(username == nil)
		{
			username = @"";
		}
		NSString *authorizationUsername = [sipAccount authorizationUsername];
		if(authorizationUsername == nil)
		{
			authorizationUsername = @"";
		}
		[registrarHostField setStringValue:host];
		[registrarUsernameField setStringValue:username];
		[registrarAuthorizationUsernameField setStringValue:authorizationUsername];
		
		enableSIPAccountProxy = YES;
	}
	
	NSCell *cell = (NSCell *)[sipProxyModeMatrix cellWithTag:XMSIPProxyMode_UseSIPAccount];
	if(enableSIPAccountProxy == YES)
	{
		[cell setEnabled:YES];
	}
	else
	{
		[cell setEnabled:NO];
		[sipProxyModeMatrix selectCellWithTag:XMSIPProxyMode_NoProxy];
	}
	[self sipProxyModeSelected:self];
}

- (IBAction)sipProxyModeSelected:(id)sender
{
	XMSIPProxyMode proxyMode = (XMSIPProxyMode)[[sipProxyModeMatrix selectedCell] tag];
	
	BOOL enableTextFields = NO;
	
	if(proxyMode == XMSIPProxyMode_CustomProxy)
	{
		enableTextFields = YES;
	}
	
	[sipProxyHostField setEnabled:enableTextFields];
	[sipProxyUsernameField setEnabled:enableTextFields];
	[sipProxyPasswordField setEnabled:enableTextFields];
	
	[self defaultAction:self];
}

- (IBAction)moveAudioCodec:(id)sender
{
	int rowIndex = [audioCodecPreferenceOrderTableView selectedRow];
	int newIndex;
	if(sender == moveAudioCodecUpButton)
	{
		newIndex = rowIndex - 1;
	}
	else
	{
		newIndex = rowIndex + 1;
	}
	[currentLocation audioCodecListExchangeRecordAtIndex:rowIndex withRecordAtIndex:newIndex];
	[audioCodecPreferenceOrderTableView reloadData];
	
	NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:newIndex];
	[audioCodecPreferenceOrderTableView selectRowIndexes:indexSet byExtendingSelection:NO];
	
	[self defaultAction:self];
}

- (IBAction)toggleEnableVideo:(id)sender
{
	[self _validateVideoUserInterface];
	[self defaultAction:self];
}

- (IBAction)moveVideoCodec:(id)sender
{
	int rowIndex = [videoCodecPreferenceOrderTableView selectedRow];
	int newIndex;
	if(sender == moveVideoCodecUpButton)
	{
		newIndex = rowIndex - 1;
	}
	else
	{
		newIndex = rowIndex + 1;
	}
	[currentLocation videoCodecListExchangeRecordAtIndex:rowIndex withRecordAtIndex:newIndex];
	[videoCodecPreferenceOrderTableView reloadData];
	
	NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:newIndex];
	[videoCodecPreferenceOrderTableView selectRowIndexes:indexSet byExtendingSelection:NO];
	
	[self defaultAction:self];
}

- (IBAction)endNewLocationSheet:(id)sender
{
	int returnCode;
	
	if(sender == newLocationOKButton)
	{
		// check whether the name already exists
		NSString *locationName = [newLocationNameField stringValue];
		unsigned count = [locations count];
		unsigned i;
		for(i = 0; i < count; i++)
		{
			XMLocation *location = (XMLocation *)[locations objectAtIndex:i];
			if([[location name] isEqualToString:locationName])
			{
				[self _alertLocationName];
				
				return;
			}
		}
		returnCode = NSOKButton;
	}
	else
	{
		returnCode = NSCancelButton; 
	}
	
	[NSApp endSheet:newLocationSheet returnCode:returnCode];
	[newLocationSheet orderOut:self];
}

#pragma mark -
#pragma mark Account Module Methods

- (void)noteAccountsDidChange
{
	unsigned h323AccountToSelect = 0;
	unsigned h323AccountTag = 0;
	unsigned sipAccountToSelect = 0;
	unsigned sipAccountTag = 0;
	
	if(currentLocation != nil)
	{
		h323AccountTag = [currentLocation h323AccountTag];
		sipAccountTag = [currentLocation sipAccountTag];
	}
	
	/* updating the H323 accounts Pop Up */
	[h323AccountsPopUp removeAllItems];
	NSMenu *menu = [h323AccountsPopUp menu];
	
	NSMenuItem *noneItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"XM_LOCATION_PREFERENCES_NONE_ITEM", @"")
													  action:NULL
											   keyEquivalent:@""];
	[noneItem setTag:0];
	[menu addItem:noneItem];
	[noneItem release];
	
	unsigned count = [accountModule h323AccountCount];
	unsigned i;
	
	if(count != 0)
	{
		[menu addItem:[NSMenuItem separatorItem]];
	}
	
	for(i = 0; i < count; i++)
	{
		XMH323Account *h323Account = [accountModule h323AccountAtIndex:i];
		
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[h323Account name]
														  action:NULL keyEquivalent:@""];
		unsigned tag = [h323Account tag];
		
		[menuItem setTag:tag];
		if(tag == h323AccountTag)
		{
			h323AccountToSelect = (i+2);
		}
		
		[menu addItem:menuItem];
		
		[menuItem release];
	}
	
	/* updating the SIP accounts Pop Up */
	[sipAccountsPopUp removeAllItems];
	menu = [sipAccountsPopUp menu];
	
	noneItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"XM_LOCATION_PREFERENCES_NONE_ITEM", @"")
										  action:NULL
								   keyEquivalent:@""];
	[noneItem setTag:0];
	[menu addItem:noneItem];
	[noneItem release];
	
	count = [accountModule sipAccountCount];
	
	if(count != 0)
	{
		[menu addItem:[NSMenuItem separatorItem]];
	}
	
	for(i = 0; i < count; i++)
	{
		XMSIPAccount *sipAccount = [accountModule sipAccountAtIndex:i];
		
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[sipAccount name]
														  action:NULL keyEquivalent:@""];
		unsigned tag = [sipAccount tag];
		[menuItem setTag:tag];
		
		if(sipAccountTag == tag)
		{
			sipAccountToSelect = (i+2);
		}
		
		[menu addItem:menuItem];
		
		[menuItem release];
	}
	
	[h323AccountsPopUp selectItemAtIndex:h323AccountToSelect];
	[sipAccountsPopUp selectItemAtIndex:sipAccountToSelect];
	
	[self gatekeeperAccountSelected:self];
	[self sipAccountSelected:self];
}

#pragma mark -
#pragma mark delegate methods

- (void)controlTextDidChange:(NSNotification *)notif
{
	// we simply want the same effect as the default action.
	[self defaultAction:self];
}

#pragma mark -
#pragma mark Adding a New Location

- (void)_addLocation:(XMLocation *)location
{	
	// the current count is the later index for the new location
	unsigned index = [locations count];
	
	// adding the location
	[locations addObject:location];
	
	// validate the GUI
	NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
	[locationsTableView reloadData];
	[locationsTableView selectRowIndexes:indexSet byExtendingSelection:NO];
	[sectionsTab selectFirstTabViewItem:self];
	[self _validateLocationButtonUserInterface];
	
	[self defaultAction:self];
}

#pragma mark -
#pragma mark Location Load & Save Methods

- (void)_loadCurrentLocation
{
	int state;
	NSString *string;
	
	// load the Network section
	unsigned bandwidth = [currentLocation bandwidthLimit];
	unsigned index = [bandwidthLimitPopUp indexOfItemWithTag:bandwidth];
	[bandwidthLimitPopUp selectItemAtIndex:index];
	
	state = ([currentLocation useSTUN] == YES) ? NSOnState : NSOffState;
	[useSTUNRadioButton setState:state];
	
	if(state == NSOffState)
	{
		state = ([currentLocation useAddressTranslation] == YES) ? NSOnState : NSOffState;
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
	
	string = [currentLocation stunServer];
	if(string == nil)
	{
		string = @"";
	}
	[stunServerField setStringValue:string];
	
	string = [currentLocation externalAddress];
	if(string == nil)	// this means that the external address is automatically picked
	{
		state = NSOnState;
		string = @"";
	}
	else
	{
		state = NSOffState;
	}
	[externalAddressField setStringValue:string];
	[autoGetExternalAddressSwitch setState:state];
	
	[minTCPPortField setIntValue:[currentLocation tcpPortBase]];
	[maxTCPPortField setIntValue:[currentLocation tcpPortMax]];
	[minUDPPortField setIntValue:[currentLocation udpPortBase]];
	[maxUDPPortField setIntValue:[currentLocation udpPortMax]];
	
	// load the H.323 section
	state = ([currentLocation enableH323] == YES) ? NSOnState : NSOffState;
	[enableH323Switch setState:state];
	
	state = ([currentLocation enableH245Tunnel] == YES) ? NSOnState : NSOffState;
	[enableH245TunnelSwitch setState:state];
	
	state = ([currentLocation enableFastStart] == YES) ? NSOnState : NSOffState;
	[enableFastStartSwitch setState:state];
	
	unsigned gatekeeperAccountTag = [currentLocation h323AccountTag];
	BOOL result = [h323AccountsPopUp selectItemWithTag:gatekeeperAccountTag];
	if(result == NO)
	{
		[h323AccountsPopUp selectItemAtIndex:0];
	}
	// causing the account information to be displayed.
	[self gatekeeperAccountSelected:self];
	
	// loading the SIP section
	state = ([currentLocation enableSIP] == YES) ? NSOnState : NSOffState;
	[enableSIPSwitch setState:state];
	
	unsigned sipAccountTag = [currentLocation sipAccountTag];
	result = [sipAccountsPopUp selectItemWithTag:sipAccountTag];
	if(result == NO)
	{
		[sipAccountsPopUp selectItemAtIndex:0];
		sipAccountTag = 0;
	}
	
	XMSIPProxyMode sipProxyMode = [currentLocation sipProxyMode];
	if(sipProxyMode == XMSIPProxyMode_UseSIPAccount && sipAccountTag == 0)
	{
		sipProxyMode = XMSIPProxyMode_NoProxy;
	}
	
	[sipProxyModeMatrix selectCellWithTag:sipProxyMode];
	
	NSString *sipProxyHost = nil;
	NSString *sipProxyUsername = nil;
	NSString *sipProxyPassword = nil;
	
	if(sipProxyMode == XMSIPProxyMode_CustomProxy)
	{
		sipProxyHost = [currentLocation sipProxyHost];
		sipProxyUsername = [currentLocation sipProxyUsername];
		sipProxyPassword = [currentLocation sipProxyPassword];
	}
	
	if(sipProxyHost == nil)
	{
		sipProxyHost = @"";
	}
	if(sipProxyUsername == nil)
	{
		sipProxyUsername = @"";
	}
	if(sipProxyPassword == nil)
	{
		sipProxyPassword = @"";
	}
	
	[sipProxyHostField setStringValue:sipProxyHost];
	[sipProxyUsernameField setStringValue:sipProxyUsername];
	[sipProxyPasswordField setStringValue:sipProxyPassword];
	
	// causing the account information to be displayed
	[self sipAccountSelected:self];
	
	// loading the Audio section
	[audioBufferSizeSlider setIntValue:[currentLocation audioBufferSize]];
	[audioCodecPreferenceOrderTableView reloadData];
	
	// loading the Video section
	state = ([currentLocation enableVideo] == YES) ? NSOnState : NSOffState;
	[enableVideoSwitch setState:state];
	
	[videoFrameRateField setIntValue:[currentLocation videoFramesPerSecond]];
	
	[videoCodecPreferenceOrderTableView reloadData];
	
	state = ([currentLocation enableH264LimitedMode] == YES) ? NSOnState : NSOffState;
	[enableH264LimitedModeSwitch setState:state];
	
	// finally, it's time to validate some GUI-Elements
	[self _validateSTUNUserInterface];
	[self _validateAddressTranslationUserInterface];
	[self _validateExternalAddressUserInterface];
	[self _validateH323UserInterface];
	[self _validateSIPUserInterface];
	[self _validateAudioOrderUserInterface];
	[self _validateVideoUserInterface];
}

- (void)_saveCurrentLocation
{
	BOOL flag;
	NSString *string;
	
	// warn if no protocol is enabled
	if([enableH323Switch state] == NSOffState && [enableSIPSwitch state] == NSOffState)
	{
		[self _alertNoProtocolEnabled:currentLocation];
	}
	
	// saving the network section
	[currentLocation setBandwidthLimit:[[bandwidthLimitPopUp selectedItem] tag]];
	
	flag = ([useSTUNRadioButton state] == NSOnState) ? YES : NO;
	[currentLocation setUseSTUN:flag];
	
	string = [stunServerField stringValue];
	if([string isEqualToString:@""])
	{
		string = nil;
	}
	[currentLocation setSTUNServer:string];
	
	flag = ([useIPAddressTranslationRadioButton state] == NSOnState) ? YES : NO;
	[currentLocation setUseAddressTranslation:flag];
	
	string = [externalAddressField stringValue];
	if([string isEqualToString:@""] || [autoGetExternalAddressSwitch state] == NSOnState)
	{
		string = nil;
	}
	[currentLocation setExternalAddress:string];
	
	[currentLocation setTCPPortBase:[minTCPPortField intValue]];
	[currentLocation setTCPPortMax:[maxTCPPortField intValue]];
	[currentLocation setUDPPortBase:[minUDPPortField intValue]];
	[currentLocation setUDPPortMax:[maxUDPPortField intValue]];
	
	// saving the H.323 section
	flag = ([enableH323Switch state] == NSOnState) ? YES : NO;
	[currentLocation setEnableH323:flag];
	
	flag = ([enableH245TunnelSwitch state] == NSOnState) ? YES : NO;
	[currentLocation setEnableH245Tunnel:flag];
	
	flag = ([enableFastStartSwitch state] == NSOnState) ? YES : NO;
	[currentLocation setEnableFastStart:flag];
	
	unsigned gatekeeperTag = [[h323AccountsPopUp selectedItem] tag];
	[currentLocation setH323AccountTag:gatekeeperTag];
	
	// saving the SIP section
	flag = ([enableSIPSwitch state] == NSOnState) ? YES : NO;
	[currentLocation setEnableSIP:flag];
	
	unsigned sipAccountTag = [[sipAccountsPopUp selectedItem] tag];
	[currentLocation setSIPAccountTag:sipAccountTag];
	
	XMSIPProxyMode sipProxyMode = (XMSIPProxyMode)[[sipProxyModeMatrix selectedCell] tag];
	[currentLocation setSIPProxyMode:sipProxyMode];
	if(sipProxyMode == XMSIPProxyMode_CustomProxy)
	{
		NSString *host = [sipProxyHostField stringValue];
		NSString *username = [sipProxyUsernameField stringValue];
		NSString *password = [sipProxyPasswordField stringValue];
		
		if([host isEqualToString:@""])
		{
			host = nil;
		}
		if([username isEqualToString:@""])
		{
			username = nil;
		}
		if([password isEqualToString:@""])
		{
			password = nil;
		}
		
		[currentLocation setSIPProxyHost:host];
		[currentLocation setSIPProxyUsername:username];
		[currentLocation setSIPProxyPassword:password];
	}
	
	// saving the audio section
	[currentLocation setAudioBufferSize:[audioBufferSizeSlider intValue]];
	
	// saving the video section
	flag = ([enableVideoSwitch state] == NSOnState) ? YES : NO;
	[currentLocation setEnableVideo:flag];
	
	[currentLocation setVideoFramesPerSecond:[videoFrameRateField intValue]];
	
	flag = ([enableH264LimitedModeSwitch state] == NSOnState) ? YES : NO;
	[currentLocation setEnableH264LimitedMode:flag];
}

#pragma mark -
#pragma mark User Interface validation Methods

- (void)_validateLocationButtonUserInterface
{
	BOOL flag = ([locations count] == 1) ? NO : YES;
	[deleteLocationButton setEnabled:flag];
}

- (void)_validateSTUNUserInterface
{
	BOOL flag = ([useSTUNRadioButton state] == NSOnState) ? YES : NO;
	
	[stunServerField setEnabled:flag];
}

- (void)_validateAddressTranslationUserInterface
{
	BOOL flag = ([useIPAddressTranslationRadioButton state] == NSOnState) ? YES : NO;
	
	[autoGetExternalAddressSwitch setEnabled:flag];
	[getExternalAddressButton setEnabled:flag];
	
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
	BOOL flag = ([autoGetExternalAddressSwitch state] == NSOffState) ? YES : NO;
	[externalAddressField setEnabled:flag];
	
	NSColor *textColor;
		
	if(flag == NO)
	{
		XMUtils *utils = [XMUtils sharedInstance];
		NSString *externalAddress = [utils checkipExternalAddress];
		NSString *displayString;
		
		if(externalAddress == nil)
		{
			if(isFetchingExternalAddress)
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

- (void)_validateH323UserInterface
{
	BOOL flag = ([enableH323Switch state] == NSOnState) ? YES : NO;
	
	[enableH245TunnelSwitch setEnabled:flag];
	[enableFastStartSwitch setEnabled:flag];
	[h323AccountsPopUp setEnabled:flag];
}

- (void)_validateSIPUserInterface
{
	BOOL flag = ([enableSIPSwitch state] == NSOnState) ? YES : NO;
	
	[sipAccountsPopUp setEnabled:flag];
}

- (void)_validateAudioOrderUserInterface
{
	unsigned count = [currentLocation audioCodecListCount];
	int selectedRow = [audioCodecPreferenceOrderTableView selectedRow];
	BOOL enableUp = YES;
	BOOL enableDown = YES;
	
	if(selectedRow == 0)
	{
		enableUp = NO;
	}
	if(selectedRow == (count -1))
	{
		enableDown = NO;
	}
	[moveAudioCodecUpButton setEnabled:enableUp];
	[moveAudioCodecDownButton setEnabled:enableDown];
}

- (void)_validateVideoUserInterface
{
	BOOL flag = ([enableVideoSwitch state] == NSOnState) ? YES : NO;
	
	[videoFrameRateField setEnabled:flag];
	[videoCodecPreferenceOrderTableView setHidden:!flag];
	[enableH264LimitedModeSwitch setEnabled:flag];
	[self _validateVideoOrderUserInterface];
}

- (void)_validateVideoOrderUserInterface
{
	BOOL enableFlag = ([enableVideoSwitch state] == NSOnState) ? YES : NO;
	
	BOOL enableUp = enableFlag;
	BOOL enableDown = enableFlag;
	
	if(enableFlag == YES)
	{
		unsigned count = [currentLocation videoCodecListCount];
		int selectedRow = [videoCodecPreferenceOrderTableView selectedRow];
	
		if(selectedRow == 0)
		{
			enableUp = NO;
		}
		if(selectedRow == (count -1))
		{
			enableDown = NO;
		}
	}
	
	[moveVideoCodecUpButton setEnabled:enableUp];
	[moveVideoCodecDownButton setEnabled:enableDown];
}

#pragma mark -
#pragma mark TableView dataSource & delegate methods

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	if(tableView == locationsTableView)
	{
		return [locations count];
	}
	if(tableView == audioCodecPreferenceOrderTableView)
	{
		return [currentLocation audioCodecListCount];
	}
	if(tableView == videoCodecPreferenceOrderTableView)
	{
		return [currentLocation videoCodecListCount];
	}
	
	return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(int)rowIndex
{
	if(tableView == locationsTableView)
	{
		return [(XMLocation *)[locations objectAtIndex:rowIndex] name];
	}
	
	if(tableView != audioCodecPreferenceOrderTableView &&
	   tableView != videoCodecPreferenceOrderTableView)
	{
		return nil;
	}
	
	NSString *columnIdentifier = [column identifier];
	XMPreferencesCodecListRecord *record;
	
	if(tableView == audioCodecPreferenceOrderTableView)
	{
		record = [currentLocation audioCodecListRecordAtIndex:rowIndex];
	}
	else if(tableView == videoCodecPreferenceOrderTableView)
	{
		record = [currentLocation videoCodecListRecordAtIndex:rowIndex];
	}
	
	if([columnIdentifier isEqualToString:XMKey_EnabledIdentifier])
	{
		return [NSNumber numberWithBool:[record isEnabled]];
	}
	
	XMCodecIdentifier identifier = identifier = [record identifier];
	XMCodec *codec = [[XMCodecManager sharedInstance] codecForIdentifier:identifier];
	return [codec propertyForKey:columnIdentifier];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if(tableView == locationsTableView)
	{
		if([anObject isKindOfClass:[NSString class]])
		{
			NSString *newName = (NSString *)anObject;
			
			// check whether this name already exists
			unsigned count = [locations count];
			unsigned i;
			for(i = 0; i < count; i++)
			{
				if(i == rowIndex)
				{
					continue;
				}
				
				XMLocation *location = [locations objectAtIndex:i];
				
				if([[location name] isEqualToString:newName])
				{
					[self _alertLocationName];
					return;
				}
			}
			
			[(XMLocation *)[locations objectAtIndex:rowIndex] setName:newName];
		}
	}
	
	if(tableView == audioCodecPreferenceOrderTableView)
	{
		[[currentLocation audioCodecListRecordAtIndex:rowIndex] setEnabled:[anObject boolValue]];
		[audioCodecPreferenceOrderTableView reloadData];
	}
	
	if(tableView == videoCodecPreferenceOrderTableView)
	{
		[[currentLocation videoCodecListRecordAtIndex:rowIndex] setEnabled:[anObject boolValue]];
		[videoCodecPreferenceOrderTableView reloadData];
	}
	
	[self defaultAction:self];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notif
{
	NSTableView *tableView = (NSTableView *)[notif object];
	
	if(tableView == locationsTableView)
	{
		if(currentLocation)
		{
			[self _saveCurrentLocation];
		}
		
		unsigned newIndex = [locationsTableView selectedRow];
		
		// change the current location
		currentLocation = [locations objectAtIndex:newIndex];
		
		// update the GUI to show the new location
		[self _loadCurrentLocation];
	}
	
	if(tableView == audioCodecPreferenceOrderTableView)
	{
		[self _validateAudioOrderUserInterface];
	}
	
	if(tableView == videoCodecPreferenceOrderTableView)
	{
		[self _validateVideoOrderUserInterface];
	}
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if(tableView == audioCodecPreferenceOrderTableView)
	{
		NSColor *colorToUse;
		XMPreferencesCodecListRecord *codecRecord = [currentLocation audioCodecListRecordAtIndex:rowIndex];
		if([codecRecord isEnabled])
		{
			colorToUse = [NSColor controlTextColor];
		}
		else
		{
			colorToUse = [NSColor disabledControlTextColor];
		}
		[aCell setTextColor:colorToUse];
		
		if([[aTableColumn identifier] isEqualToString:XMKey_EnabledIdentifier])
		{
			XMCodec *codec = [[XMCodecManager sharedInstance] codecForIdentifier:[codecRecord identifier]];
			[(XMBooleanCell *)aCell setDoesPopUp:[codec canDisable]];
			
		}
	}
	if(tableView == videoCodecPreferenceOrderTableView)
	{
		NSColor *colorToUse;
		XMPreferencesCodecListRecord *codecRecord = [currentLocation videoCodecListRecordAtIndex:rowIndex];
		if([codecRecord isEnabled])
		{
			colorToUse = [NSColor controlTextColor];
		}
		else
		{
			colorToUse = [NSColor disabledControlTextColor];
		}
		[aCell setTextColor:colorToUse];
		
		if([[aTableColumn identifier] isEqualToString:XMKey_EnabledIdentifier])
		{
			XMCodec *codec = [[XMCodecManager sharedInstance] codecForIdentifier:[codecRecord identifier]];
			[(XMBooleanCell *)aCell setDoesPopUp:[codec canDisable]];
			
		}
	}
}

#pragma mark -
#pragma mark Sheet Modal Delegate Methods

- (void)_newLocationSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode context:(void *)context
{
	if(returnCode == NSOKButton)
	{
		NSString *name = [newLocationNameField stringValue];
		
		XMLocation *location = [[XMLocation alloc] initWithName:name];
		[self _addLocation:location];
		[location release];
	}
}

#pragma mark -
#pragma mark Notification Responding Methods

- (void)_didStartFetchingExternalAddress:(NSNotification *)notif
{
	isFetchingExternalAddress = YES;
}

- (void)_didEndFetchingExternalAddress:(NSNotification *)notif
{
	isFetchingExternalAddress = NO;
	[self _validateExternalAddressUserInterface];
}

- (void)_importLocationsAssistantDidEndWithLocations:(NSArray *)theLocations
										h323Accounts:(NSArray *)h323Accounts
										 sipAccounts:(NSArray *)sipAccounts
{
	[accountModule addH323Accounts:h323Accounts];
	[accountModule addSIPAccounts:sipAccounts];
	[self noteAccountsDidChange];
	
	unsigned count = [theLocations count];
	unsigned i;
	
	unsigned index = [locations count];
	
	// check for name collisions
	for(i = 0; i < count; i++)
	{
		XMLocation *location = [theLocations objectAtIndex:i];
		NSString *name = [location name];
		
		unsigned existingCount = [locations count];
		unsigned j;
		
		for(j = 0; j < existingCount; j++)
		{
			XMLocation *testLocation = [locations objectAtIndex:j];
			
			if([[testLocation name] isEqualToString:name])
			{
				name = [name stringByAppendingString:@" 1"];
				[location setName:name];
				j = 0;
			}
		}
		
		[locations addObject:location];
	}
	
	if(count != 0)
	{
		// validate the GUI
		NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
		[locationsTableView reloadData];
		[locationsTableView selectRowIndexes:indexSet byExtendingSelection:NO];
		[sectionsTab selectFirstTabViewItem:self];
		[self _validateLocationButtonUserInterface];
		
		[self defaultAction:self];
	}
}

#pragma mark -
#pragma mark Misc Methods

- (void)_alertLocationName
{
	NSAlert *alert = [[NSAlert alloc] init];
				
	[alert setMessageText:NSLocalizedString(@"XM_LOCATION_PREFERENCES_NAME_EXISTS", @"")];
	[alert setInformativeText:NSLocalizedString(@"XM_PREFERENCES_NAME_SUGGESTION", @"")];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
			
	[alert runModal];
	
	[alert release];
}

- (void)_alertNoProtocolEnabled:(XMLocation *)location
{
	NSAlert *alert = [[NSAlert alloc] init];
				
	[alert setMessageText:NSLocalizedString(@"XM_LOCATION_PREFERENCES_NO_PROTOCOL_ENABLED", @"")];
	
	NSString *infoText = [[NSString alloc] initWithFormat:NSLocalizedString(@"XM_LOCATION_PREFERENCES_NO_PROTOCOL_ENABLED_INFO", @""), [location name]];
	[alert setInformativeText:infoText];
	[infoText release];
	
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
	
	[alert runModal];
	
	[alert release];
}

@end
