/*
 * $Id: XMInCallModule.h,v 1.6 2005/11/29 18:56:29 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_IN_CALL_MODULE_H__
#define __XM_IN_CALL_MODULE_H__

#import <Cocoa/Cocoa.h>
#import "XMMainWindowModule.h"

@class XMSimpleVideoView, XMInCallView;

@interface XMInCallModule : NSObject <XMMainWindowModule> {

	IBOutlet XMInCallView *contentView;
	
	IBOutlet XMSimpleVideoView *videoView;
	IBOutlet NSButton *hangupButton;
	IBOutlet NSTextField *remotePartyField;
	
	NSNib *nibLoader;
	
	BOOL didClearCall;
	
	BOOL isVideoEnabled;
}

- (IBAction)clearCall:(id)sender;

@end

#endif // __XM_IN_CALL_MODULE_H__
