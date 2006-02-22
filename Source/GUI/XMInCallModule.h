/*
 * $Id: XMInCallModule.h,v 1.7 2006/02/22 16:12:33 zmit Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
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
