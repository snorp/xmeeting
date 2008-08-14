/*
 * $Id: XMPreferences.h,v 1.22 2008/08/14 19:57:05 hfriederich Exp $
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
@private
  /* General settings */
  NSString	*userName;						// The user name to be used
  BOOL		 automaticallyAcceptIncomingCalls;
  
  /* Network settings */
  unsigned	 bandwidthLimit;			// The bandwidth limit in bit/s (0 for no limit)
  NSString	*publicAddress; 		// A string containing the external ipv4 address (xxx.xxx.xxx.xxx)
  unsigned	 tcpPortBase;					// The lower limit of the tcp port range
  unsigned	 tcpPortMax;					// The upper limit of the tcp port range
  unsigned	 udpPortBase;					// The lower limit of the udp port range
  unsigned	 udpPortMax;					// The upper limit of the udp port range
  NSArray     *stunServers;       // A list of STUN servers to be used
  
  /* audio settings */
  NSMutableArray *audioCodecList;         // An array containing XMCodecListRecord instances.
  BOOL         enableSilenceSuppression;  // Flag to indicate whether silence suppression is enabled or not
  BOOL         enableEchoCancellation;    // Flag to indicate whether echo cancellation is enabled or not
  unsigned	 audioPacketTime;             // time (in ms) of audio per packet
  
  /* video settings */
  BOOL		 enableVideo;             // Enables/disables video
  unsigned	 videoFramesPerSecond;	// Framerate for sent video
  NSMutableArray *videoCodecList;		// An array containing XMCodecListRecord instances
  BOOL		 enableH264LimitedMode;		// Enables/disables the H.264 limited mode
  
  /* H.323-specific settings */
  BOOL		 enableH323;                  // Flag to indicate whether H.323 is active or not
  BOOL		 enableH245Tunnel;            // Enable H.245 Tunneling
  BOOL		 enableFastStart;             // Enable H.323 Fast-Start
  NSString	*gatekeeperAddress;         // A string with the address of the Gatekeeper to use (domain or ip)
  NSString	*gatekeeperTerminalAlias1;  // A string containing an alisas for the Gatekeeper registration. 
  NSString	*gatekeeperTerminalAlias2;  // A string containing a second alias for Gatekeeper registration
  NSString	*gatekeeperPassword;        // A string containing the password for the Gatekeeper registration
  
  /* SIP-specific settings */
  BOOL		 enableSIP;                 // Flag to indicate whether SIP is active or not
  NSArray		*sipRegistrationRecords;	// An array containing XMPreferencesRegistrationRecord instances. Index zero is default
  NSString	*sipProxyHost;            // A string containing the host address of the SIP proxy to use
  NSString	*sipProxyUsername;        // A string containing the username for the SIP proxy to use
  NSString	*sipProxyPassword;        // A string containing the password for the SIP proxy to use
  
  /* Misc settings */
  NSString    *internationalDialingPrefix;
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

- (NSString *)publicAddress;
- (void)setExternalAddress:(NSString *)string;

- (unsigned)tcpPortBase;
- (void)setTCPPortBase:(unsigned)value;

- (unsigned)tcpPortMax;
- (void)setTCPPortMax:(unsigned)value;

- (unsigned)udpPortBase;
- (void)setUDPPortBase:(unsigned)value;

- (unsigned)udpPortMax;
- (void)setUDPPortMax:(unsigned)value;

- (NSArray *)stunServers;
- (void)setSTUNServers:(NSArray *)stunServers;

#pragma mark Audio-specific Methods

- (NSArray *)audioCodecList;
- (unsigned)audioCodecListCount;
- (XMPreferencesCodecListRecord *)audioCodecListRecordAtIndex:(unsigned)index;
- (void)audioCodecListExchangeRecordAtIndex:(unsigned)index1 withRecordAtIndex:(unsigned)index2;
- (void)resetAudioCodecs;

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
- (void)resetVideoCodecs;

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
 * If -gatekeeperAlias1 returns a non-nil value, a registration
 * attempt is made. -gatekeeperAlias2 is optional for a second
 * alias (e.g. e-mail and phone number). If -gatekeeperAddress
 * returns nil, the framework attempts to discover an available
 * Gatekeeper. Otherwise, the Gatekeeper as specified in
 * -gatekeeperAddress is used.
 **/
- (NSString *)gatekeeperAddress;
- (void)setGatekeeperAddress:(NSString *)host;

- (NSString *)gatekeeperTerminalAlias1;
- (void)setGatekeeperTerminalAlias1:(NSString *)alias;

- (NSString *)gatekeeperTerminalAlias2;
- (void)setGatekeeperTerminalAlias2:(NSString *)alias;

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

#pragma mark Misc Methods

- (NSString *)internationalDialingPrefix;
- (void)setInternationalDialingPrefix:(NSString *)prefix;

@end

#endif // __XM_PREFERENCES_H__
