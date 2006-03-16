/*
 * $Id: XMWindow.m,v 1.3 2006/03/16 14:13:57 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
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

@implementation XMChildWindow

/**
 * This undocumented method returns NO if the window has no
 * title bar. If NO is returned, all controls drawn are grayed
 * and without any visible indication to user interaction.
 * Therefore, YES is returned here to achieve the desired behaviour.
 * If anyone knows a better solution, don't hesitate to report it...
 **/
- (BOOL)_hasActiveControls
{
	return YES;
}

@end
