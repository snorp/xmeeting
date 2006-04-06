/*
 * $Id: XMAccountPreferencesModule.h,v 1.2 2006/04/06 23:15:32 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_ACCOUNT_PREFERENCES_MODULE_H__
#define __XM_ACCOUNT_PREFERENCES_MODULE_H__

#import <Cocoa/Cocoa.h>

#import "XMPreferencesModule.h"

extern NSString *XMKey_AccountPreferencesNameIdentifier;
extern NSString *XMKey_AccountPreferencesHostIdentifier;
extern NSString *XMKey_AccountPreferencesUsernameIdentifier;
extern NSString *XMKey_AccountPreferencesPhoneNumberIdentifier;

@class XMLocationPreferencesModule, XMH323Account, XMSIPAccount;

@interface XMAccountPreferencesModule : NSObject <XMPreferencesModule> {

	XMPreferencesWindowController *prefWindowController;
	
	NSMutableArray *h323Accounts;
	NSMutableArray *sipAccounts;
	
	XMH323Account *h323AccountToEdit;
	XMSIPAccount *sipAccountToEdit;
	
	IBOutlet NSView *contentView;
	float contentViewHeight;
	
	/* connection to the location module */
	IBOutlet XMLocationPreferencesModule *locationModule;
	
	IBOutlet NSTableView *h323AccountsTableView;
	IBOutlet NSButton *addH323AccountButton;
	IBOutlet NSButton *deleteH323AccountButton;
	IBOutlet NSButton *editH323AccountButton;
	
	IBOutlet NSTableView *sipAccountsTableView;
	IBOutlet NSButton *addSIPAccountButton;
	IBOutlet NSButton *deleteSIPAccountButton;
	IBOutlet NSButton *editSIPAccountButton;
	
	IBOutlet NSPanel *editH323AccountPanel;
	IBOutlet NSTextField *h323AccountNameField;
	IBOutlet NSTextField *h323GatekeeperHostField;
	IBOutlet NSTextField *h323UsernameField;
	IBOutlet NSTextField *h323PhoneNumberField;
	IBOutlet NSTextField *h323PasswordField;
	
	IBOutlet NSPanel *editSIPAccountPanel;
	IBOutlet NSTextField *sipAccountNameField;
	IBOutlet NSTextField *sipRegistrarHostField;
	IBOutlet NSTextField *sipUsernameField;
	IBOutlet NSTextField *sipAuthorizationUsernameField;
	IBOutlet NSTextField *sipPasswordField;

}

- (IBAction)addH323Account:(id)sender;
- (IBAction)deleteH323Account:(id)sender;
- (IBAction)editH323Account:(id)sender;

- (IBAction)addSIPAccount:(id)sender;
- (IBAction)deleteSIPAccount:(id)sender;
- (IBAction)editSIPAccount:(id)sender;

- (IBAction)endH323AccountEdit:(id)sender;
- (IBAction)cancelH323AccountEdit:(id)sender;

- (IBAction)endSIPAccountEdit:(id)sender;
- (IBAction)cancelSIPAccountEdit:(id)sender;

- (unsigned)h323AccountCount;
- (XMH323Account *)h323AccountAtIndex:(unsigned)index;

- (unsigned)sipAccountCount;
- (XMSIPAccount *)sipAccountAtIndex:(unsigned)index;

@end

#endif // __XM_ACCOUNT_PREFERENCES_MODULE_H__
