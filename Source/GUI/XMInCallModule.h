/*
 * $Id: XMInCallModule.h,v 1.8 2006/03/14 23:06:00 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_IN_CALL_MODULE_H__
#define __XM_IN_CALL_MODULE_H__

#import <Cocoa/Cocoa.h>
#import "XMMainWindowModule.h"

@class XMSimpleVideoView, XMOSDVideoView, XMInCallView;

@interface XMInCallModule : NSObject <XMMainWindowModule> {

	IBOutlet XMInCallView *contentView;
	IBOutlet XMOSDVideoView *videoView;

	IBOutlet NSButton *hangupButton;
	IBOutlet NSTextField *remotePartyField;
	
	
	NSNib *nibLoader;
	
	BOOL didClearCall;
}

- (IBAction)clearCall:(id)sender;

@end

#endif // __XM_IN_CALL_MODULE_H__
