/*
 * $Id: XMCallHistoryModule.h,v 1.15 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CALL_HISTORY_MODULE_H__
#define __XM_CALL_HISTORY_MODULE_H__

#import <Cocoa/Cocoa.h>

#import "XMCallAddressManager.h"
#import "XMInspectorModule.h"

@class XMRecentCallsView;

@interface XMCallHistoryModule : XMInspectorModule {
	
@private
  IBOutlet NSView *contentView;
  NSSize contentViewMinSize;
  NSSize contentViewSize;
  
  IBOutlet NSScrollView *recentCallsScrollView;
  IBOutlet XMRecentCallsView *recentCallsView;
  IBOutlet NSTextView *logTextView;
  
  BOOL didLogIncomingCall;
  
  NSString *locationName;
  
  NSString *gatekeeperName;
  
  NSString *videoDevice;
  
  id<XMCallAddress> callAddress;
	
}

@end

#endif // __XM_CALL_HISTORY_MODULE_H__