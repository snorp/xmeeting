/*
 * $Id: XMCallHistoryModule.h,v 1.11 2006/06/07 10:10:15 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
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
	NSString *sipRegistrarName;
	
	NSString *videoDevice;
	
	id<XMCallAddress> callAddress;
	
}

@end

#endif // __XM_CALL_HISTORY_MODULE_H__