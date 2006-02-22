/*
 * $Id: XMAudioOnlyOSD.h,v 1.1 2006/02/22 16:12:33 zmit Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Ivan Guajana. All rights reserved.
 */

#import <Cocoa/Cocoa.h>
#import "XMOnScreenControllerView.h"

@interface XMAudioOnlyOSD : XMOnScreenControllerView {
	
}

- (id)initWithFrame:(NSRect)frameRect delegate:(id)delegate andSize:(int)size;

@end
