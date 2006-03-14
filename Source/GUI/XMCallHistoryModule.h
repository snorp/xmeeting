/*
 * $Id: XMCallHistoryModule.h,v 1.6 2006/03/14 23:06:00 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
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