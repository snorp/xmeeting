/*
 * $Id: XMApplicationFunctions.h,v 1.1 2005/08/27 22:08:22 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_APPLICATION_FUNCTIONS_H__
#define __XM_APPLICATION_FUNCTIONS_H__

#import <Cocoa/Cocoa.h>

/**
 * Converts the bytes value into the correct
 * kByte / MByte / GByte string for display
 **/
NSString *byteString(unsigned bytes);

#endif // __XM_APPLICATION_FUNCTIONS_H__
