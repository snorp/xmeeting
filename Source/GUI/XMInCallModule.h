/*
 * $Id: XMInCallModule.h,v 1.10 2006/03/23 10:04:48 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_IN_CALL_MODULE_H__
#define __XM_IN_CALL_MODULE_H__

#import <Cocoa/Cocoa.h>
#import "XMMainWindowModule.h"

@class XMOSDVideoView;

@interface XMInCallModule : NSObject <XMMainWindowModule> {

	IBOutlet NSView *contentView;
	NSSize contentViewMinSize;
	NSSize contentViewSize;
	
	IBOutlet XMOSDVideoView *videoView;

	IBOutlet NSTextField *remotePartyField;
	
	BOOL isFullScreen;
	
	BOOL didClearCall;
}

- (IBAction)clearCall:(id)sender;

@end

#endif // __XM_IN_CALL_MODULE_H__
