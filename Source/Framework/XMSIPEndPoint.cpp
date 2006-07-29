/*
 * $Id: XMSIPEndPoint.cpp,v 1.11 2006/07/29 08:54:36 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#include "XMSIPEndPoint.h"

#include "XMCallbackBridge.h"
#include "XMOpalManager.h"
#include "XMSIPConnection.h"
#include "XMMediaFormats.h"

#define XM_SIP_REGISTRAR_STATUS_TO_REGISTER 0
#define XM_SIP_REGISTRAR_STATUS_REGISTERED 1
#define XM_SIP_REGISTRAR_STATUS_FAILED 2
#define XM_SIP_REGISTRAR_STATUS_TO_UNREGISTER 3
#define XM_SIP_REGISTRAR_STATUS_TO_REMOVE 4

XMSIPEndPoint::XMSIPEndPoint(OpalManager & manager)
: SIPEndPoint(manager)
{
	isListening = FALSE;
	
	connectionToken = "";
	
	SetInitialBandwidth(UINT_MAX);
	
	SetUserAgent("XMeeting/0.3.1");
}

XMSIPEndPoint::~XMSIPEndPoint()
{
}

BOOL XMSIPEndPoint::EnableListeners(BOOL enable)
{
	BOOL result = TRUE;
	
	if(enable == TRUE)
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

BOOL XMSIPEndPoint::IsListening()
{
	return isListening;
}

void XMSIPEndPoint::PrepareRegistrarSetup()
{
	PWaitAndSignal m(registrarListMutex);
	
	unsigned i;
	unsigned count = activeRegistrars.GetSize();
	
	// marking all registrars as to unregister/remove
	// If a registrar is still used, the status will be overridden again
	for(i = 0; i < count; i++)
	{
		XMSIPRegistrarRecord & record = activeRegistrars[i];
		
		if(record.GetStatus() == XM_SIP_REGISTRAR_STATUS_REGISTERED)
		{
			record.SetStatus(XM_SIP_REGISTRAR_STATUS_TO_UNREGISTER);
		}
		else
		{
			record.SetStatus(XM_SIP_REGISTRAR_STATUS_TO_REMOVE);
		}
	}
}

void XMSIPEndPoint::UseRegistrar(const PString & host,
								 const PString & username,
								 const PString & authorizationUsername,
								 const PString & password)
{
	PWaitAndSignal m(registrarListMutex);
	
	unsigned i;
	unsigned count = activeRegistrars.GetSize();
	
	PString adjustedHost;
	PString adjustedUsername;
	
	PINDEX atLocation = username.Find('@');
	if(atLocation != P_MAX_INDEX)
	{
		adjustedUsername = username.Left(atLocation);
		adjustedHost = username.Mid(atLocation+1);
	}
	else
	{
		adjustedUsername = username;
		adjustedHost = host;
	}
	
	// searching for a record with the same information
	// if found, marking this record as registered/needs to register.
	// if not, create a new record and add it to the list
	for(i = 0; i < count; i++)
	{
		XMSIPRegistrarRecord & record = activeRegistrars[i];
		
		if(record.GetHost() == adjustedHost &&
		   record.GetUsername() == adjustedUsername)
		{
			if(record.GetPassword() != password)
			{
				record.SetPassword(password);
				record.SetStatus(XM_SIP_REGISTRAR_STATUS_TO_REGISTER);
			}
			else if(record.GetStatus() == XM_SIP_REGISTRAR_STATUS_TO_UNREGISTER)
			{
				record.SetStatus(XM_SIP_REGISTRAR_STATUS_REGISTERED);
			}
			else
			{
				record.SetStatus(XM_SIP_REGISTRAR_STATUS_TO_REGISTER);
			}
			
			return;
		}
	}
	
	XMSIPRegistrarRecord *record = new XMSIPRegistrarRecord(host, username, authorizationUsername, password);
	record->SetStatus(XM_SIP_REGISTRAR_STATUS_TO_REGISTER);
	activeRegistrars.Append(record);
}

void XMSIPEndPoint::FinishRegistrarSetup()
{
	PWaitAndSignal m(registrarListMutex);
	
	unsigned i;
	unsigned count = activeRegistrars.GetSize();
	
	for(i = count; i > 0; i--)
	{
		XMSIPRegistrarRecord & record = activeRegistrars[i-1];
		
		if(record.GetStatus() == XM_SIP_REGISTRAR_STATUS_TO_UNREGISTER)
		{
			Unregister(record.GetHost(), record.GetUsername());
			
			_XMHandleSIPUnregistration(record.GetHost(), record.GetUsername());
			
			activeRegistrars.RemoveAt(i-1);
		}
		else if(record.GetStatus() == XM_SIP_REGISTRAR_STATUS_TO_REMOVE)
		{
			activeRegistrars.RemoveAt(i-1);
		}
		else if(record.GetStatus() == XM_SIP_REGISTRAR_STATUS_TO_REGISTER)
		{
			BOOL result = Register(record.GetHost(), record.GetUsername(), record.GetAuthorizationUsername(), record.GetPassword());
			if(result == FALSE && (record.GetStatus() != XM_SIP_REGISTRAR_STATUS_FAILED))
			{
				record.SetStatus(XM_SIP_REGISTRAR_STATUS_FAILED);
				
				_XMHandleSIPRegistrationFailure(record.GetHost(), record.GetUsername(), XMSIPStatusCode_UnknownFailure);
			}
		}
	}
	
	BOOL completed = TRUE;
	count = activeRegistrars.GetSize();
	for(i = 0; i < count; i++)
	{
		XMSIPRegistrarRecord & record = activeRegistrars[i];
		
		if(record.GetStatus() == XM_SIP_REGISTRAR_STATUS_TO_REGISTER)
		{
			completed = FALSE;
			break;
		}
	}
	
	if(completed == TRUE)
	{
		_XMHandleRegistrarSetupCompleted();
	}
}

void XMSIPEndPoint::GetCallStatistics(XMCallStatisticsRecord *callStatistics)
{
	PSafePtr<SIPConnection> connection = GetSIPConnectionWithLock(connectionToken, PSafeReadOnly);
	
	if(connection != NULL)
	{
		// not supported at the moment
		callStatistics->roundTripDelay = UINT_MAX;
		
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

void XMSIPEndPoint::OnRegistrationFailed(const PString & host,
										 const PString & username,
										 SIP_PDU::StatusCodes reason,
										 BOOL wasRegistering)
{
	PWaitAndSignal m(registrarListMutex);
	
	if(wasRegistering == FALSE)
	{
		return;
	}
	
	BOOL setupIsComplete = TRUE;
	
	unsigned i;
	unsigned count = activeRegistrars.GetSize();
	
	for(i = 0; i < count; i++)
	{
		XMSIPRegistrarRecord & record = activeRegistrars[i];
		
		PString theHost = record.GetHost();
		PString theUsername = record.GetUsername();
		
		PINDEX atLocation = theUsername.Find('@');
		if(atLocation != P_MAX_INDEX)
		{
			theHost = theUsername.Mid(atLocation+1);
			theUsername = theUsername.Left(atLocation);
		}
		
		if(theHost == host &&
		  theUsername == username)
		{
			if(record.GetStatus() != XM_SIP_REGISTRAR_STATUS_TO_REGISTER)
			{
				return;
			}
			record.SetStatus(XM_SIP_REGISTRAR_STATUS_FAILED);
			
			_XMHandleSIPRegistrationFailure(record.GetHost(), record.GetUsername(), (XMSIPStatusCode)reason);
		}
		
		unsigned status = record.GetStatus();
		
		if(status == XM_SIP_REGISTRAR_STATUS_TO_REGISTER)
		{
			setupIsComplete = FALSE;
		}
	}
	
	if(setupIsComplete == TRUE)
	{
		_XMHandleRegistrarSetupCompleted();
		return;
	}
}

void XMSIPEndPoint::OnRegistered(const PString & host,
								 const PString & username,
								 BOOL wasRegistering)
{
	PWaitAndSignal m(registrarListMutex);
	
	if(wasRegistering == FALSE)
	{
		return;
	}
	
	BOOL setupIsComplete = TRUE;
	
	unsigned i;
	unsigned count = activeRegistrars.GetSize();
	
	for(i = 0; i < count; i++)
	{
		XMSIPRegistrarRecord & record = activeRegistrars[i];
		
		// if the user entered username in the form username@registrar.net
		// both username and registrar.net will be used as username / host
		// respectively. This circumstance is taken into account here
		PString theHost = record.GetHost();
		PString theUsername = record.GetUsername();
		
		PINDEX atLocation = theUsername.Find('@');
		if(atLocation != P_MAX_INDEX)
		{
			theHost = theUsername.Mid(atLocation+1);
			theUsername = theUsername.Left(atLocation);
		}
		
		if(theHost == host &&
		   theUsername == username)
		{
			unsigned status = record.GetStatus();
			
			if(status == XM_SIP_REGISTRAR_STATUS_TO_REGISTER)
			{
				_XMHandleSIPRegistration(record.GetHost(), record.GetUsername());
			}
			
			record.SetStatus(XM_SIP_REGISTRAR_STATUS_REGISTERED);
			
			if(status != XM_SIP_REGISTRAR_STATUS_TO_REGISTER)
			{
				return;
			}
		}
		
		if(record.GetStatus() == XM_SIP_REGISTRAR_STATUS_TO_REGISTER)
		{
			setupIsComplete = FALSE;
		}
	}
	
	if(setupIsComplete == TRUE)
	{
		_XMHandleRegistrarSetupCompleted();
	}
}

void XMSIPEndPoint::OnEstablished(OpalConnection & connection)
{
	XMOpalManager *manager = (XMOpalManager *)(&GetManager());
	
	connectionToken = connection.GetToken();
	
	manager->SetCallInformation(connectionToken,
								connection.GetRemotePartyName(),
								connection.GetRemotePartyNumber(),
								connection.GetRemotePartyAddress(),
								connection.GetRemoteApplication(),
								XMCallProtocol_SIP);
	
	SIPEndPoint::OnEstablished(connection);
}

void XMSIPEndPoint::OnReleased(OpalConnection & connection)
{
	if(connection.GetToken() == connectionToken)
	{
		XMOpalManager *manager = (XMOpalManager *)(&GetManager());
		PString empty = "";
	
		manager->SetCallInformation(connectionToken,
									empty,
									empty,
									empty,
									empty,
									XMCallProtocol_SIP);
	
		connectionToken = "";
	}
	
	SIPEndPoint::OnReleased(connection);
}

SIPConnection * XMSIPEndPoint::CreateConnection(OpalCall & call,
												const PString & token,
												void * userData,
												const SIPURL & destination,
												OpalTransport * transport,
												SIP_PDU * invite)
{
	return new XMSIPConnection(call, *this, token, destination, transport);
}

#pragma mark -
#pragma mark XMSIPRegistrarRecord methods

XMSIPRegistrarRecord::XMSIPRegistrarRecord(const PString & theHost,
										   const PString & theUsername,
										   const PString & theAuthorizationUsername,
										   const PString & thePassword)
{
	host = theHost;
	username = theUsername;
	authorizationUsername = theAuthorizationUsername;
	password = thePassword;
}

XMSIPRegistrarRecord::~XMSIPRegistrarRecord()
{
}

const PString & XMSIPRegistrarRecord::GetHost() const
{
	return host;
}

const PString & XMSIPRegistrarRecord::GetUsername() const
{
	return username;
}

const PString & XMSIPRegistrarRecord::GetAuthorizationUsername() const
{
	return authorizationUsername;
}

const PString & XMSIPRegistrarRecord::GetPassword() const
{
	return password;
}

void XMSIPRegistrarRecord::SetPassword(const PString & thePassword)
{
	password = thePassword;
}

unsigned XMSIPRegistrarRecord::GetStatus() const
{
	return status;
}

void XMSIPRegistrarRecord::SetStatus(unsigned theStatus)
{
	status = theStatus;
}
		