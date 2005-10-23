/*
 * $Id: XMStringConstants.m,v 1.9 2005/10/23 19:59:00 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMTypes.h"
#import "XMPrivate.h"

#pragma mark Notifications

NSString *XMNotification_FrameworkDidInitialize = @"XMeetingFrameworkDidInitializeNotificaiton";
NSString *XMNotification_FrameworkDidClose = @"XMeetingFrameworkDidCloseNotification";

NSString *XMNotification_UtilsDidStartFetchingExternalAddress = @"XMeetingUtilsDidStartFetchingExternalAddressNotification";
NSString *XMNotification_UtilsDidEndFetchingExternalAddress = @"XMeetingUtilsDidEndFetchingExternalAddressNotification";

NSString *XMNotification_CallManagerDidStartSubsystemSetup = @"XMeetingCallManagerDidStartSubsystemSetupNotification";
NSString *XMNotification_CallManagerDidEndSubsystemSetup = @"XMeetingCallManagerDidEndSubsystemSetupNotification";

NSString *XMNotification_CallManagerDidStartCallInitiation = @"XMeetingCallManagerDidStartCallInitiationNotification";
NSString *XMNotification_CallManagerDidStartCalling = @"XMeetingCallManagerDidStartCallingNotification";
NSString *XMNotification_CallManagerDidNotStartCalling = @"XMeetingCallManagerCallDidNotStartCallingNotification";
NSString *XMNotification_CallManagerDidStartRingingAtRemoteParty = @"XMeetingCallManagerDidStartRingingAtRemotePartyNotification";
NSString *XMNotification_CallManagerDidReceiveIncomingCall = @"XMeetingCallManagerDidReceiveIncomingCallNotification";
NSString *XMNotification_CallManagerDidEstablishCall = @"XMeetingCallManagerDidEstablishCallNotification";
NSString *XMNotification_CallManagerDidClearCall = @"XMeetingCallManagerDidClearCallNotification";

NSString *XMNotification_CallManagerDidNotEnableH323 = @"XMeetingCallManagerDidNotEnableH323Notification";
NSString *XMNotification_CallManagerDidStartGatekeeperRegistrationProcess = @"XMeetingCallManagerDidStartGatekeeperRegistrationProcessNotification";
NSString *XMNotification_CallManagerDidEndGatekeeperRegistrationProcess = @"XMeetingCallManagerDidEndGatekeeperRegistrationProcessNotification";
NSString *XMNotification_CallManagerDidRegisterAtGatekeeper = @"XMeetingCallManagerDidRegisterAtGatekeeperNotification";
NSString *XMNotification_CallManagerDidUnregisterFromGatekeeper = @"XMeetingCallManagerDidUnregisterFromGatekeeperNotification";
NSString *XMNotification_CallManagerDidNotRegisterAtGatekeeper = @"XMeetingCallManagerDidNotRegisterAtGatekeeperNotification";

NSString *XMNotification_CallManagerDidOpenOutgoingAudioStream = @"XMeetingCallManagerDidOpenOutgoingAudioStreamNotification";
NSString *XMNotification_CallManagerDidOpenIncomingAudioStream = @"XMeetingCallManagerDidOpenIncomingAudioStreamNotification";
NSString *XMNotification_CallManagerDidOpenOutgoingVideoStream = @"XMeetingCallManagerDidOpenOutgoingVideoStreamNotification";
NSString *XMNotification_CallManagerDidOpenIncomingVideoStream = @"XMeetingCallManagerDidOpenIncomingVideoStreamNotification";

NSString *XMNotification_CallManagerDidCloseOutgoingAudioStream = @"XMeetingCallManagerDidCloseOutgoingAudioStreamNotification";
NSString *XMNotification_CallManagerDidCloseIncomingAudioStream = @"XMeetingCallManagerDidCloseIncomingAudioStreamNotification";
NSString *XMNotification_CallManagerDidCloseOutgoingVideoStream = @"XMeetingCallManagerDidCloseOutgoingVideoStreamNotification";
NSString *XMNotification_CallManagerDidCloseIncomingVideoStream = @"XMeetingCallManagerDidCloseIncomingVideoStreamNotification";

NSString *XMNotification_CallManagerDidUpdateCallStatistics = @"XMeetingCallManagerDidUpdateCallStatisticsNotification";

NSString *XMNotification_AudioManagerInputDeviceDidChange = @"XMeetingAudioManagerInputDeviceDidChangeNotification";
NSString *XMNotification_AudioManagerOutputDeviceDidChange = @"XMeetingAudioManagerOutputDeviceDidChangeNotification";
NSString *XMNotification_AudioManagerInputVolumeDidChange = @"XMeetingAudioManagerInputVolumeDidChangeNotification";
NSString *XMNotification_AudioManagerOutputVolumeDidChange = @"XMeetingAudioManagerOutputVolumeDidChangeNotification";
NSString *XMNotification_AudioManagerDidUpdateDeviceList = @"XMeetingAudioManagerDidUpdateDeviceListNotification";

NSString *XMNotification_VideoManagerDidStartInputDeviceListUpdate = @"XMeetingVideoManagerDidStartVideoInputDeviceListUpdateNotification";
NSString *XMNotification_VideoManagerDidUpdateInputDeviceList = @"XMeetingVideoManagerDidUpdateInputDeviceListNotification";
NSString *XMNotification_VideoManagerDidStartReceivingVideo = @"XMeetingVideoManagerDidStartReceivingVideoNotification";
NSString *XMNotification_VideoManagerDidEndReceivingVideo = @"XMeetingVideoManagerDidEndReceivingVideoNotification";

NSString *XMNotification_AddressBookManagerDidChangeDatabase = @"XMeetingAddressBookManagerDidChangeDatabaseNotification";

#pragma mark Exceptions

NSString *XMException_InvalidAction = @"XMeetingInvalidActionException";
NSString *XMException_InvalidParameter = @"XmeetngInvalidParameterException";
NSString *XMException_UnsupportedCoder = @"XMeetingUnsupportedCoderException";
NSString *XMException_InternalConsistencyFailure = @"XMeetingInternalConsistencFailureException";

NSString *XMExceptionReason_InvalidParameterMustNotBeNil = @"Parameter must not be nil";
NSString *XMExceptionReason_InvalidParameterMustBeOfCorrectType = @"Parameter must be of correct type";
NSString *XMExceptionReason_InvalidParameterMustBeValidKey = @"Key must be valid for this object";
NSString *XMExceptionReason_UnsupportedCoder = @"Only NSCoder sublasses which allow keyed coding are supported";
NSString *XMExceptionReason_CallManagerInvalidActionIfInSubsystemSetupOrInCall = @"Not allowed during subsystem setup or while in a call";
NSString *XMExceptionReason_CallManagerInvalidActionIfNotInCall = @"Not allowed unless in a call";
NSString *XMExceptionReason_CallManagerInvalidActionIfCallStatusNotIncoming = @"Not allowed if not an incoming call";
NSString *XMExceptionReason_CallManagerInvalidActionIfH323Listening = @"Not allowed if H.323 is already succesfully setup";
NSString *XMExceptionReason_CallManagerInvalidActionIfH323Disabled = @"Not allowed if H.323 is disabled in preferences";
NSString *XMExceptionReason_CallManagerInvalidActionIfGatekeeperRegistered = @"Not allowed if succesfully registered at gatekeeper";
NSString *XMExceptionReason_CallManagerInvalidActionIfGatekeeperDisabled = @"Not allowed if gatekeeper usage is disabled in preferences";
NSString *XMExceptionReason_CodecManagerInternalConsistencyFailure = @"Parsing the infos for available codecs failed (%@)";

#pragma mark Audio Codecs

NSString *XMCodec_Audio_G711_ALaw = @"g.711-alaw";
NSString *XMCodec_Audio_G711_uLaw = @"g.711-ulaw";
NSString *XMCodec_Audio_Speex = @"speex";
NSString *XMCodec_Audio_GSM = @"gsm";
NSString *XMCodec_Audio_G726 = @"g.726";
NSString *XMCodec_Audio_iLBC = @"ilbc";

#pragma mark Video Codecs

NSString *XMCodec_Video_H261 = @"h.261";
NSString *XMCodec_Video_H263 = @"h.263";

#pragma mark Keys

NSString *XMKey_PreferencesUserName = @"XMeeting_UserName";
NSString *XMKey_PreferencesAutomaticallyAcceptIncomingCalls = @"XMeeting_AutomaticallyAcceptIncomingCalls";

NSString *XMKey_PreferencesBandwidthLimit = @"XMeeting_BandwidthLimit";
NSString *XMKey_PreferencesUseAddressTranslation = @"XMeeting_UseAddressTranslation";
NSString *XMKey_PreferencesExternalAddress = @"XMeeting_ExternalAddress";
NSString *XMKey_PreferencesTCPPortBase = @"XMeeting_TCPPortBase";
NSString *XMKey_PreferencesTCPPortMax = @"XMeeting_TCPPortMax";
NSString *XMKey_PreferencesUDPPortBase = @"XMeeting_UDPPortBase";
NSString *XMKey_PreferencesUDPPortMax = @"XMeeting_UDPPortMax";

NSString *XMKey_PreferencesAudioCodecList = @"XMeeting_AudioCodecList";
NSString *XMKey_PreferencesAudioBufferSize = @"XMeeting_AudioBufferSize";

NSString *XMKey_PreferencesEnableVideo = @"XMeeting_EnableVideo";
NSString *XMKey_PreferencesVideoFramesPerSecond = @"XMeeting_VideoFramesPerSecond";
NSString *XMKey_PreferencesPreferredVideoSize = @"XMeeting_PreferredVideoSize";
NSString *XMKey_PreferencesVideoCodecList = @"XMeeting_VideoCodecList";

NSString *XMKey_PreferencesEnableH323 = @"XMeeting_EnableH323";
NSString *XMKey_PreferencesEnableH245Tunnel = @"XMeeting_EnableH245Tunnel";
NSString *XMKey_PreferencesEnableFastStart = @"XMeeting_EnableFastStart";
NSString *XMKey_PreferencesUseGatekeeper = @"XMeeting_UseGatekeeper";
NSString *XMKey_PreferencesGatekeeperAddress = @"XMeeting_GatekeeperAddress";
NSString *XMKey_PreferencesGatekeeperID = @"XMeeting_GatekeeperID";
NSString *XMKey_PreferencesGatekeeperUsername = @"XMeeting_GatekeeperUsername";
NSString *XMKey_PreferencesGatekeeperPhoneNumber = @"XMeeting_GatekeeperPhoneNumber";

NSString *XMKey_PreferencesCodecListRecordIdentifier = @"XMeeting_Identifier";
NSString *XMKey_PreferencesCodecListRecordIsEnabled = @"XMeeting_IsEnabled";

NSString *XMKey_CodecManagerCodecDescriptionsFilename = @"XMCodecDescriptions";
NSString *XMKey_CodecManagerCodecDescriptionsFiletype = @"plist";
NSString *XMKey_CodecManagerAudioCodecs = @"XMeeting_AudioCodecs";
NSString *XMKey_CodecManagerVideoCodecs = @"XMeeting_VideoCodecs";

NSString *XMKey_CodecIdentifier = @"XMeeting_Identifier";
NSString *XMKey_CodecName = @"XMeeting_Name";
NSString *XMKey_CodecBandwidth = @"XMeeting_Bandwidth";
NSString *XMKey_CodecQuality = @"XMeeting_Quality";

NSString *XMKey_URLType = @"XMeeting_URLType";
NSString *XMKey_URLAddress = @"XMeeting_Address";

#pragma mark Address Book Properties

NSString *XMAddressBookProperty_CallURL = @"XMeeting_URL";
NSString *XMAddressBookProperty_HumanReadableCallURLRepresentation = @"XMeeting_HumanReadableURLRepresentation";