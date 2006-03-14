/*
 * $Id: XMCallInfoView.h,v 1.2 2006/03/14 23:06:00 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CALL_INFO_VIEW_H__
#define __XM_CALL_INFO_VIEW_H__

#import <Cocoa/Cocoa.h>

@class XMCallInfo;

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
