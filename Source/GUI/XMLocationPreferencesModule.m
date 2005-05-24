/*
 * $Id: XMLocationPreferencesModule.m,v 1.4 2005/05/24 15:21:02 hfriederich Exp $
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
- (void)_validateVideoTransmitUserInterface;
- (void)_validateVideoOrderUserInterface;

// table view source methods
- (int)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)column row:(int)rowIndex;
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;

// modal delegate methods
- (void)_newLocationSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode context:(void *)context;
- (void)_deleteLocationAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode context:(void *)context;

@end

@implementation XMLocationPreferencesModule

- (id)init
{
	prefWindowController = [[XMPreferencesWindowController sharedInstance] retain];
	
	locations = [[NSMutableArray alloc] initWithCapacity:3];
	
	return self;
}

- (void)awakeFromNib
{
	contentViewHeight = [contentView frame].size.height;
	[prefWindowController addPreferencesModule:self];
	
	XMBooleanCell *cell = [[XMBooleanCell alloc] init];
	
	NSTableColumn *column = [audioCodecPreferenceOrderTableView tableColumnWithIdentifier:XMKey_CodecIsEnabled];
	[column setDataCell:cell];
	[audioCodecPreferenceOrderTableView setRowHeight:16];
	
	column = [videoCodecPreferenceOrderTableView tableColumnWithIdentifier:XMKey_CodecIsEnabled];
	[column setDataCell:cell];
	[videoCodecPreferenceOrderTableView setRowHeight:16];
	
	[cell release];
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

- (IBAction)toggleEnableVideoTransmit:(id)sender
{
	[self _validateVideoTransmitUserInterface];
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
	
	[minTCPPortField setIntValue:[currentLocation tcpPortMin]];
	[maxTCPPortField setIntValue:[currentLocation tcpPortMax]];
	[minUDPPortField setIntValue:[currentLocation udpPortMin]];
	[maxUDPPortField setIntValue:[currentLocation udpPortMax]];
	
	// load the H.323 section
	state = ([currentLocation h323IsEnabled] == YES) ? NSOnState : NSOffState;
	[enableH323Switch setState:state];
	
	state = ([currentLocation h323EnableH245Tunnel] == YES) ? NSOnState : NSOffState;
	[enableH245TunnelSwitch setState:state];
	
	state = ([currentLocation h323EnableFastStart] == YES) ? NSOnState : NSOffState;
	[enableFastStartSwitch setState:state];
	
	state = ([currentLocation h323UseGatekeeper] == YES) ? NSOnState : NSOffState;
	[useGatekeeperSwitch setState:state];
	
	string = [currentLocation h323GatekeeperAddress];
	if(!string)
	{
		string = @"";
	}
	[gatekeeperHostField setStringValue:string];
	
	string = [currentLocation h323GatekeeperID];
	if(!string)
	{
		string = @"";
	}
	[gatekeeperIDField setStringValue:string];
	
	string = [currentLocation h323GatekeeperUsername];
	if(!string)
	{
		string = @"";
	}
	[gatekeeperUserAliasField setStringValue:string];
	
	string = [currentLocation h323GatekeeperE164Number];
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
	state = ([currentLocation enableVideoReceive] == YES) ? NSOnState : NSOffState;
	[enableVideoReceiveSwitch setState:state];
	
	state = ([currentLocation sendVideo] == YES) ? NSOnState : NSOffState;
	[enableVideoTransmitSwitch setState:state];
	
	[videoFrameRateField setIntValue:[currentLocation sendFPS]];
	
	state = [currentLocation videoSize];
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
	[self _validateVideoTransmitUserInterface];
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
	
	[currentLocation setTCPPortMin:[minTCPPortField intValue]];
	[currentLocation setTCPPortMax:[maxTCPPortField intValue]];
	[currentLocation setUDPPortMin:[minUDPPortField intValue]];
	[currentLocation setUDPPortMax:[maxUDPPortField intValue]];
	
	// saving the H.323 section
	flag = ([enableH323Switch state] == NSOnState) ? YES : NO;
	[currentLocation setH323IsEnabled:flag];
	
	flag = ([enableH245TunnelSwitch state] == NSOnState) ? YES : NO;
	[currentLocation setH323EnableH245Tunnel:flag];
	
	flag = ([enableFastStartSwitch state] == NSOnState) ? YES : NO;
	[currentLocation setH323EnableFastStart:flag];
	
	flag = ([useGatekeeperSwitch state] == NSOnState) ? YES : NO;
	[currentLocation setH323UseGatekeeper:flag];
	
	string = [gatekeeperHostField stringValue];
	if([string isEqualToString:@""])
	{
		string = nil;
	}
	[currentLocation setH323GatekeeperAddress:string];
	
	string = [gatekeeperIDField stringValue];
	if([string isEqualToString:@""])
	{
		string = nil;
	}
	[currentLocation setH323GatekeeperID:string];
	
	string = [gatekeeperUserAliasField stringValue];
	if([string isEqualToString:@""])
	{
		string = nil;
	}
	[currentLocation setH323GatekeeperUsername:string];
	
	string = [gatekeeperPhoneNumberField stringValue];
	if([string isEqualToString:@""])
	{
		string = nil;
	}
	[currentLocation setH323GatekeeperE164Number:string];
	
	// saving the SIP section
	
	// saving the audio section
	[currentLocation setAudioBufferSize:[audioBufferSizeSlider intValue]];
	
	// saving the video section
	flag = ([enableVideoReceiveSwitch state] == NSOnState) ? YES : NO;
	[currentLocation setEnableVideoReceive:flag];
	
	flag = ([enableVideoTransmitSwitch state] == NSOnState) ? YES : NO;
	[currentLocation setSendVideo:flag];
	
	[currentLocation setSendFPS:[videoFrameRateField intValue]];
	
	XMVideoSize size = ([videoSizePopUp indexOfSelectedItem] == 0) ? XMVideoSize_CIF : XMVideoSize_QCIF;
	[currentLocation setVideoSize:size];
}

- (void)_validateLocationButtonUserInterface
{
	BOOL flag = ([locations count] == 1) ? NO : YES;
	[deleteLocationButton setEnabled:flag];
	
	[importLocationsButton setEnabled:NO];
}

- (void)_validateAddressTranslationUserInterface
{
	BOOL flag = ([useIPAddressTranslationSwitch state] == NSOnState) ? YES : NO;
	
	[externalAddressField setEnabled:flag];
	[autoGetExternalAddressSwitch setEnabled:flag];
	
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

- (void)_validateVideoTransmitUserInterface
{
	BOOL flag = ([enableVideoTransmitSwitch state] == NSOnState) ? YES : NO;
	
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
	
	NSString *identifier = [column identifier];
	XMCodecListRecord *record;
	
	if(tableView == audioCodecPreferenceOrderTableView)
	{
		record = [currentLocation audioCodecListRecordAtIndex:rowIndex];
	}
	else if(tableView == videoCodecPreferenceOrderTableView)
	{
		record = [currentLocation videoCodecListRecordAtIndex:rowIndex];
	}
	
	if([identifier isEqualToString:XMKey_CodecIsEnabled])
	{
		return [NSNumber numberWithBool:[record isEnabled]];
	}
	
	XMCodecDescriptor *codecDescriptor = [[XMCodecManager sharedInstance] codecDescriptorForKey:[record key]];
	return [codecDescriptor propertyForKey:identifier];
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
		[[currentLocation audioCodecListRecordAtIndex:rowIndex] setIsEnabled:[anObject boolValue]];
		[audioCodecPreferenceOrderTableView reloadData];
	}
	
	if(tableView == videoCodecPreferenceOrderTableView)
	{
		[[currentLocation videoCodecListRecordAtIndex:rowIndex] setIsEnabled:[anObject boolValue]];
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

@end
