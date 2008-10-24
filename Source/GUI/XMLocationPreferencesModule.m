/*
 * $Id: XMLocationPreferencesModule.m,v 1.36 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
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
#import "XMIPAddressFormatter.h"
#import "XMIDDPrefixFormatter.h"

#define XM_RENAME_TAG 50
#define XM_DUPLICATE_TAG 51

#define TABLE_FONT_SIZE 13

NSString *XMKey_LocationPreferencesModuleIdentifier = @"XMeeting_LocationPreferencesModule";

NSString *XMKey_InitialNameIdentifier = @"Name";
NSString *XMKey_InitialBandwidthIdentifier = @"Bandwidth";
NSString *XMKey_InitialQualityIdentifier = @"Quality";
NSString *XMKey_EnabledIdentifier = @"Enabled";

NSString *XMKey_SIPAccountNameIdentifier = @"name";
NSString *XMKey_SIPAccountDomainIdentifier = @"domain";
NSString *XMKey_SIPAccountEnabledIdentifier = @"enabled";

@interface XMSIPAccountInfo : NSObject {
  unsigned tag;
  BOOL enabled;
}

- (id)_initWithTag:(unsigned)tag enabled:(BOOL)enabled;
- (unsigned)tag;
- (void)setTag:(unsigned)tag;
- (BOOL)enabled;
- (void)setEnabled:(BOOL)flag;

@end

@interface XMMultipleLocationsWrapper : XMLocation {
  NSArray *locations;
}

- (id)_initWithLocations:(NSArray *)locations;
- (NSObject *)_valueForKey:(NSString *)key;
- (NSObject *)_valueForKey:(NSString *)key checkNil:(BOOL)checkNil nilObject:(NSObject *)nilObject;
- (void)_setValue:(NSObject *)value forKey:(NSString *)key;

@end

@interface XMLocationPreferencesModule (PrivateMethods)

// delegate methods
- (void)controlTextDidChange:(NSNotification *)notif;

  // adding new locations
- (void)_addLocation:(XMLocation *)location;

  // loading and saving the current selected location
- (void)_loadCurrentLocation;
- (void)_saveCurrentLocation;

- (void)_setUnsignedInt:(unsigned)value forTextField:(NSTextField *)textField;
- (unsigned)_extractUnsignedIntFromTextField:(NSTextField *)textField;

- (void)_setState:(NSNumber *)state forSwitch:(NSButton *)button;
- (NSNumber *)_extractStateFromSwitch:(NSButton *)button;

- (void)_setTag:(unsigned)tag forPopUp:(NSPopUpButton *)popUpButton;
- (unsigned)_extractTagFromPopUp:(NSPopUpButton *)popUpButton;

- (void)_setTag:(unsigned)tag forNonePopUp:(NSPopUpButton *)popUpButton;
- (unsigned)_extractTagFromPopUp:(NSPopUpButton *)popUpButton;

- (void)_setString:(NSString *)string forTextField:(NSTextField *)textField;
- (NSString *)_extractStringFromTextField:(NSTextField *)textField;

- (void)_updateGatekeeperAccountInfo;

  // user interface validation methods
- (void)_validateLocationButtonUserInterface;
- (void)_validateExternalAddressUserInterface;
- (void)_validateSTUNUserInterface;
- (void)_validateH323UserInterface;
- (void)_validateSIPUserInterface;
- (void)_validateSIPAccountsUserInterface;
- (void)_validateSIPProxyUserInterface;
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

- (void)_didUpdateNetworkInformation:(NSNotification *)notif;

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
  multipleLocationsWrapper = nil;
  
  stunServers = nil;
  sipAccounts = nil;
  audioCodecs = nil;
  videoCodecs = nil;
  
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
  tableColumn = [audioCodecPreferenceOrderTableView tableColumnWithIdentifier:XMKey_EnabledIdentifier];
  [[tableColumn dataCell] setControlSize:NSSmallControlSize];
  
  tableColumn = [videoCodecPreferenceOrderTableView tableColumnWithIdentifier:XMKey_InitialNameIdentifier];
  [tableColumn setIdentifier:XMKey_CodecName];
  tableColumn = [videoCodecPreferenceOrderTableView tableColumnWithIdentifier:XMKey_InitialBandwidthIdentifier];
  [tableColumn setIdentifier:XMKey_CodecBandwidth];
  tableColumn = [videoCodecPreferenceOrderTableView tableColumnWithIdentifier:XMKey_InitialQualityIdentifier];
  [tableColumn setIdentifier:XMKey_CodecQuality];
  tableColumn = [videoCodecPreferenceOrderTableView tableColumnWithIdentifier:XMKey_EnabledIdentifier];
  [[tableColumn dataCell] setControlSize:NSSmallControlSize];
  
  // adjusting the autoresizing behaviour of the two codec tables
  [audioCodecPreferenceOrderTableView setColumnAutoresizingStyle:NSTableViewLastColumnOnlyAutoresizingStyle];
  [videoCodecPreferenceOrderTableView setColumnAutoresizingStyle:NSTableViewLastColumnOnlyAutoresizingStyle];
  [audioCodecPreferenceOrderTableView setRowHeight:16];
  [videoCodecPreferenceOrderTableView setRowHeight:16];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didUpdateNetworkInformation:)
                                               name:XMNotification_UtilsDidUpdateNetworkInformation object:nil];
  
  [actionButton sendActionOn:NSLeftMouseDownMask];
  [actionPopup selectItem: nil];
  
  [publicAddressField setFormatter:[[[XMIPAddressFormatter alloc] init] autorelease]];
  [internationalDialingPrefixField setFormatter:[[[XMIDDPrefixFormatter alloc] init] autorelease]];
  
}

- (void)dealloc
{
  [prefWindowController release];
  [locations release];
  [stunServers release];
  [sipAccounts release];
  [audioCodecs release];
  [videoCodecs release];
  
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
  
  // making sure that there is no wrong data saved
  currentLocation = nil;
  
  // preparing the h323 and SIP account pop up buttons
  [self noteAccountsDidChange];
  
  // causing the table view to reload its data and select the first item
  [locationsTableView selectAll:self];
  
  // validating the location buttons
  [self _validateLocationButtonUserInterface];
  
  // displaying the first tab item at the start
  [sectionsTab selectFirstTabViewItem:self];
}

- (void)savePreferences
{
  XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
  
  // in case that the locations table view is editing a location's name,
  // we have to store that value as well
  unsigned index = [locationsTableView editedRow];
  if(index != -1)
  {
    NSCell *cell = [locationsTableView selectedCell];
    NSText *text = [locationsTableView currentEditor];
    [cell endEditing:text];
  }
  
  // first, save the current location
  [self _saveCurrentLocation];
  
  // pass the changed locations to the preferences manager
  [preferencesManager setLocations:locations];
}

- (void)becomeActiveModule
{
  [[locationsTableView window] makeFirstResponder:locationsTableView];
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
  unsigned count = [locations count];
  
  NSString *currentLocationName = [currentLocation name];
  NSString *newName = [currentLocationName stringByAppendingString:NSLocalizedString(@"XM_LOCATION_PREFERENCES_COPY_SUFFIX", @"")];
  XMLocation *duplicate = [currentLocation duplicateWithName:newName];
  
  [self _addLocation:duplicate];
  [duplicate release];
  
  [locationsTableView editColumn:0 row:count withEvent:nil select:YES];
}

- (IBAction)deleteLocation:(id)sender
{
  unsigned index = [locations indexOfObject:currentLocation];
  
  if (index == NSNotFound) {
    return;
  }
  
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

- (IBAction)selectAllLocations:(id)sender
{
  [locationsTableView selectAll:sender];
}

- (IBAction)renameLocation:(id)sender
{
  unsigned index = [locations indexOfObject:currentLocation];
  if (index == NSNotFound) {
    return;
  }
  
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

- (IBAction)toggleAutoGetExternalAddress:(id)sender
{
  [self _validateExternalAddressUserInterface];
  [autoGetExternalAddressSwitch setAllowsMixedState:NO];
  [self defaultAction:self];
}

- (IBAction)addSTUNServer:(id)sender
{
  unsigned count = [stunServers count];
  [stunServers addObject:@"<>"];
  [stunServersTable reloadData];
  NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:count];
  [stunServersTable selectRowIndexes:indexSet byExtendingSelection:NO];
  [stunServersTable editColumn:0 row:count withEvent:nil select:YES];
  [self _validateSTUNUserInterface];
  [self defaultAction:self];
}

- (IBAction)removeSTUNServer:(id)sender
{
  if (stunServers != nil) {
    int selectedRow = [stunServersTable selectedRow];
    if (selectedRow != -1) {
      [stunServers removeObjectAtIndex:selectedRow];
    }
    [stunServersTable reloadData];
    [self _validateSTUNUserInterface];
  [self defaultAction:self];
  }
}

- (IBAction)moveSTUNServerUp:(id)sender
{
  int selectedRow = [stunServersTable selectedRow];
  if (selectedRow != -1) {
    [stunServers exchangeObjectAtIndex:selectedRow withObjectAtIndex:(selectedRow-1)];
    NSIndexSet *rows = [NSIndexSet indexSetWithIndex:(selectedRow-1)];
    [stunServersTable selectRowIndexes:rows byExtendingSelection:NO];
    [stunServersTable reloadData];
    [self _validateSTUNUserInterface];
    [self defaultAction:self];
  }
}

- (IBAction)moveSTUNServerDown:(id)sender
{
  int selectedRow = [stunServersTable selectedRow];
  if (selectedRow != -1) {
    [stunServers exchangeObjectAtIndex:selectedRow withObjectAtIndex:(selectedRow+1)];
    NSIndexSet *rows = [NSIndexSet indexSetWithIndex:(selectedRow+1)];
    [stunServersTable selectRowIndexes:rows byExtendingSelection:NO];
    [stunServersTable reloadData];
    [self _validateSTUNUserInterface];
    [self defaultAction:self];
  }
}

- (IBAction)overwriteSTUNServers:(id)sender
{
  stunServers = [XMDefaultSTUNServers() mutableCopy];
  [self _validateSTUNUserInterface];
  [self defaultAction:self];
}

- (IBAction)toggleEnableH323:(id)sender
{
  [self _validateH323UserInterface];
  [self defaultAction:self];
}

- (IBAction)gatekeeperAccountSelected:(id)sender
{
  [self _updateGatekeeperAccountInfo];
  
  [self defaultAction:self];
}

- (IBAction)toggleEnableSIP:(id)sender
{
  [self _validateSIPUserInterface];
  [self defaultAction:self];
}

- (IBAction)makeDefaultSIPAccount:(id)sender
{
  unsigned selectedRow = [sipAccountsTable selectedRow];
  if (selectedRow != -1) {
    [(XMSIPAccountInfo *)[sipAccounts objectAtIndex:selectedRow] setEnabled:YES];
    defaultSIPAccountIndex = selectedRow;
    [sipAccountsTable reloadData];
    [self defaultAction:self];
  }
}

- (IBAction)overwriteSIPAccounts:(id)sender
{
  [sipAccounts release];
  
  unsigned count = [accountModule sipAccountCount];
  unsigned i;
  sipAccounts = [[NSMutableArray alloc] initWithCapacity:count];
  for (i = 0; i < count; i++) {
    XMSIPAccount *account = [accountModule sipAccountAtIndex:i];
    [sipAccounts addObject:[[[XMSIPAccountInfo alloc] _initWithTag:[account tag] enabled:NO] autorelease]];
  }
  defaultSIPAccountIndex = UINT_MAX-1;
  [self _validateSIPAccountsUserInterface];
  [self defaultAction:self];
}

- (IBAction)sipProxySelected:(id)sender
{
  [self _validateSIPProxyUserInterface];
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
  [audioCodecs exchangeObjectAtIndex:rowIndex withObjectAtIndex:newIndex];
  [currentLocation audioCodecListExchangeRecordAtIndex:rowIndex withRecordAtIndex:newIndex];
  [audioCodecPreferenceOrderTableView reloadData];
  
  NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:newIndex];
  [audioCodecPreferenceOrderTableView selectRowIndexes:indexSet byExtendingSelection:NO];
  
  [self defaultAction:self];
}

- (IBAction)overwriteAudioCodecs:(id)sender
{
  [currentLocation resetAudioCodecs];
  [audioCodecs release];
  NSArray *codecs = [currentLocation audioCodecList];
  if ((NSObject *)codecs != [NSNull null]) {
    audioCodecs = [codecs mutableCopy];
  } else {
    audioCodecs = nil;
  }
  [self _validateAudioOrderUserInterface];
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
  [videoCodecs exchangeObjectAtIndex:rowIndex withObjectAtIndex:newIndex];
  [currentLocation videoCodecListExchangeRecordAtIndex:rowIndex withRecordAtIndex:newIndex];
  [videoCodecPreferenceOrderTableView reloadData];
  
  NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:newIndex];
  [videoCodecPreferenceOrderTableView selectRowIndexes:indexSet byExtendingSelection:NO];
  
  [self defaultAction:self];
}

- (IBAction)overwriteVideoCodecs:(id)sender
{
  [currentLocation resetVideoCodecs];
  [videoCodecs release];
  NSArray *codecs = [currentLocation videoCodecList];
  if ((NSObject *)codecs != [NSNull null]) {
    videoCodecs = [codecs mutableCopy];
  } else {
    videoCodecs = nil;
  }
  [self _validateVideoOrderUserInterface];
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
  
  if(currentLocation != nil)
  {
    h323AccountTag = [[h323AccountsPopUp selectedItem] tag];
  }
  
  /* updating the H323 accounts Pop Up */
  BOOL hasMultiItem = NO;
  if ([[h323AccountsPopUp itemAtIndex:0] tag] == -1) {
    hasMultiItem = YES;
  }
  
  [h323AccountsPopUp removeAllItems];
  NSMenu *menu = [h323AccountsPopUp menu];
  
  if (hasMultiItem) {
    NSMenuItem *multiItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"XM_LOCATION_PREFERENCES_MULTIPLE_VALUES", @"")
                                                       action:NULL
                                                keyEquivalent:@""];
    [multiItem setTag:-1];
    [menu addItem:multiItem];
    [multiItem release];
  }
  
  NSMenuItem *noneItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"XM_LOCATION_PREFERENCES_NONE_ITEM", @"")
                                                    action:NULL
                                             keyEquivalent:@""];
  [noneItem setTag:0];
  [menu addItem:noneItem];
  [noneItem release];
  
  unsigned count = [accountModule h323AccountCount];
  unsigned i;
  
  if(count != 0) {
    [menu addItem:[NSMenuItem separatorItem]];
  }
  
  for(i = 0; i < count; i++)
  {
    XMH323Account *h323Account = [accountModule h323AccountAtIndex:i];
    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[h323Account name]
                                                      action:NULL keyEquivalent:@""];
    unsigned tag = [h323Account tag];
    [menuItem setTag:tag];
    if(tag == h323AccountTag) {
      h323AccountToSelect = (i+2);
    }
    [menu addItem:menuItem];
    [menuItem release];
  }
  
  // Updating the SIP account tag infos (if present)
  
  if (currentLocation != nil && sipAccounts != nil) {
    NSArray *oldAccounts = sipAccounts;
    count = [accountModule sipAccountCount];
    sipAccounts = [[NSMutableArray alloc] initWithCapacity:count];
    for (i = 0; i < count; i++) {
      XMSIPAccount *sipAccount = [accountModule sipAccountAtIndex:i];
      unsigned numInfos = [oldAccounts count];
      unsigned j;
      BOOL enabled = NO;
      for (j = 0; j < numInfos; j++) {
        XMSIPAccountInfo *info = (XMSIPAccountInfo *)[oldAccounts objectAtIndex:j];
        if ([info tag] == [sipAccount tag]) {
          enabled = [info enabled];
          break;
        }
      }
      [sipAccounts addObject:[[[XMSIPAccountInfo alloc] _initWithTag:[sipAccount tag] enabled:enabled] autorelease]];
    }
    [sipAccountsTable reloadData];
    [oldAccounts release];
  }
  
  // updating the SIP proxy Pop Up
  unsigned sipAccountToSelect = 0;
  unsigned sipAccountTag = 0;
  
  if(currentLocation != nil)
  {
    sipAccountTag = [[sipProxyPopUp selectedItem] tag];
  }
  if (sipAccountTag == XMCustomSIPProxyTag) {
    sipAccountToSelect = 1;
  }
  
  hasMultiItem = NO;
  if ([[sipProxyPopUp itemAtIndex:0] tag] == -1) {
    hasMultiItem = YES;
  }
  
  [sipProxyPopUp removeAllItems];
  menu = [sipProxyPopUp menu];
  
  if (hasMultiItem) {
    NSMenuItem *multiItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"XM_LOCATION_PREFERENCES_MULTIPLE_VALUES", @"")
                                                       action:NULL
                                                keyEquivalent:@""];
    [multiItem setTag:-1];
    [menu addItem:multiItem];
    [multiItem release];
  }  
  
  noneItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"XM_LOCATION_PREFERENCES_NONE_ITEM", @"")
                                        action:NULL
                                 keyEquivalent:@""];
  [noneItem setTag:0];
  [menu addItem:noneItem];
  [noneItem release];
  
  NSMenuItem *customItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"XM_LOCATION_PREFERENCES_CUSTOM_PROXY", @"")
                                                      action:NULL
                                               keyEquivalent:@""];
  [customItem setTag:XMCustomSIPProxyTag];
  [menu addItem:customItem];
  [customItem release];
  
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
      sipAccountToSelect = (i+3);
    }
    
    [menu addItem:menuItem];
    
    [menuItem release];
  }
  
  [h323AccountsPopUp selectItemAtIndex:h323AccountToSelect];
  [sipProxyPopUp selectItemAtIndex:sipAccountToSelect];
  
  [self gatekeeperAccountSelected:self];
  [self sipProxySelected:self];
}

#pragma mark -
#pragma mark delegate methods

- (void)controlTextDidChange:(NSNotification *)notif
{
  if ([notif object] == sipProxyPasswordField) {
    sipProxyPasswordDidChange = YES;
  }
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
  if(currentLocation)
  {
    [self _saveCurrentLocation];
  }
  
  NSIndexSet * selectedRows = [locationsTableView selectedRowIndexes];
  unsigned count = [selectedRows count];
  
  if (count == 1) {
    currentLocation = [locations objectAtIndex:[selectedRows firstIndex]];
  } else {
    [multipleLocationsWrapper release];
    
    NSMutableArray * selectedLocations = [[NSMutableArray alloc] initWithCapacity:count];
    unsigned index = [selectedRows firstIndex];
    
    while (index != NSNotFound) {
      [selectedLocations addObject:[locations objectAtIndex:index]];
      index = [selectedRows indexGreaterThanIndex:index];
    }
    
    multipleLocationsWrapper = [[XMMultipleLocationsWrapper alloc] _initWithLocations:selectedLocations];
    [selectedLocations release];
    
    currentLocation = multipleLocationsWrapper;
  }
    
  int state;
  NSObject *obj;
  NSNull *null = [NSNull null];
  
  // load the Network section
  unsigned bandwidth = [currentLocation bandwidthLimit];
  [self _setTag:bandwidth forPopUp:bandwidthLimitPopUp];
  
  obj = [currentLocation publicAddress];
  if(obj == nil)	// this means that the external address is automatically picked
  {
    state = NSOnState;
    obj = @"";
  }
  else
  {
    if ([obj isEqual:@""]) {
      state = NSMixedState;
      [(NSTextFieldCell *)[publicAddressField cell] setPlaceholderString:NSLocalizedString(@"XM_LOCATION_PREFERENCES_MULTIPLE_VALUES", @"")];
    } else {
      state = NSOffState;
      if (obj == null) {
        [(NSTextFieldCell *)[publicAddressField cell] setPlaceholderString:NSLocalizedString(@"XM_LOCATION_PREFERENCES_MULTIPLE_VALUES", @"")];
        obj = @"";
      }
    }
  }
  [publicAddressField setStringValue:(NSString *)obj];
  if (state == NSMixedState) {
    [autoGetExternalAddressSwitch setAllowsMixedState:YES];
  } else {
    [autoGetExternalAddressSwitch setAllowsMixedState:NO]; 
  }
  [autoGetExternalAddressSwitch setState:state];
  [autoGetExternalAddressSwitch setNeedsDisplay];
  
  [stunServers release];
  NSArray *servers = [currentLocation stunServers];
  if ((NSObject *)servers == null) {
    stunServers = nil;
  } else {
    stunServers = [servers mutableCopy];
  }
  [stunServersTable reloadData];
  
  [self _setUnsignedInt:[currentLocation tcpPortBase] forTextField:minTCPPortField];
  [self _setUnsignedInt:[currentLocation tcpPortMax] forTextField:maxTCPPortField];
  [self _setUnsignedInt:[currentLocation udpPortBase] forTextField:minUDPPortField];
  [self _setUnsignedInt:[currentLocation udpPortMax] forTextField:maxUDPPortField];
  
  // load the H.323 section
  [self _setState:[currentLocation enableH323Number] forSwitch:enableH323Switch];
  [self _setState:[currentLocation enableH245TunnelNumber] forSwitch:enableH245TunnelSwitch];
  [self _setState:[currentLocation enableFastStartNumber] forSwitch:enableFastStartSwitch];
  
  unsigned gatekeeperAccountTag = [currentLocation h323AccountTag];
  [self _setTag:gatekeeperAccountTag forNonePopUp:h323AccountsPopUp];
  
  // causing the account information to be displayed.
  [self _updateGatekeeperAccountInfo];
  
  // loading the SIP section
  [self _setState:[currentLocation enableSIPNumber] forSwitch:enableSIPSwitch];
  [sipAccounts release];
  defaultSIPAccountIndex = UINT_MAX;
  NSArray *sipAccountTags = [currentLocation sipAccountTags];
  unsigned  defaultSIPAccountTag = [currentLocation defaultSIPAccountTag];
  if ((NSObject *)sipAccountTags == [NSNull null]) {
    sipAccounts = nil;
  } else {
    NSArray *sipAccountRecords = [accountModule sipAccounts];
    unsigned numSIPAccounts = [sipAccountRecords count];
    sipAccounts = [[NSMutableArray alloc] initWithCapacity:numSIPAccounts];
    unsigned numTags = [sipAccountTags count];
    unsigned i, j;
    for (i = 0; i < numSIPAccounts; i++) {
      XMSIPAccount *account = (XMSIPAccount *)[sipAccountRecords objectAtIndex:i];
      unsigned _tag = [account tag];
      BOOL found = NO;
      for (j = 0; j < numTags; j++) {
        if (_tag == [(NSNumber *)[sipAccountTags objectAtIndex:j] unsignedIntValue]) {
          found = YES;
          break;
        }
      }
      if (found) {
        [sipAccounts addObject:[[[XMSIPAccountInfo alloc] _initWithTag:_tag enabled:YES] autorelease]];
        if (defaultSIPAccountIndex == UINT_MAX || defaultSIPAccountTag == _tag) {
          defaultSIPAccountIndex = i;
        }
      } else {
        [sipAccounts addObject:[[[XMSIPAccountInfo alloc] _initWithTag:_tag enabled:NO] autorelease]];
      }
    }
  }
  if (defaultSIPAccountIndex == UINT_MAX) {
    defaultSIPAccountIndex = (UINT_MAX-1);
  }
  [sipAccountsTable reloadData];
  [self _setTag:[currentLocation sipProxyTag] forNonePopUp:sipProxyPopUp];
  NSString *host = [currentLocation sipProxyHost];
  NSString *username = [currentLocation sipProxyUsername];
  NSString *password = [currentLocation _sipProxyPassword];
  if (host == nil) {
    host = @"";
  }
  if (username == nil) {
    username = @"";
  }
  if (password == nil) {
    password = @"";
  }
  [self _setString:host forTextField:sipProxyHostField];
  [self _setString:username forTextField:sipProxyUsernameField];
  [self _setString:password forTextField:sipProxyPasswordField];
  
  // loading the Audio section
  [audioCodecs release];
  NSArray *codecs = [currentLocation audioCodecList];
  if ((NSObject *)codecs == null) {
    audioCodecs = nil;
  } else {
    audioCodecs = [codecs mutableCopy];
  }
  [audioCodecPreferenceOrderTableView reloadData];
  [self _setState:[currentLocation enableSilenceSuppressionNumber] forSwitch:enableSilenceSuppressionSwitch];
  [self _setState:[currentLocation enableEchoCancellationNumber] forSwitch:enableEchoCancellationSwitch];
  [self _setTag:[currentLocation audioPacketTime] forPopUp:audioPacketTimePopUp];
  
  // loading the Video section
  [self _setState:[currentLocation enableVideoNumber] forSwitch:enableVideoSwitch];
  [self _setUnsignedInt:[currentLocation videoFramesPerSecond] forTextField:videoFrameRateField];
  [videoCodecs release];
  codecs = [currentLocation videoCodecList];
  if ((NSObject *)codecs == null) {
    videoCodecs = nil;
  } else {
    videoCodecs = [codecs mutableCopy];
  }
  [videoCodecPreferenceOrderTableView reloadData];
  [self _setState:[currentLocation enableH264LimitedModeNumber] forSwitch:enableH264LimitedModeSwitch];
  
  // loading the Misc section
  [self _setString:[currentLocation internationalDialingPrefix] forTextField:internationalDialingPrefixField];
  
  // finally, it's time to validate some GUI-Elements
  [self _validateExternalAddressUserInterface];
  [self _validateSTUNUserInterface];
  [self _validateH323UserInterface];
  [self _validateSIPUserInterface];
  [self _validateSIPAccountsUserInterface];
  [self _validateSIPProxyUserInterface];
  [self _validateAudioOrderUserInterface];
  [self _validateVideoUserInterface];
  [self _validateVideoOrderUserInterface];
  
  sipProxyPasswordDidChange = NO;
}

- (void)_saveCurrentLocation
{
  NSObject *obj;
  int state;
  
  // warn if no protocol is enabled
  if([enableH323Switch state] == NSOffState && [enableSIPSwitch state] == NSOffState)
  {
    [self _alertNoProtocolEnabled:currentLocation];
  }
  
  // saving the network section
  [currentLocation setBandwidthLimit:[self _extractTagFromPopUp:bandwidthLimitPopUp]];
  
  obj = [publicAddressField stringValue];
  state = [autoGetExternalAddressSwitch state];
  if (state == NSMixedState) {
    obj = [NSNull null];
  }
  else if([obj isEqual:@""] || [autoGetExternalAddressSwitch state] == NSOnState)
  {
    obj = nil;
  }
  [currentLocation setExternalAddress:(NSString *)obj];
  
  NSArray *servers = stunServers;
  if (servers == nil) {
    servers = (NSArray *)[NSNull null];
  }
  [currentLocation setSTUNServers:servers];
  
  [currentLocation setTCPPortBase:[self _extractUnsignedIntFromTextField:minTCPPortField]];
  [currentLocation setTCPPortMax:[self _extractUnsignedIntFromTextField:maxTCPPortField]];
  [currentLocation setUDPPortBase:[self _extractUnsignedIntFromTextField:minUDPPortField]];
  [currentLocation setUDPPortMax:[self _extractUnsignedIntFromTextField:maxUDPPortField]];
  
  // saving the H.323 section
  [currentLocation setEnableH323Number:[self _extractStateFromSwitch:enableH323Switch]];
  [currentLocation setEnableH245TunnelNumber:[self _extractStateFromSwitch:enableH245TunnelSwitch]];
  [currentLocation setEnableFastStartNumber:[self _extractStateFromSwitch:enableFastStartSwitch]];
  
  [currentLocation setH323AccountTag:[self _extractTagFromPopUp:h323AccountsPopUp]];
  
  // saving the SIP section
  [currentLocation setEnableSIPNumber:[self _extractStateFromSwitch:enableSIPSwitch]];
  
  if (sipAccounts != nil && defaultSIPAccountIndex != UINT_MAX) {
    unsigned numSIPAccounts = [sipAccounts count];
    unsigned i;
    NSMutableArray *accountTags = [[NSMutableArray alloc] initWithCapacity:numSIPAccounts];
    NSArray *accountRecords = [accountModule sipAccounts];
    unsigned defaultSIPAccountTag = 0;
    for (i = 0; i < numSIPAccounts; i++) {
      if ([(XMSIPAccountInfo *)[sipAccounts objectAtIndex:i] enabled] == YES) {
        XMSIPAccount *account = (XMSIPAccount *)[accountRecords objectAtIndex:i];
        [accountTags addObject:[NSNumber numberWithUnsignedInt:[account tag]]];
        if (defaultSIPAccountTag == 0 || defaultSIPAccountIndex == i) {
          defaultSIPAccountTag = [account tag];
        }
      }
    }
    [currentLocation setSIPAccountTags:accountTags];
    [currentLocation setDefaultSIPAccountTag:defaultSIPAccountTag];
    [accountTags release];
  }
  unsigned tag = [self _extractTagFromPopUp:sipProxyPopUp];
  [currentLocation setSIPProxyTag:tag];
  
  NSString *host = [self _extractStringFromTextField:sipProxyHostField];
  NSString *username = [self _extractStringFromTextField:sipProxyUsernameField];
  NSString *password = [self _extractStringFromTextField:sipProxyPasswordField];
  if ((NSObject *)host != [NSNull null] && [host isEqualToString:@""]) {
    host = nil;
  }
  if((NSObject *)username != [NSNull null] && [username isEqualToString:@""])
  {
    username = nil;
  }
  if((NSObject *)password != [NSNull null] && [password isEqualToString:@""])
  {
    password = nil;
  }
    
  [currentLocation setSIPProxyHost:host];
  [currentLocation setSIPProxyUsername:username];
  if (sipProxyPasswordDidChange) {
    [currentLocation _setSIPProxyPassword:password];
    sipProxyPasswordDidChange = NO;
  }
  
  // saving the audio section
  [currentLocation setEnableSilenceSuppressionNumber:[self _extractStateFromSwitch:enableSilenceSuppressionSwitch]];
  [currentLocation setEnableEchoCancellationNumber:[self _extractStateFromSwitch:enableEchoCancellationSwitch]];
  [currentLocation setAudioPacketTime:[self _extractTagFromPopUp:audioPacketTimePopUp]];
  
  // saving the video section
  [currentLocation setEnableVideoNumber:[self _extractStateFromSwitch:enableVideoSwitch]];
  [currentLocation setVideoFramesPerSecond:[self _extractUnsignedIntFromTextField:videoFrameRateField]];
  [currentLocation setEnableH264LimitedModeNumber:[self _extractStateFromSwitch:enableH264LimitedModeSwitch]];
  
  // saving the misc section
  [currentLocation setInternationalDialingPrefix:[self _extractStringFromTextField:internationalDialingPrefixField]];
}

- (void)_setUnsignedInt:(unsigned)value forTextField:(NSTextField *)textField
{
  if (value == UINT_MAX) {
    [(NSTextFieldCell *)[textField cell] setPlaceholderString:NSLocalizedString(@"XM_LOCATION_PREFERENCES_MULTIPLE_VALUES", @"")];
    [textField setStringValue:@""];
  } else {
    [(NSTextFieldCell *)[textField cell] setPlaceholderString:@""];
    [textField setIntValue:value];
  }
}

- (unsigned)_extractUnsignedIntFromTextField:(NSTextField *)textField
{
  if ([[textField stringValue] isEqualToString:@""] && ![[(NSTextFieldCell *)[textField cell] placeholderString] isEqualToString:@""]) {
    return UINT_MAX;
  } else {
    return [textField intValue];
  }
}

- (void)_setState:(NSNumber *)state forSwitch:(NSButton *)button
{
  if ((NSObject *)state == (NSObject *)[NSNull null]) {
    [button setAllowsMixedState:YES];
    [button setState:NSMixedState];
    [button setNeedsDisplay]; // Bug in AppKit
  } else {
    [button setAllowsMixedState:NO];
    [button setState:([state boolValue] == YES ? NSOnState : NSOffState)];
    [button setNeedsDisplay]; // Bug in AppKit
  }
}

- (NSNumber *)_extractStateFromSwitch:(NSButton *)button
{
  int state = [button state];
  
  if (state == NSMixedState) {
    return (NSNumber *)[NSNull null];
  }
  
  BOOL value = (state == NSOnState) ? YES : NO;
  return [NSNumber numberWithBool:value];
}

- (void)_setTag:(unsigned)tag forPopUp:(NSPopUpButton *)popUpButton
{
  id<NSMenuItem> menuItem = [popUpButton itemAtIndex:0];
  if ([menuItem tag] == -1 && tag != UINT_MAX) {
    // The <Multiple values> item is present but not needed
    [popUpButton removeItemAtIndex:1];
    [popUpButton removeItemAtIndex:0];
  } else if ([menuItem tag] != -1 && tag == UINT_MAX) {
    [popUpButton insertItemWithTitle:NSLocalizedString(@"XM_LOCATION_PREFERENCES_MULTIPLE_VALUES", @"") atIndex:0];
    [[popUpButton itemAtIndex:0] setTag:-1];
    [[popUpButton menu] insertItem:[NSMenuItem separatorItem] atIndex:1];
  }

  // int -1 is the same as unsigned int UINT_MAX (two's complement)
  BOOL result = [popUpButton selectItemWithTag:tag];
  if (result == NO) {
    [popUpButton selectItemAtIndex:0];
  }
}

- (unsigned)_extractTagFromPopUp:(NSPopUpButton *)popUpButton
{
  return [[popUpButton selectedItem] tag];
}

- (void)_setTag:(unsigned)tag forNonePopUp:(NSPopUpButton *)popUpButton
{
  id<NSMenuItem> menuItem = [popUpButton itemAtIndex:0];
  if ([menuItem tag] == -1 && tag != UINT_MAX) {
    // The <Multiple values> item is present but not needed
    [popUpButton removeItemAtIndex:0];
  } else if ([menuItem tag] != -1 && tag == UINT_MAX) {
    [popUpButton insertItemWithTitle:NSLocalizedString(@"XM_LOCATION_PREFERENCES_MULTIPLE_VALUES", @"") atIndex:0];
    [[popUpButton itemAtIndex:0] setTag:-1];
  }

  // int -1 is same as unsigned int UINT_MAX (two's complement)
  BOOL result = [popUpButton selectItemWithTag:tag];
  if(result == NO)
  {
    [popUpButton selectItemAtIndex:0];
  }
}

- (void)_setString:(NSString *)string forTextField:(NSTextField *)textField
{
  if ((NSObject *)string == [NSNull null]) {
    [(NSTextFieldCell *)[textField cell] setPlaceholderString:NSLocalizedString(@"XM_LOCATION_PREFERENCES_MULTIPLE_VALUES", @"")];
    [textField setStringValue:@""];
  } else {
    [(NSTextFieldCell *)[textField cell] setPlaceholderString:@""];
    [textField setStringValue:string];
  }
}

- (NSString *)_extractStringFromTextField:(NSTextField *)textField
{
  if ([[textField stringValue] isEqualToString:@""] && ![[(NSTextFieldCell *)[textField cell] placeholderString] isEqualToString:@""]) {
    return (NSString *)[NSNull null];
  } else {
    return [textField stringValue];
  }
}

- (void)_buildSIPAccountTags
{
  [sipAccounts release];
  NSArray *sipAccountTags = [currentLocation sipAccountTags];
  if ((NSObject *)sipAccountTags == [NSNull null]) {
    sipAccounts = nil;
  } else {
    NSArray *sipAccountRecords = [accountModule sipAccounts];
    unsigned numSIPAccounts = [sipAccountRecords count];
    sipAccounts = [[NSMutableArray alloc] initWithCapacity:numSIPAccounts];
    unsigned numTags = [sipAccountTags count];
    unsigned i, j;
    for (i = 0; i < numSIPAccounts; i++) {
      XMSIPAccount *account = (XMSIPAccount *)[sipAccountRecords objectAtIndex:i];
      unsigned _tag = [account tag];
      BOOL found = NO;
      for (j = 0; j < numTags; j++) {
        if (_tag == [(NSNumber *)[sipAccountTags objectAtIndex:j] unsignedIntValue]) {
          found = YES;
          break;
        }
      }
      if (found) {
        [sipAccounts addObject:[[[XMSIPAccountInfo alloc] _initWithTag:_tag enabled:YES] autorelease]];
      } else {
        [sipAccounts addObject:[[[XMSIPAccountInfo alloc] _initWithTag:_tag enabled:NO] autorelease]];
      }
    }
  }
}

- (void)_updateGatekeeperAccountInfo
{
  unsigned index = [h323AccountsPopUp indexOfSelectedItem];
  unsigned indexOffset = 2;
  
  if ([[h323AccountsPopUp itemAtIndex:0] tag] == -1) {
    indexOffset++;
  }
  
  if(index < indexOffset)
  {
    [gatekeeperHostField setStringValue:@""];
    [gatekeeperUserAliasField setStringValue:@""];
    [gatekeeperPhoneNumberField setStringValue:@""];
  }
  else
  {
    index -= indexOffset;
    
    XMH323Account *h323Account = [accountModule h323AccountAtIndex:index];
    
    NSString *gkHost = [h323Account gatekeeperHost];
    NSString *gkUsername = [h323Account terminalAlias1];
    NSString *gkPhoneNumber = [h323Account terminalAlias2];
    
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
}

#pragma mark -
#pragma mark User Interface validation Methods

- (void)_validateLocationButtonUserInterface
{
  NSIndexSet * selectedRows = [locationsTableView selectedRowIndexes];
  if ([selectedRows count] > 1 || [locations count] == 1) {
    [deleteLocationButton setEnabled:NO];
  } else {
    [deleteLocationButton setEnabled:YES];
  }
}

- (void)_validateExternalAddressUserInterface
{
  unsigned state = [autoGetExternalAddressSwitch state];
  [publicAddressField setEnabled:(state == NSOffState ? YES : NO)];
		
  if(state == NSOnState)
  {
    XMUtils *utils = [XMUtils sharedInstance];
    NSString *publicAddress = [utils publicAddress];
    NSString *displayString;
    
    if(publicAddress == nil)
    {
      [(NSTextFieldCell *)[publicAddressField cell] setPlaceholderString:NSLocalizedString(@"XM_EXTERNAL_ADDRESS_NOT_AVAILABLE", @"")];
      displayString = @"";
    }
    else
    {
      displayString = publicAddress;
    }
    [publicAddressField setStringValue:displayString];
  }
  else if (state == NSOffState)
  {
    if (![currentLocation isKindOfClass:[XMMultipleLocationsWrapper class]]) {
      [(NSTextFieldCell *)[publicAddressField cell] setPlaceholderString:@""];
    }
  }
}

- (void)_validateSTUNUserInterface
{
  if (stunServers != nil) {
    [stunServersTab selectFirstTabViewItem:self];
    unsigned count = [stunServers count];
    int selectedRow = [stunServersTable selectedRow];
    if (count == 0 || selectedRow == -1) {
      [removeSTUNServerButton setEnabled:NO];
    } else {
      [removeSTUNServerButton setEnabled:YES];
    }
    if (selectedRow == 0) {
      [moveSTUNServerUpButton setEnabled:NO];
    } else {
      [moveSTUNServerUpButton setEnabled:YES];
    }
    if (selectedRow == (count-1)) {
      [moveSTUNServerDownButton setEnabled:NO];
    } else {
      [moveSTUNServerDownButton setEnabled:YES];
    }
  } else {
    [stunServersTab selectLastTabViewItem:self];
  }
}

- (void)_validateH323UserInterface
{
  BOOL flag = ([enableH323Switch state] == NSOffState) ? NO : YES;
  
  [enableH245TunnelSwitch setEnabled:flag];
  [enableFastStartSwitch setEnabled:flag];
  [h323AccountsPopUp setEnabled:flag];
}

- (void)_validateSIPUserInterface
{
  BOOL flag = ([enableSIPSwitch state] == NSOffState) ? NO : YES;
  
  [sipAccountsTable setHidden:!flag];
  [sipProxyPopUp setEnabled:flag];
  
  [self _validateSIPProxyUserInterface];
}

- (void)_validateSIPAccountsUserInterface
{
  if (sipAccounts != nil && defaultSIPAccountIndex != UINT_MAX) {
    [sipAccountsTab selectFirstTabViewItem:self];
    int selectedRow = [sipAccountsTable selectedRow];
    if (selectedRow == UINT_MAX) {
      [makeDefaultSIPAccountButton setEnabled:NO];
    } else {
      [makeDefaultSIPAccountButton setEnabled:YES];
    }
  } else {
    [sipAccountsTab selectLastTabViewItem:self];
  }
}

- (void)_validateSIPProxyUserInterface
{
  BOOL sipEnabled = ([enableSIPSwitch state] == NSOffState) ? NO : YES;
  unsigned selectedTag = [[sipProxyPopUp selectedItem] tag];
  BOOL enableFields = NO;
  
  if (sipEnabled == YES && selectedTag == XMCustomSIPProxyTag) {
    enableFields = YES;
  }
  [sipProxyHostField setEnabled:enableFields];
  [sipProxyUsernameField setEnabled:enableFields];
  [sipProxyPasswordField setEnabled:enableFields];
}

- (void)_validateAudioOrderUserInterface
{
  if (audioCodecs != nil) {
    [audioCodecsTab selectFirstTabViewItem:self];
    unsigned count = [audioCodecs count];
    int selectedRow = [audioCodecPreferenceOrderTableView selectedRow];
    if(selectedRow == 0) {
      [moveAudioCodecUpButton setEnabled:NO];
    } else {
      [moveAudioCodecUpButton setEnabled:YES];
    }
    if(selectedRow == (count -1)) {
      [moveAudioCodecDownButton setEnabled:NO];
    } else {
      [moveAudioCodecDownButton setEnabled:YES];
    }
  } else {
    [audioCodecsTab selectLastTabViewItem:self];
  }
}

- (void)_validateVideoUserInterface
{
  BOOL flag = ([enableVideoSwitch state] == NSOffState) ? NO : YES;
  
  [videoFrameRateField setEnabled:flag];
  [videoCodecPreferenceOrderTableView setHidden:!flag];
  [enableH264LimitedModeSwitch setEnabled:flag];
  [self _validateVideoOrderUserInterface];
}

- (void)_validateVideoOrderUserInterface
{
  if (videoCodecs != nil) {
    [videoCodecsTab selectFirstTabViewItem:self];
    unsigned count = [videoCodecs count];
    int selectedRow = [videoCodecPreferenceOrderTableView selectedRow];
      BOOL enableFlag = ([enableVideoSwitch state] == NSOffState) ? NO : YES;
    if(selectedRow == 0 || enableFlag == NO) {
      [moveVideoCodecUpButton setEnabled:NO];
    } else {
      [moveVideoCodecUpButton setEnabled:YES];
    }
    if(selectedRow == (count -1) || enableFlag == NO) {
      [moveVideoCodecDownButton setEnabled:NO];
    } else {
      [moveVideoCodecDownButton setEnabled:YES];
    }
  } else {
    [videoCodecsTab selectLastTabViewItem:self];
  }
}

- (BOOL)validateMenuItem:(id<NSMenuItem>)menuItem
{
  int tag = [menuItem tag];
  
  if (tag == XM_RENAME_TAG || tag == XM_DUPLICATE_TAG) {
    NSIndexSet * selectedRows = [locationsTableView selectedRowIndexes];
    if ([selectedRows count] > 1) {
      return NO;
    }
  }
  return YES;
}

#pragma mark -
#pragma mark TableView dataSource & delegate methods

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
  if(tableView == locationsTableView)
  {
    return [locations count];
  }
  else if (tableView == stunServersTable)
  {
    return [stunServers count];
  }
  else if (tableView == sipAccountsTable) {
    return [[accountModule sipAccounts] count];
  }
  else if(tableView == audioCodecPreferenceOrderTableView)
  {
    return [audioCodecs count];
  }
  else if(tableView == videoCodecPreferenceOrderTableView)
  {
    return [videoCodecs count];
  }
  
  return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(int)rowIndex
{
  if(tableView == locationsTableView)
  {
    return [(XMLocation *)[locations objectAtIndex:rowIndex] name];
  }
  else if (tableView == stunServersTable) {
    return [stunServers objectAtIndex:rowIndex];
  }
  else if (tableView == sipAccountsTable) {
    XMSIPAccount *sipAccount = (XMSIPAccount *)[[accountModule sipAccounts] objectAtIndex:rowIndex];
    NSString *identifier = [column identifier];
    
    if ([identifier isEqualToString:XMKey_SIPAccountNameIdentifier]) {
      return [sipAccount name];
    } else if ([identifier isEqualToString:XMKey_SIPAccountDomainIdentifier]) {
      return [sipAccount domain];
    } else {
      return [NSNumber numberWithBool:[(XMSIPAccountInfo *)[sipAccounts objectAtIndex:rowIndex] enabled]];
    }
  }
  else if(tableView != audioCodecPreferenceOrderTableView &&
     tableView != videoCodecPreferenceOrderTableView)
  {
    return nil;
  }
  NSString *columnIdentifier = [column identifier];
  XMPreferencesCodecListRecord *record;
  
  if(tableView == audioCodecPreferenceOrderTableView)
  {
    record = (XMPreferencesCodecListRecord *)[audioCodecs objectAtIndex:rowIndex];
  }
  else if(tableView == videoCodecPreferenceOrderTableView)
  {
    record = (XMPreferencesCodecListRecord *)[videoCodecs objectAtIndex:rowIndex];
  }

  if([columnIdentifier isEqualToString:XMKey_EnabledIdentifier])
  {
    return [NSNumber numberWithBool:[record isEnabled]];
  }
  XMCodecIdentifier identifier = identifier = [record identifier];
  XMCodec *codec = [[XMCodecManager sharedInstance] codecForIdentifier:identifier];
  NSObject *object = [codec propertyForKey:columnIdentifier];
  return object;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
  if(tableView == locationsTableView)
  {
    if([anObject isKindOfClass:[NSString class]])
    {
      NSString *newName = (NSString *)anObject;
      unsigned count = [locations count];
      
      // check whether this name already exists
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
  else if (tableView == stunServersTable)
  {
    NSString *serverName = (NSString *)anObject;
    [stunServers replaceObjectAtIndex:rowIndex withObject:serverName];
  }
  else if (tableView == sipAccountsTable)
  {
    XMSIPAccountInfo *info = (XMSIPAccountInfo *)[sipAccounts objectAtIndex:rowIndex];
    [info setEnabled:[anObject boolValue]];
    
    unsigned count = [sipAccounts count];
    unsigned numEnabled = 0;
    unsigned enabledIndex = UINT_MAX;
    unsigned i;
    for (i = 0; i < count; i++) {
      XMSIPAccountInfo *info = (XMSIPAccountInfo *)[sipAccounts objectAtIndex:i];
      if ([info enabled] == YES) {
        numEnabled++;
        if (enabledIndex == UINT_MAX || i == defaultSIPAccountIndex) {
          enabledIndex = i;
        }
      }
    }
    if (numEnabled == 0) {
      enabledIndex = (UINT_MAX-1);
    }
    if (enabledIndex != defaultSIPAccountIndex) {
      defaultSIPAccountIndex = enabledIndex;
      [sipAccountsTable reloadData];
    }
  }
  else if(tableView == audioCodecPreferenceOrderTableView)
  {
    [[currentLocation audioCodecListRecordAtIndex:rowIndex] setEnabled:[anObject boolValue]];
    [audioCodecPreferenceOrderTableView reloadData];
  }
  else if(tableView == videoCodecPreferenceOrderTableView)
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
    [self _loadCurrentLocation];
    [self _validateLocationButtonUserInterface];
  }
  else if (tableView == stunServersTable) {
    [self _validateSTUNUserInterface];
  }
  else if (tableView == sipAccountsTable) {
    [self _validateSIPAccountsUserInterface];
  }
  else if(tableView == audioCodecPreferenceOrderTableView)
  {
    [self _validateAudioOrderUserInterface];
  }
  else if(tableView == videoCodecPreferenceOrderTableView)
  {
    [self _validateVideoOrderUserInterface];
  }
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
  if (tableView == stunServersTable)
  {
    NSColor *color;
    if (stunServers == nil) {
      color = [NSColor disabledControlTextColor];
    } else {
      if ([aCell isHighlighted]) {
        color = [NSColor selectedControlTextColor];
      } else {
        color = [NSColor controlTextColor];
      }
    }
    [(NSTextFieldCell *)aCell setTextColor:color];
  }
  else if (tableView == sipAccountsTable)
  {
    if ([[aTableColumn identifier] isEqualToString:XMKey_SIPAccountEnabledIdentifier]) {
      return;
    }
    if (rowIndex == defaultSIPAccountIndex) {
      [aCell setFont:[NSFont boldSystemFontOfSize:TABLE_FONT_SIZE]];
    } else {
      [aCell setFont:[NSFont systemFontOfSize:TABLE_FONT_SIZE]];
    }
  }
  else if(tableView == audioCodecPreferenceOrderTableView)
  {
    XMPreferencesCodecListRecord *codecRecord = (XMPreferencesCodecListRecord *)[audioCodecs objectAtIndex:rowIndex];
    XMCodec *codec = [[XMCodecManager sharedInstance] codecForIdentifier:[codecRecord identifier]];
    if ([[aTableColumn identifier] isEqualToString:XMKey_EnabledIdentifier]) {
      [aCell setEnabled:[codec canDisable]];
    } else {
      if ([codecRecord isEnabled]) {
        [(NSTextFieldCell *)aCell setTextColor:[NSColor controlTextColor]];
      } else {
        [(NSTextFieldCell *)aCell setTextColor:[NSColor disabledControlTextColor]];
      }
    }
  }
  else if(tableView == videoCodecPreferenceOrderTableView)
  {
    XMPreferencesCodecListRecord *codecRecord = (XMPreferencesCodecListRecord *)[videoCodecs objectAtIndex:rowIndex];
    XMCodec *codec = [[XMCodecManager sharedInstance] codecForIdentifier:[codecRecord identifier]];
    if ([[aTableColumn identifier] isEqualToString:XMKey_EnabledIdentifier]) {
      [aCell setEnabled:[codec canDisable]];
    } else {
      if ([codecRecord isEnabled]) {
        [(NSTextFieldCell *)aCell setTextColor:[NSColor controlTextColor]];
      } else {
        [(NSTextFieldCell *)aCell setTextColor:[NSColor disabledControlTextColor]];
      }
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

- (void)_didUpdateNetworkInformation:(NSNotification *)notif
{
  [self _validateExternalAddressUserInterface];
}

- (void)_importLocationsAssistantDidEndWithLocations:(NSArray *)theLocations
										h323Accounts:(NSArray *)h323Accounts
										 sipAccounts:(NSArray *)_sipAccounts
{
  [accountModule addH323Accounts:h323Accounts];
  [accountModule addSIPAccounts:_sipAccounts];
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

#pragma mark -

@implementation XMSIPAccountInfo

- (id)_initWithTag:(unsigned)_tag enabled:(BOOL)_enabled
{
  self = [super init];
  tag = _tag;
  enabled = _enabled;
  return self;
}

- (unsigned)tag
{
  return tag;
}

- (void)setTag:(unsigned)_tag
{
  tag = _tag;
}

- (BOOL)enabled
{
  return enabled;
}

- (void)setEnabled:(BOOL)flag
{
  enabled = flag;
}

@end

#pragma mark -

@implementation XMMultipleLocationsWrapper

#pragma mark Init & Deallocation Methods

- (id)_initWithLocations:(NSArray *)_locations
{
  self = [super initWithName:@""];
  locations = [_locations copy];
  return self;
}

- (void)dealloc
{
  [locations release];
  [super dealloc];
}

#pragma mark -
#pragma mark Overriding methods

- (unsigned)bandwidthLimit 
{
  NSObject *value = [self _valueForKey:XMKey_PreferencesBandwidthLimit];
  if (value == [NSNull null]) {
    return UINT_MAX;
  }
  return [(NSNumber *)value unsignedIntValue];
}

- (void)setBandwidthLimit:(unsigned)value
{
  if (value != UINT_MAX) {
    [self _setValue:[NSNumber numberWithUnsignedInt:value] forKey:XMKey_PreferencesBandwidthLimit];
  }
}

// Returns:
// nil   : If all locations have nil external address
// String: If all locations have same manual external address
// NSNull: If locations have different external addresses
// @""   : If locations have different external addresses AND at least one location has nil external address
- (NSString *)publicAddress
{
  return (NSString *)[self _valueForKey:XMKey_PreferencesExternalAddress checkNil:YES nilObject:@""];
}

- (void)setExternalAddress:(NSObject *)address
{
  if (address != [NSNull null]) {
    [self _setValue:address forKey:XMKey_PreferencesExternalAddress];
  }
}

- (unsigned)tcpPortBase
{
  NSObject *value = [self _valueForKey:XMKey_PreferencesTCPPortBase];
  if (value == [NSNull null]) {
    return UINT_MAX;
  }
  return [(NSNumber *)value unsignedIntValue];
}

- (void)setTCPPortBase:(unsigned)value
{
  if (value != UINT_MAX) {
    [self _setValue:[NSNumber numberWithUnsignedInt:value] forKey:XMKey_PreferencesTCPPortBase];
  }
}

- (unsigned)tcpPortMax
{
  NSObject *value = [self _valueForKey:XMKey_PreferencesTCPPortMax];
  if (value == [NSNull null]) {
    return UINT_MAX;
  }
  return [(NSNumber *)value unsignedIntValue];
}

- (void)setTCPPortMax:(unsigned)value
{
  if (value != UINT_MAX) {
    [self _setValue:[NSNumber numberWithUnsignedInt:value] forKey:XMKey_PreferencesTCPPortMax];
  }
}

- (unsigned)udpPortBase
{
  NSObject *value = [self _valueForKey:XMKey_PreferencesUDPPortBase];
  if (value == [NSNull null]) {
    return UINT_MAX;
  }
  return [(NSNumber *)value unsignedIntValue];
}

- (void)setUDPPortBase:(unsigned)value
{
  if (value != UINT_MAX) {
    [self _setValue:[NSNumber numberWithUnsignedInt:value] forKey:XMKey_PreferencesUDPPortBase];
  }
}

- (unsigned)udpPortMax
{
  NSObject *value = [self _valueForKey:XMKey_PreferencesUDPPortMax];
  if (value == [NSNull null]) {
    return UINT_MAX;
  }
  return [(NSNumber *)value unsignedIntValue];
}

- (void)setUDPPortMax:(unsigned)value
{
  if (value != UINT_MAX) {
    [self _setValue:[NSNumber numberWithUnsignedInt:value] forKey:XMKey_PreferencesUDPPortMax];
  }
}

- (NSArray *)stunServers
{
  return (NSArray *)[self _valueForKey:XMKey_PreferencesSTUNServers];
}

- (void)setSTUNServers:(NSArray *)servers
{
  if ((NSObject *)servers != [NSNull null]) {
    [self _setValue:servers forKey:XMKey_PreferencesSTUNServers];
  }
}

- (NSNumber *)enableH323Number
{
  return (NSNumber *)[self _valueForKey:XMKey_PreferencesEnableH323];
}

- (void)setEnableH323Number:(NSNumber *)number
{
  if ((NSObject *)number != [NSNull null]) {
    [self _setValue:number forKey:XMKey_PreferencesEnableH323];
  }
}

- (NSNumber *)enableH245TunnelNumber
{
  return (NSNumber *)[self _valueForKey:XMKey_PreferencesEnableH245Tunnel];
}

- (void)setEnableH245TunnelNumber:(NSNumber *)number
{
  if ((NSObject *)number != [NSNull null]) {
    [self _setValue:number forKey:XMKey_PreferencesEnableH245Tunnel];
  }
}

- (NSNumber *)enableFastStartNumber
{
  return (NSNumber *)[self _valueForKey:XMKey_PreferencesEnableFastStart];
}

- (void)setEnableFastStartNumber:(NSNumber *)number
{
  if ((NSObject *)number != [NSNull null]) {
    [self _setValue:number forKey:XMKey_PreferencesEnableFastStart];
  }
}

- (unsigned)h323AccountTag
{
  unsigned count = [locations count];
  unsigned i;
  unsigned _tag;
  for (i = 0; i < count; i++) {
    XMLocation *location = (XMLocation *)[locations objectAtIndex:i];
    if (i == 0) {
      _tag = [location h323AccountTag];
    } else {
      if (_tag != [location h323AccountTag]) {
        return UINT_MAX;
      }
    }
  }
  return _tag;
}

- (void)setH323AccountTag:(unsigned)_tag
{
  if (_tag != UINT_MAX) {
    unsigned count = [locations count];
    unsigned i;
    for (i = 0; i < count; i++) {
      XMLocation *location = (XMLocation *)[locations objectAtIndex:i];
      [location setH323AccountTag:_tag];
    }
  }
}

- (NSNumber *)enableSIPNumber
{
  return (NSNumber *)[self _valueForKey:XMKey_PreferencesEnableSIP];
}

- (void)setEnableSIPNumber:(NSNumber *)number
{
  if ((NSObject *)number != [NSNull null]) {
    [self _setValue:number forKey:XMKey_PreferencesEnableSIP];
  }
}

- (NSArray *)sipAccountTags
{
  unsigned count = [locations count];
  unsigned i;
  NSArray *array;
  
  for (i = 0; i < count; i++) {
    XMLocation *location = (XMLocation *)[locations objectAtIndex:i];
    if (i == 0) {
      array = [location sipAccountTags];
    } else {
      NSArray *array2 = [location sipAccountTags];
      if (![array2 isEqual:array] && array2 != array) {
        array = (NSArray *)[NSNull null]; // Locations have different values
        break;
      }
    }
  }
  return array;
}

- (void)setSIPAccountTags:(NSArray *)tags
{
  if ((NSObject *)tags != [NSNull null]) {
    unsigned count = [locations count];
    unsigned i;
    for (i = 0; i < count; i++) {
      XMLocation *location = (XMLocation *)[locations objectAtIndex:i];
      [location setSIPAccountTags:tags];
    }
  }
}

- (unsigned)defaultSIPAccountTag
{
  unsigned count = [locations count];
  unsigned i;
  unsigned _tag;
  for (i = 0; i < count; i++) {
    XMLocation *location = (XMLocation *)[locations objectAtIndex:i];
    if (i == 0) {
      _tag = [location sipProxyTag];
    } else {
      if (_tag != [location defaultSIPAccountTag]) {
        return UINT_MAX;
      }
    }
  }
  return _tag;
}

- (void)setDefaultSIPAccountTag:(unsigned)_tag
{
  if (_tag != UINT_MAX) {
    unsigned count = [locations count];
    unsigned i;
    for (i = 0; i < count; i++) {
      XMLocation *location = (XMLocation *)[locations objectAtIndex:i];
      [location setDefaultSIPAccountTag:_tag];
    }
  }
}

- (unsigned)sipProxyTag
{
  unsigned count = [locations count];
  unsigned i;
  unsigned _tag;
  for (i = 0; i < count; i++) {
    XMLocation *location = (XMLocation *)[locations objectAtIndex:i];
    if (i == 0) {
      _tag = [location sipProxyTag];
    } else {
      if (_tag != [location sipProxyTag]) {
        return UINT_MAX;
      }
    }
  }
  return _tag;
}

- (void)setSIPProxyTag:(unsigned)_tag
{
  if (_tag != UINT_MAX) {
    unsigned count = [locations count];
    unsigned i;
    for (i = 0; i < count; i++) {
      XMLocation *location = (XMLocation *)[locations objectAtIndex:i];
      [location setSIPProxyTag:_tag];
    }
  }
}

- (NSString *)sipProxyHost
{
  return (NSString *)[self _valueForKey:XMKey_PreferencesSIPProxyHost];
}

- (void)setSIPProxyHost:(NSString *)host
{
  if ((NSObject *)host != [NSNull null]) {
    [self _setValue:host forKey:XMKey_PreferencesSIPProxyHost];
  }
}

- (NSString *)sipProxyUsername
{
  return (NSString *)[self _valueForKey:XMKey_PreferencesSIPProxyUsername];
}

- (void)setSIPProxyUsername:(NSString *)username
{
  if ((NSObject *)username != [NSNull null]) {
    [self _setValue:username forKey:XMKey_PreferencesSIPProxyUsername];
  }
}

- (NSString *)_sipProxyPassword
{
  unsigned count = [locations count];
  unsigned i;
  NSString *pwd;
  for (i = 0; i < count; i++) {
    XMLocation *location = (XMLocation *)[locations objectAtIndex:i];
    if (i == 0) {
      pwd = [location _sipProxyPassword];
    } else {
      NSString *pwd2 = [location _sipProxyPassword];
      if (![pwd isEqualToString:pwd2] && pwd != pwd2) {
        return (NSString *)[NSNull null];
      }
    }
  }
  return pwd;
}

- (void)_setSIPProxyPassword:(NSString *)password
{
  if ((NSObject *)password != [NSNull null]) {
    unsigned count = [locations count];
    unsigned i;
    for (i = 0; i < count; i++) {
      XMLocation *location = (XMLocation *)[locations objectAtIndex:i];
      [location _setSIPProxyPassword:password];
    }
  }
}

- (NSArray *)audioCodecList
{
  return (NSArray *)[self _valueForKey:XMKey_PreferencesAudioCodecList];
}

- (void)audioCodecListExchangeRecordAtIndex:(unsigned)index1 withRecordAtIndex:(unsigned)index2
{
  unsigned count = [locations count];
  unsigned i;
  
  for (i = 0; i < count; i++) {
    XMLocation *location = (XMLocation *)[locations objectAtIndex:i];
    [location audioCodecListExchangeRecordAtIndex:index1 withRecordAtIndex:index2];
  }
}

- (void)resetAudioCodecs
{
  unsigned count = [locations count];
  unsigned i;
  
  for (i = 0; i < count; i++) {
    XMLocation *location = (XMLocation *)[locations objectAtIndex:i];
    [location resetAudioCodecs];
  }
}

- (NSNumber *)enableSilenceSuppressionNumber
{
   return (NSNumber *)[self _valueForKey:XMKey_PreferencesEnableSilenceSuppression];
}

- (void)setEnableSilenceSuppressionNumber:(NSNumber *)number
{
  if ((NSObject *)number != [NSNull null]) {
    [self _setValue:number forKey:XMKey_PreferencesEnableSilenceSuppression];
  }
}

- (NSNumber *)enableEchoCancellationNumber
{
  return (NSNumber *)[self _valueForKey:XMKey_PreferencesEnableEchoCancellation];
}

- (void)setEnableEchoCancellationNumber:(NSNumber *)number
{
  if ((NSObject *)number != [NSNull null]) {
    [self _setValue:number forKey:XMKey_PreferencesEnableEchoCancellation];
  }
}

- (unsigned)audioPacketTime
{
  NSObject *value = [self _valueForKey:XMKey_PreferencesAudioPacketTime];
  if (value == [NSNull null]) {
    return UINT_MAX;
  }
  return [(NSNumber *)value unsignedIntValue];
}

- (void)setAudioPacketTime:(unsigned)value
{
  if (value != UINT_MAX) {
    [self _setValue:[NSNumber numberWithUnsignedInt:value] forKey:XMKey_PreferencesAudioPacketTime];
  }
}

- (NSNumber *)enableVideoNumber
{
  return (NSNumber *)[self _valueForKey:XMKey_PreferencesEnableVideo];
}

- (void)setEnableVideoNumber:(NSNumber *)number
{
  if ((NSObject *)number != [NSNull null]) {
    [self _setValue:number forKey:XMKey_PreferencesEnableVideo];
  }
}

- (unsigned)videoFramesPerSecond
{
  NSObject *value = [self _valueForKey:XMKey_PreferencesVideoFramesPerSecond];
  if (value == [NSNull null]) {
    return UINT_MAX;
  }
  return [(NSNumber *)value unsignedIntValue];
}

- (void)setVideoFramesPerSecond:(unsigned)value
{
  if (value != UINT_MAX) {
    [self _setValue:[NSNumber numberWithUnsignedInt:value] forKey:XMKey_PreferencesVideoFramesPerSecond];
  }
}

- (NSArray *)videoCodecList
{
  return (NSArray *)[self _valueForKey:XMKey_PreferencesVideoCodecList];
}

- (void)videoCodecListExchangeRecordAtIndex:(unsigned)index1 withRecordAtIndex:(unsigned)index2
{
  unsigned count = [locations count];
  unsigned i;
  
  for (i = 0; i < count; i++) {
    XMLocation *location = (XMLocation *)[locations objectAtIndex:i];
    [location videoCodecListExchangeRecordAtIndex:index1 withRecordAtIndex:index2];
  }
}

- (void)resetVideoCodecs
{
  unsigned count = [locations count];
  unsigned i;
  
  for (i = 0; i < count; i++) {
    XMLocation *location = (XMLocation *)[locations objectAtIndex:i];
    [location resetVideoCodecs];
  }
}

- (NSNumber *)enableH264LimitedModeNumber
{
  return (NSNumber *)[self _valueForKey:XMKey_PreferencesEnableH264LimitedMode];
}

- (void)setEnableH264LimitedModeNumber:(NSNumber *)number
{
  if ((NSObject *)number != [NSNull null]) {
    [self _setValue:number forKey:XMKey_PreferencesEnableH264LimitedMode];
  }
}

- (NSString *)internationalDialingPrefix
{
  return (NSString *)[self _valueForKey:XMKey_PreferencesInternationalDialingPrefix];
}

- (void)setInternationalDialingPrefix:(NSString *)prefix
{
  if ((NSObject *)prefix != [NSNull null]) {
    [self _setValue:prefix forKey:XMKey_PreferencesInternationalDialingPrefix];
  }
}

#pragma mark -
#pragma mark Private Methods

- (NSObject *)_valueForKey:(NSString *)key
{
  return [self _valueForKey:key checkNil:NO nilObject:nil];
}

- (NSObject *)_valueForKey:(NSString *)key checkNil:(BOOL)checkNil nilObject:(NSObject *)nilObject
{
  unsigned count = [locations count];
  unsigned i;
  NSObject *object;
  BOOL hasNil = NO;
  
  for (i = 0; i < count; i++) {
    XMLocation *location = (XMLocation *)[locations objectAtIndex:i];
    if (i == 0) {
      object = [location valueForKey:key];
      if (object == nil) {
        hasNil = YES;
      }
    } else {
      NSObject *object2 = [location valueForKey:key];
      if (object2 == nil) {
        hasNil = YES;
      }
      if (![object2 isEqual:object] && object2 != object) {
        object = [NSNull null]; // Locations have different values
        if (checkNil == NO) {
          break;
        }
      }
    }
  }
  if (checkNil == YES && hasNil == YES && object == [NSNull null]) {
    return nilObject;
  }
  return object;
}

- (void)_setValue:(NSObject *)value forKey:(NSString *)key
{
  unsigned count = [locations count];
  unsigned i;
  
  for (i = 0; i < count; i++) {
    XMLocation *location = (XMLocation *)[locations objectAtIndex:i];
    [location setValue:value forKey:key];
  }
}

@end
