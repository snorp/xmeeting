/*
 * $Id: XMPreferences.h,v 1.1 2005/02/11 12:58:44 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "XMTypes.h"

@class XMCodecListEntry;

/*
 * This class encapsulates all needed preferences required to
 * make calls using this framework. Instances of this class
 * are passed to the XMController when making calls.
 *
 * This version of the class is very lightweight, in contrast
 * to the previous one. The preferences are no longer directly
 * stored in the UserDefaults database. Instead, this must now
 * be done inside the application using this framework.
 * This new design offers more flexibility on how to organize
 * the UserDefaults database. This is needed for the so-called
 * LocationManager behaviour in ohphoneX.
 */

/*
 * A list of predefined keys which can be used in conjunction with user defaults.
 * These keys are also used for encoding/decoding
 */
// Location / behavior - specific keys
extern NSString *XMKey_AutoanswerCalls;
extern NSString *XMKey_BandwidthLimit;
extern NSString *XMKey_UseIPAddressTranslation;
extern NSString *XMKey_ExternalIPAddress;

// port-specific keys
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
extern NSString *XMKey_H323_EnableH245Tunnel;
extern NSString *XMKey_H323_EnableFastStart;
extern NSString *XMKey_H323_LocalListenerPort;
extern NSString *XMKey_H323_RemoteListenerPort;
extern NSString *XMKey_H323_UseGatekeeper;
extern NSString *XMKey_H323_GatekeeperHost;
extern NSString *XMKey_H323_GatekeeperID;
extern NSString *XMKey_H323_GatekeeperUsername;
extern NSString *XMKey_H323_GatekeeperE164Number;

// XMCodecListEntry keys
extern NSString *XMKey_CodecKey;
extern NSString *XMKey_CodecIsEnabled;

@interface XMPreferences : NSObject <NSCopying, NSCoding> 
{
	/* Location / behaviour-specific settings */
	BOOL		 autoanswerCalls;			// If yes, calls are automatically ansered. Otherwise, the user is asked.
	unsigned	 bandwidthLimit;			// The bandwidth limit in bit/s (0 for no limit)
	BOOL		 useIPAddressTranslation;	// Set whether to use ip address translation or not
	NSString	*externalIPAddress;			// A string containing the external ipv4 address (xxx.xxx.xxx.xxx)

	/* port-specific settings */
	unsigned	 tcpPortMin;				// The lower limit of the tcp port range
	unsigned	 tcpPortMax;				// The upper limit of the tcp port range
	unsigned	 udpPortMin;				// The lower limit of the udp port range
	unsigned	 udpPortMax;				// The upper limit of the udp port range

	/* audio-specific settings */
	NSMutableArray *audioCodecPreferenceList;	// An array containing XMCodecListEntry instances.
	unsigned	 audioBufferSize;			// The number of audio packets to buffer. 

	/* video-specific settings */
	BOOL		 enableVideoReceive;				// Enables/disables video receive
	BOOL		 sendVideo;					// Enables/disables video sending
	unsigned	 sendFPS;					// Framerate for sent video
	
	XMVideoSize	 videoSize;					// The preferred video size for sent video
	NSMutableArray *videoCodecPreferenceList;	// An array containing XMCodecListEntry instances

	/* H.323-specific settings */
	unsigned	 h323_LocalListenerPort;	// The local listener port to use
	unsigned	 h323_RemoteListenerPort;	// The remote listener port to call
	BOOL		 h323_EnableH245Tunnel;		// Enable H.245 Tunneling
	BOOL		 h323_EnableFastStart;		// Enable H.323 Fast-Start
	BOOL		 h323_UseGatekeeper;		// Set whether to use a gatekeeper or not
	NSString	*h323_GatekeeperHost;		// A string naming the host to use (domain or ip)
	NSString	*h323_GatekeeperID;			// A string describing the ID of the gatekeeper
	NSString	*h323_GatekeeperUsername;	// A string containing the username for gatekeeper registration
	NSString	*h323_GatekeeperE164Number;	// A string containing the E164 number for gatekeeper registration
}

#pragma mark Init & Representation Methods
/* Object init/deallocation etc */
- (id)init;		//designated initializer
- (id)initWithDictionary:(NSDictionary *)dict;	// initializes ats contents from a dictionary.

- (NSMutableDictionary *)dictionaryRepresentation;	// returns a dictionary which can be used for storage in UserDefaults etc.
													// mutable since the dictionary can be filled with other entries in subclasses etc.

#pragma mark Location / behaviour-specific Methods
- (BOOL)autoanswerCalls;
- (void)setAutoanswerCalls:(BOOL)flag;

- (unsigned)bandwidthLimit;
- (void)setBandwidthLimit:(unsigned)limit;

- (BOOL)useIPAddressTranslation;
- (void)setUseIPAddressTranslation:(BOOL)flag;

- (NSString *)externalIPAddress;
- (void)setExternalIPAddress:(NSString *)string;

#pragma mark Port-specific Methods

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
- (XMCodecListEntry *)audioCodecPreferenceListEntryAtIndex:(unsigned)index;
- (void)audioCodecPreferenceListExchangeEntryAtIndex:(unsigned)index1 withEntryAtIndex:(unsigned)index2;
- (void)audioCodecPreferenceListAddEntry:(XMCodecListEntry *)entry;
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
- (XMCodecListEntry *)videoCodecPreferenceListEntryAtIndex:(unsigned)index;
- (void)videoCodecPreferenceListExchangeEntryAtIndex:(unsigned)index1 withEntryAtIndex:(unsigned)index2;
- (void)videoCodecPreferenceListAddEntry:(XMCodecListEntry *)entry;
- (void)videoCodecPreferenceListRemoveEntryAtIndex:(unsigned)index;

#pragma mark H.323-specific Methods

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

- (NSString *)h323GatekeeperHost;
- (void)setH323GatekeeperHost:(NSString *)host;

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

@interface XMCodecListEntry : NSObject <NSCopying, NSCoding>
{
	NSString *key;			// the key to identify the codec
	BOOL	  isEnabled;	// flag whether this codec is enabled or not
}	

- (id)initWithKey:(NSString *)key isEnabled:(BOOL)enabled;	// designated initializer
- (id)initWithDictionary:(NSDictionary *)dict;				// inits from contents of this dictionary
	
- (NSMutableDictionary *)dictionaryRepresentation;			// returns a dictionary representation for UserDefaults etc.
	
- (NSString *)key;
	
- (BOOL)isEnabled;
- (void)setIsEnabled:(BOOL)flag;

@end
