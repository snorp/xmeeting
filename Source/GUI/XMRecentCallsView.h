/*
 * $Id: XMRecentCallsView.h,v 1.5 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_RECENT_CALLS_VIEW_H__
#define __XM_RECENT_CALLS_VIEW_H__

#import <Cocoa/Cocoa.h>

/**
 * This view manages the a set of XMCallInfoView instances which represent
 * the recent calls made.
 **/
@interface XMRecentCallsView : NSView {
	
@private
  IBOutlet NSScrollView *scrollView;
  BOOL layoutDone;
}

- (void)noteSubviewHeightDidChange:(NSView *)subview;

@end

#endif // __XM_RECENT_CALLS_VIEW_H__
