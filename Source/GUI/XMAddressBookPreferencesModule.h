/*
 * $Id: XMAddressBookPreferencesModule.h,v 1.3 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2006-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2008 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_ADDRESS_BOOK_PREFERENCES_MODULE_H__
#define __XM_ADDRESS_BOOK_PREFERENCES_MODULE_H__

#import <Cocoa/Cocoa.h>

#import "XMPreferencesModule.h"

@interface XMAddressBookPreferencesModule : NSObject <XMPreferencesModule> {

@private
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
