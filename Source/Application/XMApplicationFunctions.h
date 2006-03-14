/*
 * $Id: XMApplicationFunctions.h,v 1.3 2006/03/14 23:05:50 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_APPLICATION_FUNCTIONS_H__
#define __XM_APPLICATION_FUNCTIONS_H__

#import <Cocoa/Cocoa.h>
#import "XMeeting.h"

/**
 * Converts the bytes value into the correct
 * kByte / MByte / GByte string for display
 **/
NSString *byteString(unsigned bytes);

/**
 * Converts seconds into a string with format
 * (Hours:)Minutes:Seconds whereas hours is only shown
 * when the time amount is more than one hour
 **/
NSString *timeString(unsigned seconds);

/**
 * Returns the format string for representing a date
 **/
NSString *dateFormatString();

/**
 * Returns an textual representation of the callEndReason
 **/
NSString *callEndReasonString(XMCallEndReason callEndReason);

/**
 * Returns a textual representation fo the gatekeeperRegistrationFailReason
 **/
NSString *gatekeeperRegistrationFailReasonString(XMGatekeeperRegistrationFailReason failReason);

#endif // __XM_APPLICATION_FUNCTIONS_H__
