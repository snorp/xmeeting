/*
 * $Id: XMZeroConfModule.h,v 1.5 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_ZERO_CONF_MODULE_H__
#define __XM_ZERO_CONF_MOUDLE_H__

#import <Cocoa/Cocoa.h>
//#import "XMMainWindowAdditionModule.h"

@interface XMZeroConfModule : NSObject <XMMainWindowAdditionModule> {

	IBOutlet NSView *contentView;
	NSSize contentViewSize;
	
	NSNib *nibLoader;
	
}

@end

#endif // __XM_ZERO_CONF_MODULE_H__