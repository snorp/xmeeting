/*
 * $Id: XMApplicationController.h,v 1.1 2005/04/28 20:26:26 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@class XMLocalVideoView;

@interface XMApplicationController : NSObject {

	IBOutlet NSButton *callButton;
	IBOutlet NSTextField *addressField;
	IBOutlet NSTextField *remotePartyField;
	IBOutlet NSTextField *extraField;
	IBOutlet XMLocalVideoView *videoView;
	IBOutlet NSImageView *remoteView;
}

- (IBAction)callButtonPressed:(id)sender;

@end
