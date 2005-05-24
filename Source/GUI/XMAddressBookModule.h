/*
 * $Id: XMAddressBookModule.h,v 1.1 2005/05/24 15:21:02 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_ADDRESS_BOOK_MODULE_H__
#define __XM_ADDRESS_BOOK_MODULE_H__

#import <Cocoa/Cocoa.h>
#import "XMMainWindowBottomModule.h"

@class ABPeoplePickerView, ABRecord, XMCalltoURL;

@interface XMAddressBookModule : NSObject <XMMainWindowBottomModule> {

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
	
	NSString *editedId;
	XMCalltoURL *editedCalltoURL;
	
	NSNib *nibLoader;
}

- (IBAction)call:(id)sender;
- (IBAction)editURL:(id)sender;
- (IBAction)newRecord:(id)sender;
- (IBAction)launchAddressBook:(id)sender;

- (IBAction)callTypeSelected:(id)sender;
- (IBAction)gatekeeperTypeChanged:(id)sender;
- (IBAction)endEditRecordSheet:(id)sender;

- (IBAction)addNewRecord:(id)sender;
- (IBAction)cancelNewRecord:(id)sender;

@end

#endif // __XM_ADDRESS_BOOK_MODULE_H__