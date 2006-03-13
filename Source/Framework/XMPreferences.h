/*
 * $Id: XMPreferences.h,v 1.11 2006/03/13 23:46:23 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_PREFERENCES_H__
#define __XM_PREFERENCES_H__

#import <Foundation/Foundation.h>
#import "XMTypes.h"

@class XMPreferencesCodecListRecord;

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
	BOOL		 useAddressTranslation;			// Set whether to use address translation or not (NAT)
	NSString	*externalAddress;				// A string containing the external ipv4 address (xxx.xxx.xxx.xxx)
	unsigned	 tcpPortBase;					// The lower limit of the tcp port range
	unsigned	 tcpPortMax;					// The upper limit of the tcp port range
	unsigned	 udpPortBase;					// The lower limit of the udp port range
	unsigned	 udpPortMax;					// The upper limit of the udp port range

	/* audio settings */
	NSMutableArray *audioCodecList;				// An array containing XMCodecListRecord instances.
	unsigned	 audioBufferSize;				// The number of audio packets to buffer. 

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
	
	/* SIP-specific settings */
	BOOL		 enableSIP;					// Flag to indicate whether SIP is active or not
	NSArray		*registrarHosts;			// An array containing host address strings
	NSArray		*registrarUsernames;		// An array containing username strings
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

- (unsigned)audioBufferSize;
- (void)setAudioBufferSize:(unsigned)size;

- (NSArray *)audioCodecList;
- (unsigned)audioCodecListCount;
- (XMPreferencesCodecListRecord *)audioCodecListRecordAtIndex:(unsigned)index;
- (void)audioCodecListExchangeRecordAtIndex:(unsigned)index1 withRecordAtIndex:(unsigned)index2;

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

/**
 * Convenience method to determine whether a gatekeeper is used or not
 **/
- (BOOL)usesGatekeeper;

/**
 * Returns the gatekeeper password associated with this preferences 
 * instance. The default implementation returns nil.
 * It is up the application design to provide storage for the
 * password data.
 * This method should return nil if no password is set.
 * The storage must be consistend when a copy is made. It is not required
 * and not recommended either that the password will be stored through
 * a dictionary representation or encoding into an NSData object.
 **/
- (NSString *)gatekeeperPassword;

#pragma mark SIP-specific Methods

- (BOOL)enableSIP;
- (void)setEnableSIP:(BOOL)flag;

/**
 * Since the underlying framework provides the possibility to register at
 * multiple SIP registrars simultaneously, this instance allows to specify
 * multiple registrars.
 * The host at index i corresponds with the username found at index i in the username array and the
 * password at index i.
 * The arrays set by -setRegistrarHosts, -setRegistrarUsername and returned by -registrarPasswords
 * must have the same number of elements. Only complete host/username pairs will be registered.
 **/
- (NSArray *)registrarHosts;
- (void)setRegistrarHosts:(NSArray *)hosts;

- (NSArray *)registrarUsernames;
- (void)setRegistrarUsernames:(NSArray *)usernames;

/**
 * Convenience method to determine whether registrars are used or not
 **/
- (BOOL)usesRegistrars;

/**
 * Returns the registrar passwords associated with this preferences instance.
 * The array returned must have the same number of elements as the arrays returned by
 * -registrarHosts and -registrarUsernames
 * The default implementation simply returns an array with the same size as the -registrarHosts array,
 * filled with NSNull instances. It is up to the application design to provide storage for the password data.
 * This storage must be consistent when -copy is called. It is not required, and not recommended either,
 * to store the password data inside a dictionary or encode it into an NSData instance.
 **/
- (NSArray *)registrarPasswords;

@end

#endif // __XM_PREFERENCES_H__
