/*
 * $Id: XMCodec.h,v 1.5 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CODEC_H__
#define __XM_CODEC_H__

#import <Foundation/Foundation.h>
#import "XMTypes.h"

/**
 * Helper class for XMCodecManager to encapsulate
 * the information about a certain codec.
 **/
@interface XMCodec : NSObject {
  
@private
  XMCodecIdentifier identifier;
  NSString *name;
  NSString *bandwidth;
  NSString *quality;
  BOOL canDisable;
}

/**
 * Use the keys defined in XMStringConstants.h
 * for XMCodec to access the appropriate values
 **/
- (NSObject *)propertyForKey:(NSString *)key;

/**
 * Returns the identifier for this codec.
 * The identifier can be used to obtain the
 * corresponding XMCodec instance by querying
 * the XMCodecManager shared instance.
 **/
- (XMCodecIdentifier)identifier;

/**
 * Human-readable name for this codec.
 * The returned string is localized.
 **/
- (NSString *)name;

/**
 * A string containing a human-readable
 * information about how much bandwidth
 * is used by this codec.
 * The returned string is localized
 **/
- (NSString *)bandwidth;

/**
 * A string containing a human-readable
 * description of the quality of this codec.
 * The returned string is localized
 **/
- (NSString *)quality;

/**
 * Returns whether this codec can be disabled or not.
 * Certain codecs are part of the H.323 standard and
 * cannot be disabled. (G.711 and H.261)
 **/
- (BOOL)canDisable;

@end

#endif // __XM_CODEC_H__
