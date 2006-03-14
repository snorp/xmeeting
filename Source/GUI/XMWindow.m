/*
 * $Id: XMWindow.m,v 1.1 2005/11/29 18:56:29 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMWindow.h"

NSString *XMNotification_WindowWillMinimize = @"XMeetingWindowWillMinimizeNotification";

@implementation XMWindow

- (void)miniaturize:(id)sender
{
	// The OpenGL views want to draw their current content into the window frame buffer
	// before the window minimizes, so that the video does freeze but not entirely disappear
	// (white rect) when the window minimizes and is displayed in the dock.
	// Unfortunately, anything drawn after -miniaturize: has been called does not appear on screen.
	// Since this notification is posted before the window is "frozen", the changes appear on the
	// screen
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_WindowWillMinimize
														object:self];
	[super miniaturize:sender];
}

@end