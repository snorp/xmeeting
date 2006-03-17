/*
 * $Id: XMInfoModule.h,v 1.2 2006/03/17 13:20:52 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Ivan Guajana. All rights reserved.
 */

#ifndef __XM_INFO_MODULE_H__
#define __XM_INFO_MODULE_H__

#import <Cocoa/Cocoa.h>

#import "XMInspectorModule.h"

@interface XMInfoModule : XMInspectorModule {
	
	IBOutlet NSView *contentView;
	IBOutlet NSTextField *ipFld, *gdsFld, *gkFld, *statusFld;
	
	NSSize contentViewSize;
	NSNib *nibLoader;
}

@end

#endif // __XM_INFO_MODULE_H__
