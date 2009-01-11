/*
 * $Id: XMSetupAssistantModules.m,v 1.4 2009/01/11 17:20:41 hfriederich Exp $
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

- (BOOL)canContinue
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
  [[XMSetupAssistantManager sharedInstance] updateContinueStatus];
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

- (BOOL)canContinue
{
  return YES;
}

- (void)loadData:(id<XMSetupAssistantData>)data
{
  BOOL enableImportLocation = NO;
  BOOL enableEditLocation = NO;
  
  NSArray *locations = [data locations];
  XMLocation *lastLocation = (XMLocation *)[data getAttribute:XMAttribute_LastLocation];
  unsigned count = [locations count];
  unsigned selectedIndex = 0;
  for (unsigned i = 0; i < count; i++) {
    XMLocation *location = (XMLocation *)[locations objectAtIndex:i];
    if (location == lastLocation) {
      selectedIndex = i;
      break;
    }
  }
  
  [locationsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedIndex] byExtendingSelection:NO];
  [locationsTable reloadData];
  
  int rowIndex = 0;
  if ([data hasAttribute:XMAttribute_PreferencesEdit]) {
    enableEditLocation = YES;
    rowIndex = 2; // when editing, by default edit locations and do not create new ones
  }
  
  [[locationRadioButtons cellAtRow:1 column:0] setEnabled:enableImportLocation]; // row 1 is importLocation
  [[locationRadioButtons cellAtRow:2 column:0] setEnabled:enableEditLocation]; // row 2 is editLocation
  
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
    // keep current location if current location not in locations array,
    // as this is a new location in this case
    XMLocation *currentLocation = [data currentLocation];
    if (currentLocation != nil) {
      NSArray *locations = [data locations];
      unsigned count = [locations count];
      for (unsigned i = 0; i < count; i++) {
        XMLocation *location = (XMLocation *)[locations objectAtIndex:i];
        if (location == currentLocation) {
          [data setCurrentLocation:[data createLocation]];
          break;
        }
      }
    } else {
      [data setCurrentLocation:[data createLocation]];
    }
  } else if (rowIndex == 1) {
    // TODO
  } else {
    [data clearAttribute:XMAttribute_NewLocation];
    [data setAttribute:XMAttribute_EditLocation];
    
    int locationIndex = [locationsTable selectedRow];
    XMLocation *location = (XMLocation *)[[data locations] objectAtIndex:locationIndex];
    [data setCurrentLocation:location];
  }
  [data setAttribute:XMAttribute_LastLocation value:[data currentLocation]];
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

- (BOOL)canContinue
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
  [[XMSetupAssistantManager sharedInstance] updateContinueStatus];}

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

- (BOOL)canContinue
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

- (BOOL)canContinue
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
  [[XMSetupAssistantManager sharedInstance] updateContinueStatus];
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

- (BOOL)canContinue
{
  return YES;
}

- (void)loadData:(id<XMSetupAssistantData>)data
{
  XMLocation *currentLocation = [data currentLocation];
  XMLocation *lastLocation = (XMLocation *)[data getAttribute:XMAttribute_GatekeeperLastLocation];
  int selectedIndex = 1;
  
  if (currentLocation != lastLocation) { // read value from location
    selectedIndex = [currentLocation h323AccountTag] != 0 ? 0 : 1;
    [data clearH323AccountInfo]; // ensure data consistency
  } else { // read attribute
    selectedIndex = [data hasAttribute:XMAttribute_UseGatekeeper] ? 0 : 1;
  }
  [useGkRadioButtons selectCellAtRow:selectedIndex column:0];
}

- (void)saveData:(id<XMSetupAssistantData>)data
{
  XMLocation *currentLocation = [data currentLocation];
  [data setAttribute:XMAttribute_GatekeeperLastLocation value:currentLocation]; // store current location to ensure data integrity
  
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

- (BOOL)canContinue
{
  NSString *str = [gkUserAlias1Field stringValue];
  if ([str length] == 0) {
    [[gkUserAlias1Field window] makeFirstResponder:gkUserAlias1Field];
    return NO;
  }
  return YES;
}

- (void)loadData:(id<XMSetupAssistantData>)data
{
  [gkHostField setStringValue:[data gkHost]];
  [gkUserAlias1Field setStringValue:[data gkUserAlias1]];
  [gkUserAlias2Field setStringValue:[data gkUserAlias2]];
  [gkPasswordField setStringValue:[data gkPassword]];
}

- (void)saveData:(id<XMSetupAssistantData>)data
{
  [data setGKHost:[gkHostField stringValue]];
  [data setGKUserAlias1:[gkUserAlias1Field stringValue]];
  [data setGKUserAlias2:[gkUserAlias2Field stringValue]];
  [data setGKPassword:[gkPasswordField stringValue]];
}

- (void)editData:(NSArray *)editKeys
{
  [[gkHostField window] makeFirstResponder:gkHostField];
}

- (void)controlTextDidChange:(NSNotification *)notif
{
  [[XMSetupAssistantManager sharedInstance] updateContinueStatus];
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

- (BOOL)canContinue
{
  return YES;
}

- (void)loadData:(id<XMSetupAssistantData>)data
{
  XMLocation *currentLocation = [data currentLocation];
  XMLocation *lastLocation = (XMLocation *)[data getAttribute:XMAttribute_SIPRegistrationLastLocation];
  int selectedIndex = 1;
  
  if (currentLocation != lastLocation) { // read value from location
    selectedIndex = [currentLocation defaultSIPAccountTag] != 0 ? 0 : 1;
    [data clearSIPAccountInfo]; // ensure data consistency
  } else { // read attribute
    selectedIndex = [data hasAttribute:XMAttribute_UseSIPRegistration] ? 0 : 1;
  }
  [useRegistrationRadioButtons selectCellAtRow:selectedIndex column:0];
}

- (void)saveData:(id<XMSetupAssistantData>)data
{
  XMLocation *currentLocation = [data currentLocation];
  [data setAttribute:XMAttribute_SIPRegistrationLastLocation value:currentLocation]; // store current location to ensure data integrity
  
  int selectedIndex = [useRegistrationRadioButtons selectedRow];
  if (selectedIndex == 0) {
    [data setAttribute:XMAttribute_UseSIPRegistration];
  } else {
    [data clearAttribute:XMAttribute_UseSIPRegistration];
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
  if ([[data currentLocation] enableSIP] && [data hasAttribute:XMAttribute_UseSIPRegistration]) {
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

- (BOOL)canContinue
{
  NSString *str = [sipRegDomainField stringValue];
  if ([str length] == 0) {
    return NO;
  }
  str = [sipRegUsernameField stringValue];
  if ([str length] == 0) {
    return NO;
  }
  return YES;
}

- (void)loadData:(id<XMSetupAssistantData>)data
{
  [sipRegDomainField setStringValue:[data sipRegDomain]];
  [sipRegUsernameField setStringValue:[data sipRegUsername]];
  [sipRegAuthorizationUsernameField setStringValue:[data sipRegAuthorizationUsername]];
  [sipRegPasswordField setStringValue:[data sipRegPassword]];
}

- (void)saveData:(id<XMSetupAssistantData>)data
{
  [data setSIPRegDomain:[sipRegDomainField stringValue]];
  [data setSIPRegUsername:[sipRegUsernameField stringValue]];
  [data setSIPRegAuthorizationUsername:[sipRegAuthorizationUsernameField stringValue]];
  [data setSIPRegPassword:[sipRegPasswordField stringValue]];
}

- (void)editData:(NSArray *)editKeys
{
  [[sipRegDomainField window] makeFirstResponder:sipRegDomainField];
}

- (void)controlTextDidChange:(NSNotification *)notif
{
  [[XMSetupAssistantManager sharedInstance] updateContinueStatus];
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

- (BOOL)canContinue
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

- (BOOL)canContinue
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
  return NSLocalizedString(@"XM_SETUP_ASSISTANT_COMPLETED", @"");
}

- (BOOL)showCornerImage
{
  return YES;
}

- (NSView *)contentView
{
  return contentView;
}

- (BOOL)canContinue
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

#pragma mark -
#pragma mark Edit Mode

/**
 * Dummy module that simply displays a view
 **/
@implementation XMSAFirstLaunchIntroductionModule

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
  return NSLocalizedString(@"XM_SETUP_ASSISTANT_WELCOME", @"");
}

- (BOOL)showCornerImage
{
  return NO;
}

- (NSView *)contentView
{
  return contentView;
}

- (BOOL)canContinue
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

@implementation XMSAFirstLaunchDoneModule 

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
  return NSLocalizedString(@"XM_SETUP_ASSISTANT_COMPLETED", @"");
}

- (BOOL)showCornerImage
{
  return YES;
}

- (NSView *)contentView
{
  return contentView;
}

- (BOOL)canContinue
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

