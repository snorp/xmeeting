/*
 * $Id: XMTextChatModule.h,v 1.6 2008/11/04 23:12:35 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
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
