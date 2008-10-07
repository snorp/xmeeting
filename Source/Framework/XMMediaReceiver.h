/*
 * $Id: XMMediaReceiver.h,v 1.13 2008/10/07 23:19:17 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_MEDIA_RECEIVER_H__
#define __XM_MEDIA_RECEIVER_H__

#import <Cocoa/Cocoa.h>
#import <QuickTime/QuickTime.h>
#import "XMTypes.h"

typedef struct XMAtom {
  UInt16 length;
  UInt8 *data;
} XMAtom;

@interface XMMediaReceiver : NSObject {

@private
  ICMDecompressionSessionRef videoDecompressionSession;
  XMCodecIdentifier videoCodecIdentifier;
  ImageDescriptionHandle videoImageDescription;
  
  XMAtom *h264SPSAtoms;
  UInt8 numberOfH264SPSAtoms;
  XMAtom *h264PPSAtoms;
  UInt8 numberOfH264PPSAtoms;
}

- (id)_init;
- (void)_close;

- (void)_startMediaReceivingForSession:(unsigned)sessionID withCodec:(XMCodecIdentifier)codecIdentifier;
- (void)_stopMediaReceivingForSession:(unsigned)sessionID;
- (BOOL)_decodeFrameForSession:(unsigned)sessionID data:(UInt8 *)data length:(unsigned)length callToken:(const char *)callToken;

- (void)_handleH264SPSAtomData:(UInt8 *)data length:(unsigned)length;
- (void)_handleH264PPSAtomData:(UInt8 *)data length:(unsigned)length;

@end

#endif // __XM_MEDIA_RECEIVER_H__
