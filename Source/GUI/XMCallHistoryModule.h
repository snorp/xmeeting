/*
 * $Id: XMCallHistoryModule.h,v 1.5 2005/10/17 12:57:54 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CALL_HISTORY_MODULE_H__
#define __XM_CALL_HISTORY_MODULE_H__

#import <Cocoa/Cocoa.h>

#import "XMCallAddressManager.h"
#import "XMMainWindowAdditionModule.h"

@class XMRecentCallsView;

@interface XMCallHistoryModule : NSObject <XMMainWindowAdditionModule> {
	
	IBOutlet NSView *contentView;
	NSSize contentViewSize;
	
	IBOutlet NSScrollView *recentCallsScrollView;
	IBOutlet XMRecentCallsView *recentCallsView;
	IBOutlet NSTextView *logTextView;
	
	NSNib *nibLoader;
	
	BOOL didLogIncomingCall;
	
	NSString *gatekeeperName;
	id<XMCallAddress> callAddress;
	
}

@end

#endif // __XM_CALL_HISTORY_MODULE_H__