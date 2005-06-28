/*
 * $Id: XMCodec.h,v 1.1 2005/06/28 20:41:06 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CODEC_H__
#define __XM_CODEC_H__

#import <Cocoa/Cocoa.h>

/**
 * Helper class for XMCodecManager to encapsulate
 * the information about a certain codec.
 **/
@interface XMCodec : NSObject {
	NSString *identifier;
	NSString *name;
	NSString *bandwidth;
	NSString *quality;
}

/**
 * Use the keys defined in XMStringConstants.h
 * for XMCodec to access the appropriate values
 **/
- (NSString *)propertyForKey:(NSString *)key;

/**
 * Obtaining the properties
 **/
- (NSString *)identifier;
- (NSString *)name;
- (NSString *)bandwidth;
- (NSString *)quality;

@end

#endif // __XM_CODEC_H__
