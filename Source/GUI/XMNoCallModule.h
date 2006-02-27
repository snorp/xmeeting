/*
 * $Id: XMNoCallModule.h,v 1.8 2006/02/27 19:53:13 hfriederich Exp $
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
	IBOutlet NSPopUpButton *recentCallsPopUpButton;
	IBOutlet XMDatabaseField *callAddressField;
	IBOutlet NSPopUpButton *locationsPopUpButton;
	IBOutlet NSButton *callButton;
	
	IBOutlet NSTextField *statusFieldOne;
	
	// Optimizations for XMDatabaseField completions
	unsigned uncompletedStringLength;
	NSMutableArray *matchedAddresses;
	NSMutableArray *completions;
	
	NSNib *nibLoader;
	
	NSMenuItem *imageItem;
	
	IBOutlet NSImageView *semaphoreView;
	
	BOOL isCalling;
}

- (IBAction)call:(id)sender;
- (IBAction)changeActiveLocation:(id)sender;
- (IBAction)showAddressBookModuleSheet:(id)sender;
- (IBAction)showInspector:(id)sender;
- (IBAction)showTools:(id)sender;
- (IBAction)showSelfView:(id)sender;


@end

#endif // __XM_NO_CALL_MODULE_H__