/*
 * $Id: XMCodecManager.h,v 1.4 2005/06/23 12:35:56 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CODEC_MANAGER_H__
#define __XM_CODEC_MANAGER_H__

#import <Foundation/Foundation.h>

@class XMCodecDescriptor;

/**
 * XMCodecManager provides the interface for accessing information
 * about all available audio/video codecs.
 * The actual data is encapsulated in XMCodecDescriptor classes.
 * The keys for each codec can be used in XMPreferences for the
 * codec preference lists.
 **/
@interface XMCodecManager : NSObject {
	
	NSMutableArray *audioCodecDescriptors;
	NSMutableArray *videoCodecDescriptors;

}

/*
 * Returns the shared singleton instance of XMCodecManager
 */
+ (XMCodecManager *)sharedInstance;

/*
 * Access to codec descriptors by their identifier.
 * See XMStringConstants for a list of available codec identifiers
 */
- (XMCodecDescriptor *)codecDescriptorForIdentifier:(NSString *)identifier;

/*
 * Accessing the available audio codecs
 */
- (unsigned)audioCodecCount;
- (XMCodecDescriptor *)audioCodecDescriptorAtIndex:(unsigned)index;

/*
 * Accessing the available video codecs
 */
- (unsigned)videoCodecCount;
- (XMCodecDescriptor *)videoCodecDescriptorAtIndex:(unsigned)index;

@end

/**
 * Helper class for XMCodecManager to encapsulate
 * the information about a certain codec.
 **/
@interface XMCodecDescriptor : NSObject {
	NSString *identifier;
	NSString *name;
	NSString *bandwidth;
	NSString *quality;
}

- (NSString *)propertyForKey:(NSString *)key;

/*
 * Obtaining the properties
 */
- (NSString *)identifier;
- (NSString *)name;
- (NSString *)bandwidth;
- (NSString *)quality;

@end

#endif // __XM_CODEC_MANAGER_H__
