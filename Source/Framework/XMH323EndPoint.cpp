/*
 * $Id: XMH323EndPoint.cpp,v 1.8 2005/10/17 12:57:53 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#include <ptclib/random.h>
#include <opal/call.h>
#include <h323/h323pdu.h>
#include <h323/gkclient.h>
#include <ptclib/url.h>
#include <ptclib/pils.h>

#include "XMCallbackBridge.h"
#include "XMH323EndPoint.h"

#pragma mark Init & Deallocation

XMH323EndPoint::XMH323EndPoint(OpalManager & manager)
: H323EndPoint(manager)
{
	isListening = FALSE;
	
	connectionToken = "";
	remoteName = "";
	remoteNumber = "";
	remoteAddress = "";
	remoteApplication = "";
}

XMH323EndPoint::~XMH323EndPoint()
{
}

#pragma mark Endpoint Setup

BOOL XMH323EndPoint::EnableListeners(BOOL flag)
{
	BOOL result = TRUE;
	
	if(flag == TRUE)
	{
		if(isListening == FALSE)
		{
			result = StartListeners(GetDefaultListeners());
			if(result == TRUE)
			{
				isListening = TRUE;
			}
		}
	}
	else
	{
		if(isListening == TRUE)
		{
			RemoveListener(NULL);
			isListening = FALSE;
		}
	}
	
	return result;
}

BOOL XMH323EndPoint::IsListening()
{
	return isListening;
}

XMGatekeeperRegistrationFailReason XMH323EndPoint::SetGatekeeper(const PString & address,
																 const PString & identifier,
																 const PString & username,
																 const PString & phoneNumber)
{	
	// By setting the user name , we clear all previously used aliases
	SetLocalUserName(GetManager().GetDefaultUserName());
	
	if(identifier != NULL || address != NULL)
	{
		if(username != NULL)
		{
			AddAliasName(username);
		}
		if(phoneNumber != NULL)
		{
			AddAliasName(phoneNumber);
		}
		
		// if didRegisterAtGatekeeper is yes after the
		// call to UseGatekeeper, we have a new registration
		// and notify the XMeeting framework
		BOOL wasRegisteredAtGatekeeper = IsRegisteredWithGatekeeper();
		didRegisterAtGatekeeper = FALSE;
		gatekeeperRegistrationFailReason = XMGatekeeperRegistrationFailReason_NoFailure;
		
		BOOL result = UseGatekeeper(address, identifier);
		
		if(result == TRUE && didRegisterAtGatekeeper == TRUE)
		{
			if(wasRegisteredAtGatekeeper == TRUE)
			{
				// There was a registration previously, thus we have unregistered
				// from this previous gatekeeper
				_XMHandleGatekeeperUnregistration();
			}
			
			PString gatekeeperName = GetGatekeeper()->GetName();
			_XMHandleGatekeeperRegistration(gatekeeperName);
		}
		else if (result == FALSE)
		{
			if(wasRegisteredAtGatekeeper == TRUE)
			{
				// same as above
				_XMHandleGatekeeperUnregistration();
			}
			
			if(gatekeeperRegistrationFailReason == XMGatekeeperRegistrationFailReason_NoFailure)
			{
				gatekeeperRegistrationFailReason = XMGatekeeperRegistrationFailReason_GatekeeperNotFound;
			}
		}
	}
	else
	{
		BOOL doesUnregister = FALSE;
		
		if(GetGatekeeper() != NULL)
		{
			doesUnregister = TRUE;
		}
		
		RemoveGatekeeper();
		
		// if we unregistered, we have to inform the obj-C world
		if(doesUnregister == TRUE)
		{
			_XMHandleGatekeeperUnregistration();
		}
		
		gatekeeperRegistrationFailReason = XMGatekeeperRegistrationFailReason_NoFailure;
	}
	
	return gatekeeperRegistrationFailReason;
}

void XMH323EndPoint::CheckGatekeeperRegistration()
{
	if(IsRegisteredWithGatekeeper() == FALSE)
	{
		_XMHandleGatekeeperUnregistration();
	}
}

#pragma mark Getting call information

void XMH323EndPoint::GetCallInformation(PString & theRemoteName,
										PString & theRemoteNumber,
										PString & theRemoteAddress,
										PString & theRemoteApplication)
{
	theRemoteName = remoteName;
	theRemoteNumber = remoteNumber;
	theRemoteAddress = remoteAddress;
	theRemoteApplication = remoteApplication;
}
										
void XMH323EndPoint::GetCallStatistics(XMCallStatisticsRecord *callStatistics)
{
	PSafePtr<H323Connection> connection = FindConnectionWithLock(connectionToken, PSafeReadOnly);
	
	if(connection != NULL)
	{
		unsigned roundTripDelay = connection->GetRoundTripDelay().GetMilliSeconds();
		callStatistics->roundTripDelay = roundTripDelay;
		
		//fetching the audio statistics
		RTP_Session *session = connection->GetSession(OpalMediaFormat::DefaultAudioSessionID);
		
		if(session != NULL)
		{
			callStatistics->audioPacketsSent = session->GetPacketsSent();
			callStatistics->audioBytesSent = session->GetOctetsSent();
			callStatistics->audioMinimumSendTime = session->GetMinimumSendTime();
			callStatistics->audioAverageSendTime = session->GetAverageSendTime();
			callStatistics->audioMaximumSendTime = session->GetMaximumSendTime();
			
			callStatistics->audioPacketsReceived = session->GetPacketsReceived();
			callStatistics->audioBytesReceived = session->GetOctetsReceived();
			callStatistics->audioMinimumReceiveTime = session->GetMinimumReceiveTime();
			callStatistics->audioAverageReceiveTime = session->GetAverageReceiveTime();
			callStatistics->audioMaximumReceiveTime = session->GetMaximumReceiveTime();
			
			callStatistics->audioPacketsLost = session->GetPacketsLost();
			callStatistics->audioPacketsOutOfOrder = session->GetPacketsOutOfOrder();
			callStatistics->audioPacketsTooLate = session->GetPacketsTooLate();
		}
		
		//fetching the audio statistics
		session = connection->GetSession(OpalMediaFormat::DefaultVideoSessionID);
		
		if(session != NULL)
		{
			callStatistics->videoPacketsSent = session->GetPacketsSent();
			callStatistics->videoBytesSent = session->GetOctetsSent();
			callStatistics->videoMinimumSendTime = session->GetMinimumSendTime();
			callStatistics->videoAverageSendTime = session->GetAverageSendTime();
			callStatistics->videoMaximumSendTime = session->GetMaximumSendTime();
			
			callStatistics->videoPacketsReceived = session->GetPacketsReceived();
			callStatistics->videoBytesReceived = session->GetOctetsReceived();
			callStatistics->videoMinimumReceiveTime = session->GetMinimumReceiveTime();
			callStatistics->videoAverageReceiveTime = session->GetAverageReceiveTime();
			callStatistics->videoMaximumReceiveTime = session->GetMaximumReceiveTime();
			
			callStatistics->videoPacketsLost = session->GetPacketsLost();
			callStatistics->videoPacketsOutOfOrder = session->GetPacketsOutOfOrder();
			callStatistics->videoPacketsTooLate = session->GetPacketsTooLate();
		}
	}
}

#pragma mark Overriding Callbacks

void XMH323EndPoint::OnRegistrationConfirm()
{
	didRegisterAtGatekeeper = TRUE;
	H323EndPoint::OnRegistrationConfirm();
}

void XMH323EndPoint::OnRegistrationReject()
{
	gatekeeperRegistrationFailReason = XMGatekeeperRegistrationFailReason_RegistrationReject;
	H323EndPoint::OnRegistrationReject();
}

void XMH323EndPoint::OnEstablished(OpalConnection & connection)
{
	connectionToken = connection.GetToken();
	remoteName = connection.GetRemotePartyName();
	remoteNumber = connection.GetRemotePartyNumber();
	remoteAddress = connection.GetRemotePartyAddress();
	remoteApplication = connection.GetRemoteApplication();
	
	H323EndPoint::OnEstablished(connection);
}

void XMH323EndPoint::OnReleased(OpalConnection & connection)
{	
	remoteName = "";
	remoteNumber = "";
	remoteAddress = "";
	remoteApplication = "";
	
	H323EndPoint::OnReleased(connection);
	
	/*
	unsigned callID = connection.GetCall().GetToken().AsUnsigned();
	XMCallEndReason endReason = (XMCallEndReason)connection.GetCall().GetCallEndReason();
	//_XMHandleCallCleared(callID, endReason);
	 */
}