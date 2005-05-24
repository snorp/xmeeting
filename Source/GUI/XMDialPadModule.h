/*
 * $Id: XMDialPadModule.h,v 1.1 2005/05/24 15:21:02 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_DIAL_PAD_MODULE_H__
#define __XM_DIAL_PAD_MODULE_H__

#import <Cocoa/Cocoa.h>
#import "XMMainWindowBottomModule.h"

@interface XMDialPadModule : NSObject <XMMainWindowBottomModule> {

	IBOutlet NSView *contentView;
	NSSize contentViewSize;
	
	NSNib *nibLoader;
}

@end

#endif // __XM_DIAL_PAD_MODULE_H__
