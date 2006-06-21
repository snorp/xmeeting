/*
 * $Id: XMCallInfoView.h,v 1.4 2006/06/21 18:22:58 hfriederich Exp $
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
	
	NSAnimation *resizeAnimation;
	float animationStartHeight;
	float animationTargetHeight;
	
	NSString *endDateString;
	NSString *callStartString;
	NSString *callEndString;
	NSString *callDurationString;
	NSString *callDirectionString;
	NSString *endReasonString;
	NSString *localAddressString;
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
