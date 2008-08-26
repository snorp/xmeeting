/*
 * $Id: XMApplicationFunctions.h,v 1.10 2008/08/26 08:14:06 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_APPLICATION_FUNCTIONS_H__
#define __XM_APPLICATION_FUNCTIONS_H__

#import <Cocoa/Cocoa.h>
#import "XMeeting.h"

/**
 * Provides useful functions for the application
 **/

/**
 * Converts the bytes value into the correct
 * kByte / MByte / GByte string for display
 **/
NSString *XMByteString(unsigned bytes);

/**
 * Converts seconds into a string with format
 * (Hours:)Minutes:Seconds whereas hours is only shown
 * when the time amount is more than one hour
 **/
NSString *XMTimeString(unsigned seconds);

/**
 * Returns the format string for representing a date
 **/
NSString *XMDateFormatString();

/**
 * Returns an textual representation of the callEndReason
 **/
NSString *XMCallEndReasonString(XMCallEndReason callEndReason);

/**
 * Returns a textual representation fo the gatekeeperRegistrationFailReason
 **/
NSString *XMGatekeeperRegistrationStatusString(XMGatekeeperRegistrationStatus failReason);

/**
 * Returns a textual representation for the SIP status code
 **/
NSString *XMSIPStatusCodeString(XMSIPStatusCode statusCode);

/**
 * Returns an array containing addresses of known STUN Servers
 **/
NSArray *XMDefaultSTUNServers();

/**
 * Returns a string representation of the NAT Type reported
 **/
NSString *XMNATTypeString(XMNATType type);

/**
 * This category adds a useful method to determine whether a given string has a 
 * prefix by searching case insensitive
 **/
@interface NSString (XMExtensions)

- (BOOL)hasPrefixCaseInsensitive:(NSString *)prefix;

@end

#endif // __XM_APPLICATION_FUNCTIONS_H__
