/*
 * $Id: XMTextChatModule.h,v 1.4 2006/06/07 10:10:16 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_TEXT_CHAT_MODULE_H__
#define __XM_TEXT_CHAT_MODULE_H__

#import <Cocoa/Cocoa.h>
#import "XMMainWindowAdditionModule.h"

@interface XMTextChatModule : NSObject <XMMainWindowAdditionModule> {

	IBOutlet NSView *contentView;
	NSSize contentViewSize;
}

@end

#endif // __XM_TEXT_CHAT_MODULE_H__
