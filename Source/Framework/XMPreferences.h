/*
 * $Id: XMPreferences.h,v 1.2 2005/04/28 20:26:27 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "XMTypes.h"

@class XMCodecListRecord;

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
 * To simplify this task, this class can be cast into a
 * NSDictionary-Representation or encoded using NSKeyedCoding.
 **/

#pragma mark XMPreferences - Keys
/**
 * These keys can be used to query dictionaries created by XMPreferencss instances.
 * The settings are described in the corresponding methods of XMPreferences.
 **/

// Call-Management keys
extern NSString *XMKey_AutoAnswerCalls;

// Network-specific keys
extern NSString *XMKey_BandwidthLimit;
extern NSString *XMKey_UseAddressTranslation;
extern NSString *XMKey_ExternalAddress;
extern NSString *XMKey_TCPPortMin;
extern NSString *XMKey_TCPPortMax;
extern NSString *XMKey_UDPPortMin;
extern NSString *XMKey_UDPPortMax;

// audio-specific keys
extern NSString *XMKey_AudioCodecPreferenceList;
extern NSString *XMKey_AudioBufferSize;

// video-specific keys
extern NSString *XMKey_EnableVideoReceive;
extern NSString *XMKey_SendVideo;
extern NSString *XMKey_SendFPS;
extern NSString *XMKey_VideoSize;
extern NSString *XMKey_VideoCodecPreferenceList;

// H323-specific keys
extern NSString *XMKey_H323_IsEnabled;
extern NSString *XMKey_H323_EnableH245Tunnel;
extern NSString *XMKey_H323_EnableFastStart;
extern NSString *XMKey_H323_LocalListenerPort;
extern NSString *XMKey_H323_RemoteListenerPort;
extern NSString *XMKey_H323_UseGatekeeper;
extern NSString *XMKey_H323_GatekeeperAddress;
extern NSString *XMKey_H323_GatekeeperID;
extern NSString *XMKey_H323_GatekeeperUsername;
extern NSString *XMKey_H323_GatekeeperE164Number;

#pragma mark XMCodecListRecord - Keys
/**
 * These keys can be used to query XMCodecList instances.
 * The settings are described in the corresponding methods of XMCodecListRecord
 **/
extern NSString *XMKey_CodecKey;
extern NSString *XMKey_CodecIsEnabled;

@interface XMPreferences : NSObject <NSCopying, NSCoding> 
{	
	/* Network settings */
	unsigned	 bandwidthLimit;				// The bandwidth limit in bit/s (0 for no limit)
	BOOL		 useAddressTranslation;			// Set whether to use address translation or not (NAT)
	NSString	*externalAddress;				// A string containing the external ipv4 address (xxx.xxx.xxx.xxx)
	unsigned	 tcpPortMin;					// The lower limit of the tcp port range
	unsigned	 tcpPortMax;					// The upper limit of the tcp port range
	unsigned	 udpPortMin;					// The lower limit of the udp port range
	unsigned	 udpPortMax;					// The upper limit of the udp port range

	/* audio settings */
	NSMutableArray *audioCodecPreferenceList;	// An array containing XMCodecListRecord instances.
	unsigned	 audioBufferSize;				// The number of audio packets to buffer. 

	/* video settings */
	BOOL		 enableVideoReceive;			// Enables/disables video receive
	BOOL		 sendVideo;						// Enables/disables video sending
	unsigned	 sendFPS;						// Framerate for sent video
	XMVideoSize	 videoSize;						// The preferred video size for sent video
	NSMutableArray *videoCodecPreferenceList;	// An array containing XMCodecListRecord instances

	/* H.323-specific settings */
	BOOL		 h323_IsEnabled;				// Flag to indicate whether H.323 is active or not
	unsigned	 h323_LocalListenerPort;		// The local listener port to use, currently not supported
	unsigned	 h323_RemoteListenerPort;		// The remote listener port to call, currently not supported
	BOOL		 h323_EnableH245Tunnel;			// Enable H.245 Tunneling
	BOOL		 h323_EnableFastStart;			// Enable H.323 Fast-Start
	BOOL		 h323_UseGatekeeper;			// Set whether to use a gatekeeper or not
	NSString	*h323_GatekeeperAddress;		// A string with the address of the gatekeeper to use (domain or ip)
	NSString	*h323_GatekeeperID;				// A string describing the ID of the gatekeeper
	NSString	*h323_GatekeeperUsername;		// A string containing the username for gatekeeper registration
	NSString	*h323_GatekeeperE164Number;		// A string containing the E164 number for gatekeeper registration
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

#pragma mark Methods for Network settings
- (unsigned)bandwidthLimit;
- (void)setBandwidthLimit:(unsigned)limit;

- (BOOL)useAddressTranslation;
- (void)setUseAddressTranslation:(BOOL)flag;

- (NSString *)externalAddress;
- (void)setExternalAddress:(NSString *)string;

- (unsigned)tcpPortMin;
- (void)setTCPPortMin:(unsigned)value;

- (unsigned)tcpPortMax;
- (void)setTCPPortMax:(unsigned)value;

- (unsigned)udpPortMin;
- (void)setUDPPortMin:(unsigned)value;

- (unsigned)udpPortMax;
- (void)setUDPPortMax:(unsigned)value;

#pragma mark Audio-specific Methods

- (unsigned)audioCodecPreferenceListCount;
- (XMCodecListRecord *)audioCodecPreferenceListEntryAtIndex:(unsigned)index;
- (void)audioCodecPreferenceListExchangeEntryAtIndex:(unsigned)index1 withEntryAtIndex:(unsigned)index2;
- (void)audioCodecPreferenceListAddEntry:(XMCodecListRecord *)entry;
- (void)audioCodecPreferenceListRemoveEntryAtIndex:(unsigned)index;

- (unsigned)audioBufferSize;
- (void)setAudioBufferSize:(unsigned)size;

#pragma mark Video-specific Methods

- (BOOL)enableVideoReceive;
- (void)setEnableVideoReceive:(BOOL)flag;

- (BOOL)sendVideo;
- (void)setSendVideo:(BOOL)flag;

- (unsigned)sendFPS;
- (void)setSendFPS:(unsigned)value;

- (XMVideoSize)videoSize;
- (void)setVideoSize:(XMVideoSize)size;

- (unsigned)videoCodecPreferenceListCount;
- (XMCodecListRecord *)videoCodecPreferenceListEntryAtIndex:(unsigned)index;
- (void)videoCodecPreferenceListExchangeEntryAtIndex:(unsigned)index1 withEntryAtIndex:(unsigned)index2;
- (void)videoCodecPreferenceListAddEntry:(XMCodecListRecord *)entry;
- (void)videoCodecPreferenceListRemoveEntryAtIndex:(unsigned)index;

#pragma mark H.323-specific Methods

- (BOOL)h323IsEnabled;
- (void)setH323IsEnabled:(BOOL)flag;

- (BOOL)h323EnableH245Tunnel;
- (void)setH323EnableH245Tunnel:(BOOL)flag;

- (BOOL)h323EnableFastStart;
- (void)setH323EnableFastStart:(BOOL)flag;

/* currently unsupported */
- (unsigned)h323LocalListenerPort;
- (void)setH323LocalListenerPort:(unsigned)port;

/* currently unsupported */
- (unsigned)h323RemoteListenerPort;
- (void)setH323RemoteListenerPort:(unsigned)port;

- (BOOL)h323UseGatekeeper;
- (void)setH323UseGatekeeper:(BOOL)flag;

- (NSString *)h323GatekeeperAddress;
- (void)setH323GatekeeperAddress:(NSString *)host;

- (NSString *)h323GatekeeperID;
- (void)setH323GatekeeperID:(NSString *)string;

- (NSString *)h323GatekeeperUsername;
- (void)setH323GatekeeperUsername:(NSString *)string;

- (NSString *)h323GatekeeperE164Number;
- (void)setH323GatekeeperE164Number:(NSString *)string;

/* currently not supported */
- (NSString *)h323GatekeeperPassword;
- (BOOL)setH323GatekeeperPassword:(NSString *)password;

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
	NSString *key;			// the key to identify the codec
	BOOL	  isEnabled;	// flag whether this codec is enabled or not
}	

/**
 * Designated initializer
 **/
- (id)initWithKey:(NSString *)key isEnabled:(BOOL)enabled;

/**
 * initializes the instance with the contents of the dictionary, using the keys as defined above.
 **/
- (id)initWithDictionary:(NSDictionary *)dict;
	
/**
 * Creates a dictionary representation of this object
 **/
- (NSMutableDictionary *)dictionaryRepresentation;

/**
 * Returns the codec key associated with this instance.
 * This information cannot be changed
 **/
- (NSString *)key;

- (BOOL)isEnabled;
- (void)setIsEnabled:(BOOL)flag;

@end
