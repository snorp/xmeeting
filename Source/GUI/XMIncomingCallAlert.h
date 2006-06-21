/*
 * $Id: XMIncomingCallAlert.h,v 1.1 2006/06/21 22:16:48 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_INCOMING_CALL_ALERT_H__
#define __XM_INCOMING_CALL_ALERT_H__

#import <Cocoa/Cocoa.h>
#import "XMeeting.h"

@interface XMIncomingCallAlert : NSObject {

	IBOutlet NSPanel *panel;
	IBOutlet NSTextField *infoField;
	IBOutlet NSTextField *detailsField;
	float detailsFieldHeight;
}

/**
 * Setup of the alert instance with the given call info
 **/
- (id)initWithCallInfo:(XMCallInfo *)callInfo;

/**
 * Returns the same values as NSAlert
 **/
- (int)runModal;

/**
 * Action Methods
 **/
- (IBAction)acceptCall:(id)sender;
- (IBAction)rejectCall:(id)sender;
- (IBAction)toggleShowDetails:(id)sender;

@end

#endif // __XM_INCOMING_CALL_ALERT_H__
