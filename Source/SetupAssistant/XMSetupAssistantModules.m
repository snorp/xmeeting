/*
 * $Id: XMSetupAssistantModules.m,v 1.2 2009/01/08 06:26:49 hfriederich Exp $
 *
 * Copyright (c) 2009 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2009 Hannes Friederich. All rights reserved.
 */

#import "XMSetupAssistantModules.h"

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

- (NSString *)title
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

- (NSString *)title
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
  BOOL enableImportLocation = NO;
  BOOL enableEditLocation = NO;
  
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
    [locationsTable setEnabled:NO];
  } else {
    [locationsTable setEnabled:YES];
  }
}

- (void)saveData:(id<XMSetupAssistantData>)data
{
  int rowIndex = [locationRadioButtons selectedRow];
  
  if (rowIndex == 0) {
    [data clearAttribute:XMAttribute_EditLocation];
    [data setAttribute:XMAttribute_NewLocation];
  } else if (rowIndex == 1) {
    // TODO
  } else {
    [data clearAttribute:XMAttribute_NewLocation];
    [data setAttribute:XMAttribute_EditLocation];
  }
  
  // TODO: Add code to select location
}

- (void)editData:(NSArray *)editKeys
{
  // no need to do anything
}

- (IBAction)radioButtonAction:(id)sender
{
  int rowIndex = [locationRadioButtons selectedRow];
  
  if (rowIndex == 2) {
    [locationsTable setEnabled:YES];
  } else {
    [locationsTable setEnabled:NO];
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

- (NSString *)title
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

- (NSString *)title
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

- (NSString *)title
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

@end

@implementation XMSAH323Module 

- (NSArray *)editKeys
{
  return [NSArray array];
}

- (BOOL)isActiveForData:(id<XMSetupAssistantData>)data
{
  return YES;
}

- (NSString *)title
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

@end

@implementation XMSAGatekeeperModule 

- (NSArray *)editKeys
{
  return [NSArray array];
}

- (BOOL)isActiveForData:(id<XMSetupAssistantData>)data
{
  return YES;
}

- (NSString *)title
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

@end

@implementation XMSASIPModule 

- (NSArray *)editKeys
{
  return [NSArray array];
}

- (BOOL)isActiveForData:(id<XMSetupAssistantData>)data
{
  return YES;
}

- (NSString *)title
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

@end

@implementation XMSARegistrationModule 

- (NSArray *)editKeys
{
  return [NSArray array];
}

- (BOOL)isActiveForData:(id<XMSetupAssistantData>)data
{
  return YES;
}

- (NSString *)title
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

- (NSString *)title
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

- (NSString *)title
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

- (NSString *)title
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
