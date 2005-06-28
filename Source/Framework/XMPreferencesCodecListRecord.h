/*
 * $Id: XMPreferencesCodecListRecord.h,v 1.1 2005/06/28 20:43:46 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_PREFERENCES_CODEC_LIST_RECORD_H__
#define __XM_PREFERENCES_CODEC_LIST_RECORD_H__

#import <Cocoa/Cocoa.h>
	
/**
 * An instance of XMPreferencesCodecListRecord encapsulates all relevant
 * information for a codec (its key and its status (enabled / disabled))
 * This class is used within XMPreferences instances to maintain the
 * codec preference order list for the audio and video codecs.
 * The available codecs and additional information about the codecs can
 * be found using the XMCodecManager API.
 **/
@interface XMPreferencesCodecListRecord : NSObject <NSCopying, NSCoding>
{
	NSString *identifier;	// the key to identify the codec
	BOOL	  isEnabled;	// flag whether this codec is enabled or not
}

/**
 * Creates a dictionary representation of this object
 **/
- (NSMutableDictionary *)dictionaryRepresentation;

/**
 * Obtain the values using keys
 **/
- (id)propertyForKey:(NSString *)key;
- (void)setProperty:(id)property forKey:(NSString *)key;

/**
 * Returns the codec identifier associated with this instance.
 **/
- (NSString *)identifier;

/**
 * Dealing with the enabled/disabled status
 **/
- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)flag;

@end

#endif // __XM_PREFERENCES_CODEC_LIST_RECORD_H__
