/*
 * $Id: XMInfoModule.h,v 1.4 2006/03/20 18:22:40 hfriederich Exp $
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
	IBOutlet NSImageView *ipAddressSemaphoreView;
	
	IBOutlet NSTextField *h323StatusField;
	IBOutlet NSImageView *h323StatusSemaphoreView;
	IBOutlet NSTextField *gatekeeperField;
	IBOutlet NSImageView *gatekeeperSemaphoreView;
	IBOutlet NSTextField *phoneNumberField;
	
	IBOutlet NSTextField *sipStatusField;
	IBOutlet NSImageView *sipStatusSemaphoreView;
	IBOutlet NSTextField *registrarField;
	IBOutlet NSImageView *registrarSemaphoreView;
	IBOutlet NSTextField *sipUsernameField;

}

@end

#endif // __XM_INFO_MODULE_H__
