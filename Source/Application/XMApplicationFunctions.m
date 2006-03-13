/*
 * $Id: XMApplicationFunctions.m,v 1.2 2006/03/13 23:46:21 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMApplicationFunctions.h"

NSString *byteString(unsigned bytes)
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

NSString *timeString(unsigned time)
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

NSString *dateFormatString()
{
	return @"%Y-%m-%d %H:%M:%S";
}

NSString *callEndReasonString(XMCallEndReason callEndReason)
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

NSString *gatekeeperRegistrationFailReasonString(XMGatekeeperRegistrationFailReason failReason)
{
	NSString *failReasonString;
	
	switch(failReason)
	{
		/*case XMGatekeeperRegistrationFailReason_NoGatekeeperSpecified:
			failReasonString = @"No gatekeeper specified";
			break;*/
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