/*
 * $Id: XMRecentCallsView.h,v 1.2 2006/03/14 23:06:00 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_RECENT_CALLS_VIEW_H__
#define __XM_RECENT_CALLS_VIEW_H__

#import <Cocoa/Cocoa.h>

@interface XMRecentCallsView : NSView {
	
	IBOutlet NSScrollView *scrollView;
	
	BOOL layoutDone;
}

- (void)noteSubviewHeightDidChange:(NSView *)subview;

@end

#endif // __XM_RECENT_CALLS_VIEW_H__
