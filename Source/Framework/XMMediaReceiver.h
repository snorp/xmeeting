/*
 * $Id: XMMediaReceiver.h,v 1.8 2006/01/09 22:22:57 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_MEDIA_RECEIVER_H__
#define __XM_MEDIA_RECEIVER_H__

#import <Cocoa/Cocoa.h>
#import <QuickTime/QuickTime.h>
#import "XMTypes.h"

@interface XMMediaReceiver : NSObject {

	ICMDecompressionSessionRef videoDecompressionSession;
	XMCodecIdentifier videoCodecIdentifier;
	unsigned videoPayloadType;
	XMVideoSize videoMediaSize;
}

- (id)_init;
- (void)_close;

- (void)_startMediaReceivingForSession:(unsigned)sessionID withCodec:(XMCodecIdentifier)codecIdentifier
							 videoSize:(XMVideoSize)videoSize payloadType:(unsigned)payloadType;
- (void)_stopMediaReceivingForSession:(unsigned)sessionID;
- (BOOL)_decodeFrameForSession:(unsigned)sessionID data:(UInt8 *)data length:(unsigned)length;

@end

#endif // __XM_MEDIA_RECEIVER_H__
