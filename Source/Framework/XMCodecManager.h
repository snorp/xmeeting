/*
 * $Id: XMCodecManager.h,v 1.10 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CODEC_MANAGER_H__
#define __XM_CODEC_MANAGER_H__

#import <Foundation/Foundation.h>
#import "XMTypes.h"

@class XMCodec;

/**
 * XMCodecManager provides the interface for accessing information
 * about all available audio/video codecs.
 * The actual data is encapsulated in XMCodec classes.
 * The keys for each codec are used in XMPreferences objects
 * to manage their codec preference lists.
 **/
@interface XMCodecManager : NSObject {

@private
  NSMutableArray *audioCodecs;
  NSMutableArray *videoCodecs;
}

/**
 * Returns the shared singleton instance of XMCodecManager
 **/
+ (XMCodecManager *)sharedInstance;

/**
 * Access to codecs by their identifier.
 * See XMTypes for a list of available codec identifiers
 **/
- (XMCodec *)codecForIdentifier:(XMCodecIdentifier)identifier;

/**
 * Accessing the available audio codecs
 **/
- (unsigned)audioCodecCount;
- (XMCodec *)audioCodecAtIndex:(unsigned)index;

/**
 * Accessing the available video codecs
 **/
- (unsigned)videoCodecCount;
- (XMCodec *)videoCodecAtIndex:(unsigned)index;

@end

#endif // __XM_CODEC_MANAGER_H__
