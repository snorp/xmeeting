/*
 * $Id: XMNoCallModule.h,v 1.2 2005/05/31 14:59:52 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_NO_CALL_MODULE_H__
#define __XM_NO_CALL_MODULE_H__

#import <Cocoa/Cocoa.h>
#import "XMMainWindowModule.h"

@class XMAddressBookManager, XMDatabaseField, XMPreferencesManager;

@interface XMNoCallModule : NSObject <XMMainWindowModule> {
	// XMMainWindowModule Outlets and variables
	IBOutlet NSView *contentView;
	NSSize contentViewSize;
	
	// GUI Outlets
	IBOutlet XMDatabaseField *callAddressField;
	IBOutlet NSPopUpButton *locationsPopUp;
	IBOutlet NSButton *callHistoryButton;
	IBOutlet NSButton *callButton;
	IBOutlet NSTextField *statusFieldOne;
	IBOutlet NSTextField *statusFieldTwo;
	
	// Optimizations for XMDatabaseField completions
	unsigned uncompletedStringLength;
	NSMutableArray *matchedValidRecords;
	NSMutableArray *completions;
	
	XMAddressBookManager *addressBookManager;
	NSNib *nibLoader;
	
	XMPreferencesManager *preferencesManager;
}

- (IBAction)call:(id)sender;
- (IBAction)changeActiveLocation:(id)sender;
- (IBAction)showCallHistory:(id)sender;

@end

#endif // __XM_NO_CALL_MODULE_H__