/*
 * $Id: XMMediaReceiver.h,v 1.7 2005/11/24 21:13:02 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_MEDIA_RECEIVER_H__
#define __XM_MEDIA_RECEIVER_H__

#import <Cocoa/Cocoa.h>
#import <QuickTime/QuickTime.h>
#import "XMTypes.h"

@interface XMMediaReceiver : NSObject {

	RTPReassembler videoPacketReassembler;
	ICMDecompressionSessionRef videoDecompressionSession;
	XMCodecIdentifier videoCodecIdentifier;
	unsigned videoPayloadType;
	XMVideoSize videoMediaSize;
	
	BOOL didSucceedDecodingFrame;
	BOOL canReleasePackets;
	
	BOOL doesClose;
}

- (id)_init;
- (void)_close;

- (void)_startMediaReceivingWithCodec:(XMCodecIdentifier)codecIdentifier payloadType:(unsigned)payloadType 
							videoSize:(XMVideoSize)videoSize session:(unsigned)sessionID;
- (void)_stopMediaReceivingForSession:(unsigned)sessionID;
- (BOOL)_processPacket:(UInt8 *)packet length:(unsigned)length session:(unsigned)sessionID canReleasePackets:(unsigned *)canReleasePackets;

@end

#endif // __XM_MEDIA_RECEIVER_H__
