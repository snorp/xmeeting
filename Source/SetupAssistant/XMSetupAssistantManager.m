/*
 * $Id: XMSetupAssistantManager.m,v 1.23 2009/01/11 17:20:41 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#import "XMSetupAssistantManager.h"
#import "XMPreferencesWindowController.h"

#import "XMeeting.h"
#import "XMPreferencesManager.h"
#import "XMPreferencesWindowController.h"
#import "XMPreferencesModule.h"
#import "XMLocation.h"
#import "XMH323Account.h"
#import "XMSIPAccount.h"
#import "XMApplicationFunctions.h"

NSString *XMAttribute_FirstLaunch = @"FirstLaunch";
NSString *XMAttribute_PreferencesEdit = @"PreferencesEdit";
NSString *XMAttribute_LocationImport = @"LocationImport";
NSString *XMAttribute_LastLocation = @"LastLocation";
NSString *XMAttribute_NewLocation = @"NewLocation";
NSString *XMAttribute_EditLocation = @"EditLocation";
NSString *XMAttribute_GatekeeperLastLocation = @"GatekeeperLastLocation";
NSString *XMAttribute_UseGatekeeper = @"UseGatekeeper";
NSString *XMAttribute_SIPRegistrationLastLocation = @"SIPRegistrationLastLocation";
NSString *XMAttribute_UseSIPRegistration = @"UseSIPRegistration";

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
- (void)_cleanup;

- (void)_loadModule:(id<XMSetupAssistantModule>)module;
- (void)_setupButtons;

- (XMH323Account *)_h323AccountWithTag:(unsigned)tag;
- (XMSIPAccount *)_sipAccountWithTag:(unsigned)tag;

- (void)_createH323AccountForLocation:(XMLocation *)location;
- (void)_createSIPAccountForLocation:(XMLocation *)location;

- (void)_updateDataOfH323Account:(XMH323Account *)account;
- (void)_updateDataOfSIPAccount:(XMSIPAccount *)account;

@end

@implementation XMSetupAssistantManager

#pragma mark Class Methods

static XMSetupAssistantManager *sharedInstance = nil;

+ (XMSetupAssistantManager *)sharedInstance
{  
  if (sharedInstance == nil) {
    sharedInstance = [[XMSetupAssistantManager alloc] _init];
  }
  
  return sharedInstance;
}

#pragma mark -
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
  
  locations = nil;
  h323Accounts = nil;
  sipAccounts = nil;
  currentLocation = nil;
  username = nil;
  gkHost = nil;
  gkUserAlias1 = nil;
  gkUserAlias2 = nil;
  gkPassword = nil;
  sipRegDomain = nil;
  sipRegUsername = nil;
  sipRegAuthorizationUsername = nil;
  sipRegPassword = nil;
  
  editKeys = nil;
  attributes = nil;
  
  return self;
}

- (void)_cleanup
{
  [locations release];
  locations = nil;
  
  [h323Accounts release];
  h323Accounts = nil;
  
  [sipAccounts release];
  sipAccounts = nil;
  
  [currentLocation release];
  currentLocation = nil;
  
  [username release];
  username = nil;
  
  [gkHost release];
  gkHost = nil;
  [gkUserAlias1 release];
  gkUserAlias1 = nil;
  [gkUserAlias2 release];
  gkUserAlias2 = nil;
  [gkPassword release];
  gkPassword = nil;
  
  [sipRegDomain release];
  sipRegDomain = nil;
  [sipRegUsername release];
  sipRegUsername = nil;
  [sipRegAuthorizationUsername release];
  sipRegAuthorizationUsername = nil;
  [sipRegPassword release];
  sipRegPassword = nil;
  
  [controller release];
  controller = nil;
  
  currentModule = nil; // never retained
  
  [editKeys release];
  editKeys = nil;
  [attributes release];
  attributes = nil;
}

- (void)dealloc
{
  [self _cleanup];
  [super dealloc];
}

#pragma mark -
#pragma mark Public Methods

- (void)runEditAssistantInWindow:(NSWindow *)displayWindow
{
  XMPreferencesManager *prefManager = [XMPreferencesManager sharedInstance];
  
  // trigger loading of the nib file if needed
  [self window];
  
  // refresh the locations and accounts
  [self _cleanup];
  locations = [[prefManager locations] copy];
  h323Accounts = [[prefManager h323Accounts] copy];
  sipAccounts = [[prefManager sipAccounts] copy];
  
  [controller release];
  controller = [[XMSAEditController alloc] initWithSetupAssistant:self];
  attributes = [[NSMutableDictionary alloc] initWithCapacity:8];
  [self setAttribute:XMAttribute_PreferencesEdit];
  
  [self continueAssistant:self];
  
  [displayWindow setContentView:contentView];
  [detailedViewButton setHidden:NO];
}

- (void)abortEditAssistant
{
  [[contentView window] performClose:self];
}

- (void)finishEditAssistant
{
  XMPreferencesManager *prefManager = [XMPreferencesManager sharedInstance];
  
  if (username != nil) {
    [prefManager setUserName:username];
  }
  if (h323Accounts != nil) {
    [prefManager setH323Accounts:h323Accounts];
  }
  if (sipAccounts != nil) {
    [prefManager setSIPAccounts:sipAccounts];
  }
  if (locations != nil) {
    [prefManager setLocations:locations];
  }
  [prefManager synchronizeAndNotify];
  
  // close window without user interaction
  [[contentView window] close];
}

- (void)runFirstApplicationLaunchAssistantWithDelegate:(NSObject *)theDelegate
                    didEndSelector:(SEL)theDidEndSelector
{
  delegate = theDelegate;
  didEndSelector = theDidEndSelector;
  
  // cleanup
  [self _cleanup];
  
  // triggering the nib loading if necessary
  NSWindow *window = [self window];
  
  // create empty data
  locations = [[NSArray alloc] init];
  h323Accounts = [[NSArray alloc] init];
  sipAccounts = [[NSArray alloc] init];
  
  [controller release];
  controller = [[XMSAFirstLaunchController alloc] initWithSetupAssistant:self];
  attributes = [[NSMutableDictionary alloc] initWithCapacity:8];
  [self setAttribute:XMAttribute_FirstLaunch];
  
  [self continueAssistant:self];
  
  [window setContentView:contentView];
  [detailedViewButton setHidden:YES];
  
  // changing some default settings of the location
  [currentLocation setEnableVideo:YES];
  [currentLocation setBandwidthLimit:512000];
  [currentLocation setEnableH323:YES];
  [currentLocation setEnableSIP:YES];
  
  // show the assistant
  [window center];
  [window setContentView:contentView];
  [self showWindow:self];
}

- (void)abortFirstLaunchAssistant
{
  [[self window] close];
  [delegate performSelector:didEndSelector];
}

- (void)finishFirstLaunchAssistant
{
  XMPreferencesManager *prefManager = [XMPreferencesManager sharedInstance];
  
  if (username != nil) {
    [prefManager setUserName:username];
  }
  if (h323Accounts != nil) {
    [prefManager setH323Accounts:h323Accounts];
  }
  if (sipAccounts != nil) {
    [prefManager setSIPAccounts:sipAccounts];
  }
  if (locations != nil) {
    [prefManager setLocations:locations];
  }
  [prefManager synchronizeAndNotify];
  
  [[self window] close];
  [delegate performSelector:didEndSelector];
}

- (void)runImportLocationsAssistantModalForWindow:(NSWindow *)window 
                  modalDelegate:(NSObject *)theModalDelegate
                   didEndSelector:(SEL)theDidEndSelector
{
  /*modalWindow = window;
  delegate = theModalDelegate;
  didEndSelector = theDidEndSelector;
  
  currentKeysToAskIndex = 0;
  
  if (locationFilePath != nil)
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
              contextInfo:NULL];*/
}

- (NSSize)contentViewSize
{
  // force loading of the nib file
  [self window];
  
  return [contentView bounds].size;
}

- (id<XMSetupAssistantController>)controller
{
  return controller;
}

- (id<XMSetupAssistantModule>)currentModule
{
  return currentModule;
}

- (void)setEditKeys:(NSArray *)keys
{
  NSArray *old = editKeys;
  editKeys = [keys retain];
  [old release];
}

- (void)addLocation:(XMLocation *)location
{
  NSArray *old = locations;
  locations = [[locations arrayByAddingObject:location] retain];
  [old release];
}

- (void)updateContinueStatus
{
  if ([currentModule canContinue]) {
    [continueButton setEnabled:YES];
  } else {
    [continueButton setEnabled:NO];
  }
} 

#pragma mark -
#pragma mark XMSetupAssistantData Methods

- (NSArray *)locations
{
  return locations;
}

- (BOOL)hasAttribute:(NSString *)attribute
{
  return ([attributes objectForKey:attribute] != nil) ? YES : NO;
}

- (NSObject *)getAttribute:(NSString *)attribute
{
  return [attributes objectForKey:attribute];
}

- (void)setAttribute:(NSString *)attribute
{
  [attributes setObject:attribute forKey:attribute];
}

- (void)setAttribute:(NSString *)attribute value:(NSObject *)value
{
  [attributes setObject:value forKey:attribute];
}

- (void)clearAttribute:(NSString *)attribute
{
  [attributes removeObjectForKey:attribute];
}

- (XMLocation *)currentLocation
{
  return currentLocation;
}

- (void)setCurrentLocation:(XMLocation *)location
{
  XMLocation *old = currentLocation;
  currentLocation = [location retain];
  [old release];
}

- (XMLocation *)createLocation
{
  XMLocation *location = [[XMLocation alloc] init];
  // set some default values
  [location setEnableVideo:YES];
  [location setBandwidthLimit:512000];
  [location setEnableH323:YES];
  [location setEnableSIP:YES];
  
  // choose appropriate name
  NSString *nameTemplate = NSLocalizedString(@"XM_SETUP_ASSISTANT_NEW_LOCATION_NAME", @"");
  unsigned index = 1;
  while (index < 1000) {
    NSString *name = [NSString stringWithFormat:nameTemplate, index];
    
    unsigned count = [locations count];
    BOOL found = NO;
    for (unsigned i = 0; i < count; i++) {
      XMLocation *location = (XMLocation *)[locations objectAtIndex:i];
      if ([[location name] isEqualToString:name]) {
        found = YES;
        break;
      }
    }
    if (found == NO) {
      [location setName:name];
      index = 1000;
    }
    index++;
  }
  
  return [location autorelease];
}

- (NSString *)username
{
  if (username == nil) {
    username = [[[XMPreferencesManager sharedInstance] userName] retain];
  }
  return username;
}

- (void)setUsername:(NSString *)newUsername
{
  NSString *old = username;
  username = [newUsername retain];
  [old release];
}

- (void)clearH323AccountInfo
{
  [gkHost release];
  gkHost = nil;
  [gkUserAlias1 release];
  gkUserAlias1 = nil;
  [gkUserAlias2 release];
  gkUserAlias2 = nil;
  [gkPassword release];
  gkPassword = nil;
}

- (void)saveH323AccountInfo
{
  unsigned tag = [currentLocation h323AccountTag];
  BOOL useGK = [self hasAttribute:XMAttribute_UseGatekeeper];
  
  if (tag == 0 && useGK == NO) {
    // not using GK, and not planned to do so -> do nothing
  } else if (tag == 0 && useGK == YES) {
    // not using GK so far, but planned to do so: create new account
    [self _createH323AccountForLocation:currentLocation];
  } else if (tag != 0 && useGK == NO) {
    // using GK, but planned to no longer do so: remove acount if possible
    BOOL requireAccount = NO;
    unsigned count = [locations count];
    for (unsigned i = 0; i < count; i++) {
      XMLocation *location = (XMLocation *)[locations objectAtIndex:i];
      if (location != currentLocation) {
        if ([location h323AccountTag] == tag) { // other location uses same account
          requireAccount = YES;
          break;
        }
      }
    }
    if (requireAccount == NO) {
      // delete account
      NSMutableArray *accounts = [h323Accounts mutableCopy];
      unsigned count = [accounts count];
      for (unsigned i = 0; i < count; i++) {
        XMH323Account *account = (XMH323Account *)[accounts objectAtIndex:i];
        if ([account tag] == tag) {
          [accounts removeObjectAtIndex:i];
          break;
        }
      }
      NSArray *old = h323Accounts;
      h323Accounts = [accounts copy];
      [old release];
      [accounts release];
    }
    [currentLocation setH323AccountTag:0]; // remove account binding
  } else {
    // using GK, and planned to do so: update account data.
    XMH323Account *account = [self _h323AccountWithTag:tag];
    
    [self _updateDataOfH323Account:account];
  }
  
  [self clearH323AccountInfo];
}

- (NSString *)gkHost
{
  if (gkHost == nil) {
    unsigned tag = [currentLocation h323AccountTag];
    if (tag != nil) {
      XMH323Account *account = [self _h323AccountWithTag:tag];
      if (account != nil) {
        gkHost = [account gatekeeperHost];
      }
    }
    if (gkHost == nil) {
      gkHost = @"";
    }
    [gkHost retain];
  }
  return gkHost;
}

- (void)setGKHost:(NSString *)host
{
  NSString *old = gkHost;
  gkHost = [host copy];
  [old release];
}

- (NSString *)gkUserAlias1
{
  if (gkUserAlias1 == nil) {
    unsigned tag = [currentLocation h323AccountTag];
    if (tag != nil) {
      XMH323Account *account = [self _h323AccountWithTag:tag];
      if (account != nil) {
        gkUserAlias1 = [account terminalAlias1];
      }
    }
    if (gkUserAlias1 == nil) {
      gkUserAlias1 = @"";
    }
    [gkUserAlias1 retain];
  }
  return gkUserAlias1;
}

- (void)setGKUserAlias1:(NSString *)userAlias
{
  NSString *old = gkUserAlias1;
  gkUserAlias1 = [userAlias copy];
  [old release];
}

- (NSString *)gkUserAlias2
{
  if (gkUserAlias2 == nil) {
    unsigned tag = [currentLocation h323AccountTag];
    if (tag != nil) {
      XMH323Account *account = [self _h323AccountWithTag:tag];
      if (account != nil) {
        gkUserAlias2 = [account terminalAlias2];
      }
    }
    if (gkUserAlias2 == nil) {
      gkUserAlias2 = @"";
    }
    [gkUserAlias2 retain];
  }
  return gkUserAlias2;
}

- (void)setGKUserAlias2:(NSString *)userAlias
{
  NSString *old = gkUserAlias2;
  gkUserAlias2 = [userAlias copy];
  [old release];
}

- (NSString *)gkPassword
{
  if (gkPassword == nil) {
    unsigned tag = [currentLocation h323AccountTag];
    if (tag != nil) {
      XMH323Account *account = [self _h323AccountWithTag:tag];
      if (account != nil) {
        gkPassword = [account password];
      }
    }
    if (gkPassword == nil) {
      gkPassword = @"";
    }
    [gkPassword retain];
  }
  return gkPassword;
}

- (void)setGKPassword:(NSString *)password
{
  NSString *old = gkPassword;
  gkPassword = [password copy];
  [old release];
}

- (void)clearSIPAccountInfo
{
  [sipRegDomain release];
  sipRegDomain = nil;
  [sipRegUsername release];
  sipRegUsername = nil;
  [sipRegAuthorizationUsername release];
  sipRegAuthorizationUsername = nil;
  [sipRegPassword release];
  sipRegPassword = nil;
}

- (void)saveSIPAccountInfo
{
  unsigned tag = [currentLocation defaultSIPAccountTag];
  BOOL useReg = [self hasAttribute:XMAttribute_UseSIPRegistration];
  
  if (tag == 0 && useReg == NO) {
    // not using registration, and not planned to do so -> do nothing
  } else if (tag == 0 && useReg == YES) {
    // not using registration so far, but planned to do so: create new account
    [self _createSIPAccountForLocation:currentLocation];
  } else if (tag != 0 && useReg == NO) {
    // using registration, but planned to no longer do so: remove acount if possible
    BOOL requireAccount = NO;
    unsigned count = [locations count];
    for (unsigned i = 0; i < count; i++) {
      XMLocation *location = (XMLocation *)[locations objectAtIndex:i];
      if (location != currentLocation) {
        NSArray *sipTags = [location sipAccountTags];
        unsigned sipTagCount = [sipTags count];
        for (unsigned j = 0; j < sipTagCount; j++) {
          NSNumber *number = (NSNumber *)[sipTags objectAtIndex:j];
          if ([number unsignedIntValue] == tag) { // other location uses same account
            requireAccount = YES;
            break;
          }
        }
        if (requireAccount == YES) {
          break;
        }
      }
    }
    if (requireAccount == NO) {
      // delete account
      NSMutableArray *accounts = [sipAccounts mutableCopy];
      unsigned count = [accounts count];
      for (unsigned i = 0; i < count; i++) {
        XMSIPAccount *account = (XMSIPAccount *)[accounts objectAtIndex:i];
        if ([account tag] == tag) {
          [accounts removeObjectAtIndex:i];
          break;
        }
      }
      NSArray *old = sipAccounts;
      sipAccounts = [accounts copy];
      [old release];
      [accounts release];
    }
    [currentLocation setSIPAccountTags:[NSArray array]]; // remove account binding
    [currentLocation setDefaultSIPAccountTag:0];
  } else {
    // using registration, and planned to do so: update account data.
    XMSIPAccount *account = [self _sipAccountWithTag:tag];
    
    [self _updateDataOfSIPAccount:account];
  }
  
  [self clearSIPAccountInfo];
}

- (NSString *)sipRegDomain
{
  if (sipRegDomain == nil) {
    unsigned tag = [currentLocation defaultSIPAccountTag];
    if (tag != nil) {
      XMSIPAccount *account = [self _sipAccountWithTag:tag];
      if (account != nil) {
        sipRegDomain = [account domain];
      }
    }
    if (sipRegDomain == nil) {
      sipRegDomain = @"";
    }
    [sipRegDomain retain];
  }
  return sipRegDomain;
}

- (void)setSIPRegDomain:(NSString *)domain
{
  NSString *old = sipRegDomain;
  sipRegDomain = [domain copy];
  [old release];
}

- (NSString *)sipRegUsername
{
  if (sipRegUsername == nil) {
    unsigned tag = [currentLocation defaultSIPAccountTag];
    if (tag != nil) {
      XMSIPAccount *account = [self _sipAccountWithTag:tag];
      if (account != nil) {
        sipRegUsername = [account username];
      }
    }
    if (sipRegUsername == nil) {
      sipRegUsername = @"";
    }
    [sipRegUsername retain];
  }
  return sipRegUsername;
}

- (void)setSIPRegUsername:(NSString *)sipUsername
{
  NSString *old = sipRegUsername;
  sipRegUsername = [sipUsername copy];
  [old release];
}

- (NSString *)sipRegAuthorizationUsername
{
  if (sipRegAuthorizationUsername == nil) {
    unsigned tag = [currentLocation defaultSIPAccountTag];
    if (tag != nil) {
      XMSIPAccount *account = [self _sipAccountWithTag:tag];
      if (account != nil) {
        sipRegAuthorizationUsername = [account authorizationUsername];
      }
    }
    if (sipRegAuthorizationUsername == nil) {
      sipRegAuthorizationUsername = @"";
    }
    [sipRegAuthorizationUsername retain];
  }
  return sipRegAuthorizationUsername;
}

- (void)setSIPRegAuthorizationUsername:(NSString *)authorizationUsername
{
  NSString *old = sipRegAuthorizationUsername;
  sipRegAuthorizationUsername = [authorizationUsername copy];
  [old release];
}

- (NSString *)sipRegPassword
{
  if (sipRegPassword == nil) {
    unsigned tag = [currentLocation defaultSIPAccountTag];
    if (tag != nil) {
      XMSIPAccount *account = [self _sipAccountWithTag:tag];
      if (account != nil) {
        sipRegPassword = [account password];
      }
    }
    if (sipRegPassword == nil) {
      sipRegPassword = @"";
    }
    [sipRegPassword retain];
  }
  return sipRegPassword;
}

- (void)setSIPRegPassword:(NSString *)password
{
  NSString *old = sipRegPassword;
  sipRegPassword = [password copy];
  [old release];
}

#pragma mark -
#pragma mark Action Methods

- (IBAction)cancelAssistant:(id)sender
{
  if (controller != nil) {
    [controller cancel];
  }
}

- (IBAction)continueAssistant:(id)sender
{
  if (currentModule != nil && ![currentModule canContinue]) {
    // should not happen actually
    NSBeep();
    return;
  }
  [currentModule saveData:self];
  
  if (controller != nil) {
    // loop until a 'valid' module is found
    int counter = 0;
    while (counter < 1000) { // avoid infinite loops
      id<XMSetupAssistantModule> module = [controller nextModule];
      if (module == nil) { // logic error
        NSBeep();
        return;
      }
      if ([module isActiveForData:self]) {
        [self _loadModule:module];
        break;
      }
      counter++;
    }
  }
}

- (IBAction)goBackAssistant:(id)sender
{
  // always can go back
  [currentModule saveData:self];
  
  if (controller != nil) {
    // loop until a 'valid' module is found
    int counter = 0;
    while(counter < 1000) {
      id<XMSetupAssistantModule> module = [controller previousModule];
      if (module == nil) { // logic error
        NSBeep();
        return;
      }
      if ([module isActiveForData:self]) {
        [self _loadModule:module];
        break;
      }
      counter++;
    }
  }
}

- (IBAction)switchToDetailedView:(id)sender
{
  [[XMPreferencesWindowController sharedInstance] switchToDetailedView:sender];
}

#pragma mark -
#pragma mark Private Methods

- (void)_loadModule:(id<XMSetupAssistantModule>)module
{
  [module loadData:self];
  
  [titleField setStringValue:[module titleForData:self]];
  [cornerImage setHidden:![module showCornerImage]];
  [contentBox setContentView:[module contentView]];
  
  // save reference to module
  currentModule = module;
  
  [self _setupButtons]; // set which buttons are enabled
  [self updateContinueStatus];
  [module editData:editKeys];
}

- (void)_setupButtons
{
  if ([controller hasNextModule]) {
    [continueButton setTitle:NSLocalizedString(@"XM_SETUP_ASSISTANT_CONTINUE", @"")];
    [continueButton setKeyEquivalent:@""];
  } else {
    [continueButton setTitle:NSLocalizedString(@"XM_SETUP_ASSISTANT_FINISH", @"")];
    [continueButton setKeyEquivalent:@"\r"];
  }
  [goBackButton setEnabled:[controller hasPreviousModule]];
}

- (XMH323Account *)_h323AccountWithTag:(unsigned)tag
{
  unsigned count = [h323Accounts count];
  for (unsigned i = 0; i < count; i++) {
    XMH323Account *account = (XMH323Account *)[h323Accounts objectAtIndex:i];
    if ([account tag] == tag) {
      return account;
    }
  }
  return nil;
}

- (XMSIPAccount *)_sipAccountWithTag:(unsigned)tag
{
  unsigned count = [sipAccounts count];
  for (unsigned i = 0; i < count; i++) {
    XMSIPAccount *account = (XMSIPAccount *)[sipAccounts objectAtIndex:i];
    if ([account tag] == tag) {
      return account;
    }
  }
  return nil;
}

- (void)_createH323AccountForLocation:(XMLocation *)location
{
  XMH323Account *account = [[XMH323Account alloc] init];
  
  // choose appropriate name
  NSString *nameTemplate = NSLocalizedString(@"XM_SETUP_ASSISTANT_NEW_H323_ACCOUNT_NAME", @"");
  unsigned index = 1;
  while (index < 1000) {
    NSString *name = [NSString stringWithFormat:nameTemplate, index];
    
    unsigned count = [h323Accounts count];
    BOOL found = NO;
    for (unsigned i = 0; i < count; i++) {
      XMH323Account *otherAccount = (XMH323Account *)[h323Accounts objectAtIndex:i];
      if ([[otherAccount name] isEqualToString:name]) {
        found = YES;
        break;
      }
    }
    if (found == NO) {
      [account setName:name];
      index = 1000;
    }
    index++;
  }
  
  [self _updateDataOfH323Account:account];
  
  // add account to H323 accounts
  NSArray *old = h323Accounts;
  h323Accounts = [[h323Accounts arrayByAddingObject:account] retain];
  [old release];
  
  // link location to account
  [location setH323AccountTag:[account tag]];
}

- (void)_createSIPAccountForLocation:(XMLocation *)location
{
  XMSIPAccount *account = [[XMSIPAccount alloc] init];
  
  // choose appropriate name
  NSString *nameTemplate = NSLocalizedString(@"XM_SETUP_ASSISTANT_NEW_SIP_ACCOUNT_NAME", @"");
  unsigned index = 1;
  while (index < 1000) {
    NSString *name = [NSString stringWithFormat:nameTemplate, index];
    
    unsigned count = [sipAccounts count];
    BOOL found = NO;
    for (unsigned i = 0; i < count; i++) {
      XMSIPAccount *otherAccount = (XMSIPAccount *)[sipAccounts objectAtIndex:i];
      if ([[otherAccount name] isEqualToString:name]) {
        found = YES;
        break;
      }
    }
    if (found == NO) {
      [account setName:name];
      index = 1000;
    }
    index++;
  }
  
  [self _updateDataOfSIPAccount:account];
  
  // add account to SIP accounts
  NSArray *old = sipAccounts;
  sipAccounts = [[sipAccounts arrayByAddingObject:account] retain];
  [old release];
  
  // link location to account
  [location setSIPAccountTags:[NSArray arrayWithObject:[NSNumber numberWithInt:[account tag]]]];
  [location setDefaultSIPAccountTag:[account tag]];
}

- (void)_updateDataOfH323Account:(XMH323Account *)account
{
  NSString *str = gkHost;
  if ([str length] == 0) {
    str = nil;
  }
  [account setGatekeeperHost:str];
  [account setTerminalAlias1:gkUserAlias1];
  str = gkUserAlias2;
  if ([str length] == 0) {
    str = nil;
  }
  [account setTerminalAlias2:str];
  str = gkPassword;
  if ([str length] == 0) {
    str = nil;
  }
  [account setPassword:str];
}

- (void)_updateDataOfSIPAccount:(XMSIPAccount *)account
{
  [account setDomain:sipRegDomain];
  [account setUsername:sipRegUsername];
  NSString *str = sipRegAuthorizationUsername;
  if ([str length] == 0) {
    str = nil;
  }
  [account setAuthorizationUsername:str];
  str = sipRegPassword;
  if ([str length] == 0) {
    str = nil;
  }
  [account setPassword:str];
}

@end

#pragma mark -
#pragma mark -

@implementation XMSAEditController

- (id)init
{
  [self doesNotRecognizeSelector:_cmd];
  [self release];
  return nil;
}

- (id)initWithSetupAssistant:(XMSetupAssistantManager *)setupAssistant
{
  firstLocation = YES;
  state = 0;
  moduleIndex = UINT_MAX;
  introductionModule = [setupAssistant->editIntroductionModule retain];
  generalModule = [setupAssistant->generalSettingsModule retain];
  modules = [[NSArray alloc] initWithObjects:setupAssistant->locationModule, setupAssistant->newLocationModule, 
                                             setupAssistant->networkModule, setupAssistant->protocolModule,
                                             setupAssistant->h323Module, setupAssistant->gatekeeperModule,
                                             setupAssistant->sipModule, setupAssistant->registrationModule,
                                             setupAssistant->videoModule, setupAssistant->editDoneModule, nil];
  
  [setupAssistant setEditKeys:[NSArray array]];
  
  return self;
}

- (void)dealloc
{
  [introductionModule release];
  [generalModule release];
  [modules release];
  
  [super dealloc];
}

- (id<XMSetupAssistantModule>)nextModule
{
  if (state == 0) { // first run, show introduction module
    state = 1;
    return introductionModule;
  } else if (state == 1) { // show general module next
    state = 2;
    moduleIndex = UINT_MAX;
    return generalModule;
  } else if (state >= 2) { // use modules from the array
    [[XMPreferencesWindowController sharedInstance] notePreferencesDidChange]; // mark window as dirty
    state = 3;
    moduleIndex++;
    if (moduleIndex == [modules count]) { // finished
      XMSetupAssistantManager *manager = [XMSetupAssistantManager sharedInstance];
      [manager saveH323AccountInfo];
      [manager saveSIPAccountInfo];
      if ([manager hasAttribute:XMAttribute_NewLocation]) {
        // store the location
        [manager addLocation:[manager currentLocation]];
      }
      [manager performSelector:@selector(finishEditAssistant) withObject:nil afterDelay:0.0];
      moduleIndex--;
    }
    return (id<XMSetupAssistantModule>)[modules objectAtIndex:moduleIndex];
  }
  return nil; // error
}

- (id<XMSetupAssistantModule>)previousModule
{
  if (state == 2) { // show introduction module again
    state = 1;
    return introductionModule;
  } else if (state == 3) {
    if (moduleIndex == 0 && firstLocation == YES) { // show general module again
      state = 2;
      moduleIndex = UINT_MAX;
      return generalModule;
    }
    moduleIndex--;
    return (id<XMSetupAssistantModule>)[modules objectAtIndex:moduleIndex];
  }
  return nil; // error
}

- (BOOL)hasNextModule
{
  if (state <= 2) {
    return YES;
  }
  return moduleIndex < ([modules count]-1) ? YES : NO;
}

- (BOOL)hasPreviousModule
{
  if (state < 2) { // introduction module
    return NO;
  } else if (state == 2) { // general module
    return YES;
  } else if (firstLocation == YES) { // allowed to go back
    return YES;
  }
  return moduleIndex > 0 ? YES : NO;
}

- (void)cancel
{
  [[XMSetupAssistantManager sharedInstance] abortEditAssistant];
}

- (void)continueAssistant
{
  if (state >= 2 && moduleIndex == [modules count]-1) {
    XMSetupAssistantManager *manager = [XMSetupAssistantManager sharedInstance];
    firstLocation = NO;
    moduleIndex = UINT_MAX;
    
    [manager saveH323AccountInfo];
    [manager saveSIPAccountInfo];
    if ([manager hasAttribute:XMAttribute_NewLocation]) {
      // store the location
      [manager addLocation:[manager currentLocation]];
    }
    
    // clear some attributes
    [manager clearAttribute:XMAttribute_NewLocation];
    [manager clearAttribute:XMAttribute_EditLocation];
    
    [manager continueAssistant:self];
  }
}

@end

#pragma mark -
#pragma mark -

@implementation XMSAFirstLaunchController

- (id)init
{
  [self doesNotRecognizeSelector:_cmd];
  [self release];
  return nil;
}

- (id)initWithSetupAssistant:(XMSetupAssistantManager *)setupAssistant
{
  moduleIndex = UINT_MAX;
  modules = [[NSArray alloc] initWithObjects:setupAssistant->firstLaunchIntroductionModule, 
             setupAssistant->generalSettingsModule, 
             setupAssistant->locationModule, 
             setupAssistant->newLocationModule, 
             setupAssistant->networkModule, 
             setupAssistant->protocolModule,
             setupAssistant->h323Module, 
             setupAssistant->gatekeeperModule,
             setupAssistant->sipModule, 
             setupAssistant->registrationModule,
             setupAssistant->videoModule, 
             setupAssistant->firstLaunchDoneModule, nil];
  
  [setupAssistant setEditKeys:[NSArray array]];
  
  return self;
}

- (void)dealloc
{
  [modules release];
  
  [super dealloc];
}

- (id<XMSetupAssistantModule>)nextModule
{
  moduleIndex++;
  if (moduleIndex == [modules count]) { // finished
    XMSetupAssistantManager *manager = [XMSetupAssistantManager sharedInstance];
    [manager saveH323AccountInfo];
    [manager saveSIPAccountInfo];
    [manager addLocation:[manager currentLocation]];
    [manager performSelector:@selector(finishFirstLaunchAssistant) withObject:nil afterDelay:0.0];
    moduleIndex--;
  }
  return (id<XMSetupAssistantModule>)[modules objectAtIndex:moduleIndex];
}

- (id<XMSetupAssistantModule>)previousModule
{
  moduleIndex--;
  return (id<XMSetupAssistantModule>)[modules objectAtIndex:moduleIndex];
}

- (BOOL)hasNextModule
{
  return moduleIndex < ([modules count]-1) ? YES : NO;
}

- (BOOL)hasPreviousModule
{
  return moduleIndex > 0 ? YES : NO;
}

- (void)cancel
{
  [[XMSetupAssistantManager sharedInstance] abortFirstLaunchAssistant];
}

@end