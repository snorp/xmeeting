/*
 * $Id: XMH323EndPoint.cpp,v 1.20 2006/06/06 16:38:48 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#include "XMH323EndPoint.h"

#include <ptclib/random.h>
#include <opal/call.h>
#include <h323/h323pdu.h>
#include <h323/gkclient.h>
#include <ptclib/url.h>
#include <ptclib/pils.h>

#include <h224/q922.h>

//#include <h323/h46018.h>

#include "XMCallbackBridge.h"
#include "XMOpalManager.h"
#include "XMH323Connection.h"

#include <opal/transcoders.h>

#pragma mark Init & Deallocation

//static H460PluginServiceDescriptor<H460_FeatureStd18> H460_FeatureStd18_descriptor;

XMH323EndPoint::XMH323EndPoint(OpalManager & manager)
: H323EndPoint(manager)
{
	//adjusting some time intervals
	gatekeeperRequestTimeout = PTimeInterval(0, 2);
	
	isListening = FALSE;
	
	connectionToken = "";
	
	SetInitialBandwidth(UINT_MAX);
	
	SetIsH224Enabled(TRUE);
	
	// Workaround to register the H.460 plugins
	/*PString serviceName = "H460_FeatureStd18";
	PString serviceType = "H460_Feature";
	PPluginManager::GetPluginManager().RegisterService(serviceName, serviceType, &H460_FeatureStd18_descriptor);*/
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
																 const PString & username,
																 const PString & phoneNumber,
																 const PString & password)
{
	// By setting the user name, we clear all previously used aliases
	SetLocalUserName(GetManager().GetDefaultUserName());
	
	if(username != NULL)
	{
		AddAliasName(username);
	}
	if(phoneNumber != NULL)
	{
		AddAliasName(phoneNumber);
	}
	
	if(address != NULL)
	{
		// If we are registered at a gatekeeper, we determine first whether we
		// have to unregister from the existing gatekeeper or not.
		// This is the case when either the gatekeeper address/identifier changes
		// or the username/password combination does change.
		if(gatekeeper != NULL)
		{
			BOOL needsGatekeeperRegistrationChange = FALSE;
		
			// check for different address
			if(gatekeeper->GetTransport().GetRemoteAddress().IsEquivalent(address) == FALSE)
			{
				needsGatekeeperRegistrationChange = TRUE;
			}
			
			// changes in username/phonenumber will be handled in the next info request response
			// If the password changed, however, we have to rerun the registration process
			if(needsGatekeeperRegistrationChange == FALSE && (password != NULL))
			{
				if(gatekeeperUsername != username ||
				   gatekeeperPassword != password)
				{
					needsGatekeeperRegistrationChange = TRUE;
				}
			}
			
			if(needsGatekeeperRegistrationChange == TRUE)
			{
				RemoveGatekeeper();
				_XMHandleGatekeeperUnregistration();
			}
			else
			{
				// no need to change the existing configuration
				// changes in username/phonenumber will be handled in the
				// next info request
				gatekeeperRegistrationFailReason = XMGatekeeperRegistrationFailReason_NoFailure;
				return gatekeeperRegistrationFailReason;
			}
		}
		
		// setting the password if needed
		if(password != NULL)
		{
			SetGatekeeperPassword(password, username);
		}
		
		didRegisterAtGatekeeper = FALSE;
		gatekeeperRegistrationFailReason = XMGatekeeperRegistrationFailReason_NoFailure;
		
		BOOL result = UseGatekeeper(address);
		
		if(result == TRUE && didRegisterAtGatekeeper == TRUE)
		{
			PString gatekeeperName = GetGatekeeper()->GetName();
			_XMHandleGatekeeperRegistration(gatekeeperName);
		}
		else if(result == FALSE)
		{
			if(gatekeeperRegistrationFailReason == XMGatekeeperRegistrationFailReason_NoFailure)
			{
				gatekeeperRegistrationFailReason = XMGatekeeperRegistrationFailReason_GatekeeperNotFound;
			}
		}
	}
	else
	{
		// We don't use any gatekeeper
		if(GetGatekeeper() != NULL)
		{
			RemoveGatekeeper();
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

#pragma mark Getting call statistics
										
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
	XMOpalManager * manager = (XMOpalManager *)(&GetManager());
	
	connectionToken = connection.GetToken();
	
	manager->SetCallInformation(connectionToken,
								connection.GetRemotePartyName(),
								connection.GetRemotePartyNumber(),
								connection.GetRemotePartyAddress(),
								connection.GetRemoteApplication(),
								XMCallProtocol_H323);
	
	H323EndPoint::OnEstablished(connection);
}

void XMH323EndPoint::OnReleased(OpalConnection & connection)
{
	if(connection.GetToken() == connectionToken)
	{
		XMOpalManager * manager = (XMOpalManager *)(&GetManager());
		PString empty = "";

		manager->SetCallInformation(connectionToken,
									empty,
									empty,
									empty,
									empty,
									XMCallProtocol_H323);
	
		connectionToken = "";
	}
	
	H323EndPoint::OnReleased(connection);
}

H323Connection * XMH323EndPoint::CreateConnection(OpalCall & call,
												  const PString & token,
												  void * userData,
												  OpalTransport & transport,
												  const PString & alias,
												  const H323TransportAddress & address,
												  H323SignalPDU * setupPDU)
{
	return new XMH323Connection(call, *this, token, alias, address);
}

#pragma mark -
#pragma mark H.460 support

BOOL XMH323EndPoint::OnSendFeatureSet(unsigned id, H225_FeatureSet & message)
{
	return features.SendFeature(id, message);
}

void XMH323EndPoint::OnReceiveFeatureSet(unsigned id, const H225_FeatureSet & message)
{
	features.ReceiveFeature(id, message);
}
