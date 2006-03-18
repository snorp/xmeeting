/*
 * $Id: XMTypes.h,v 1.19 2006/03/18 18:26:13 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_TYPES_H__
#define __XM_TYPES_H__

/**
 * This header provides important enumerations, exceptions, notifications
 * and NSString keys used within the framework
 **/

#pragma mark Enumerations

/**
 * Defines the possible results of a NAT detection operation
 **/
typedef enum XMNATDetectionResult
{
	XMNATDetectionResult_Error = 0,
	XMNATDetectionResult_NoNAT,
	XMNATDetectionResult_HasNAT
} XMNATDetectionResult;

/**
 * Defines all available call protocols
 **/
typedef enum XMCallProtocol
{
	XMCallProtocol_UnknownProtocol = 0,
	XMCallProtocol_H323,
	XMCallProtocol_SIP,
	XMCallProtocolCount
} XMCallProtocol;

/**
 * Defines some reasons why starting a call did fail
 **/
typedef enum XMCallStartFailReason
{
	XMCallStartFailReason_NoFailure = 0,
	XMCallStartFailReason_UnknownFailure,
	XMCallStartFailReason_AlreadyInCall,
	XMCallStartFailReason_ProtocolNotEnabled,
	XMCallStartFailReason_GatekeeperUsedButNotSpecified,
	XMCallStartFailReasonCount
} XMCallStartFailReason;

/**
 * Defines the various states in which a call can be
 **/
typedef enum XMCallStatus
{
	XMCallStatus_Unknown = 0,
	XMCallStatus_Calling,
	XMCallStatus_Ringing,
	XMCallStatus_Incoming,
	XMCallStatus_Active,
	XMCallStatus_Terminating,
	XMCallStatus_Ended,
	XMCallStatusCount
} XMCallStatus;

/**
 * Defines the CallEnd reasons.
 * Note that this is a simple copy from the CallEndReason enum
 * in OpalConnection
 **/
typedef enum XMCallEndReason
{
	XMCallEndReason_EndedByLocalUser = 0,     /// Local endpoint application cleared call
	XMCallEndReason_EndedByNoAccept,          /// Local endpoint did not accept call OnIncomingCall()=FALSE
	XMCallEndReason_EndedByAnswerDenied,      /// Local endpoint declined to answer call
	XMCallEndReason_EndedByRemoteUser,        /// Remote endpoint application cleared call
	XMCallEndReason_EndedByRefusal,           /// Remote endpoint refused call
	XMCallEndReason_EndedByNoAnswer,          /// Remote endpoint did not answer in required time
	XMCallEndReason_EndedByCallerAbort,       /// Remote endpoint stopped calling
	XMCallEndReason_EndedByTransportFail,     /// Transport error cleared call
	XMCallEndReason_EndedByConnectFail,       /// Transport connection failed to establish call
	XMCallEndReason_EndedByGatekeeper,        /// Gatekeeper has cleared call
	XMCallEndReason_EndedByNoUser,            /// Call failed as could not find user (in GK)
	XMCallEndReason_EndedByNoBandwidth,       /// Call failed as could not get enough bandwidth
	XMCallEndReason_EndedByCapabilityExchange,/// Could not find common capabilities
	XMCallEndReason_EndedByCallForwarded,     /// Call was forwarded using FACILITY message
	XMCallEndReason_EndedBySecurityDenial,    /// Call failed a security check and was ended
	XMCallEndReason_EndedByLocalBusy,         /// Local endpoint busy
	XMCallEndReason_EndedByLocalCongestion,   /// Local endpoint congested
	XMCallEndReason_EndedByRemoteBusy,        /// Remote endpoint busy
	XMCallEndReason_EndedByRemoteCongestion,  /// Remote endpoint congested
	XMCallEndReason_EndedByUnreachable,       /// Could not reach the remote party
	XMCallEndReason_EndedByNoEndPoint,        /// The remote party is not running an endpoint
	XMCallEndReason_EndedByHostOffline,       /// The remote party host off line
	XMCallEndReason_EndedByTemporaryFailure,  /// The remote failed temporarily app may retry
	XMCallEndReason_EndedByQ931Cause,         /// The remote ended the call with unmapped Q.931 cause code
	XMCallEndReason_EndedByDurationLimit,     /// Call cleared due to an enforced duration limit
	XMCallEndReason_EndedByInvalidConferenceID, /// Call cleared due to invalid conference ID
	XMCallEndReasonCount
} XMCallEndReason;

/**
 * Defines the various gatekeeper registration fail reasons
 **/
typedef enum XMGatekeeperRegistrationFailReason
{
	XMGatekeeperRegistrationFailReason_NoFailure = 0,
	XMGatekeeperRegistrationFailReason_UnknownFailure,
	XMGatekeeperRegistrationFailReason_GatekeeperNotFound,
	XMGatekeeperRegistrationFailReason_RegistrationReject
} XMGatekeeperRegistrationFailReason;

/**
 * Defines the various SIP registrar registration fail reasons
 **/
typedef enum XMSIPStatusCode
{
	XMSIPStatusCode_NoFailure							=   0,
	XMSIPStatusCode_UnknownFailure						=   1,
	
	XMSIPStatusCode_Information_Trying					= 100,
	XMSIPStatusCode_Information_Ringing					= 180,
	XMSIPStatusCode_Information_CallForwarded			= 181,
	XMSIPStatusCode_Information_Queued					= 182,
	XMSIPStatusCode_Information_Session_Progress		= 183,
	
	XMSIPStatusCode_Succesful_OK						= 200,
	XMSIPStatusCode_Succesful_Accepted					= 202,
	
	XMSIPStatusCode_Redirection_MultipleChoices			= 300,
	XMSIPStatusCode_Redirection_MovedPermamently		= 301,
	XMSIPStatusCode_Redirection_MovedTemporarily		= 302,
	XMSIPStatusCode_Redirection_UseProxy				= 305,
	XMSIPStatusCode_Redirection_AlternativeService		= 380,
	
	XMSIPStatusCode_Failure_BadRequest					= 400,
	XMSIPStatusCode_Failure_UnAuthorized				= 401,
	XMSIPStatusCode_Failure_PaymentRequired				= 402,
	XMSIPStatusCode_Failure_Forbidden					= 403,
	XMSIPStatusCode_Failure_NotFound					= 404,
	XMSIPStatusCode_Failure_MethodNotAllowed			= 405,
	XMSIPStatusCode_Failure_NotAcceptable				= 406,
	XMSIPStatusCode_Failure_ProxyAuthenticationRequired = 407,
	XMSIPStatusCode_Failure_RequestTimeout				= 408,
	XMSIPStatusCode_Failure_Conflict					= 409,
	XMSIPStatusCode_Failure_Gone						= 410,
	XMSIPStatusCode_Failure_LengthRequired				= 411,
	XMSIPStatusCode_Failure_RequestEntityTooLarge		= 413,
	XMSIPStatusCode_Failure_RequestURITooLong			= 414,
	XMSIPStatusCode_Failure_UnsupportedMediaScheme		= 415,
	XMSIPStatusCode_Failure_UnsupportedURIScheme		= 416,
	XMSIPStatusCode_Failure_BadExtension				= 420,
	XMSIPStatusCode_Failure_ExtensionRequired			= 421,
	XMSIPStatusCode_Failure_IntervalTooBrief			= 423,
	XMSIPStatusCode_Failure_TemporarilyUnavailable		= 480,
	XMSIPStatusCode_Failure_TransactionDoesNotExist		= 481,
	XMSIPStatusCode_Failure_LoopDetected				= 482,
	XMSIPStatusCode_Failure_TooManyHops					= 483,
	XMSIPStatusCode_Failure_AddressIncomplete			= 484,
	XMSIPStatusCode_Failure_Ambiguous					= 485,
	XMSIPStatusCode_Failure_BusyHere					= 486,
	XMSIPStatusCode_Failure_RequestTerminated			= 487,
	XMSIPStatusCode_Failure_NotAcceptableHere			= 488,
	XMSIPStatusCode_Failure_BadEvent					= 489,
	XMSIPStatusCode_Failure_RequestPending				= 491,
	XMSIPStatusCode_Failure_Undecipherable				= 493,
	
	XMSIPStatusCode_Failure_InternalServerError			= 500,
	XMSIPStatusCode_Failure_NotImplemented				= 501,
	XMSIPStatusCode_Failure_BadGateway					= 502,
	XMSIPStatusCode_Failure_ServiceUnavailable			= 503,
	XMSIPStatusCode_Failure_ServerTimeout				= 504,
	XMSIPStatusCode_Failure_SIPVersionNotSupported		= 505,
	XMSIPStatusCode_Failure_MessageTooLarge				= 513,
	
	XMSIPStatusCode_GlobalFailure_BusyEverywhere		= 600,
	XMSIPStatusCode_GlobalFailure_Decline				= 603,
	XMSIPStatusCode_GlobalFailure_DoesNotExistAnywhere	= 604,
	XMSIPStatusCode_GlobalFailure_NotAcceptable			= 606,
	
	XMSIPStatusCodeCount
} XMSIPStatusCode;

/**
 * Defines the audio codecs
 **/
typedef enum XMCodecIdentifier
{
	XMCodecIdentifier_UnknownCodec = 0,
	
	// Audio Codecs
	XMCodecIdentifier_G711_uLaw = 1,
	XMCodecIdentifier_G711_ALaw,
	
	// Video Codecs
	XMCodecIdentifier_H261 = 100,
	XMCodecIdentifier_H263,
	XMCodecIdentifier_H264
	
} XMCodecIdentifier;

/**
 * Defines the various VideoSizes which are supported
 * by the framework
 **/
typedef enum XMVideoSize
{
	XMVideoSize_NoVideo = 0,
	XMVideoSize_SQCIF,
	XMVideoSize_QCIF,
	XMVideoSize_CIF,
	XMVideoSize_4CIF,
	XMVideoSize_16CIF,
	XMVideoSize_320_240,
	XMVideoSizeCount
} XMVideoSize;

/**
 * Defines the various types of URL's that the XMeeting framework understands
 **/
/*typedef enum XMURLType
{
	XMURLType_GeneralPurposeURL = 0,
	XMURLType_H323URL,
	XMURLType_CalltoURL,
	XMURLTypeCount
} XMURLType;*/

/**
 * Defines the types of connection an XMCalltoURL instance can implement
 **/
/*/typedef enum XMCalltoURLType
{
	XMCalltoURLType_Unknown = 0,
	XMCalltoURLType_Direct,
	XMCalltoURLType_Gatekeeper,
	XMCalltoURLType_Directory,	// not supported
	XMCalltoURLType_Gateway,	// not supported
	XMCalltoURLTypeCount
} XMCalltoURLType;*/

#pragma mark Structs

typedef struct XMCallStatisticsRecord
{
	unsigned roundTripDelay;
	unsigned audioPacketsSent;
	unsigned audioBytesSent;
	unsigned audioMinimumSendTime;
	unsigned audioAverageSendTime;
	unsigned audioMaximumSendTime;
	unsigned audioPacketsReceived;
	unsigned audioBytesReceived;
	unsigned audioMinimumReceiveTime;
	unsigned audioAverageReceiveTime;
	unsigned audioMaximumReceiveTime;
	unsigned audioPacketsLost;
	unsigned audioPacketsOutOfOrder;
	unsigned audioPacketsTooLate;
	unsigned videoPacketsSent;
	unsigned videoBytesSent;
	unsigned videoMinimumSendTime;
	unsigned videoAverageSendTime;
	unsigned videoMaximumSendTime;
	unsigned videoPacketsReceived;
	unsigned videoBytesReceived;
	unsigned videoMinimumReceiveTime;
	unsigned videoAverageReceiveTime;
	unsigned videoMaximumReceiveTime;
	unsigned videoPacketsLost;
	unsigned videoPacketsOutOfOrder;
	unsigned videoPacketsTooLate;
} XMCallStatisticsRecord;

#endif // __XM_TYPES_H__
