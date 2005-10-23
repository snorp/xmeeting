/*
 * $Id: XMLocationPreferencesModule.m,v 1.9 2005/10/23 19:59:00 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMLocationPreferencesModule.h"
#import "XMPreferencesWindowController.h"
#import "XMPreferencesManager.h"
#import "XMLocation.h"
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
- (void)_validateAddressTranslationUserInterface;
- (void)_validateExternalAddressUserInterface;
- (void)_validateH323UserInterface;
- (void)_validateGatekeeperUserInterface;
- (void)_validateAudioOrderUserInterface;
- (void)_validateVideoUserInterface;
- (void)_validateVideoOrderUserInterface;

// table view source methods
- (int)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)column row:(int)rowIndex;
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;

// modal delegate methods
- (void)_newLocationSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode context:(void *)context;
- (void)_deleteLocationAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode context:(void *)context;

// notification responding
- (void)_didEndFetchingExternalAddress:(NSNotification *)notif;

@end

@implementation XMLocationPreferencesModule

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
												 name:XMNotification_UtilsDidStartFetchingExternalAddress object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didEndFetchingExternalAddress:)
												 name:XMNotification_UtilsDidEndFetchingExternalAddress object:nil];
	
	XMUtils *utils = [XMUtils sharedInstance];
	if([utils didSucceedFetchingExternalAddress] && [utils externalAddress] == nil)
	{
		// in this case, the external address has not yet been fetched, thus
		// we start fetching the address
		[utils startFetchingExternalAddress];
		isFetchingExternalAddress = YES;
	}
}

- (void)dealloc
{
	[prefWindowController release];
	[locations release];
	
	[super dealloc];
}

#pragma mark XMPreferencesModule protocol methdos

- (unsigned)position
{
	return 1;
}

- (NSString *)identifier
{
	return XMKey_LocationPreferencesModuleIdentifier;
}

- (NSString *)toolbarLabel
{
	return NSLocalizedString(@"Locations", @"LocationPreferencesModuleLabel");
}

- (NSImage *)toolbarImage
{
	return nil;
}

- (NSString *)toolTipText
{
	return NSLocalizedString(@"Edit the Locations", @"LocationPreferencesModuleToolTip");
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
	// replacing the locations with a fresh set
	[locations removeAllObjects];
	[locations addObjectsFromArray:[[XMPreferencesManager sharedInstance] locations]];
	
	// making sure that there is no wrong data saved
	currentLocation = nil;
	
	// causing the table view to reload its data and select the first item
	NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:0];
	[locationsTableView selectRowIndexes:indexSet byExtendingSelection:NO];
	[locationsTableView reloadData];
	
	// validating the location buttons
	[self _validateLocationButtonUserInterface];
	
	// displaying the first tab item at the start
	[sectionsTab selectFirstTabViewItem:self];
}

- (void)savePreferences
{
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
	
	// then, give the changed locations to XMPreferencesManager
	[[XMPreferencesManager sharedInstance] setLocations:locations];
}

#pragma mark User Interface Methods

- (IBAction)defaultAction:(id)sender
{
	[prefWindowController notePreferencesDidChange];
}

- (IBAction)createNewLocation:(id)sender
{
	[newLocationNameField setStringValue:NSLocalizedString(@"New Location", @"New Location Name")];
	[newLocationNameField selectText:self];
	
	// we obtain the window through the NSView's -window method
	[NSApp beginSheet:newLocationSheet modalForWindow:[sectionsTab window] modalDelegate:self
	   didEndSelector:@selector(_newLocationSheetDidEnd:returnCode:context:) contextInfo:NULL];
}

- (IBAction)importLocations:(id)sender
{
}

- (IBAction)duplicateLocation:(id)sender
{
	unsigned index = [locations count];
	
	NSString *currentLocationName = [currentLocation name];
	NSString *newName = [currentLocationName stringByAppendingString:NSLocalizedString(@" Copy", @"LocationCopySuffix")];
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

- (IBAction)toggleUseAddressTranslation:(id)sender
{
	[self _validateAddressTranslationUserInterface];
	[self defaultAction:self];
}

- (IBAction)getExternalAddress:(id)sender
{
	XMUtils *utils = [XMUtils sharedInstance];
	
	[utils startFetchingExternalAddress];
	
	[externalAddressField setStringValue:NSLocalizedString(@"Fetching...", @"")];
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

- (IBAction)toggleUseGatekeeper:(id)sender
{
	[self _validateGatekeeperUserInterface];
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
	[audioCodecPreferenceOrderTableView selectRowIndexes:indexSet byExtendingSelection:NO];
	
	[self defaultAction:self];
}

- (IBAction)endNewLocationSheet:(id)sender
{
	int returnCode;
	
	if(sender == newLocationOKButton)
	{
		returnCode = NSOKButton;
	}
	else
	{
		returnCode = NSCancelButton; 
	}
	
	[NSApp endSheet:newLocationSheet returnCode:returnCode];
	[newLocationSheet orderOut:self];
}

#pragma mark delegate methods

- (void)controlTextDidChange:(NSNotification *)notif
{
	// we simply want the same effect as the default action.
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
		if([[currentLocation audioCodecListRecordAtIndex:rowIndex] isEnabled])
		{
			colorToUse = [NSColor controlTextColor];
		}
		else
		{
			colorToUse = [NSColor disabledControlTextColor];
		}
		[aCell setTextColor:colorToUse];
	}
	if(tableView == videoCodecPreferenceOrderTableView)
	{
		NSColor *colorToUse;
		if([[currentLocation videoCodecListRecordAtIndex:rowIndex] isEnabled])
		{
			colorToUse = [NSColor controlTextColor];
		}
		else
		{
			colorToUse = [NSColor disabledControlTextColor];
		}
		[aCell setTextColor:colorToUse];
	}
}


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

#pragma mark Load & Save a Location

- (void)_loadCurrentLocation
{
	int state;
	NSString *string;
	
	// load the Network section
	unsigned bandwidth = [currentLocation bandwidthLimit];
	unsigned index = [bandwidthLimitPopUp indexOfItemWithTag:bandwidth];
	[bandwidthLimitPopUp selectItemAtIndex:index];
	
	state = ([currentLocation useAddressTranslation] == YES) ? NSOnState : NSOffState;
	[useIPAddressTranslationSwitch setState:state];
	
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
	
	state = ([currentLocation useGatekeeper] == YES) ? NSOnState : NSOffState;
	[useGatekeeperSwitch setState:state];
	
	string = [currentLocation gatekeeperAddress];
	if(!string)
	{
		string = @"";
	}
	[gatekeeperHostField setStringValue:string];
	
	string = [currentLocation gatekeeperID];
	if(!string)
	{
		string = @"";
	}
	[gatekeeperIDField setStringValue:string];
	
	string = [currentLocation gatekeeperUsername];
	if(!string)
	{
		string = @"";
	}
	[gatekeeperUserAliasField setStringValue:string];
	
	string = [currentLocation gatekeeperPhoneNumber];
	if(!string)
	{
		string = @"";
	}
	[gatekeeperPhoneNumberField setStringValue:string];
	
	// loading the SIP section
	
	// loading the Audio section
	[audioBufferSizeSlider setIntValue:[currentLocation audioBufferSize]];
	[audioCodecPreferenceOrderTableView reloadData];
	
	// loading the Video section
	state = ([currentLocation enableVideo] == YES) ? NSOnState : NSOffState;
	[enableVideoSwitch setState:state];
	
	[videoFrameRateField setIntValue:[currentLocation videoFramesPerSecond]];
	
	state = [currentLocation preferredVideoSize];
	if(state == XMVideoSize_QCIF)
	{
		state = 1;
	}
	else
	{
		state = 0;
	}
	[videoSizePopUp selectItemAtIndex:state];
	
	[videoCodecPreferenceOrderTableView reloadData];
	
	// finally, it's time to validate some GUI-Elements
	[self _validateAddressTranslationUserInterface];
	[self _validateExternalAddressUserInterface];
	[self _validateH323UserInterface];
	[self _validateAudioOrderUserInterface];
	[self _validateVideoUserInterface];
	[self _validateVideoOrderUserInterface];
}

- (void)_saveCurrentLocation
{
	BOOL flag;
	NSString *string;
	
	// saving the network section
	[currentLocation setBandwidthLimit:[[bandwidthLimitPopUp selectedItem] tag]];
	
	flag = ([useIPAddressTranslationSwitch state] == NSOnState) ? YES : NO;
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
	
	flag = ([useGatekeeperSwitch state] == NSOnState) ? YES : NO;
	[currentLocation setUseGatekeeper:flag];
	
	string = [gatekeeperHostField stringValue];
	if([string isEqualToString:@""])
	{
		string = nil;
	}
	[currentLocation setGatekeeperAddress:string];
	
	string = [gatekeeperIDField stringValue];
	if([string isEqualToString:@""])
	{
		string = nil;
	}
	[currentLocation setGatekeeperID:string];
	
	string = [gatekeeperUserAliasField stringValue];
	if([string isEqualToString:@""])
	{
		string = nil;
	}
	[currentLocation setGatekeeperUsername:string];
	
	string = [gatekeeperPhoneNumberField stringValue];
	if([string isEqualToString:@""])
	{
		string = nil;
	}
	[currentLocation setGatekeeperPhoneNumber:string];
	
	// saving the SIP section
	
	// saving the audio section
	[currentLocation setAudioBufferSize:[audioBufferSizeSlider intValue]];
	
	// saving the video section
	flag = ([enableVideoSwitch state] == NSOnState) ? YES : NO;
	[currentLocation setEnableVideo:flag];
	
	[currentLocation setVideoFramesPerSecond:[videoFrameRateField intValue]];
	
	XMVideoSize size = ([videoSizePopUp indexOfSelectedItem] == 0) ? XMVideoSize_CIF : XMVideoSize_QCIF;
	[currentLocation setPreferredVideoSize:size];
}

#pragma mark validate the user interface

- (void)_validateLocationButtonUserInterface
{
	BOOL flag = ([locations count] == 1) ? NO : YES;
	[deleteLocationButton setEnabled:flag];
	
	[importLocationsButton setEnabled:NO];
}

- (void)_validateAddressTranslationUserInterface
{
	BOOL flag = ([useIPAddressTranslationSwitch state] == NSOnState) ? YES : NO;
	
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
		NSString *externalAddress = [utils externalAddress];
		NSString *displayString;
		
		if(externalAddress == nil)
		{
			if(isFetchingExternalAddress)
			{
				displayString = NSLocalizedString(@"Fetching...", @"");
			}
			else
			{
				displayString = NSLocalizedString(@"<Not available>", @"");
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
	[useGatekeeperSwitch setEnabled:flag];
	
	if(flag)	// the interface is active and we have to separately validate the gatekeeper GUI
	{
		[self _validateGatekeeperUserInterface];
	}
	else
	{
		[gatekeeperHostField setEnabled:NO];
		[gatekeeperIDField setEnabled:NO];
		[gatekeeperUserAliasField setEnabled:NO];
		[gatekeeperPhoneNumberField setEnabled:NO];
	}
}

- (void)_validateGatekeeperUserInterface
{
	// we are guaranteed that H.323 is enabled
	BOOL flag = ([useGatekeeperSwitch state] == NSOnState) ? YES : NO;
	
	[gatekeeperHostField setEnabled:flag];
	[gatekeeperIDField setEnabled:flag];
	[gatekeeperUserAliasField setEnabled:flag];
	[gatekeeperPhoneNumberField setEnabled:flag];
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
	[videoSizePopUp setEnabled:flag];
}

- (void)_validateVideoOrderUserInterface
{
	unsigned count = [currentLocation videoCodecListCount];
	int selectedRow = [videoCodecPreferenceOrderTableView selectedRow];
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
	
	[moveVideoCodecUpButton setEnabled:enableUp];
	[moveVideoCodecDownButton setEnabled:enableDown];
}

#pragma mark tableViewSource methods

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
	
	XMCodec *codec = [[XMCodecManager sharedInstance] codecForIdentifier:[record identifier]];
	return [codec propertyForKey:columnIdentifier];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if(tableView == locationsTableView)
	{
		if([anObject isKindOfClass:[NSString class]])
		{
			[(XMLocation *)[locations objectAtIndex:rowIndex] setName:(NSString *)anObject];
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

@end
