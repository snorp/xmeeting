/*
 * $Id: XMInCallModule.h,v 1.5 2005/10/19 22:09:17 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_IN_CALL_MODULE_H__
#define __XM_IN_CALL_MODULE_H__

#import <Cocoa/Cocoa.h>
#import "XMMainWindowModule.h"

@class XMVideoView, XMInCallView;

@interface XMInCallModule : NSObject <XMMainWindowModule> {

	IBOutlet XMInCallView *contentView;
	
	IBOutlet XMVideoView *videoView;
	IBOutlet NSButton *hangupButton;
	IBOutlet NSTextField *remotePartyField;
	
	NSNib *nibLoader;
	
	BOOL didClearCall;
	
	BOOL isVideoEnabled;
}

- (IBAction)clearCall:(id)sender;

@end

#endif // __XM_IN_CALL_MODULE_H__
