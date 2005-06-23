/*
 * $Id: XMPreferences.h,v 1.5 2005/06/23 12:35:56 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_PREFERENCES_H__
#define __XM_PREFERENCES_H__

#import <Foundation/Foundation.h>
#import "XMTypes.h"

@class XMCodecListRecord;

#pragma mark XMCodecListRecord - Keys


/**
* This class encapsulates all setting options which affect
 * the call behaviour both for H.323/SIP.
 * Instances of this class are passed to XMCallManager
 * to setup the underlying OPAL system.
 *
 * This version of the class is very lightweight, in contrast
 * to the previous one. The preferences are no longer directly
 * stored in the UserDefaults database, this has to be done
 * by the application using this framework.
 * This new design offers more flexibility on how to organize
 * the UserDefaults database since it allows to store multiple
 * sets of preferences and to easily switch between them.
 * To simplify this task, this class can be turned into a
 * NSDictionary-Representation or encoded using NSKeyedCoding.
 **/
@interface XMPreferences : NSObject <NSCopying, NSCoding> 
{	
	/* General settings */
	NSString	*userName;						// The user name to be used
	BOOL		 autoAnswerCalls;
	
	/* Network settings */
	unsigned	 bandwidthLimit;				// The bandwidth limit in bit/s (0 for no limit)
	BOOL		 useAddressTranslation;			// Set whether to use address translation or not (NAT)
	NSString	*externalAddress;				// A string containing the external ipv4 address (xxx.xxx.xxx.xxx)
	unsigned	 tcpPortBase;					// The lower limit of the tcp port range
	unsigned	 tcpPortMax;					// The upper limit of the tcp port range
	unsigned	 udpPortBase;					// The lower limit of the udp port range
	unsigned	 udpPortMax;					// The upper limit of the udp port range

	/* audio settings */
	NSMutableArray *audioCodecPreferenceList;	// An array containing XMCodecListRecord instances.
	unsigned	 audioBufferSize;				// The number of audio packets to buffer. 

	/* video settings */
	BOOL		 enableVideoReceive;			// Enables/disables video receive
	BOOL		 enableVideoTransmit;			// Enables/disables video sending
	unsigned	 videoFramesPerSecond;			// Framerate for sent video
	XMVideoSize	 videoSize;						// The preferred video size for sent video
	NSMutableArray *videoCodecPreferenceList;	// An array containing XMCodecListRecord instances

	/* H.323-specific settings */
	BOOL		 enableH323;				// Flag to indicate whether H.323 is active or not
	BOOL		 enableH245Tunnel;			// Enable H.245 Tunneling
	BOOL		 enableFastStart;			// Enable H.323 Fast-Start
	BOOL		 useGatekeeper;				// Set whether to use a gatekeeper or not
	NSString	*gatekeeperAddress;			// A string with the address of the gatekeeper to use (domain or ip)
	NSString	*gatekeeperID;				// A string describing the ID of the gatekeeper
	NSString	*gatekeeperUsername;		// A string containing the username for gatekeeper registration
	NSString	*gatekeeperPhoneNumber;		// A string containing the E164 number for gatekeeper registration
}

#pragma mark Init & Representation Methods
/**
 * designated initializer. All settings are pre-set to the most reasonable values
 **/
- (id)init;

/**
 * initializes the instance with the contents of dict. The dictionary is queried with the keys
 * described. If a key is not contained in the dictionary, the default value is used.
 **/
- (id)initWithDictionary:(NSDictionary *)dict;

/**
 * Creates a Dictionary containing key-value pairs of all settings.
 * The returned instance is of type NSMutableDictionary to allow subclasses to
 * fill in additional informations etc.
 **/
- (NSMutableDictionary *)dictionaryRepresentation;

#pragma mark Methods for General Settings

- (NSString *)userName;
- (void)setUserName:(NSString *)name;

- (BOOL)autoAnswerCalls;
- (void)setAutoAnswerCalls:(BOOL)flag;

#pragma mark Methods for Network settings

- (unsigned)bandwidthLimit;
- (void)setBandwidthLimit:(unsigned)limit;

- (BOOL)useAddressTranslation;
- (void)setUseAddressTranslation:(BOOL)flag;

- (NSString *)externalAddress;
- (void)setExternalAddress:(NSString *)string;

- (unsigned)tcpPortBase;
- (void)setTCPPortBase:(unsigned)value;

- (unsigned)tcpPortMax;
- (void)setTCPPortMax:(unsigned)value;

- (unsigned)udpPortBase;
- (void)setUDPPortBase:(unsigned)value;

- (unsigned)udpPortMax;
- (void)setUDPPortMax:(unsigned)value;

#pragma mark Audio-specific Methods

- (unsigned)audioCodecListCount;
- (XMCodecListRecord *)audioCodecListRecordAtIndex:(unsigned)index;
- (void)audioCodecListExchangeRecordAtIndex:(unsigned)index1 withRecordAtIndex:(unsigned)index2;

- (unsigned)audioBufferSize;
- (void)setAudioBufferSize:(unsigned)size;

#pragma mark Video-specific Methods

- (BOOL)enableVideoReceive;
- (void)setEnableVideoReceive:(BOOL)flag;

- (BOOL)enableVideoTransmit;
- (void)setEnableVideoTransmit:(BOOL)flag;

- (unsigned)videoFramesPerSecond;
- (void)setVideoFramesPerSecond:(unsigned)value;

- (XMVideoSize)videoSize;
- (void)setVideoSize:(XMVideoSize)size;

- (unsigned)videoCodecListCount;
- (XMCodecListRecord *)videoCodecListRecordAtIndex:(unsigned)index;
- (void)videoCodecListExchangeRecordAtIndex:(unsigned)index1 withRecordAtIndex:(unsigned)index2;

#pragma mark H.323-specific Methods

- (BOOL)enableH323;
- (void)setEnableH323:(BOOL)flag;

- (BOOL)enableH245Tunnel;
- (void)setEnableH245Tunnel:(BOOL)flag;

- (BOOL)enableFastStart;
- (void)setEnableFastStart:(BOOL)flag;

- (BOOL)useGatekeeper;
- (void)setUseGatekeeper:(BOOL)flag;

- (NSString *)gatekeeperAddress;
- (void)setGatekeeperAddress:(NSString *)host;

- (NSString *)gatekeeperID;
- (void)setGatekeeperID:(NSString *)string;

- (NSString *)gatekeeperUsername;
- (void)setGatekeeperUsername:(NSString *)string;

- (NSString *)gatekeeperPhoneNumber;
- (void)setGatekeeperPhoneNumber:(NSString *)string;

@end

/**
 * An instance of XMCodecListRecord encapsulates all relevant
 * information for a codec such as its key and its status,
 * (enabled / disabled) and is used in the context of the
 * audio/video codec preference lists.
 * To get a list of available codecs and additional informations
 * about a certain codec, please refer to the XMCodecManager API.
 **/
@interface XMCodecListRecord : NSObject <NSCopying, NSCoding>
{
	NSString *identifier;	// the key to identify the codec
	BOOL	  isEnabled;	// flag whether this codec is enabled or not
}
	
/**
 * Creates a dictionary representation of this object
 **/
- (NSMutableDictionary *)dictionaryRepresentation;

/**
 * Returns the codec key associated with this instance.
 * This information cannot be changed
 **/
- (NSString *)identifier;

- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)flag;

@end

#endif // __XM_PREFERENCES_H__
