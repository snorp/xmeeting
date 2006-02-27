/*
 * $Id: XMBusyModule.h,v 1.1 2006/02/27 19:53:13 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_BUSY_MODULE_H__
#define __XM_BUSY_MODULE_H__

#import <Cocoa/Cocoa.h>
#import "XMMainWindowModule.h"

@interface XMBusyModule : NSObject <XMMainWindowModule> {

	IBOutlet NSView *contentView;
	NSSize contentViewSize;
	
	IBOutlet NSProgressIndicator *busyIndicator;
	
	NSNib *nibLoader;
}

@end

#endif // __XM_BUSY_MODULE_H__
