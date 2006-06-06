/*
 * $Id: XMApplicationFunctions.m,v 1.11 2006/06/06 16:38:48 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMApplicationFunctions.h"

#define XM_STUN_SERVERS_FILE_NAME @"XMSTUNServers"
#define XM_STUN_SERVERS_FILE_TYPE @"plist"

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
	return NSLocalizedString(@"XM_DATE_FORMAT_STRING", @"");
}

NSString *XMCallEndReasonString(XMCallEndReason callEndReason)
{
	NSString *reasonString;
	
	switch(callEndReason)
	{
		case XMCallEndReason_EndedByLocalUser:
			reasonString = NSLocalizedString(@"XM_CALL_END_USER_CLEARED", @"");
			break;
		case XMCallEndReason_EndedByNoAccept:
		case XMCallEndReason_EndedByRefusal:
			reasonString = NSLocalizedString(@"XM_CALL_END_REMOTE_REFUSED", @"");
			break;
		case XMCallEndReason_EndedByRemoteUser:
			reasonString = NSLocalizedString(@"XM_CALL_END_REMOTE_CLEARED", @"");
			break;
		case XMCallEndReason_EndedByAnswerDenied:
		case XMCallEndReason_EndedByNoAnswer:
			reasonString = NSLocalizedString(@"XM_CALL_END_REMOTE_NO_ANSWER", @"");;
			break;
		case XMCallEndReason_EndedByCallerAbort:
			reasonString = NSLocalizedString(@"XM_CALL_END_REMOTE_ABORT", @"");
			break;
		case XMCallEndReason_EndedByTransportFail:
		case XMCallEndReason_EndedByConnectFail:
			reasonString = NSLocalizedString(@"XM_CALL_END_INTERNAL_FAILURE", @"");
			break;
		case XMCallEndReason_EndedByGatekeeper:
			reasonString = NSLocalizedString(@"XM_CALL_END_GK_CLEARED", @"");
			break;
		case XMCallEndReason_EndedByNoUser:
			reasonString = NSLocalizedString(@"XM_CALL_END_NO_USER", @"");
			break;
		case XMCallEndReason_EndedByNoBandwidth:
			reasonString = NSLocalizedString(@"XM_CALL_END_NO_BANDWIDTH", @"");
			break;
		case XMCallEndReason_EndedByCapabilityExchange:
			reasonString = NSLocalizedString(@"XM_CALL_END_CAP_EXCHANGE", @"");
			break;
		case XMCallEndReason_EndedByCallForwarded:
			reasonString = NSLocalizedString(@"XM_CALL_END_FORWARDED", @"");
			break;
		case XMCallEndReason_EndedBySecurityDenial:
			reasonString = NSLocalizedString(@"XM_CALL_END_SECURITY_DENIAL", @"");
			break;
		case XMCallEndReason_EndedByRemoteBusy:
		case XMCallEndReason_EndedByRemoteCongestion:
			reasonString = NSLocalizedString(@"XM_CALL_END_REMOTE_BUSY", @"");
			break;
		case XMCallEndReason_EndedByUnreachable:
			reasonString = NSLocalizedString(@"XM_CALL_END_REMOTE_UNREACHABLE", @"");
			break;
		case XMCallEndReason_EndedByNoEndPoint:
			reasonString = NSLocalizedString(@"XM_CALL_END_NO_ENDPOINT", @"");
			break;
		case XMCallEndReason_EndedByHostOffline:
			reasonString = NSLocalizedString(@"XM_CALL_END_HOST_OFFLINE", @"");
			break;
		case XMCallEndReason_EndedByDurationLimit:
			reasonString = NSLocalizedString(@"XM_CALL_END_DURATION_LIMIT", @"");
			break;
		case XMCallEndReason_EndedByInvalidConferenceID:
			reasonString = NSLocalizedString(@"XM_CALL_END_CONFERENCE_ID", @"");
			break;
		default:
			reasonString = [NSString stringWithFormat:NSLocalizedString(@"XM_UNKNOWN_REASON", @""), callEndReason];
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
			failReasonString = NSLocalizedString(@"XM_GK_REG_FAILED_NOT_FOUND", @"");
			break;
		case XMGatekeeperRegistrationFailReason_RegistrationReject:
			failReasonString = NSLocalizedString(@"XM_GK_REG_FAILED_REJECTED", @"");
			break;
		default:
			failReasonString = NSLocalizedString(@"XM_UNKNOWN_REASON", @"");
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
			statusCodeString = NSLocalizedString(@"XM_UNKNOWN_REASON", @"");
	}
	
	return statusCodeString;
}

NSArray *XMDefaultSTUNServers()
{
	static NSArray *servers = nil;
	
	if(servers == nil)
	{
		NSBundle *bundle = [NSBundle mainBundle];
		NSString *filePath = [bundle pathForResource:XM_STUN_SERVERS_FILE_NAME
											  ofType:XM_STUN_SERVERS_FILE_TYPE];
		
		NSData *data = [NSData dataWithContentsOfFile:filePath];
		
		NSString *errorString;
		servers = (NSArray *)[NSPropertyListSerialization propertyListFromData:data
															  mutabilityOption:NSPropertyListImmutable
																		format:NULL
															  errorDescription:&errorString];
		
		if(servers == nil)
		{
			[NSException raise:XMException_InternalConsistencyFailure format:@"Coulnd't load STUN Servers (%@)", errorString];
			return nil;
		}
		
		[servers retain];
	}
	
	return servers;
}

NSString *XMNATTypeString(XMNATType type)
{
	switch(type) {
		
		case XMNATType_Error:
			return @"<Error>";
		case XMNATType_NoNAT:
			return @"None";
		case XMNATType_ConeNAT:
			return @"Cone NAT";
		case XMNATType_RestrictedNAT:
			return @"Restricted NAT";
		case XMNATType_PortRestrictedNAT:
			return @"Port Restricted NAT";
		case XMNATType_SymmetricNAT:
			return @"Symmetric NAT";
		case XMNATType_SymmetricFirewall:
			return @"SymmetricFirewall";
		case XMNATType_BlockedNAT:
			return @"Blocked NAT";
		case XMNATType_PartialBlockedNAT:
			return @"Partial Blocked NAT";
		case XMNATType_UnknownNAT:
			return @"Unknown NAT";
		default:
			return @"ERROR";
	}
}

@implementation NSString (XMExtensions)

- (BOOL)hasPrefixCaseInsensitive:(NSString *)prefix
{
	unsigned length = [prefix length];
	
	if(length > [self length])
	{
		return NO;
	}
	
	NSRange searchRange = NSMakeRange(0, length);
	
	NSRange prefixRange = [self rangeOfString:prefix
									  options:(NSCaseInsensitiveSearch | NSLiteralSearch | NSAnchoredSearch)
										range:searchRange];
	if(prefixRange.location != NSNotFound)
	{
		return YES;
	}
	
	return NO;
}

@end