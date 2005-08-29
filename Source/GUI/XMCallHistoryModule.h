/*
 * $Id: XMCallHistoryModule.h,v 1.3 2005/08/29 15:19:51 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CALL_HISTORY_MODULE_H__
#define __XM_CALL_HISTORY_MODULE_H__

#import <Cocoa/Cocoa.h>
#import "XMMainWindowAdditionModule.h"

@interface XMCallHistoryModule : NSObject <XMMainWindowAdditionModule> {
	
	IBOutlet NSView *contentView;
	NSSize contentViewSize;
	
	IBOutlet NSTextView *logTextView;
	
	NSNib *nibLoader;
	
	NSString *dateFormatString;
	
	BOOL didLogIncomingCall;
}

@end

#endif // __XM_CALL_HISTORY_MODULE_H__