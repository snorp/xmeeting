/*
 * $Id: XMNoCallModule.h,v 1.4 2005/06/23 12:35:57 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_NO_CALL_MODULE_H__
#define __XM_NO_CALL_MODULE_H__

#import <Cocoa/Cocoa.h>
#import "XMMainWindowModule.h"

@class XMAddressBookManager, XMDatabaseField, XMCallAddressManager, XMPreferencesManager;

/**
 * XMNoCallModule is the main window module displayed when the
 * application is not in a call.
 **/
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
	NSMutableArray *matchedAddresses;
	NSMutableArray *completions;
	
	NSNib *nibLoader;
	
	XMCallAddressManager *callAddressManager;
	XMPreferencesManager *preferencesManager;
	
	BOOL isCalling;
}

- (IBAction)call:(id)sender;
- (IBAction)changeActiveLocation:(id)sender;
- (IBAction)showCallHistory:(id)sender;

@end

#endif // __XM_NO_CALL_MODULE_H__