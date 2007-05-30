/*
 * $Id: XMPreferences.h,v 1.16 2007/05/30 08:41:16 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_PREFERENCES_H__
#define __XM_PREFERENCES_H__

#import <Foundation/Foundation.h>
#import "XMTypes.h"

@class XMPreferencesCodecListRecord, XMPreferencesRegistrationRecord;

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
	BOOL		 automaticallyAcceptIncomingCalls;
	
	/* Network settings */
	unsigned	 bandwidthLimit;				// The bandwidth limit in bit/s (0 for no limit)
	BOOL		 useSTUN;						// Set whether to use a STUN server or not
	NSString	*stunServer;					// Address of the STUN server
	BOOL		 useAddressTranslation;			// Set whether to use address translation or not (NAT)
	NSString	*externalAddress;				// A string containing the external ipv4 address (xxx.xxx.xxx.xxx)
	unsigned	 tcpPortBase;					// The lower limit of the tcp port range
	unsigned	 tcpPortMax;					// The upper limit of the tcp port range
	unsigned	 udpPortBase;					// The lower limit of the udp port range
	unsigned	 udpPortMax;					// The upper limit of the udp port range

	/* audio settings */
	NSMutableArray *audioCodecList;				// An array containing XMCodecListRecord instances.
	BOOL         enableSilenceSuppression;      // Flag to indicate whether silence suppression is enabled or not
	BOOL         enableEchoCancellation;        // Flag to indicate whether echo cancellation is enabled or not
	unsigned	 audioPacketTime;				// time (in ms) of audio per packet

	/* video settings */
	BOOL		 enableVideo;					// Enables/disables video
	unsigned	 videoFramesPerSecond;			// Framerate for sent video
	NSMutableArray *videoCodecList;				// An array containing XMCodecListRecord instances
	BOOL		 enableH264LimitedMode;			// Enables/disables the H.264 limited mode

	/* H.323-specific settings */
	BOOL		 enableH323;				// Flag to indicate whether H.323 is active or not
	BOOL		 enableH245Tunnel;			// Enable H.245 Tunneling
	BOOL		 enableFastStart;			// Enable H.323 Fast-Start
	NSString	*gatekeeperAddress;			// A string with the address of the gatekeeper to use (domain or ip)
	NSString	*gatekeeperUsername;		// A string containing the username for gatekeeper registration
	NSString	*gatekeeperPhoneNumber;		// A string containing the E164 number for gatekeeper registration
	NSString	*gatekeeperPassword;		// A string containing the password for the gatekeeper registration
	
	/* SIP-specific settings */
	BOOL		 enableSIP;					// Flag to indicate whether SIP is active or not
	NSArray		*sipRegistrationRecords;		// An array containing XMPreferencesRegistrationRecord instances
	NSString	*sipProxyHost;				// A string containing the host address of the SIP proxy to use
	NSString	*sipProxyUsername;			// A string containing the username for the SIP proxy to use
	NSString	*sipProxyPassword;			// A string containing the password for the SIP proxy to use
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

#pragma mark accessing the properties through keys

/**
 * Returns an object containing the value defined with
 * key. For a list of valid keys, have a look at
 * XMStringConstants.h
 **/
- (id)valueForKey:(NSString *)key;

/**
 * Allows to set the value associated with key.
 * Please note that the codecLists cannot be
 * set directly. Attempts to do so will result
 * in an exception being raised.
 **/
- (void)setValue:(id)value forKey:(NSString *)key;

#pragma mark Methods for General Settings

- (NSString *)userName;
- (void)setUserName:(NSString *)name;

- (BOOL)automaticallyAcceptIncomingCalls;
- (void)setAutomaticallyAcceptIncomingCalls:(BOOL)flag;

#pragma mark Methods for Network settings

- (unsigned)bandwidthLimit;
- (void)setBandwidthLimit:(unsigned)limit;

- (BOOL)useSTUN;
- (void)setUseSTUN:(BOOL)flag;

- (NSString *)stunServer;
- (void)setSTUNServer:(NSString *)string;

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

- (NSArray *)audioCodecList;
- (unsigned)audioCodecListCount;
- (XMPreferencesCodecListRecord *)audioCodecListRecordAtIndex:(unsigned)index;
- (void)audioCodecListExchangeRecordAtIndex:(unsigned)index1 withRecordAtIndex:(unsigned)index2;

- (BOOL)enableSilenceSuppression;
- (void)setEnableSilenceSuppression:(BOOL)flag;

- (BOOL)enableEchoCancellation;
- (void)setEnableEchoCancellation:(BOOL)flag;

- (unsigned)audioPacketTime;
- (void)setAudioPacketTime:(unsigned)audioPacketTime;

#pragma mark Video-specific Methods

- (BOOL)enableVideo;
- (void)setEnableVideo:(BOOL)flag;

- (unsigned)videoFramesPerSecond;
- (void)setVideoFramesPerSecond:(unsigned)value;

- (NSArray *)videoCodecList;
- (unsigned)videoCodecListCount;
- (XMPreferencesCodecListRecord *)videoCodecListRecordAtIndex:(unsigned)index;
- (void)videoCodecListExchangeRecordAtIndex:(unsigned)index1 withRecordAtIndex:(unsigned)index2;

- (BOOL)enableH264LimitedMode;
- (void)setEnableH264LimitedMode:(BOOL)flag;

#pragma mark H.323-specific Methods

- (BOOL)enableH323;
- (void)setEnableH323:(BOOL)flag;

- (BOOL)enableH245Tunnel;
- (void)setEnableH245Tunnel:(BOOL)flag;

- (BOOL)enableFastStart;
- (void)setEnableFastStart:(BOOL)flag;

/**
 * If -gatekeeperAddress and -gatekeeperUsername return
 * non-nil values, a registration attempt is made.
 * If either of these values is nil, the preferences instance
 * is considered not to use a gatekeeper
 **/
- (NSString *)gatekeeperAddress;
- (void)setGatekeeperAddress:(NSString *)host;

- (NSString *)gatekeeperUsername;
- (void)setGatekeeperUsername:(NSString *)username;

- (NSString *)gatekeeperPhoneNumber;
- (void)setGatekeeperPhoneNumber:(NSString *)phoneNumber;

- (NSString *)gatekeeperPassword;
- (void)setGatekeeperPassword:(NSString *)password;

/**
 * Convenience method to determine whether a gatekeeper is used or not
 **/
- (BOOL)usesGatekeeper;

#pragma mark SIP-specific Methods

- (BOOL)enableSIP;
- (void)setEnableSIP:(BOOL)flag;

/**
 * Since the underlying framework provides the possibility to register at
 * multiple SIP registrars simultaneously, this instance allows to specify
 * multiple registrations.
 **/
- (NSArray *)sipRegistrationRecords;
- (void)setSIPRegistrationRecords:(NSArray *)records;

/**
 * Convenience method to determine whether registrations are used or not
 **/
- (BOOL)usesRegistrations;

/**
 * SIP proxy settings
 **/
- (NSString *)sipProxyHost;
- (void)setSIPProxyHost:(NSString *)address;

- (NSString *)sipProxyUsername;
- (void)setSIPProxyUsername:(NSString *)username;

/**
 * Returns the password to use for the SIP proxy.
 * The default implementation returns nil and does not provide
 * storage for passwords. It is up to the application design to provide
 * storage for this password data
 **/
- (NSString *)sipProxyPassword;
- (void)setSIPProxyPassword:(NSString *)password;

@end

#endif // __XM_PREFERENCES_H__
