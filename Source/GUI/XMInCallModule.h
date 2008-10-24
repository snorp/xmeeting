/*
 * $Id: XMInCallModule.h,v 1.13 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_IN_CALL_MODULE_H__
#define __XM_IN_CALL_MODULE_H__

#import <Cocoa/Cocoa.h>
#import "XMMainWindowModule.h"

@class XMOSDVideoView;

@interface XMInCallModule : NSObject <XMMainWindowModule> {

@private
  IBOutlet NSView *contentView;
  NSSize contentViewMinSize;
  NSSize contentViewSize;
  NSSize noVideoContentViewSize;
  
  IBOutlet XMOSDVideoView *videoView;
  
  IBOutlet NSTextField *remotePartyField;
  
  BOOL isFullScreen;
  
  BOOL didClearCall;
}

- (IBAction)clearCall:(id)sender;

@end

#endif // __XM_IN_CALL_MODULE_H__
