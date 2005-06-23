/*
 * $Id: XMStringConstants.h,v 1.1 2005/06/23 12:35:56 hfriederich Exp $
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
extern NSString *XMNotification_DidStartFetchingExternalAddress;

/**
 * Posted every time a search for an external address ends.
 * The success or failure of the operation can be queried
 * from the XMUtils instance.
 **/
extern NSString *XMNotification_DidEndFetchingExternalAddress;

/**
 * Notifications posted by XMCallManager
 **/

// subsystem setup
extern NSString *XMNotification_DidGoOnline;
extern NSString *XMNotification_DidGoOffline;
extern NSString *XMNotification_DidStartSubsystemSetup;
extern NSString *XMNotification_DidEndSubsystemSetup;

// call management
extern NSString *XMNotification_DidStartCalling;
extern NSString *XMNotification_IncomingCall;		// posted when there is an incoming call, waiting for user acknowledge
extern NSString *XMNotification_CallEstablished;	// posted when a call is established
extern NSString *XMNotification_CallCleared;		// posted when a call did end.

// h.323
extern NSString *XMNotification_GatekeeperRegistration;
extern NSString *XMNotification_GatekeeperUnregistration;
extern NSString *XMNotification_GatekeeperRegistrationFailure;

/**
 * Notifications posted by XMAudioManager
 **/
extern NSString *XMNotification_AudioInputDeviceDidChange;
extern NSString *XMNotification_AudioOutputDeviceDidChange;
extern NSString *XMNotification_AudioInputVolumeDidChange;
extern NSString *XMNotification_AudioOutputVolumeDidChange;

/**
 * Notifications posted by XMVideoManager
 **/
extern NSString *XMNotification_DidStartVideoGrabbing;
extern NSString *XMNotification_DidStopVideoGrabbing;
extern NSString *XMNotification_DidReadVideoFrame;
extern NSString *XMNotification_DidUpdateVideoDeviceList;

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
extern NSString *XMAudioCodec_G711_ALaw;
extern NSString *XMAudioCodec_G711_uLaw;
extern NSString *XMAudioCodec_Speex;
extern NSString *XMAudioCodec_GSM;
extern NSString *XMAudioCodec_iLBC;

#pragma mark Video Codecs

/**
 * List of currently available video codecs. These strings can
 * be used as keys to access the corresponding codec descriptors.
 **/
extern NSString *XMVideoCodec_H261;
extern NSString *XMVideoCodec_H263;	

#pragma mark CodecManager Keys

/**
 * List of keys for accessing the properties of a codec description
 **/
extern NSString *XMKey_CodecDescriptor_Identifier;
extern NSString *XMKey_CodecDescriptor_Name;
extern NSString *XMKey_CodecDescriptor_Bandwidth;
extern NSString *XMKey_CodecDescriptor_Quality;

#pragma mark AddressBook Properties

/**
 * These properties are registered in the AddressBook database and
 * can be used to query the AddressBook database directly.
 * (type is kABStringProperty)
 **/
extern NSString *XMAddressBook_CallURLProperty;
extern NSString *XMAddressBook_HumanReadableCallAddressProperty;

#endif // __XM_STRING_CONSTANTS_H__