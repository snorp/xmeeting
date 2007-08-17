/*
 * $Id: XMAddressBookModule.h,v 1.12 2007/08/17 11:36:43 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_ADDRESS_BOOK_MODULE_H__
#define __XM_ADDRESS_BOOK_MODULE_H__

#import <Cocoa/Cocoa.h>

#import "XMAddressBookManager.h"
#import "XMInspectorModule.h"

@class ABPeoplePickerView, ABPerson, XMGeneralPurposeAddressResource;

@interface XMAddressBookModule : XMInspectorModule {

@private
  IBOutlet NSView *contentView;
  NSSize contentViewMinSize;
  NSSize contentViewSize;
  
  // outlets in the "main" content view
  IBOutlet ABPeoplePickerView *addressBookView;
  IBOutlet NSButton *callButton;
  IBOutlet NSButton *newRecordButton;
  IBOutlet NSButton *actionButton;
  IBOutlet NSPopUpButton *actionPopup;
  
  // outlets for the edit record sheet
  IBOutlet NSPanel *editRecordSheet;
  
  IBOutlet NSTextField *recordNameField;
  IBOutlet NSPopUpButton *callProtocolPopUp;
  IBOutlet NSPopUpButton *labelPopUp;
  IBOutlet NSTextField *labelField;
  IBOutlet NSBox *addressEditBox;
  
  IBOutlet NSButton *okButton;
  IBOutlet NSButton *cancelButton;
  IBOutlet NSButton *deleteButton;
  
  IBOutlet NSView *h323View;
  IBOutlet NSTextField *h323CallAddressField;
  IBOutlet NSButton *useSpecificGatekeeperSwitch;
  IBOutlet NSTextField *h323GatekeeperHostField;
  IBOutlet NSTextField *h323GatekeeperUsernameField;
  IBOutlet NSTextField *h323GatekeeperPhoneNumberField;
  
  IBOutlet NSView *sipView;
  IBOutlet NSTextField *sipCallAddressField;
  
  // outlets for the new record sheet
  IBOutlet NSPanel *newRecordSheet;
  IBOutlet NSTextField *firstNameField;
  IBOutlet NSTextField *lastNameField;
  IBOutlet NSTextField *organizationField;
  IBOutlet NSButton *isOrganizationSwitch;
  
  XMAddressBookRecord *editedRecord;
  
  XMGeneralPurposeAddressResource *editedAddress;
}

- (IBAction)call:(id)sender;
- (IBAction)newRecord:(id)sender;
- (IBAction)cogWheelAction:(id)sender;

- (IBAction)editAddress:(id)sender;
- (IBAction)newAddress:(id)sender;
- (IBAction)makePrimaryAddress:(id)sender;
- (IBAction)launchAddressBook:(id)sender;

- (IBAction)callProtocolSelected:(id)sender;
- (IBAction)labelSelected:(id)sender;
- (IBAction)endEditRecordSheet:(id)sender;

- (IBAction)toggleUseSpecificGatekeeper:(id)sender;

- (IBAction)addNewRecord:(id)sender;
- (IBAction)cancelNewRecord:(id)sender;

@end

#endif // __XM_ADDRESS_BOOK_MODULE_H__
