/*
 * $Id: XMUtils.h,v 1.2 2005/05/24 15:21:02 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_UTILS_H__
#define __XM_UTILS_H__

#import <Cocoa/Cocoa.h>

@interface XMUtils : NSObject {
}

/**
 * parses whether str is a phone number and consists of only
 * digits, white space and '(' ')' '+' or '-'
 **/
+ (BOOL)isPhoneNumber:(NSString *)str;

@end

#endif // __XM_UTILS_H__
