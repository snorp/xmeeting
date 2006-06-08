/*
 * $Id: XMStringConstants.h,v 1.22 2006/06/08 15:31:51 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_STRING_CONSTANTS_H__
#define __XM_STRING_CONSTANTS_H__

#pragma mark XMeeting Framework Notifications

/**
 * Posted when the XMeeting Framework is initialized and ready to be used
 **/
extern NSString *XMNotification_FrameworkDidInitialize;

/**
 * Posted when the XMeeting Framework has been closed and can no longer be
 * used (unless initialized again)
 **/
extern NSString *XMNotification_FrameworkDidClose;

#pragma mark XMUtils Notifications

/**
 * Posted every time the local addresses do change. This happens
 * if the system configuration location changes or if a network
 * cable is plugged in and the host gets connected to a network.
 **/
extern NSString *XMNotification_UtilsDidUpdateLocalAddresses;

/**
 * Posted every time the receiver starts a search for an external
 * address.
 **/
extern NSString *XMNotification_UtilsDidStartFetchingCheckipExternalAddress;

/**
 * Posted every time a search for an external address ends.
 * The success or failure of the operation can be queried
 * from the XMUtils instance.
 **/
extern NSString *XMNotification_UtilsDidEndFetchingCheckipExternalAddress;

/**
 * Posted every time the STUN information (natType and probably
 * external address) are updated
 **/
extern NSString *XMNotification_UtilsDidUpdateSTUNInformation;

#pragma mark XMCallManager Notifications

/**
 * Posted when the CallManager starts setting up the subsystem.
 **/
extern NSString *XMNotification_CallManagerDidStartSubsystemSetup;

/**
 * Posted when the CallManager ends setting up the subsystem
 **/
extern NSString *XMNotification_CallManagerDidEndSubsystemSetup;

/**
 * Posted when the CallManager started to initiate a call
 * This indicates that the success or failure of the call 
 * initiation cannot be determined immediately.
 * After this notification has been posted, it is no longer
 * allowed to make modifications such as changing the preferences
 * or so until either the call start failed or the call is
 * cleared.
 **/
extern NSString *XMNotification_CallManagerDidStartCallInitiation;

/**
 * Posted when the framework started calling the remote party
 **/
extern NSString *XMNotification_CallManagerDidStartCalling;

/**
 * Posted when the attempt to start a call failed. This normally
 * indicates a serious problem such as no address specified or
 * that in the same time an incoming call appeared etc
 * the userInfo dictionary has the following keys set:
 * @"Address" : address one tried to call to
 **/
extern NSString *XMNotification_CallManagerDidNotStartCalling;

/**
 * Posted when the phone is ringing at the remote party.
 * This indicates that the remote party exists and is online,
 * but that the remote user has to accept the call first
 **/
extern NSString *XMNotification_CallManagerDidStartRingingAtRemoteParty;

/**
 * Posted when there is an incoming call, waiting for user response
 **/
extern NSString *XMNotification_CallManagerDidReceiveIncomingCall;

/**
 * Posted when the call is established
 **/
extern NSString *XMNotification_CallManagerDidEstablishCall;

/**
 * Posted when the call is cleared. It doesn't matter whether
 * the call was actually established or not and whether this
 * is an incoming or outgoing call
 **/
extern NSString *XMNotification_CallManagerDidClearCall;

/**
 * Posted when the Framework couldn't enable the H323 subsystem. This
 * normally indicates problems like the H.323 listener ports not open
 * and so on
 **/
extern NSString *XMNotification_CallManagerDidNotEnableH323;

/**
 * Posted when the Framework did start registering at a gatekeeper.
 * This can be a lengthy task
 **/
extern NSString *XMNotification_CallManagerDidStartGatekeeperRegistrationProcess;

/**
 * Posted when the Framework did end the gatekeeper registration task
 **/
extern NSString *XMNotification_CallManagerDidEndGatekeeperRegistrationProcess;

/**
 * Posted when the Framework sucessfully registered at a gatekeeper.
 * This notification is only posted when the Framework has a new registration
 **/
extern NSString *XMNotification_CallManagerDidRegisterAtGatekeeper;

/**
 * Posted when the Framework unregistered from a gatekeeper
 **/
extern NSString *XMNotification_CallManagerDidUnregisterFromGatekeeper;

/**
 * Posted when the Framework failed to register at a gatekeeper
 **/
extern NSString *XMNotification_CallManagerDidNotRegisterAtGatekeeper;

/**
 * Posted when the Framwork couldn't enable the SIP subsystem. This normally
 * indicates problems like the SIP ports not open and so on
 **/
extern NSString *XMNotification_CallManagerDidNotEnableSIP;

/**
 * Posted when the Framwork did start registering at SIP registrars.
 * This can be a lengthy task
 **/
extern NSString *XMNotification_CallManagerDidStartSIPRegistrationProcess;

/**
 * Posted when the Framework finished registereing at SIP registrars
 **/
extern NSString *XMNotification_CallManagerDidEndSIPRegistrationProcess;

/**
 * Posted when the Framwork succesfully registered at a SIP registrar.
 * This notification is only posted when the Framework has a new registration
 * made.
 **/
extern NSString *XMNotification_CallManagerDidRegisterAtSIPRegistrar;

/**
 * Posted when the Framework unregistered from a SIP registrar
 **/
extern NSString *XMNotification_CallManagerDidUnregisterFromSIPRegistrar;

/**
 * Posted when the Framework failed to register at the registrar
 **/
extern NSString *XMNotification_CallManagerDidNotRegisterAtSIPRegistrar;

/**
 * Posted when the appropriate media stream is opened
 **/
extern NSString *XMNotification_CallManagerDidOpenOutgoingAudioStream;
extern NSString *XMNotification_CallManagerDidOpenIncomingAudioStream;
extern NSString *XMNotification_CallManagerDidOpenOutgoingVideoStream;
extern NSString *XMNotification_CallManagerDidOpenIncomingVideoStream;

/**
 * Posted when the appropriate media stream is closed
 **/
extern NSString *XMNotification_CallManagerDidCloseOutgoingAudioStream;
extern NSString *XMNotification_CallManagerDidCloseIncomingAudioStream;
extern NSString *XMNotification_CallManagerDidCloseOutgoingVideoStream;
extern NSString *XMNotification_CallManagerDidCloseIncomingVideoStream;

/**
 * Posted when the call statistics are updated
 **/
extern NSString *XMNotification_CallManagerDidUpdateCallStatistics;

/**
 * Posted when a FECC channel was opened. This channel will remain
 * open until the call is finished
 **/
extern NSString *XMNotification_CallManagerDidOpenFECCChannel;

#pragma mark XMAudioManager Notifications

extern NSString *XMNotification_AudioManagerInputDeviceDidChange;
extern NSString *XMNotification_AudioManagerOutputDeviceDidChange;
extern NSString *XMNotification_AudioManagerInputVolumeDidChange;
extern NSString *XMNotification_AudioManagerOutputVolumeDidChange;
extern NSString *XMNotification_AudioManagerDidUpdateDeviceList;

#pragma mark XMVideoManager Notifications

/**
 * Posted when the VideoManager did start to update the video device list
 **/
extern NSString *XMNotification_VideoManagerDidStartInputDeviceListUpdate;

/**
 * Posted when the VideoManager did update the video device list
 * This also indicates that the input device list update process
 * has finished
 **/
extern NSString *XMNotification_VideoManagerDidUpdateInputDeviceList;

/**
 * Posted when the VideoManager did start changing the video input device.
 * Since this might be a lengthy task, the begin and end of this task
 * are posted through notifications.
 **/
extern NSString *XMNotification_VideoManagerDidStartSelectedInputDeviceChange;

/**
 * Posted when the video input device did change.
 **/
extern NSString *XMNotification_VideoManagerDidChangeSelectedInputDevice;

/**
 * Posted when the VideoManager did start transmitting video to the remote
 * party.
 * When this notification is posted, the size of the transmitted video
 * is also known
 **/
extern NSString *XMNotification_VideoManagerDidStartTransmittingVideo;

/**
 * Posted when the VideoManager no longer transmits video to the remote
 * party.
 **/
extern NSString *XMNotification_VideoManagerDidEndTransmittingVideo;

/**
 * Posted when the VideoManager did start receiving video from the remote
 * party.
 * When this notification is posted, the size of the remote video is also
 * known.
 **/
extern NSString *XMNotification_VideoManagerDidStartReceivingVideo;

/**
 * Posted when the VideoManager no longer receives video from the
 * remote party
 **/
extern NSString *XMNotification_VideoManagerDidEndReceivingVideo;

#pragma mark Exceptions

extern NSString *XMException_InvalidAction;
extern NSString *XMException_InvalidParameter;
extern NSString *XMException_UnsupportedCoder;
extern NSString *XMException_InternalConsistencyFailure;

#pragma mark XMPreferences Keys

// General keys
extern NSString *XMKey_PreferencesUserName;
extern NSString *XMKey_PreferencesAutomaticallyAcceptIncomingCalls;

// Network-specific keys
extern NSString *XMKey_PreferencesBandwidthLimit;
extern NSString *XMKey_PreferencesUseSTUN;
extern NSString *XMKey_PreferencesSTUNServer;
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
extern NSString *XMKey_PreferencesEnableVideo;
extern NSString *XMKey_PreferencesVideoFramesPerSecond;
extern NSString *XMKey_PreferencesPreferredVideoSize;
extern NSString *XMKey_PreferencesVideoCodecList;
extern NSString *XMKey_PreferencesEnableH264LimitedMode;

// H323-specific keys
extern NSString *XMKey_PreferencesEnableH323;
extern NSString *XMKey_PreferencesEnableH245Tunnel;
extern NSString *XMKey_PreferencesEnableFastStart;
extern NSString *XMKey_PreferencesGatekeeperAddress;
extern NSString *XMKey_PreferencesGatekeeperUsername;
extern NSString *XMKey_PreferencesGatekeeperPhoneNumber;
extern NSString *XMKey_PreferencesGatekeeperPassword;

// SIP-specific keys
extern NSString *XMKey_PreferencesEnableSIP;
extern NSString *XMKey_PreferencesRegistrarRecords;
extern NSString *XMKey_PreferencesSIPProxyHost;
extern NSString *XMKey_PreferencesSIPProxyUsername;
extern NSString *XMKey_PreferencesSIPProxyPassword;

#pragma mark XMPreferencesCodecListRecord Keys

extern NSString *XMKey_PreferencesCodecListRecordIdentifier;
extern NSString *XMKey_PreferencesCodecListRecordIsEnabled;

#pragma mark XMPreferencesRegistarRecord Keys

extern NSString *XMKey_PreferencesRegistrarRecordHost;
extern NSString *XMKey_PreferencesRegistrarRecordUsername;
extern NSString *XMKey_PreferencesRegistrarRecordAuthorizationUsername;
extern NSString *XMKey_PreferencesRegistrarRecordPassword;

#pragma mark XMCodecManager Keys

/**
 * List of keys for accessing the properties of a codec description
 **/
extern NSString *XMKey_CodecIdentifier;
extern NSString *XMKey_CodecName;
extern NSString *XMKey_CodecBandwidth;
extern NSString *XMKey_CodecQuality;
extern NSString *XMKey_CodecCanDisable;

#pragma mark XMAddressResource and subclasses keys

extern NSString *XMKey_AddressResourceCallProtocol;
extern NSString *XMKey_AddressResourceAddress;
extern NSString *XMKey_AddressResourceHumanReadableAddress;

#endif // __XM_STRING_CONSTANTS_H__