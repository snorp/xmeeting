/*
 * $Id: XMInfoModule.h,v 1.1 2006/02/22 16:12:33 zmit Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Ivan Guajana. All rights reserved.
 */

#ifndef __XM_INFO_MODULE_H__
#define __XM_INFO_MODULE_H__

#import <Cocoa/Cocoa.h>
#import "XMMainWindowAdditionModule.h"

@interface XMInfoModule : NSObject <XMMainWindowAdditionModule> {
	
	IBOutlet NSView *contentView;
	IBOutlet NSTextField *ipFld, *gdsFld, *gkFld, *statusFld;
	
	NSSize contentViewSize;
	NSNib *nibLoader;
}

@end

#endif // __XM_INFO_MODULE_H__
