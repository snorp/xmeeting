/*
 * $Id: XMTypes.h,v 1.1 2005/02/11 12:58:44 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_TYPES_H__
#define __XM_TYPES_H__

/**
 * This header provides important enumerations used within the
 * framework
 **/

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
 */
typedef enum XMListenerStatus
{
	XMListenerStatus_Offline = 0,
	XMListenerStatus_Listening,
	XMListenerStatus_Error,
	XMListenerStatus_InCall,
	XMListenerStatusCount
} XMListenerStatus;
#endif // __XM_TYPES_H__
