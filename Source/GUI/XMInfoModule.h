/*
 * $Id: XMInfoModule.h,v 1.3 2006/03/18 20:46:22 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Ivan Guajana, Hannes Friederich. All rights reserved.
 */

#ifndef __XM_INFO_MODULE_H__
#define __XM_INFO_MODULE_H__

#import <Cocoa/Cocoa.h>

#import "XMInspectorModule.h"

@interface XMInfoModule : XMInspectorModule {
	
	IBOutlet NSView *contentView;
	NSSize contentViewSize;
	
	IBOutlet NSTextField *ipAddressesField; 
	IBOutlet NSTextField *h323StatusField;
	IBOutlet NSTextField *gatekeeperField;
	IBOutlet NSTextField *phoneNumberField;
	IBOutlet NSTextField *sipStatusField;
	IBOutlet NSTextField *registrarField;
	IBOutlet NSTextField *sipUsernameField;

}

@end

#endif // __XM_INFO_MODULE_H__
