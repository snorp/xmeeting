/*
 * $Id: XMApplicationFunctions.m,v 1.5 2006/03/18 18:26:10 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMApplicationFunctions.h"

NSString *XMByteString(unsigned bytes)
{
	double value;
	
	if(bytes > (1024 * 1024 * 1024)) //GByte size
	{
		value = bytes / (double)(1024 * 1024 * 1024);
		return [NSString stringWithFormat:@"%4.1f GB", value];
	}
	else if(bytes > (1024 * 1024))
	{
		value = bytes / (double)(1024 * 1024);
		return [NSString stringWithFormat:@"%4.1f MB", value];
	}
	else if(bytes > 1024)
	{
		value = bytes / (double)1024;
		return [NSString stringWithFormat:@"%4.1f KB", value];
	}
	else
	{
		return [NSString stringWithFormat:@"%d Bytes", bytes];
	}
}

NSString *XMTimeString(unsigned time)
{
	unsigned hours = time / (60 * 60);
	unsigned minutes = (time / 60) - (60 * hours);
	unsigned seconds = time % 60;
	
	if(hours > 0)
	{
		return [NSString stringWithFormat:@"%d:%d:%d", hours, minutes, seconds];
	}
	else
	{
		return [NSString stringWithFormat:@"%d:%d", minutes, seconds];
	}
}

NSString *XMDateFormatString()
{
	return @"%Y-%m-%d %H:%M:%S";
}

NSString *XMCallEndReasonString(XMCallEndReason callEndReason)
{
	NSString *reasonString;
	
	switch(callEndReason)
	{
		case XMCallEndReason_EndedByLocalUser:
			reasonString = @"User cleared call";
			break;
		case XMCallEndReason_EndedByNoAccept:
		case XMCallEndReason_EndedByRefusal:
			reasonString = @"Remote party refused call";
			break;
		case XMCallEndReason_EndedByRemoteUser:
			reasonString = @"Remote party cleared call";
			break;
		case XMCallEndReason_EndedByAnswerDenied:
		case XMCallEndReason_EndedByNoAnswer:
			reasonString = @"Remote party did not answer call";
			break;
		case XMCallEndReason_EndedByCallerAbort:
			reasonString = @"Remote party stopped calling";
			break;
		case XMCallEndReason_EndedByTransportFail:
		case XMCallEndReason_EndedByConnectFail:
			reasonString = @"Internal transport/connect failure";
			break;
		case XMCallEndReason_EndedByGatekeeper:
			reasonString = @"Gatekeeper cleared call";
			break;
		case XMCallEndReason_EndedByNoUser:
			reasonString = @"No such user registered at gatekeeper";
			break;
		case XMCallEndReason_EndedByNoBandwidth:
			reasonString = @"Insufficient bandwidth";
			break;
		case XMCallEndReason_EndedByCapabilityExchange:
			reasonString = @"No common media capabilities";
			break;
		case XMCallEndReason_EndedByCallForwarded:
			reasonString = @"Call forwarded";
			break;
		case XMCallEndReason_EndedBySecurityDenial:
			reasonString = @"Call failed security check";
			break;
		case XMCallEndReason_EndedByRemoteBusy:
		case XMCallEndReason_EndedByRemoteCongestion:
			reasonString = @"Remote party is busy";
			break;
		case XMCallEndReason_EndedByUnreachable:
			reasonString = @"Remote party unreachable";
			break;
		case XMCallEndReason_EndedByNoEndPoint:
			reasonString = @"No endpoint running at remote party";
			break;
		case XMCallEndReason_EndedByHostOffline:
			reasonString = @"Remote party host is offline";
			break;
		case XMCallEndReason_EndedByDurationLimit:
			reasonString = @"Call duration limit reached";
			break;
		case XMCallEndReason_EndedByInvalidConferenceID:
			reasonString = @"Invalid conference ID";
			break;
		default:
			reasonString = [NSString stringWithFormat:@"Unspecified reason (%d)", callEndReason];
			break;
	}
	
	return reasonString;
		
}

NSString *XMGatekeeperRegistrationFailReasonString(XMGatekeeperRegistrationFailReason failReason)
{
	NSString *failReasonString;
	
	switch(failReason)
	{
		case XMGatekeeperRegistrationFailReason_GatekeeperNotFound:
			failReasonString = @"Gatekeeper not found";
			break;
		case XMGatekeeperRegistrationFailReason_RegistrationReject:
			failReasonString = @"Gatekeeper rejected registration";
			break;
		default:
			failReasonString = @"Unknown reason";
			break;
	}
	
	return failReasonString;
}

NSString *XMSIPStatusCodeString(XMSIPStatusCode statusCode)
{
	NSString *statusCodeString;
	
	switch(statusCode)
	{
		case XMSIPStatusCode_NoFailure:
			statusCodeString = @"No Failure";
			break;
		case XMSIPStatusCode_Information_Trying:
			statusCodeString = @"100 Trying";
			break;
		case XMSIPStatusCode_Information_Ringing:
			statusCodeString = @"180 Ringing";
			break;
		case XMSIPStatusCode_Information_CallForwarded:
			statusCodeString = @"181 Call Forwarded";
			break;
		case XMSIPStatusCode_Information_Queued:
			statusCodeString = @"182 Queued";
			break;
		case XMSIPStatusCode_Information_Session_Progress:
			statusCodeString = @"183 Session Progress";
			break;
			
		case XMSIPStatusCode_Succesful_OK:
			statusCodeString = @"200 OK";
			break;
		case XMSIPStatusCode_Succesful_Accepted:
			statusCodeString = @"202 Accepted";
			break;
			
		case XMSIPStatusCode_Redirection_MultipleChoices:
			statusCodeString = @"300 Multiple Choices";
			break;
		case XMSIPStatusCode_Redirection_MovedPermamently:
			statusCodeString = @"301 Moved Permamently";
			break;
		case XMSIPStatusCode_Redirection_MovedTemporarily:
			statusCodeString = @"302 Moved Temporarily";
			break;
		case XMSIPStatusCode_Redirection_UseProxy:
			statusCodeString = @"305 Use Proxy";
			break;
		case XMSIPStatusCode_Redirection_AlternativeService:
			statusCodeString = @"380 Alternative Service";
			break;
			
		case XMSIPStatusCode_Failure_BadRequest:
			statusCodeString = @"400 Bad Request";
			break;
		case XMSIPStatusCode_Failure_UnAuthorized:
			statusCodeString = @"401 Unauthorized";
			break;
		case XMSIPStatusCode_Failure_PaymentRequired:
			statusCodeString = @"402 Payment Required";
			break;
		case XMSIPStatusCode_Failure_Forbidden:
			statusCodeString = @"403 Forbidden";
			break;
		case XMSIPStatusCode_Failure_NotFound:
			statusCodeString = @"404 Not Found";
			break;
		case XMSIPStatusCode_Failure_MethodNotAllowed:
			statusCodeString = @"405 Method Not Allowed";
			break;
		case XMSIPStatusCode_Failure_NotAcceptable:
			statusCodeString = @"406 Not Acceptable";
			break;
		case XMSIPStatusCode_Failure_ProxyAuthenticationRequired:
			statusCodeString = @"407 Proxy Authentication Required";
			break;
		case XMSIPStatusCode_Failure_RequestTimeout:
			statusCodeString = @"408 Request Timeout";
			break;
		case XMSIPStatusCode_Failure_Conflict:
			statusCodeString = @"409 Conflict";
			break;
		case XMSIPStatusCode_Failure_Gone:
			statusCodeString = @"410 Gone";
			break;
		case XMSIPStatusCode_Failure_LengthRequired:
			statusCodeString = @"411 LengthRequired";
			break;
		case XMSIPStatusCode_Failure_RequestEntityTooLarge:
			statusCodeString = @"413 Request Entity Too Large";
			break;
		case XMSIPStatusCode_Failure_RequestURITooLong:
			statusCodeString = @"414 Request URI Too Long";
			break;
		case XMSIPStatusCode_Failure_UnsupportedMediaScheme:
			statusCodeString = @"415 Unsupported Media Scheme";
			break;
		case XMSIPStatusCode_Failure_UnsupportedURIScheme:
			statusCodeString = @"416 Unsupported URI Scheme";
			break;
		case XMSIPStatusCode_Failure_BadExtension:
			statusCodeString = @"420 Bad Extension";
			break;
		case XMSIPStatusCode_Failure_ExtensionRequired:
			statusCodeString = @"421 Extension Required";
			break;
		case XMSIPStatusCode_Failure_IntervalTooBrief:
			statusCodeString = @"423 Interval Too Brief";
			break;
		case XMSIPStatusCode_Failure_TemporarilyUnavailable:
			statusCodeString = @"480 Temporarily Unavailable";
			break;
		case XMSIPStatusCode_Failure_TransactionDoesNotExist:
			statusCodeString = @"481 Transaction Does Not Exist";
			break;
		case XMSIPStatusCode_Failure_LoopDetected:
			statusCodeString = @"482 Loop Detected";
			break;
		case XMSIPStatusCode_Failure_TooManyHops:
			statusCodeString = @"483 Too Many Hops";
			break;
		case XMSIPStatusCode_Failure_AddressIncomplete:
			statusCodeString = @"484 Address Incomplete";
			break;
		case XMSIPStatusCode_Failure_Ambiguous:
			statusCodeString = @"485 Ambiguous";
			break;
		case XMSIPStatusCode_Failure_BusyHere:
			statusCodeString = @"486 Busy Here";
			break;
		case XMSIPStatusCode_Failure_RequestTerminated:
			statusCodeString = @"487 Request Terminated";
			break;
		case XMSIPStatusCode_Failure_NotAcceptableHere:
			statusCodeString = @"488 Not Acceptable Here";
			break;
		case XMSIPStatusCode_Failure_BadEvent:
			statusCodeString = @"489 Bad Event";
			break;
		case XMSIPStatusCode_Failure_RequestPending:
			statusCodeString = @"491 Request Pending";
			break;
		case XMSIPStatusCode_Failure_Undecipherable:
			statusCodeString = @"492 Undecipherable";
			break;
			
		case XMSIPStatusCode_Failure_InternalServerError:
			statusCodeString = @"500 Internal Server Error";
			break;
		case XMSIPStatusCode_Failure_NotImplemented:
			statusCodeString = @"501 Not Implemented";
			break;
		case XMSIPStatusCode_Failure_BadGateway:
			statusCodeString = @"502 Bad Gateway";
			break;
		case XMSIPStatusCode_Failure_ServiceUnavailable:
			statusCodeString = @"503 Service Unavailable";
			break;
		case XMSIPStatusCode_Failure_ServerTimeout:
			statusCodeString = @"504 Server Timeout";
			break;
		case XMSIPStatusCode_Failure_SIPVersionNotSupported:
			statusCodeString = @"505 SIP Version Not Supported";
			break;
		case XMSIPStatusCode_Failure_MessageTooLarge:
			statusCodeString = @"513 Message Too Large";
			break;
			
		case XMSIPStatusCode_GlobalFailure_BusyEverywhere:
			statusCodeString = @"600 Busy Everywhere";
			break;
		case XMSIPStatusCode_GlobalFailure_Decline:
			statusCodeString = @"603 Decline";
			break;
		case XMSIPStatusCode_GlobalFailure_DoesNotExistAnywhere:
			statusCodeString = @"604 Does Not Exist Anywhere";
			break;
		case XMSIPStatusCode_GlobalFailure_NotAcceptable:
			statusCodeString = @"606 Not Acceptable";
			break;
			
		default:
			statusCodeString = @"Unknown Failure";
	}
	
	return statusCodeString;
}