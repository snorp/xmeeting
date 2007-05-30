/*
 * $Id: XMCallHistoryModule.h,v 1.12 2007/05/30 08:41:17 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CALL_HISTORY_MODULE_H__
#define __XM_CALL_HISTORY_MODULE_H__

#import <Cocoa/Cocoa.h>

#import "XMCallAddressManager.h"
#import "XMInspectorModule.h"

@class XMRecentCallsView;

@interface XMCallHistoryModule : XMInspectorModule {
	
	IBOutlet NSView *contentView;
	NSSize contentViewMinSize;
	NSSize contentViewSize;
	
	IBOutlet NSScrollView *recentCallsScrollView;
	IBOutlet XMRecentCallsView *recentCallsView;
	IBOutlet NSTextView *logTextView;
	
	BOOL didLogIncomingCall;
	
	NSString *locationName;
	
	NSString *gatekeeperName;
	NSString *sipRegistrationName;
	
	NSString *videoDevice;
	
	id<XMCallAddress> callAddress;
	
}

@end

#endif // __XM_CALL_HISTORY_MODULE_H__