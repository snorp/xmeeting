/*
 * $Id: XMInCallView.h,v 1.1 2005/10/19 22:09:17 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_IN_CALL_VIEW_H__
#define __XM_IN_CALL_VIEW_H__

#import <Cocoa/Cocoa.h>
#import "XMeeting.h"

@interface XMInCallView : NSView {
	
	IBOutlet NSView *statusContentView;
	IBOutlet NSView *videoContentView;
	IBOutlet NSView *buttonContentView;
	
	unsigned statusContentHeight;
	unsigned buttonContentHeight;
	unsigned minContentWidth;
	XMVideoSize videoSize;

	BOOL showVideoContent;
}

- (void)setShowVideoContent:(BOOL)flag;

/**
 * Returns whether window size change needed
 * or not
 **/
- (BOOL)setVideoSize:(XMVideoSize)videoSize;

- (NSSize)minimumSize;
- (NSSize)preferredSize;
- (NSSize)maximumSize;

- (NSSize)adjustResizeDifference:(NSSize)resizeDifference minimumHeight:(unsigned)minimumHeight;

@end

#endif // __XM_IN_CALL_VIEW_H__
