/*
 * $Id: XMInfoModule.h,v 1.6 2007/05/30 08:41:17 hfriederich Exp $
 *
 * Copyright (c) 2006-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2007 Ivan Guajana, Hannes Friederich. All rights reserved.
 */

#ifndef __XM_INFO_MODULE_H__
#define __XM_INFO_MODULE_H__

#import <Cocoa/Cocoa.h>

#import "XMInspectorModule.h"

@interface XMInfoModule : XMInspectorModule {
	
	IBOutlet NSView *contentView;
	NSSize contentViewSize;
	
	IBOutlet NSBox *networkBox;
	IBOutlet NSTextField *ipAddressesField;
	IBOutlet NSImageView *ipAddressSemaphoreView;
	IBOutlet NSTextField *natTypeField;
	IBOutlet NSImageView *natTypeSemaphoreView;
	
	IBOutlet NSButton *h323Disclosure;
	IBOutlet NSBox *h323Box;
	IBOutlet NSTextField *h323Title;
	IBOutlet NSTextField *h323StatusField;
	IBOutlet NSImageView *h323StatusSemaphoreView;
	IBOutlet NSTextField *gatekeeperField;
	IBOutlet NSImageView *gatekeeperSemaphoreView;
	IBOutlet NSTextField *phoneNumberField;
	
	IBOutlet NSButton *sipDisclosure;
	IBOutlet NSBox *sipBox;
	IBOutlet NSTextField *sipTitle;
	IBOutlet NSTextField *sipStatusField;
	IBOutlet NSImageView *sipStatusSemaphoreView;
	IBOutlet NSTextField *registrationField;
	IBOutlet NSImageView *registrationSemaphoreView;
	IBOutlet NSTextField *sipUsernameField;
	
	unsigned addressExtraHeight;
	unsigned h323BoxHeight;
	unsigned sipBoxHeight;
	
	BOOL showH323Details;
	BOOL showSIPDetails;
}

- (IBAction)toggleShowH323Details:(id)sender;
- (IBAction)toggleShowSIPDetails:(id)sender;

@end

#endif // __XM_INFO_MODULE_H__
