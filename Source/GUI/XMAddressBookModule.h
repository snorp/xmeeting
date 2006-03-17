/*
 * $Id: XMAddressBookModule.h,v 1.9 2006/03/17 13:20:52 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_ADDRESS_BOOK_MODULE_H__
#define __XM_ADDRESS_BOOK_MODULE_H__

#import <Cocoa/Cocoa.h>

#import "XMAddressBookManager.h"
#import "XMInspectorModule.h"

@class ABPeoplePickerView, ABPerson, XMGeneralPurposeAddressResource;

@interface XMAddressBookModule : XMInspectorModule {

	IBOutlet NSView *contentView;
	NSSize contentViewSize;
	
	// outlets in the "main" content view
	IBOutlet ABPeoplePickerView *addressBookView;
	IBOutlet NSButton *callButton;
	IBOutlet NSButton *editButton;
	IBOutlet NSButton *newButton;
	IBOutlet NSButton *launchAddressBookButton;
	
	// outlets for the edit record sheet
	IBOutlet NSPanel *editRecordSheet;
	
	IBOutlet NSTextField *recordNameField;
	IBOutlet NSPopUpButton *callTypePopUp;
	
	IBOutlet NSTextField *directCallAddressLabel;
	IBOutlet NSTextField *directCallAddressField;
	
	IBOutlet NSTextField *gatekeeperCallAddressLabel;
	IBOutlet NSTextField *gatekeeperCallAddressField;
	IBOutlet NSMatrix *gatekeeperMatrix;
	IBOutlet NSTextField *gatekeeperHostField;
	
	IBOutlet NSButton *okButton;
	IBOutlet NSButton *cancelButton;
	IBOutlet NSButton *deleteButton;
	
	// outlets for the new record sheet
	IBOutlet NSPanel *newRecordSheet;
	IBOutlet NSTextField *firstNameField;
	IBOutlet NSTextField *lastNameField;
	IBOutlet NSTextField *organizationField;
	IBOutlet NSButton *isOrganizationSwitch;
	
	ABPerson<XMAddressBookRecord> *editedRecord;
	XMGeneralPurposeAddressResource *editedAddress;
	
	NSNib *nibLoader;
	
	//other outlets
	IBOutlet NSPopUpButton *actionPopup;
	IBOutlet NSButton *actionButton;
}

- (IBAction)call:(id)sender;
- (IBAction)editAddress:(id)sender;
- (IBAction)newRecord:(id)sender;
- (IBAction)launchAddressBook:(id)sender;

- (IBAction)callTypeSelected:(id)sender;
- (IBAction)gatekeeperTypeChanged:(id)sender;
- (IBAction)endEditRecordSheet:(id)sender;

- (IBAction)addNewRecord:(id)sender;
- (IBAction)cancelNewRecord:(id)sender;

- (IBAction)cogWheelAction:(id)sender;


@end

#endif // __XM_ADDRESS_BOOK_MODULE_H__
