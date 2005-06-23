/*
 * $Id: XMTextChatModule.h,v 1.2 2005/06/23 12:35:57 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_TEXT_CHAT_MODULE_H__
#define __XM_TEXT_CHAT_MODULE_H__

#import <Cocoa/Cocoa.h>
#import "XMMainWindowAdditionModule.h"

@interface XMTextChatModule : NSObject <XMMainWindowAdditionModule> {

	IBOutlet NSView *contentView;
	NSSize contentViewSize;
	
	NSNib *nibLoader;
}

@end

#endif // __XM_TEXT_CHAT_MODULE_H__
