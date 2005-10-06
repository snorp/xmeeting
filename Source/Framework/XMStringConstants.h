/*
 * $Id: XMStringConstants.h,v 1.6 2005/10/06 15:04:42 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_STRING_CONSTANTS_H__
#define __XM_STRING_CONSTANTS_H__

#pragma mark Notifications

/**
 * Posted every time the receiver starts a search for an external
 * address.
 **/
extern NSString *XMNotification_UtilsDidStartFetchingExternalAddress;

/**
 * Posted every time a search for an external address ends.
 * The success or failure of the operation can be queried
 * from the XMUtils instance.
 **/
extern NSString *XMNotification_UtilsDidEndFetchingExternalAddress;

/**
 * Notifications posted by XMCallManager
 **/

// subsystem setup
extern NSString *XMNotification_CallManagerDidGoOnline;
extern NSString *XMNotification_CallManagerDidGoOffline;
extern NSString *XMNotification_CallManagerDidStartSubsystemSetup;
extern NSString *XMNotification_CallManagerDidEndSubsystemSetup;

// call management
extern NSString *XMNotification_CallManagerDidStartCalling;
extern NSString *XMNotification_CallManagerCallStartFailed;
extern NSString *XMNotification_CallManagerIncomingCall;	// posted when there is an incoming call, waiting for user acknowledge
extern NSString *XMNotification_CallManagerCallEstablished;	// posted when a call is established
extern NSString *XMNotification_CallManagerCallCleared;		// posted when a call did end.

// h.323
extern NSString *XMNotification_CallManagerEnablingH323Failed;
extern NSString *XMNotification_CallManagerDidStartGatekeeperRegistration;
extern NSString *XMNotification_CallManagerGatekeeperRegistration;
extern NSString *XMNotification_CallManagerGatekeeperUnregistration;
extern NSString *XMNotification_CallManagerGatekeeperRegistrationFailed;

// Media Streams
extern NSString *XMNotification_CallManagerOutgoingAudioStreamOpened;
extern NSString *XMNotification_CallManagerIncomingAudioStreamOpened;
extern NSString *XMNotification_CallManagerOutgoingVideoStreamOpened;
extern NSString *XMNotification_CallManagerIncomingVideoStreamOpened;

extern NSString *XMNotification_CallManagerOutgoingAudioStreamClosed;
extern NSString *XMNotification_CallManagerIncomingAudioStreamClosed;
extern NSString *XMNotification_CallManagerOutgoingVideoStreamClosed;
extern NSString *XMNotification_CallManagerIncomingVideoStreamClosed;

// In-Call functionality
extern NSString *XMNotification_CallManagerCallStatisticsUpdated;

/**
 * Notifications posted by XMAudioManager
 **/
extern NSString *XMNotification_AudioManagerInputDeviceDidChange;
extern NSString *XMNotification_AudioManagerOutputDeviceDidChange;
extern NSString *XMNotification_AudioManagerInputVolumeDidChange;
extern NSString *XMNotification_AudioManagerOutputVolumeDidChange;
extern NSString *XMNotification_AudioManagerDidUpdateDeviceList;

/**
 * Notifications posted by XMVideoManager
 **/
extern NSString *XMNotification_VideoManagerDidStartInputDeviceListUpdate;
extern NSString *XMNotification_VideoManagerDidUpdateInputDeviceList;

/**
 * Notifications posted by XMAddressBookManager
 **/
extern NSString *XMNotification_AddressBookManagerDatabaseDidChange;

#pragma mark Exceptions

extern NSString *XMException_InvalidAction;
extern NSString *XMException_InvalidParameter;
extern NSString *XMException_UnsupportedCoder;
extern NSString *XMException_InternalConsistencyFailure;

#pragma mark Audio Codecs

/**
 * List of currently available audio codecs. These strings
 * can be used as keys to access the corresponding codec descriptors.
 **/
extern NSString *XMCodec_Audio_G711_ALaw;
extern NSString *XMCodec_Audio_G711_uLaw;
extern NSString *XMCodec_Audio_Speex;
extern NSString *XMCodec_Audio_GSM;
extern NSString *XMCodec_Audio_iLBC;

#pragma mark Video Codecs

/**
 * List of currently available video codecs. These strings can
 * be used as keys to access the corresponding codec descriptors.
 **/
extern NSString *XMCodec_Video_H261;
extern NSString *XMCodec_Video_H263;

#pragma mark XMPreferences keys

/**
 * XMPreferences Keys
 **/

// General keys
extern NSString *XMKey_PreferencesUserName;
extern NSString *XMKey_PreferencesAutoAnswerCalls;

// Network-specific keys
extern NSString *XMKey_PreferencesBandwidthLimit;
extern NSString *XMKey_PreferencesUseAddressTranslation;
extern NSString *XMKey_PreferencesExternalAddress;
extern NSString *XMKey_PreferencesTCPPortBase;
extern NSString *XMKey_PreferencesTCPPortMax;
extern NSString *XMKey_PreferencesUDPPortBase;
extern NSString *XMKey_PreferencesUDPPortMax;

// audio-specific keys
extern NSString *XMKey_PreferencesAudioBufferSize;
extern NSString *XMKey_PreferencesAudioCodecList;

// video-specific keys
extern NSString *XMKey_PreferencesEnableVideoReceive;
extern NSString *XMKey_PreferencesEnableVideoTransmit;
extern NSString *XMKey_PreferencesVideoFramesPerSecond;
extern NSString *XMKey_PreferencesVideoSize;
extern NSString *XMKey_PreferencesVideoCodecList;

// H323-specific keys
extern NSString *XMKey_PreferencesEnableH323;
extern NSString *XMKey_PreferencesEnableH245Tunnel;
extern NSString *XMKey_PreferencesEnableFastStart;
extern NSString *XMKey_PreferencesUseGatekeeper;
extern NSString *XMKey_PreferencesGatekeeperAddress;
extern NSString *XMKey_PreferencesGatekeeperID;
extern NSString *XMKey_PreferencesGatekeeperUsername;
extern NSString *XMKey_PreferencesGatekeeperPhoneNumber;

#pragma mark XMPreferencesCodecListRecord Keys

extern NSString *XMKey_PreferencesCodecListRecordIdentifier;
extern NSString *XMKey_PreferencesCodecListRecordIsEnabled;

#pragma mark XMCodecManager Keys

/**
 * List of keys for accessing the properties of a codec description
 **/
extern NSString *XMKey_CodecIdentifier;
extern NSString *XMKey_CodecName;
extern NSString *XMKey_CodecBandwidth;
extern NSString *XMKey_CodecQuality;

#pragma mark XMURL and subclasses keys

extern NSString *XMKey_URLType;
extern NSString *XMKey_URLAddress;

#pragma mark AddressBook Properties

/**
 * These properties are registered in the AddressBook database and
 * can be used to query the AddressBook database directly.
 * (type is kABStringProperty for the HumanReadableURLRepresentation
 * and kABDataProperty for the URL property)
 **/
extern NSString *XMAddressBookProperty_CallURL;
extern NSString *XMAddressBookProperty_HumanReadableCallURLRepresentation;

#endif // __XM_STRING_CONSTANTS_H__