/*
 * $Id: XMAccountPreferencesModule.m,v 1.10 2007/08/14 10:56:39 hfriederich Exp $
 *
 * Copyright (c) 2006-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2007 Hannes Friederich. All rights reserved.
 */

#import "XMAccountPreferencesModule.h"

#import "XMPreferencesManager.h"
#import "XMPreferencesWindowController.h"
#import "XMLocationPreferencesModule.h"
#import "XMH323Account.h"
#import "XMSIPAccount.h"

NSString *XMKey_AccountPreferencesNameIdentifier = @"name";
NSString *XMKey_AccountPreferencesHostIdentifier = @"host";
NSString *XMKey_AccountPreferencesUsernameIdentifier = @"username";
NSString *XMKey_AccountPreferencesPhoneNumberIdentifier = @"phonenumber";
NSString *XMKey_AccountPreferencesAuthorizationUsernameIdentifier = @"authorizationUsername";

@interface XMAccountPreferencesModule (PrivateMethods)

- (void)_validateButtons;

- (void)_h323EditAccountPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)_sipEditAccountPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (void)_alertAccountName;

@end

@implementation XMAccountPreferencesModule

#pragma mark -
#pragma mark Init & Deallocation Methods

- (id)init
{
  prefWindowController = [[XMPreferencesWindowController sharedInstance] retain];
  
  h323Accounts = [[NSMutableArray alloc] initWithCapacity:5];
  sipAccounts = [[NSMutableArray alloc] initWithCapacity:5];
  
  return self;
}

- (void)awakeFromNib
{
  contentViewHeight = [contentView frame].size.height;
  [prefWindowController addPreferencesModule:self];
  
  [h323AccountsTableView setTarget:self];
  [h323AccountsTableView setDoubleAction:@selector(editH323Account:)];
  
  [sipAccountsTableView setTarget:self];
  [sipAccountsTableView setDoubleAction:@selector(editSIPAccount:)];
}

- (void)dealloc
{
  [prefWindowController release];
  
  [h323Accounts release];
  [sipAccounts release];
  
  [super dealloc];
}

#pragma mark -
#pragma mark XMPreferencesModule methods

- (unsigned)position
{
  return 2;
}

- (NSString *)identifier
{
  return @"XMeeting_AccountPreferencesModule";
}

- (NSString *)toolbarLabel
{
  return NSLocalizedString(@"XM_ACCOUNT_PREFERENCES_NAME", @"");
}

- (NSImage *)toolbarImage
{
  return [NSImage imageNamed:@"accountPreferences.tif"];
}

- (NSString *)toolTipText
{
  return NSLocalizedString(@"XM_ACCOUNT_PREFERENCES_TOOLTIP", @"");
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
  
  [h323Accounts removeAllObjects];
  [h323Accounts addObjectsFromArray:[preferencesManager h323Accounts]];
  
  [sipAccounts removeAllObjects];
  [sipAccounts addObjectsFromArray:[preferencesManager sipAccounts]];
  
  [self _validateButtons];
}

- (void)savePreferences
{
  XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
  
  [preferencesManager setH323Accounts:h323Accounts];
  [preferencesManager setSIPAccounts:sipAccounts];
}

- (void)becomeActiveModule
{
}

#pragma mark -
#pragma mark Action Methods

- (IBAction)addH323Account:(id)sender
{
  h323AccountToEdit = nil;
  
  [h323AccountNameField setStringValue:@""];
  [h323GatekeeperHostField setStringValue:@""];
  [h323UsernameField setStringValue:@""];
  [h323PhoneNumberField setStringValue:@""];
  [h323PasswordField setStringValue:@""];
  
  [editH323AccountPanel makeFirstResponder:h323AccountNameField];
  
  [NSApp beginSheet:editH323AccountPanel modalForWindow:[contentView window] modalDelegate:self
     didEndSelector:@selector(_h323EditAccountPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (IBAction)deleteH323Account:(id)sender
{
  unsigned index = [h323AccountsTableView selectedRow];
  [h323Accounts removeObjectAtIndex:index];
  
  [prefWindowController notePreferencesDidChange];
  [locationModule noteAccountsDidChange];
  
  [self _validateButtons];
  [h323AccountsTableView reloadData];
}

- (IBAction)editH323Account:(id)sender
{
  unsigned index = [h323AccountsTableView selectedRow];
  
  h323AccountToEdit = (XMH323Account *)[h323Accounts objectAtIndex:index];
  
  NSString *string = [h323AccountToEdit name];
  if(string == nil)
  {
    string = @"";
  }
  [h323AccountNameField setStringValue:string];
  
  string = [h323AccountToEdit gatekeeper];
  if(string == nil)
  {
    string = @"";
  }
  [h323GatekeeperHostField setStringValue:string];
  
  string = [h323AccountToEdit username];
  if(string == nil)
  {
    string = @"";
  }
  [h323UsernameField setStringValue:string];
  
  string = [h323AccountToEdit phoneNumber];
  if(string == nil)
  {
    string = @"";
  }
  [h323PhoneNumberField setStringValue:string];
  
  string = [h323AccountToEdit password];
  if(string == nil)
  {
    string = @"";
  }
  [h323PasswordField setStringValue:string];
  
  [editH323AccountPanel makeFirstResponder:h323AccountNameField];
  
  [NSApp beginSheet:editH323AccountPanel modalForWindow:[contentView window] modalDelegate:self
     didEndSelector:@selector(_h323EditAccountPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (IBAction)addSIPAccount:(id)sender
{
  sipAccountToEdit = nil;
  
  [sipAccountNameField setStringValue:@""];
  [sipRegistrationDomainField setStringValue:@""];
  [sipUsernameField setStringValue:@""];
  [sipPasswordField setStringValue:@""];
  
  [editSIPAccountPanel makeFirstResponder:sipAccountNameField];
  
  [NSApp beginSheet:editSIPAccountPanel modalForWindow:[contentView window] modalDelegate:self
     didEndSelector:@selector(_sipEditAccountPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (IBAction)deleteSIPAccount:(id)sender
{
  unsigned index = [sipAccountsTableView selectedRow];
  [sipAccounts removeObjectAtIndex:index];
  
  [prefWindowController notePreferencesDidChange];
  [locationModule noteAccountsDidChange];
  
  [self _validateButtons];
  [sipAccountsTableView reloadData];
}

- (IBAction)editSIPAccount:(id)sender
{
  unsigned index = [sipAccountsTableView selectedRow];
  
  sipAccountToEdit = (XMSIPAccount *)[sipAccounts objectAtIndex:index];
  
  NSString *string = [sipAccountToEdit name];
  if(string == nil)
  {
    string = @"";
  }
  [sipAccountNameField setStringValue:string];
  
  string = [sipAccountToEdit domain];
  if(string == nil)
  {
    string = @"";
  }
  [sipRegistrationDomainField setStringValue:string];
  
  string = [sipAccountToEdit username];
  if(string == nil)
  {
    string = @"";
  }
  [sipUsernameField setStringValue:string];
  
  string = [sipAccountToEdit authorizationUsername];
  if(string == nil)
  {
    string = @"";
  }
  [sipAuthorizationUsernameField setStringValue:string];
  
  string = [sipAccountToEdit password];
  if(string == nil)
  {
    string = @"";
  }
  [sipPasswordField setStringValue:string];
  
  [editSIPAccountPanel makeFirstResponder:sipAccountNameField];
  
  [NSApp beginSheet:editSIPAccountPanel modalForWindow:[contentView window] modalDelegate:self
     didEndSelector:@selector(_sipEditAccountPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (IBAction)endH323AccountEdit:(id)sender
{
  NSString *name = [h323AccountNameField stringValue];
  
  unsigned count = [h323Accounts count];
  unsigned i;
  
  for(i = 0; i < count; i++)
  {
    XMH323Account *account = [h323Accounts objectAtIndex:i];
    
    if(account == h323AccountToEdit)
    {
      continue;
    }
    
    if([[account name] isEqualToString:name])
    {
      [self _alertAccountName];
      return;
    }
  }
  
  [NSApp endSheet:editH323AccountPanel returnCode:NSRunStoppedResponse];
  [editH323AccountPanel orderOut:self];
}

- (IBAction)cancelH323AccountEdit:(id)sender
{
  [NSApp endSheet:editH323AccountPanel returnCode:NSRunAbortedResponse];
  [editH323AccountPanel orderOut:self];
}

- (IBAction)endSIPAccountEdit:(id)sender
{
  NSString *name = [sipAccountNameField stringValue];
  
  unsigned count = [sipAccounts count];
  unsigned i;
  
  for(i = 0; i < count; i++)
  {
    XMSIPAccount *account = [sipAccounts objectAtIndex:i];
    
    if(account == sipAccountToEdit)
    {
      continue;
    }
    
    if([[account name] isEqualToString:name])
    {
      [self _alertAccountName];
      return;
    }
  }
  
  [NSApp endSheet:editSIPAccountPanel returnCode:NSRunStoppedResponse];
  [editSIPAccountPanel orderOut:self];
}

- (IBAction)cancelSIPAccountEdit:(id)sender
{
  [NSApp endSheet:editSIPAccountPanel returnCode:NSRunAbortedResponse];
  [editSIPAccountPanel orderOut:self];
}

#pragma mark -
#pragma mark Location Module Help Methods

- (unsigned)h323AccountCount
{
  return [h323Accounts count];
}

- (XMH323Account *)h323AccountAtIndex:(unsigned)index
{
  return (XMH323Account *)[h323Accounts objectAtIndex:index];
}

- (unsigned)sipAccountCount
{
  return [sipAccounts count];
}

- (XMSIPAccount *)sipAccountAtIndex:(unsigned)index
{
  return (XMSIPAccount *)[sipAccounts objectAtIndex:index];
}

- (NSArray *)sipAccounts
{
  return sipAccounts;
}

- (void)addH323Accounts:(NSArray *)theAccounts
{
  unsigned count = [theAccounts count];
  unsigned i;
  
  for(i = 0; i < count; i++)
  {
    XMH323Account *account = (XMH323Account *)[theAccounts objectAtIndex:i];
    NSString *name = [account name];
    
    unsigned existingCount = [h323Accounts count];
    unsigned j;
    
    for(j = 0; j < existingCount; j++)
    {
      XMH323Account *accountToTest = (XMH323Account *)[h323Accounts objectAtIndex:j];
      
      if([[accountToTest name] isEqualToString:name])
      {
        name = [name stringByAppendingString:@" 1"];
        [account setName:name];
        j = 0;
      }
    }
    
    [h323Accounts addObject:account];
  }
  
  [self _validateButtons];
  [h323AccountsTableView reloadData];
}

- (void)addSIPAccounts:(NSArray *)theAccounts
{
  unsigned count = [theAccounts count];
  unsigned i;
  
  for(i = 0; i < count; i++)
  {
    XMSIPAccount *account = (XMSIPAccount *)[theAccounts objectAtIndex:i];
    NSString *name = [account name];
    
    unsigned existingCount = [sipAccounts count];
    unsigned j;
    
    for(j = 0; j < existingCount; j++)
    {
      XMSIPAccount *accountToTest = (XMSIPAccount *)[sipAccounts objectAtIndex:j];
      
      if([[accountToTest name] isEqualToString:name])
      {
        name = [name stringByAppendingString:@" 1"];
        [account setName:name];
        j = 0;
      }
    }
    
    [sipAccounts addObject:account];
  }
  
  [self _validateButtons];
  [sipAccountsTableView reloadData];
}

#pragma mark -
#pragma mark TableView data source & delegate methods

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{	
  if(tableView == h323AccountsTableView)
  {
    return [h323Accounts count];
  }
  else if(tableView == sipAccountsTableView)
  {
    return [sipAccounts count];
  }
  
  return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)rowIndex
{
  NSString *identifier = [tableColumn identifier];
  
  if(tableView == h323AccountsTableView)
  {
    XMH323Account *h323Account = (XMH323Account *)[h323Accounts objectAtIndex:rowIndex];
    
    if([identifier isEqualToString:XMKey_AccountPreferencesNameIdentifier])
    {
      return [h323Account name];
    }
    else if([identifier isEqualToString:XMKey_AccountPreferencesHostIdentifier])
    {
      return [h323Account gatekeeper];
    }
    else if([identifier isEqualToString:XMKey_AccountPreferencesUsernameIdentifier])
    {
      return [h323Account username];
    }
    else if([identifier isEqualToString:XMKey_AccountPreferencesPhoneNumberIdentifier])
    {
      return [h323Account phoneNumber];
    }
  }
  else if(tableView == sipAccountsTableView)
  {
    XMSIPAccount *sipAccount = (XMSIPAccount *)[sipAccounts objectAtIndex:rowIndex];
    
    if([identifier isEqualToString:XMKey_AccountPreferencesNameIdentifier])
    {
      return [sipAccount name];
    }
    else if([identifier isEqualToString:XMKey_AccountPreferencesHostIdentifier])
    {
      return [sipAccount domain];
    }
    else if([identifier isEqualToString:XMKey_AccountPreferencesUsernameIdentifier])
    {
      return [sipAccount username];
    }
    else if([identifier isEqualToString:XMKey_AccountPreferencesAuthorizationUsernameIdentifier])
    {
      return [sipAccount authorizationUsername];
    }
  }
  
  return @"";
}

- (void)tableViewSelectionDidChange:(NSNotification *)notif
{
  [self _validateButtons];
}

#pragma mark -
#pragma mark Private Methods

- (void)_validateButtons
{
  BOOL enableButtons;
  
  if([h323AccountsTableView selectedRow] == -1)
  {
    enableButtons = NO;
  }
  else
  {
    enableButtons = YES;
  }
  
  [deleteH323AccountButton setEnabled:enableButtons];
  [editH323AccountButton setEnabled:enableButtons];
  
  if([sipAccountsTableView selectedRow] == -1)
  {
    enableButtons = NO;
  }
  else
  {
    enableButtons = YES;
  }
  
  [deleteSIPAccountButton setEnabled:enableButtons];
  [editSIPAccountButton setEnabled:enableButtons];
}

- (void)_h323EditAccountPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
  if(returnCode == NSRunStoppedResponse)
  {
    BOOL isNewAccount = NO;
    
    if(h323AccountToEdit == nil)
    {
      h323AccountToEdit = [[XMH323Account alloc] init];
      isNewAccount = YES;
    }
    
    NSString *string = [h323AccountNameField stringValue];
    if([string isEqualToString:@""])
    {
      string = nil;
    }
    [h323AccountToEdit setName:string];
    
    string = [h323GatekeeperHostField stringValue];
    if([string isEqualToString:@""])
    {
      string = nil;
    }
    [h323AccountToEdit setGatekeeper:string];
    
    string = [h323UsernameField stringValue];
    if([string isEqualToString:@""])
    {
      string = nil;
    }
    [h323AccountToEdit setUsername:string];
    
    string = [h323PhoneNumberField stringValue];
    if([string isEqualToString:@""])
    {
      string = nil;
    }
    [h323AccountToEdit setPhoneNumber:string];
    
    string = [h323PasswordField stringValue];
    if([string isEqualToString:@""])
    {
      string = nil;
    }
    [h323AccountToEdit setPassword:string];
    
    if(isNewAccount == YES)
    {
      [h323Accounts addObject:h323AccountToEdit];
      [h323AccountToEdit release];
    }
    
    [prefWindowController notePreferencesDidChange];
    [locationModule noteAccountsDidChange];
    
    [self _validateButtons];
    [h323AccountsTableView reloadData];
  }
}

- (void)_sipEditAccountPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
  if(returnCode == NSRunStoppedResponse)
  {
    BOOL isNewAccount = NO;
    
    if(sipAccountToEdit == nil)
    {
      sipAccountToEdit = [[XMSIPAccount alloc] init];
      isNewAccount = YES;
    }
    
    NSString *string = [sipAccountNameField stringValue];
    if([string isEqualToString:@""])
    {
      string = nil;
    }
    [sipAccountToEdit setName:string];
    
    string = [sipRegistrationDomainField stringValue];
    if([string isEqualToString:@""])
    {
      string = nil;
    }
    [sipAccountToEdit setDomain:string];
    
    string = [sipUsernameField stringValue];
    if([string isEqualToString:@""])
    {
      string = nil;
    }
    [sipAccountToEdit setUsername:string];
    
    string = [sipAuthorizationUsernameField stringValue];
    if([string isEqualToString:@""])
    {
      string = nil;
    }
    [sipAccountToEdit setAuthorizationUsername:string];
    
    string = [sipPasswordField stringValue];
    if([string isEqualToString:@""])
    {
      string = nil;
    }
    [sipAccountToEdit setPassword:string];
    
    if(isNewAccount == YES)
    {
      [sipAccounts addObject:sipAccountToEdit];
      [sipAccountToEdit release];
    }
    
    [prefWindowController notePreferencesDidChange];
    [locationModule noteAccountsDidChange];
    
    [self _validateButtons];
    [sipAccountsTableView reloadData];
  }
}

- (void)_alertAccountName
{
  NSAlert *alert = [[NSAlert alloc] init];
  
  [alert setMessageText:NSLocalizedString(@"XM_ACCOUNT_PREFERENCES_NAME_EXISTS", @"")];
  [alert setInformativeText:NSLocalizedString(@"XM_PREFERENCES_NAME_SUGGESTION", @"")];
  [alert setAlertStyle:NSWarningAlertStyle];
  [alert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
  
  [alert runModal];
  
  [alert release];
}

@end
