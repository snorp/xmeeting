/*
 * $Id: XMInCallModule.h,v 1.2 2005/06/23 12:35:57 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_IN_CALL_MODULE_H__
#define __XM_IN_CALL_MODULE_H__

#import <Cocoa/Cocoa.h>
#import "XMMainWindowModule.h"

@interface XMInCallModule : NSObject <XMMainWindowModule> {

	IBOutlet NSView *contentView;
	NSSize contentViewMinSize;
	
	IBOutlet NSButton *hangupButton;
	IBOutlet NSTextField *remotePartyField;
	
	NSNib *nibLoader;
}

- (IBAction)clearCall:(id)sender;

@end

#endif // __XM_IN_CALL_MODULE_H__
