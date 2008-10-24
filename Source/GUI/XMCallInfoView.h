/*
 * $Id: XMCallInfoView.h,v 1.7 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
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

@private
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
  NSString *callProtocolString;
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
