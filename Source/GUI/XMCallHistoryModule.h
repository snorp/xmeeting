/*
 * $Id: XMCallHistoryModule.h,v 1.16 2008/12/27 08:08:54 hfriederich Exp $
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
  
  IBOutlet NSTabView *tabView;
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