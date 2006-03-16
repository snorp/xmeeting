/*
 * $Id: XMCallInfoView.h,v 1.3 2006/03/16 14:13:57 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CALL_INFO_VIEW_H__
#define __XM_CALL_INFO_VIEW_H__

#import <Cocoa/Cocoa.h>

@class XMCallInfo;

/**
 * This class displays all possible information about recent calls
 * made in a user-friendly manner.
 **/
@interface XMCallInfoView : NSControl {
	
	XMCallInfo *callInfo;
	NSTextFieldCell *textDrawCell;
	NSRect disclosureRect;
	unsigned disclosureState;
	
	NSString *endDateString;
	NSString *callStartString;
	NSString *callEndString;
	NSString *callDurationString;
	NSString *callDirectionString;
	NSString *endReasonString;
	NSString *remoteNumberString;
	NSString *remoteAddressString;
	NSString *remoteApplicationString;
	NSString *audioOutString;
	NSString *audioInString;
	NSString *videoOutString;
	NSString *videoInString;
}

- (XMCallInfo *)callInfo;
- (void)setCallInfo:(XMCallInfo *)callInfo;

- (float)requiredHeightForWidth:(float)width;

@end

#endif // __XM_CALL_INFO_VIEW_H__
