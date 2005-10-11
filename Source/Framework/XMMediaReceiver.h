/*
 * $Id: XMMediaReceiver.h,v 1.1 2005/10/11 09:03:10 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_MEDIA_RECEIVER_H__
#define __XM_MEDIA_RECEIVER_H__

#import <Cocoa/Cocoa.h>
#import <QuickTime/QuickTime.h>

@interface XMMediaReceiver : NSObject {

	RTPReassembler videoPacketReassembler;
	ICMDecompressionSessionRef videoDecompressionSession;
}

+ (XMMediaReceiver *)sharedInstance;

- (BOOL)_processPacket:(UInt8 *)packet length:(unsigned)length session:(unsigned)sessionID;

@end

#endif // __XM_MEDIA_RECEIVER_H__
