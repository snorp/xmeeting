/*
 * $Id: XMWindow.m,v 1.7 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#import "XMWindow.h"

NSString *XMNotification_WindowWillMiniaturize = @"XMeetingWindowWillMiniaturizeNotification";

@implementation XMWindow

- (void)miniaturize:(id)sender
{
  // The OpenGL views want to draw their current content into the window frame buffer
  // before the window minimizes, so that the video does freeze but not entirely disappear
  // (white rect) when the window minimizes and is displayed in the dock.
  // Unfortunately, anything drawn after -miniaturize: has been called does not appear on screen.
  // Since this notification is posted before the window is "frozen", the changes appear on the
  // screen
  [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_WindowWillMiniaturize object:self];
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

@implementation XMFullScreenWindow

- (id)init
{
  NSScreen *mainScreen = [NSScreen mainScreen];
  NSRect mainScreenRect = [mainScreen frame];
  
  self = [super initWithContentRect:mainScreenRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO screen:mainScreen];
  
  [self setLevel:NSScreenSaverWindowLevel];
  
  return self;
}

- (BOOL)canBecomeKeyWindow
{
  return YES;
}

/*- (void)applicationSwitched:(NSNotification *)notif
{
  //if the camera is activated when in fullscreen, it may happen that ichat
  //will become the active application. To avoid this, we re-activate ourselves.
  [NSApp activateIgnoringOtherApps:YES];
  [self makeKeyAndOrderFront:nil];
  [self setLevel:NSScreenSaverWindowLevel];
}*/

// blocking this behaviour
/*- (void)resignKeyWindow
{
}

- (void)resignMainWindow
{
}*/

/*- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [super dealloc];
}*/

@end
