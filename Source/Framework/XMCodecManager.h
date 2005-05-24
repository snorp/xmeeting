/*
 * $Id: XMCodecManager.h,v 1.3 2005/05/24 15:21:01 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CODEC_MANAGER_H__
#define __XM_CODEC_MANAGER_H__

#import <Foundation/Foundation.h>

/**
 * List of currently available audio codecs. These strings
 * can be used as keys to access the respecive codec descriptions.
 **/
extern NSString *XMAudioCodec_G711_ALaw;
extern NSString *XMAudioCodec_G711_uLaw;
extern NSString *XMAudioCodec_Speex;
extern NSString *XMAudioCodec_GSM;
extern NSString *XMAudioCodec_iLBC;

/**
 * List of currently available video codecs. These strings can
 * be used as keys to access the respective codec descriptions.
 **/
extern NSString *XMVideoCodec_H261;
extern NSString *XMVideoCodec_H263;	

/**
 * List of keys for accessing the properties of a codec description
 **/
extern NSString *XMKey_CodecKey;
extern NSString *XMKey_CodecName;
extern NSString *XMKey_CodecBandwidth;
extern NSString *XMKey_CodecQuality;

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
 * Access to codec descriptors by their keys
 */
- (XMCodecDescriptor *)codecDescriptorForKey:(NSString *)codecKey;

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
	NSString *key;
	NSString *name;
	NSString *bandwidth;
	NSString *quality;
}

/*
 * Obtaining the properties
 */
- (NSString *)key;
- (NSString *)name;
- (NSString *)bandwidth;
- (NSString *)quality;

/*
 * Returns the property associated with key.
 * For a list of available keys, see above
 */
- (NSString *)propertyForKey:(NSString *)key;

@end

#endif // __XM_CODEC_MANAGER_H__
