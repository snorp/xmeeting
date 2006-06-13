/*
 * $Id: XMAddressBookPreferencesModule.h,v 1.1 2006/06/13 20:27:18 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_ADDRESS_BOOK_PREFERENCES_MODULE_H__
#define __XM_ADDRESS_BOOK_PREFERENCES_MODULE_H__

#import <Cocoa/Cocoa.h>

#import "XMPreferencesModule.h"

@interface XMAddressBookPreferencesModule : NSObject <XMPreferencesModule> {

	XMPreferencesWindowController *prefWindowController;
	
	IBOutlet NSView *contentView;
	float contentViewHeight;
	
	IBOutlet NSButton *enableABDatabaseSearchSwitch;
	IBOutlet NSButton *enableABPhoneNumbersSwitch;
	IBOutlet NSMatrix *phoneNumberProtocolMatrix;
	
}

- (IBAction)defaultAction:(id)sender;
- (IBAction)toggleEnableABPhoneNumbers:(id)sender;

@end

#endif // __XM_ADDRESS_BOOK_PREFERENCES_MODULE_H__
