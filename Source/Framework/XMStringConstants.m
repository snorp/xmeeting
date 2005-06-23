/*
 * $Id: XMStringConstants.m,v 1.1 2005/06/23 12:35:56 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMTypes.h"
#import "XMPrivate.h"

#pragma mark Notifications

NSString *XMNotification_DidStartFetchingExternalAddress = @"XMeeting_DidStartFetchingExternalAddressNotification";
NSString *XMNotification_DidEndFetchingExternalAddress = @"XMeeting_DidEndFetchingExternalAddressNotification";

NSString *XMNotification_DidGoOnline = @"XMeeting_DidGoOnlineNotification";
NSString *XMNotification_DidGoOffline = @"XMeeting_DidGoOfflineNotification";
NSString *XMNotification_DidStartSubsystemSetup = @"XMeeting_DidStartSubsystemSetupNotification";
NSString *XMNotification_DidEndSubsystemSetup = @"XMeeting_DidEndSubsystemSetupNotification";

NSString *XMNotification_DidStartCalling = @"XMeeting_DidStartCallingNotification";
NSString *XMNotification_IncomingCall = @"XMeeting_IncomingCallNotification";
NSString *XMNotification_CallEstablished = @"XMeeting_CallEstablishedNotification";
NSString *XMNotification_CallCleared = @"XMeeting_CallClearedNotification";

NSString *XMNotification_GatekeeperRegistration = @"XMeeting_GatekeeperRegistrationNotification";
NSString *XMNotification_GatekeeperUnregistration = @"XMeeting_GatekeeperUnregistrationNotification";
NSString *XMNotification_GatekeeperRegistrationFailure = @"XMeeting_GatekeeperRegistrationFailureNotification";

NSString *XMNotification_AudioInputDeviceDidChange = @"XMeeting_AudioInputDeviceDidChangeNotification";
NSString *XMNotification_AudioOutputDeviceDidChange = @"XMeeting_AudioOutputDeviceDidChangeNotification";
NSString *XMNotification_AudioInputVolumeDidChange = @"XMeeting_AudioInputVolumeDidChangeNotification";
NSString *XMNotification_AudioOutputVolumeDidChange = @"XMeeting_AudioOutputVolumeDidChangeNotification";

NSString *XMNotification_DidStartVideoGrabbing = @"XMeeting_DidStartVideoGrabbingNotification";
NSString *XMNotification_DidStopVideoGrabbing = @"XMeeting_DidEndVideoGrabbingNotification";
NSString *XMNotification_DidReadVideoFrame = @"XMeeting_DidReadVideoFrameNotification";
NSString *XMNotification_DidUpdateVideoDeviceList = @"XMeeting_DidUpdateVideoDeviceListNotification";

#pragma mark Exceptions

NSString *XMException_InvalidAction = @"XMeeting_InvalidActionException";
NSString *XMException_InvalidParameter = @"Xmeeting_InvalidParameterException";
NSString *XMException_UnsupportedCoder = @"XMeeting_UnsupportedCoderException";
NSString *XMException_InternalConsistencyFailure = @"XMeeting_InternalConsistencFailureException";

NSString *XMExceptionReason_InvalidParameterMustNotBeNil = @"Parameter must not be nil";
NSString *XMExceptionReason_UnsupportedCoder = @"Only NSCoder sublasses which allow keyed coding are supported";
NSString *XMExceptionReason_CallManagerInvalidActionWhileOffline = @"Not allowed while CallManager is offline";
NSString *XMExceptionReason_CallManagerInvalidActionWhileSubsystemSetup = @"Not allowed during subsystem setup";
NSString *XMExceptionReason_CallManagerInvalidActionWhileInCall = @"Not allowed while in call";
NSString *XMExceptionReason_CallManagerInvalidActionWhileNotInCall = @"Not allowed unless calling or in a call";
NSString *XMExceptionReason_CallManagerCallEstablishedInternalConsistencyFailure = @"Call established without active call";
NSString *XMExceptionReason_CallManagerCallClearedInternalConsistencyFailure = @"Call cleared without active call";
NSString *XMExceptionReason_CodecManagerInternalConsistencyFailure = @"Parsing the infos for available codecs failed (%@)";

#pragma mark Audio Codecs

NSString *XMAudioCodec_G711_ALaw = @"g.711-alaw";
NSString *XMAudioCodec_G711_uLaw = @"g.711-ulaw";
NSString *XMAudioCodec_Speex = @"speex";
NSString *XMAudioCodec_GSM = @"gsm";
NSString *XMAudioCodec_G726 = @"g.726";
NSString *XMAudioCodec_iLBC = @"ilbc";
NSString *XMAudioCodec_IMA_ADPCM = @"ima_adpcm";
NSString *XMAudioCodec_LPC = @"lpc";

#pragma mark Video Codecs

NSString *XMVideoCodec_H261 = @"h.261";
NSString *XMVideoCodec_H263 = @"h.263";

#pragma mark Address Book Properties

NSString *XMAddressBook_CallURLProperty = @"XMeeting_CallURL";
NSString *XMAddressBook_HumanReadableCallAddressProperty = @"XMeeting_HumanReadableCallAddress";

#pragma mark Private Keys

NSString *XMKey_Preferences_UserName = @"XMeeting_UserName";
NSString *XMKey_Preferences_AutoAnswerCalls = @"XMeeting_AutoAnswerCalls";

NSString *XMKey_Preferences_BandwidthLimit = @"XMeeting_BandwidthLimit";
NSString *XMKey_Preferences_UseAddressTranslation = @"XMeeting_UseAddressTranslation";
NSString *XMKey_Preferences_ExternalAddress = @"XMeeting_ExternalAddress";
NSString *XMKey_Preferences_TCPPortBase = @"XMeeting_TCPPortBase";
NSString *XMKey_Preferences_TCPPortMax = @"XMeeting_TCPPortMax";
NSString *XMKey_Preferences_UDPPortBase = @"XMeeting_UDPPortBase";
NSString *XMKey_Preferences_UDPPortMax = @"XMeeting_UDPPortMax";

NSString *XMKey_Preferences_AudioCodecPreferenceList = @"XMeeting_AudioCodecPreferenceList";
NSString *XMKey_Preferences_AudioBufferSize = @"XMeeting_AudioBufferSize";

NSString *XMKey_Preferences_EnableVideoReceive = @"XMeeting_EnableVideoReceive";
NSString *XMKey_Preferences_EnableVideoTransmit = @"XMeeting_EnableVideoTransmit";
NSString *XMKey_Preferences_VideoFramesPerSecond = @"XMeeting_VideoFramesPerSecond";
NSString *XMKey_Preferences_VideoSize = @"XMeeting_VideoSize";
NSString *XMKey_Preferences_VideoCodecPreferenceList = @"XMeeting_VideoCodecPreferenceList";

NSString *XMKey_Preferences_EnableH323 = @"XMeeting_EnableH323";
NSString *XMKey_Preferences_EnableH245Tunnel = @"XMeeting_EnableH245Tunnel";
NSString *XMKey_Preferences_EnableFastStart = @"XMeeting_EnableFastStart";
NSString *XMKey_Preferences_UseGatekeeper = @"XMeeting_UseGatekeeper";
NSString *XMKey_Preferences_GatekeeperAddress = @"XMeeting_GatekeeperAddress";
NSString *XMKey_Preferences_GatekeeperID = @"XMeeting_GatekeeperID";
NSString *XMKey_Preferences_GatekeeperUsername = @"XMeeting_GatekeeperUsername";
NSString *XMKey_Preferences_GatekeeperPhoneNumber = @"XMeeting_GatekeeperPhoneNumber";

NSString *XMKey_CodecListRecord_Identifier = @"XMeeting_Identifier";
NSString *XMKey_CodecListRecord_IsEnabled = @"XMeeting_IsEnabled";

NSString *XMKey_CodecDescriptor_Identifier = @"XMeeting_Identifier";
NSString *XMKey_CodecDescriptor_Name = @"XMeeting_Name";
NSString *XMKey_CodecDescriptor_Bandwidth = @"XMeeting_Bandwidth";
NSString *XMKey_CodecDescriptor_Quality = @"XMeeting_Quality";

NSString *XMKey_CodecManager_CodecDescriptionsFilename = @"XMCodecDescriptions";
NSString *XMKey_CodecManager_CodecDescriptionsFiletype = @"plist";
NSString *XMKey_CodecManager_AudioCodecs = @"XMeeting_AudioCodecs";
NSString *XMKey_CodecManager_VideoCodecs = @"XMeeting_VideoCodecs";