/*
 * $Id: XMSIPEndPoint.cpp,v 1.37 2007/09/13 15:02:44 hfriederich Exp $
 *
 * Copyright (c) 2006-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2007 Hannes Friederich. All rights reserved.
 */

#include "XMSIPEndPoint.h"

#include "XMCallbackBridge.h"
#include "XMOpalManager.h"
#include "XMSIPConnection.h"
#include "XMMediaFormats.h"
#include "XMNetworkConfiguration.h"

#include <ptlib/ipsock.h>
#include <ptclib/enum.h>

XMSIPEndPoint::XMSIPEndPoint(OpalManager & manager)
: SIPEndPoint(manager)
{
  isListening = FALSE;
  
  connectionToken = "";
  
  SetInitialBandwidth(UINT_MAX);
  
  SetNATBindingRefreshMethod(EmptyRequest);
  
  releasingConnections.DisallowDeleteObjects();
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

void XMSIPEndPoint::PrepareRegistrationSetup(BOOL proxyChanged)
{
  PWaitAndSignal m(registrationListMutex);
  
  unsigned i;
  unsigned count = activeRegistrations.GetSize();
  
  // marking all registrations as to unregister/remove
  // If a registration is still used, the status will be overridden again
  for(i = 0; i < count; i++)
  {
    XMSIPRegistrationRecord & record = activeRegistrations[i];
    
    if(record.GetStatus() == XMSIPRegistrationRecord::Registered &&
       proxyChanged == FALSE)
    {
      record.SetStatus(XMSIPRegistrationRecord::ToUnregister);
    }
    else
    {
      record.SetStatus(XMSIPRegistrationRecord::ToRemove);
    }
  }
}

void XMSIPEndPoint::UseRegistration(const PString & host,
                                    const PString & username,
                                    const PString & authorizationUsername,
                                    const PString & password,
                                    BOOL proxyChanged)
{
  PWaitAndSignal m(registrationListMutex);
  
  unsigned i;
  unsigned count = activeRegistrations.GetSize();
  
  PString registration;
  
  PINDEX atLocation = username.Find('@');
  if(atLocation != P_MAX_INDEX)
  {
    registration = username;
  }
  else
  {
    registration = username + '@' + host;
  }
  
  if (proxyChanged == FALSE) {
    // searching for a record with the same information
    // if found, marking this record as registered/needs to register.
    // if not, create a new record and add it to the list
    for(i = 0; i < count; i++)
    {
      XMSIPRegistrationRecord & record = activeRegistrations[i];
      
      if(record.GetRegistration() == registration)
      {
        if(record.GetPassword() != password)
        {
          record.SetPassword(password);
          record.SetStatus(XMSIPRegistrationRecord::ToRegister);
        }
        else if(record.GetStatus() == XMSIPRegistrationRecord::ToUnregister)
        {
          record.SetStatus(XMSIPRegistrationRecord::Registered);
        }
        else
        {
          record.SetStatus(XMSIPRegistrationRecord::ToRegister);
        }
        
        return;
      }
    }
  }
  
  XMSIPRegistrationRecord *record = new XMSIPRegistrationRecord(registration, authorizationUsername, password);
  record->SetStatus(XMSIPRegistrationRecord::ToRegister);
  activeRegistrations.Append(record);
}

void XMSIPEndPoint::FinishRegistrationSetup(BOOL proxyChanged)
{
  if (proxyChanged) {
    // Unregister all registrations and re-register with the new proxy information
    for (PSafePtr<SIPHandler> handler(activeSIPHandlers, PSafeReadWrite); handler != NULL; ++handler) {
      Unregister(handler->GetRemotePartyAddress());
    }
  }
  
  PWaitAndSignal m(registrationListMutex);
  
  int i;
  unsigned count = activeRegistrations.GetSize();
  
  for(i = (count-1); i >= 0; i--)
  {
    XMSIPRegistrationRecord & record = activeRegistrations[i];
    
    if(record.GetStatus() == XMSIPRegistrationRecord::ToUnregister)
    {
      Unregister(record.GetRegistration());
      _XMHandleSIPUnregistration(record.GetRegistration());
      activeRegistrations.RemoveAt(i);
    }
    else if(record.GetStatus() == XMSIPRegistrationRecord::ToRemove)
    {
      activeRegistrations.RemoveAt(i);
    }
    else if(record.GetStatus() == XMSIPRegistrationRecord::ToRegister)
    {
      BOOL result = Register(GetRegistrarTimeToLive().GetSeconds(),
                             record.GetRegistration(),
                             record.GetAuthorizationUsername(),
                             record.GetPassword(),
                             PString::Empty(),
                             PMaxTimeInterval,
                             PMaxTimeInterval,
                             proxyChanged);
      
      if(result == FALSE && (record.GetStatus() != XMSIPRegistrationRecord::Failed))
      {
        record.SetStatus(XMSIPRegistrationRecord::Failed);
        _XMHandleSIPRegistrationFailure(record.GetRegistration(), XMSIPStatusCode_NoNetworkInterfaces);
      }
    }
  }
  
  BOOL completed = TRUE;
  count = activeRegistrations.GetSize();
  for(i = 0; i < count; i++)
  {
    XMSIPRegistrationRecord & record = activeRegistrations[i];
    
    if(record.GetStatus() == XMSIPRegistrationRecord::ToRegister)
    {
      completed = FALSE;
      break;
    }
  }
  
  if(completed == TRUE)
  {
    _XMHandleSIPRegistrationSetupCompleted();
  }
}

void XMSIPEndPoint::HandleNetworkStatusChange()
{
}

BOOL XMSIPEndPoint::UseProxy(const PString & hostname,
							 const PString & username,
							 const PString & password)
{
  SIPURL oldProxy = GetProxy();
  
  PString adjustedUsername;
  
  PINDEX location = username.Find('@');
  if(location != P_MAX_INDEX)
  {
    adjustedUsername = username.Left(location);
  }
  else
  {
    adjustedUsername = username;
  }
  
  SetProxy(hostname, username, password);
  
  SIPURL newProxy = GetProxy();
  
  if (newProxy != oldProxy) {
    return TRUE;
  }
  return FALSE;
}

void XMSIPEndPoint::GetCallStatistics(XMCallStatisticsRecord *callStatistics)
{
  PSafePtr<SIPConnection> connection = GetSIPConnectionWithLock(connectionToken, PSafeReadOnly);
  
  if(connection != NULL)
  {
    // not supported at the moment
    callStatistics->roundTripDelay = UINT_MAX;
    
    XMOpalManager::ExtractCallStatistics(*connection, callStatistics);
  }
}

void XMSIPEndPoint::OnRegistrationFailed(const PString & aor,
										 SIP_PDU::StatusCodes reason,
										 BOOL wasRegistering)
{
  if(wasRegistering == FALSE)
  {
    return;
  }
  
  PWaitAndSignal m(registrationListMutex);
  
  BOOL setupIsComplete = TRUE;
  
  unsigned i;
  unsigned count = activeRegistrations.GetSize();
  
  for(i = 0; i < count; i++)
  {
    XMSIPRegistrationRecord & record = activeRegistrations[i];
    
    if(aor == record.GetRegistration())
    {
      if(record.GetStatus() != XMSIPRegistrationRecord::ToRegister)
      {
        return;
      }
      record.SetStatus(XMSIPRegistrationRecord::Failed);
      
      _XMHandleSIPRegistrationFailure(record.GetRegistration(), (XMSIPStatusCode)reason);
    }
    
    unsigned status = record.GetStatus();
    
    if(status == XMSIPRegistrationRecord::ToRegister)
    {
      setupIsComplete = FALSE;
    }
  }
  
  if(setupIsComplete == TRUE)
  {
    _XMHandleSIPRegistrationSetupCompleted();
    return;
  }
}

void XMSIPEndPoint::OnRegistered(const PString & aor,
								 BOOL wasRegistering)
{
  if(wasRegistering == FALSE)
  {
    return;
  }
  
  PWaitAndSignal m(registrationListMutex);
  
  
  BOOL setupIsComplete = TRUE;
  
  unsigned i;
  unsigned count = activeRegistrations.GetSize();
  
  for(i = 0; i < count; i++)
  {
    XMSIPRegistrationRecord & record = activeRegistrations[i];
    
    if(aor == record.GetRegistration())
    {
      unsigned status = record.GetStatus();
      
      if(status == XMSIPRegistrationRecord::ToRegister)
      {
        _XMHandleSIPRegistration(record.GetRegistration());
      }
      
      record.SetStatus(XMSIPRegistrationRecord::Registered);
      
      if(status != XMSIPRegistrationRecord::ToRegister)
      {
        return;
      }
    }
    
    if(record.GetStatus() == XMSIPRegistrationRecord::ToRegister)
    {
      setupIsComplete = FALSE;
    }
  }
  
  if(setupIsComplete == TRUE)
  {
    _XMHandleSIPRegistrationSetupCompleted();
  }
}

void XMSIPEndPoint::OnEstablished(OpalConnection & connection)
{
  XMOpalManager *manager = (XMOpalManager *)(&GetManager());
  
  connectionToken = connection.GetToken();
  
  SIPURL remoteURL = SIPURL(connection.GetRemotePartyAddress());
  const PString & username = remoteURL.GetUserName();
  const PString & host = remoteURL.GetHostName();
  PString remoteAddress;
  
  if (username != "") {
    remoteAddress = username + "@" + host;
  } else {
    remoteAddress = host;
  }
  
  manager->SetCallInformation(connectionToken,
                              connection.GetRemotePartyName(),
                              "",
                              remoteAddress,
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
												SIP_PDU * invite,
												unsigned int options,
                                                OpalConnection::StringOptions * stringOptions)
{
  return new XMSIPConnection(call, *this, token, destination, transport, options, stringOptions);
}

SIPURL XMSIPEndPoint::GetDefaultRegisteredPartyName()
{
  // If using a proxy, use the proxy user name and domain name
  SIPURL proxyURL = GetProxy();
  if(!proxyURL.IsEmpty())
  {
    return proxyURL;
  }
  
  // Get the superclass's implementation
  SIPURL url = SIPEndPoint::GetDefaultRegisteredPartyName();
  
  // If the superclass returns IP "0.0.0.0", make the
  // OpalTransportAddress empty. This in turn indicates
  // to the callers that they should use the current
  // transport's local address
  OpalTransportAddress address = url.GetHostAddress();
  PIPSocket::Address ip;
  if(!address.GetIpAddress(ip))
  {
    return url;
  }
  if(ip.IsAny())
  {
    url = SIPURL(GetDefaultLocalPartyName(), OpalTransportAddress());
  }
  return url;
}

void XMSIPEndPoint::CleanUp()
{
  // Clean up all connections
{
  PWaitAndSignal m(releasingConnectionsMutex);
  for (PINDEX i = 0; i < releasingConnections.GetSize(); i++)
  {
    releasingConnections[i].CleanUp();
  }
}
}

void XMSIPEndPoint::AddReleasingConnection(XMSIPConnection * connection)
{
  PWaitAndSignal m(releasingConnectionsMutex);
  
  releasingConnections.Append(connection);
}

void XMSIPEndPoint::RemoveReleasingConnection(XMSIPConnection * connection)
{
  PWaitAndSignal m(releasingConnectionsMutex);
  
  releasingConnections.Remove(connection);
}

#pragma mark -
#pragma mark XMSIPRegistrationRecord methods

XMSIPRegistrationRecord::XMSIPRegistrationRecord(const PString & _registration,
                                                 const PString & _authorizationUsername,
                                                 const PString & _password)
{
  registration = _registration;
  authorizationUsername = _authorizationUsername;
  password = _password;
}

XMSIPRegistrationRecord::~XMSIPRegistrationRecord()
{
}

