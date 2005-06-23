/*
 * $Id: XMTypes.h,v 1.5 2005/06/23 12:35:56 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
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
	XMCallProtocol_Unknown = 0,
	XMCallProtocol_H323,
	XMCallProtocol_SIP,	/* Not yet supported */
	XMCallProtocolCount
} XMCallProtocol;

/**
 * Defines the various states in which a call can be
 **/
typedef enum XMCallStatus
{
	XMCallStatus_Unknown = 0,
	XMCallStatus_Calling,		// indicates that this is an active call
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
 * Defines the various types of status the listener system can be in
 **/
typedef enum XMListenerStatus
{
	XMListenerStatus_Offline = 0,
	XMListenerStatus_Listening,
	XMListenerStatus_Error,
	XMListenerStatus_InCall,
	XMListenerStatusCount
} XMListenerStatus;

/**
 * Defines the various VideoSizes which are supported
 * by the framework
 **/
typedef enum XMVideoSize
{
	XMVideoSize_NoVideo = 0,
	XMVideoSize_QCIF,
	XMVideoSize_CIF,
	XMVideoSizeCount
} XMVideoSize;

/**
 * Defines which part of a record matched a search operation in the address book
 * database
 **/
typedef enum XMAddressBookRecordPropertyMatch
{
	XMAddressBookRecordPropertyMatch_NoMatch = 0,
	XMAddressBookRecordPropertyMatch_FirstNameMatch,
	XMAddressBookRecordPropertyMatch_LastNameMatch,
	XMAddressBookRecordPropertyMatch_CompanyMatch,
	XMAddressBookRecordPropertyMatch_CallAddressMatch,
	XMAddressBookRecordPropertyMatchCount
} XMAddressBookRecordPropertyMatch;

/**
 * Defines the various types of URL's that the XMeeting framework understands
 **/
typedef enum XMURLType
{
	XMURLType_Callto = 0,
	XMURLTypeCount
} XMURLType;

/**
 * Defines the types of connection an XMCalltoURL instance can implement
 **/
typedef enum XMCalltoURLType
{
	XMCalltoURLType_Unknown = 0,
	XMCalltoURLType_Direct,
	XMCalltoURLType_Gatekeeper,
	XMCalltoURLType_Directory,	/* not supported */
	XMCalltoURLType_Gateway,	/* not supported */
	XMCalltoURLTypeCount
} XMCalltoURLType;

#endif // __XM_TYPES_H__
