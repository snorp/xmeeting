/*
 * $Id: XMSetupAssistantModules.m,v 1.3 2009/01/09 08:08:21 hfriederich Exp $
 *
 * Copyright (c) 2009 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2009 Hannes Friederich. All rights reserved.
 */

#import "XMSetupAssistantModules.h"
#import "XMLocation.h"

#pragma mark -
#pragma mark General

@implementation XMSAGeneralModule

- (NSArray *)editKeys
{
  return [NSArray array];
}

- (BOOL)isActiveForData:(id<XMSetupAssistantData>)data
{
  return YES;
}

- (NSString *)titleForData:(id<XMSetupAssistantData>)data
{
  return NSLocalizedString(@"XM_SETUP_ASSISTANT_PI", @"");
}

- (BOOL)showCornerImage
{
  return YES;
}

- (NSView *)contentView
{
  return contentView;
}

- (BOOL)canSaveData
{
  NSString *str = [nameField stringValue];
  if ([str length] == 0) {
    [self editData:nil]; // get focus again
    return NO;
  }
  return YES;
}

- (void)loadData:(id<XMSetupAssistantData>)data
{
  [nameField setStringValue:[data username]];
}

- (void)saveData:(id<XMSetupAssistantData>)data
{
  [data setUsername:[nameField stringValue]];
}

- (void)editData:(NSArray *)editKeys
{
  [[nameField window] makeFirstResponder:nameField];
}

- (void)controlTextDidChange:(NSNotification *)notif
{
  if ([[nameField stringValue] length] == 0) {
    [[XMSetupAssistantManager sharedInstance] setButtonsEnabled:NO];
  } else {
    [[XMSetupAssistantManager sharedInstance] setButtonsEnabled:YES];
  }
}

@end

@implementation XMSALocationModule 

- (NSArray *)editKeys
{
  return [NSArray array];
}

- (BOOL)isActiveForData:(id<XMSetupAssistantData>)data
{
  return YES;
}

- (NSString *)titleForData:(id<XMSetupAssistantData>)data
{
  return NSLocalizedString(@"XM_SETUP_ASSISTANT_LOCATIONS", @"");
}

- (BOOL)showCornerImage
{
  return YES;
}

- (NSView *)contentView
{
  return contentView;
}

- (BOOL)canSaveData
{
  return YES;
}

- (void)loadData:(id<XMSetupAssistantData>)data
{
  BOOL enableImportLocation = NO;
  BOOL enableEditLocation = NO;
  
  [locationsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
  [locationsTable reloadData];
  
  if ([data hasAttribute:XMAttribute_PreferencesEdit]) {
    enableEditLocation = YES;
  }
  
  [[locationRadioButtons cellAtRow:1 column:0] setEnabled:enableImportLocation]; // row 1 is importLocation
  [[locationRadioButtons cellAtRow:2 column:0] setEnabled:enableEditLocation]; // row 2 is editLocation
  
  int rowIndex = 0;
  if ([data hasAttribute:XMAttribute_NewLocation]) {
    rowIndex = 0;
  } else if ([data hasAttribute:XMAttribute_EditLocation]) {
    rowIndex = 2;
  }
  [locationRadioButtons selectCellAtRow:rowIndex column:0];
  
  if (enableEditLocation == NO || rowIndex != 2) {
    [locationsTable setHidden:YES];
  } else {
    [locationsTable setHidden:NO];
  }
}

- (void)saveData:(id<XMSetupAssistantData>)data
{
  int rowIndex = [locationRadioButtons selectedRow];
  
  if (rowIndex == 0) { // create new location
    [data clearAttribute:XMAttribute_EditLocation];
    [data setAttribute:XMAttribute_NewLocation];
    [data setCurrentLocation:[data createLocation]];
  } else if (rowIndex == 1) {
    // TODO
  } else {
    [data clearAttribute:XMAttribute_NewLocation];
    [data setAttribute:XMAttribute_EditLocation];
    
    int locationIndex = [locationsTable selectedRow];
    XMLocation *location = (XMLocation *)[[data locations] objectAtIndex:locationIndex];
    [data setCurrentLocation:location];
  }
}

- (void)editData:(NSArray *)editKeys
{
  // no need to do anything
}

- (IBAction)radioButtonAction:(id)sender
{
  int rowIndex = [locationRadioButtons selectedRow];
  
  if (rowIndex == 2) {
    [locationsTable setHidden:NO];
  } else {
    [locationsTable setHidden:YES];
  }
}

// table data source
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
  return [[[XMSetupAssistantManager sharedInstance] locations] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)column row:(int)rowIndex
{
  XMLocation *location = (XMLocation *)[[[XMSetupAssistantManager sharedInstance] locations] objectAtIndex:rowIndex];
  return [location name];
}

@end

@implementation XMSANewLocationModule 

- (NSArray *)editKeys
{
  return [NSArray array];
}

- (BOOL)isActiveForData:(id<XMSetupAssistantData>)data
{
  // only display this if a new location is edited
  if ([data hasAttribute:XMAttribute_NewLocation]) {
    return YES;
  }
  return NO;
}

- (NSString *)titleForData:(id<XMSetupAssistantData>)data
{
  return NSLocalizedString(@"XM_SETUP_ASSISTANT_NEW_LOCATION", @"");
}

- (BOOL)showCornerImage
{
  return YES;
}

- (NSView *)contentView
{
  return contentView;
}

- (BOOL)canSaveData
{
  NSString *str = [nameField stringValue];
  if ([str length] == 0) {
    [self editData:nil]; // get focus again
    return NO;
  }
  return YES;
}

- (void)loadData:(id<XMSetupAssistantData>)data
{
  [nameField setStringValue:[[data currentLocation] name]];
}

- (void)saveData:(id<XMSetupAssistantData>)data
{
  [[data currentLocation] setName:[nameField stringValue]];
}

- (void)editData:(NSArray *)editKeys
{
  [[nameField window] makeFirstResponder:nameField];
}

- (void)controlTextDidChange:(NSNotification *)notif
{
  if ([[nameField stringValue] length] == 0) {
    [[XMSetupAssistantManager sharedInstance] setButtonsEnabled:NO];
  } else {
    [[XMSetupAssistantManager sharedInstance] setButtonsEnabled:YES];
  }
}

@end

@implementation XMSANetworkModule 

- (NSArray *)editKeys
{
  return [NSArray array];
}

- (BOOL)isActiveForData:(id<XMSetupAssistantData>)data
{
  return YES;
}

- (NSString *)titleForData:(id<XMSetupAssistantData>)data
{
  NSString *template = NSLocalizedString(@"XM_SETUP_ASSISTANT_LOCATION", @"");
  return [NSString stringWithFormat:template, [[data currentLocation] name]];
}

- (BOOL)showCornerImage
{
  return YES;
}

- (NSView *)contentView
{
  return contentView;
}

- (BOOL)canSaveData
{
  return YES;
}

- (void)loadData:(id<XMSetupAssistantData>)data
{
  [bandwidthLimitPopUp selectItemWithTag:[[data currentLocation] bandwidthLimit]];
}

- (void)saveData:(id<XMSetupAssistantData>)data
{
  [[data currentLocation] setBandwidthLimit:[[bandwidthLimitPopUp selectedItem] tag]];
}

- (void)editData:(NSArray *)editKeys
{
}

@end

@implementation XMSAProtocolModule 

- (NSArray *)editKeys
{
  return [NSArray array];
}

- (BOOL)isActiveForData:(id<XMSetupAssistantData>)data
{
  return YES;
}

- (NSString *)titleForData:(id<XMSetupAssistantData>)data
{
  NSString *template = NSLocalizedString(@"XM_SETUP_ASSISTANT_LOCATION", @"");
  return [NSString stringWithFormat:template, [[data currentLocation] name]];
}

- (BOOL)showCornerImage
{
  return YES;
}

- (NSView *)contentView
{
  return contentView;
}

- (BOOL)canSaveData
{
  if ([enableH323Switch state] == NSOffState && [enableSIPSwitch state] == NSOffState) {
    return NO;
  } else {
    return YES;
  }
}

- (void)loadData:(id<XMSetupAssistantData>)data
{
  XMLocation *location = [data currentLocation];
  
  int state = [location enableH323] ? NSOnState : NSOffState;
  [enableH323Switch setState:state];
  
  state = [location enableSIP] ? NSOnState : NSOffState;
  [enableSIPSwitch setState:state];
}

- (void)saveData:(id<XMSetupAssistantData>)data
{
  XMLocation *location = [data currentLocation];
  
  BOOL enable = [enableH323Switch state] == NSOnState ? YES : NO;
  [location setEnableH323:enable];
  
  enable = [enableSIPSwitch state] == NSOnState ? YES : NO;
  [location setEnableSIP:enable];
}

- (void)editData:(NSArray *)editKeys
{
}

- (IBAction)action:(id)sender
{
  if ([enableH323Switch state] == NSOffState && [enableSIPSwitch state] == NSOffState) {
    [[XMSetupAssistantManager sharedInstance] setButtonsEnabled:NO];
  } else {
    [[XMSetupAssistantManager sharedInstance] setButtonsEnabled:YES];
  }
}

@end

@implementation XMSAH323Module 

- (NSArray *)editKeys
{
  return [NSArray array];
}

- (BOOL)isActiveForData:(id<XMSetupAssistantData>)data
{
  if ([[data currentLocation] enableH323]) {
    return YES;
  }
  return NO;
}

- (NSString *)titleForData:(id<XMSetupAssistantData>)data
{
  NSString *template = NSLocalizedString(@"XM_SETUP_ASSISTANT_LOCATION", @"");
  return [NSString stringWithFormat:template, [[data currentLocation] name]];
}

- (BOOL)showCornerImage
{
  return YES;
}

- (NSView *)contentView
{
  return contentView;
}

- (BOOL)canSaveData
{
  return YES;
}

- (void)loadData:(id<XMSetupAssistantData>)data
{
  int selectedIndex = [data hasAttribute:XMAttribute_UseGatekeeper] ? 0 : 1;
  [useGkRadioButtons selectCellAtRow:selectedIndex column:0];
}

- (void)saveData:(id<XMSetupAssistantData>)data
{
  int selectedIndex = [useGkRadioButtons selectedRow];
  if (selectedIndex == 0) {
    [data setAttribute:XMAttribute_UseGatekeeper];
  } else {
    [data clearAttribute:XMAttribute_UseGatekeeper];
  }
}

- (void)editData:(NSArray *)editKeys
{
}

@end

@implementation XMSAGatekeeperModule 

- (NSArray *)editKeys
{
  return [NSArray array];
}

- (BOOL)isActiveForData:(id<XMSetupAssistantData>)data
{
  if ([[data currentLocation] enableH323] && [data hasAttribute:XMAttribute_UseGatekeeper]) {
    return YES;
  }
  return NO;
}

- (NSString *)titleForData:(id<XMSetupAssistantData>)data
{
  NSString *template = NSLocalizedString(@"XM_SETUP_ASSISTANT_LOCATION", @"");
  return [NSString stringWithFormat:template, [[data currentLocation] name]];
}

- (BOOL)showCornerImage
{
  return YES;
}

- (NSView *)contentView
{
  return contentView;
}

- (BOOL)canSaveData
{
  return YES;
}

- (void)loadData:(id<XMSetupAssistantData>)data
{
}

- (void)saveData:(id<XMSetupAssistantData>)data
{
}

- (void)editData:(NSArray *)editKeys
{
}

@end

@implementation XMSASIPModule 

- (NSArray *)editKeys
{
  return [NSArray array];
}

- (BOOL)isActiveForData:(id<XMSetupAssistantData>)data
{
  if ([[data currentLocation] enableSIP]) {
    return YES;
  }
  return NO;
}

- (NSString *)titleForData:(id<XMSetupAssistantData>)data
{
  NSString *template = NSLocalizedString(@"XM_SETUP_ASSISTANT_LOCATION", @"");
  return [NSString stringWithFormat:template, [[data currentLocation] name]];
}

- (BOOL)showCornerImage
{
  return YES;
}

- (NSView *)contentView
{
  return contentView;
}

- (BOOL)canSaveData
{
  return YES;
}

- (void)loadData:(id<XMSetupAssistantData>)data
{
  int selectedIndex = [data hasAttribute:XMAttribute_UseSIPRegistrar] ? 0 : 1;
  [useRegistrarRadioButtons selectCellAtRow:selectedIndex column:0];
}

- (void)saveData:(id<XMSetupAssistantData>)data
{
  int selectedIndex = [useRegistrarRadioButtons selectedRow];
  if (selectedIndex == 0) {
    [data setAttribute:XMAttribute_UseSIPRegistrar];
  } else {
    [data clearAttribute:XMAttribute_UseSIPRegistrar];
  }
}

- (void)editData:(NSArray *)editKeys
{
}

@end

@implementation XMSARegistrationModule 

- (NSArray *)editKeys
{
  return [NSArray array];
}

- (BOOL)isActiveForData:(id<XMSetupAssistantData>)data
{
  if ([[data currentLocation] enableSIP] && [data hasAttribute:XMAttribute_UseSIPRegistrar]) {
    return YES;
  }
  return NO;
}

- (NSString *)titleForData:(id<XMSetupAssistantData>)data
{
  NSString *template = NSLocalizedString(@"XM_SETUP_ASSISTANT_LOCATION", @"");
  return [NSString stringWithFormat:template, [[data currentLocation] name]];
}

- (BOOL)showCornerImage
{
  return YES;
}

- (NSView *)contentView
{
  return contentView;
}

- (BOOL)canSaveData
{
  return YES;
}

- (void)loadData:(id<XMSetupAssistantData>)data
{
}

- (void)saveData:(id<XMSetupAssistantData>)data
{
}

- (void)editData:(NSArray *)editKeys
{
}

@end

@implementation XMSAVideoModule 

- (NSArray *)editKeys
{
  return [NSArray array];
}

- (BOOL)isActiveForData:(id<XMSetupAssistantData>)data
{
  return YES;
}

- (NSString *)titleForData:(id<XMSetupAssistantData>)data
{
  NSString *template = NSLocalizedString(@"XM_SETUP_ASSISTANT_LOCATION", @"");
  return [NSString stringWithFormat:template, [[data currentLocation] name]];
}

- (BOOL)showCornerImage
{
  return YES;
}

- (NSView *)contentView
{
  return contentView;
}

- (BOOL)canSaveData
{
  return YES;
}

- (void)loadData:(id<XMSetupAssistantData>)data
{
  int selectedIndex = [[data currentLocation] enableVideo] ? 0 : 1;
  [videoRadioButtons selectCellAtRow:selectedIndex column:0];
}

- (void)saveData:(id<XMSetupAssistantData>)data
{
  XMLocation *location = [data currentLocation];
  
  int selectedIndex = [videoRadioButtons selectedRow];
  if (selectedIndex == 0) {
    [location setEnableVideo:YES];
  } else {
    [location setEnableVideo:NO];
  }
}

- (void)editData:(NSArray *)editKeys
{
}

@end

#pragma mark -
#pragma mark Edit Mode

/**
 * Dummy module that simply displays a view
 **/
@implementation XMSAEditIntroductionModule

- (NSArray *)editKeys
{
  return [NSArray array];
}

- (BOOL)isActiveForData:(id<XMSetupAssistantData>)data
{
  return YES;
}

- (NSString *)titleForData:(id<XMSetupAssistantData>)data
{
  return NSLocalizedString(@"XM_SETUP_ASSISTANT_NAME", @"");
}

- (BOOL)showCornerImage
{
  return NO;
}

- (NSView *)contentView
{
  return contentView;
}

- (BOOL)canSaveData
{
  return YES;
}

- (void)loadData:(id<XMSetupAssistantData>)data
{
}

- (void)saveData:(id<XMSetupAssistantData>)data
{
}

- (void)editData:(NSArray *)editKeys
{
}

@end

@implementation XMSAEditDoneModule 

- (NSArray *)editKeys
{
  return [NSArray array];
}

- (BOOL)isActiveForData:(id<XMSetupAssistantData>)data
{
  return YES;
}

- (NSString *)titleForData:(id<XMSetupAssistantData>)data
{
  return NSLocalizedString(@"XM_SETUP_ASSISTANT_PI", @"");
}

- (BOOL)showCornerImage
{
  return YES;
}

- (NSView *)contentView
{
  return contentView;
}

- (BOOL)canSaveData
{
  return YES;
}

- (void)loadData:(id<XMSetupAssistantData>)data
{
}

- (void)saveData:(id<XMSetupAssistantData>)data
{
}

- (void)editData:(NSArray *)editKeys
{
}

- (IBAction)continueAssistant:(id)sender
{
  XMSAEditController *controller = (XMSAEditController *)[[XMSetupAssistantManager sharedInstance] controller];
  [controller continueAssistant];
}

@end
