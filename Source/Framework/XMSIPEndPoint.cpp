/*
 * $Id: XMSIPEndPoint.cpp,v 1.40 2008/09/16 23:16:05 hfriederich Exp $
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
: SIPEndPoint(manager),
  isListening(false),
  connectionToken("")
{
  // Don't use OPAL's bandwidth management system as this is not flexible enough
  // for our purposes
  SetInitialBandwidth(UINT_MAX);
  
  SetNATBindingRefreshMethod(EmptyRequest);
  
  releasingConnections.DisallowDeleteObjects();
}

XMSIPEndPoint::~XMSIPEndPoint()
{
}

bool XMSIPEndPoint::EnableListeners(bool enable)
{
  bool result = true;
  
  if (enable == true) {
    if (isListening == false) {
      result = StartListeners(GetDefaultListeners());
      if (result == true) {
        isListening = true;
      }
    }
  } else {
    if (isListening == true) {
      ShutDown();
      isListening = false;
    }
  }
  
  return result;
}

bool XMSIPEndPoint::UseProxy(const PString & hostname,
                             const PString & username,
                             const PString & password)
{
  SIPURL oldProxy = GetProxy();
  
  PString adjustedUsername;
  
  PINDEX location = username.Find('@');
  if (location != P_MAX_INDEX) {
    adjustedUsername = username.Left(location);
  } else {
    adjustedUsername = username;
  }
  
  SetProxy(hostname, adjustedUsername, password);
  
  SIPURL newProxy = GetProxy();
  
  if (newProxy != oldProxy) {
    return true;
  }
  return false;
}

void XMSIPEndPoint::PrepareRegistrationSetup(bool proxyChanged)
{
  PWaitAndSignal m(registrationListMutex);
  
  // marking all registrations as to unregister/remove
  // If a registration is still used, the status will be overridden again
  unsigned count = activeRegistrations.GetSize();
  for (unsigned i = 0; i < count; i++) {
    XMSIPRegistrationRecord & record = activeRegistrations[i];
    
    if (record.GetStatus() == XMSIPRegistrationRecord::Registered && proxyChanged == false) {
      record.SetStatus(XMSIPRegistrationRecord::ToUnregister);
    } else {
      // if not registered, remove it
      // if the proxy changed, we need to unregister all existing registrations and do a clean re-register
      record.SetStatus(XMSIPRegistrationRecord::ToRemove);
    }
  }
}

void XMSIPEndPoint::UseRegistration(const PString & host,
                                    const PString & username,
                                    const PString & authorizationUsername,
                                    const PString & password,
                                    bool proxyChanged)
{
  PWaitAndSignal m(registrationListMutex);
  
  PString addressOfRecord = GetAddressOfRecord(host, username);
  
  // if the proxy changed, all registrations need to be re-done using the new proxy information
  if (proxyChanged == false) {
    // searching for a record with the same information
    // if found, marking this record as registered/needs to register.
    // if not, create a new record and add it to the list
    unsigned count = activeRegistrations.GetSize();
    for (unsigned i = 0; i < count; i++) {
      XMSIPRegistrationRecord & record = activeRegistrations[i];
      
      if (record.GetAddressOfRecord() == addressOfRecord) {
        if (record.GetAuthorizationUsername() != authorizationUsername || record.GetPassword() != password) {
          // update authName/password, needs re-register
          record.SetAuthorizationUsername(authorizationUsername);
          record.SetPassword(password);
          record.SetStatus(XMSIPRegistrationRecord::ToRegister);
        } else if (record.GetStatus() == XMSIPRegistrationRecord::ToUnregister) {
          // previously registered and hence marked as to unregister -> do nothing
          record.SetStatus(XMSIPRegistrationRecord::Registered);
        } else {
          record.SetStatus(XMSIPRegistrationRecord::ToRegister);
        }
        
        // record found, break out
        return;
      }
    }
  }
  
  // no matching record found -> create a new one
  XMSIPRegistrationRecord *record = new XMSIPRegistrationRecord(addressOfRecord, authorizationUsername, password);
  record->SetStatus(XMSIPRegistrationRecord::ToRegister);
  activeRegistrations.Append(record);
}

void XMSIPEndPoint::FinishRegistrationSetup(bool proxyChanged)
{
  if (proxyChanged) {
    // Unregister all registrations and re-register with the new proxy information (below)
    UnregisterAll();
  }
  
  PWaitAndSignal m(registrationListMutex);
  
  unsigned count = activeRegistrations.GetSize();
  for (int i = (count-1); i >= 0; i--) { // go backwards since objects may be removed within the loop
    XMSIPRegistrationRecord & record = activeRegistrations[i];
    
    if (record.GetStatus() == XMSIPRegistrationRecord::ToUnregister) {
      Unregister(record.GetAddressOfRecord());
      _XMHandleSIPUnregistration(record.GetAddressOfRecord());
      activeRegistrations.RemoveAt(i);
    } else if (record.GetStatus() == XMSIPRegistrationRecord::ToRemove) {
      activeRegistrations.RemoveAt(i);
    } else if (record.GetStatus() == XMSIPRegistrationRecord::ToRegister) {
      SIPRegister::Params params;
      
      params.m_addressOfRecord = record.GetAddressOfRecord();
      params.m_authID = record.GetAuthorizationUsername();
      params.m_password = record.GetPassword();
      params.m_expire = GetRegistrarTimeToLive().GetSeconds();
      
      bool result = Register(params);
      
      if (result == false && (record.GetStatus() != XMSIPRegistrationRecord::Failed)) {
        // special condition in case no network interfaces are present
        record.SetStatus(XMSIPRegistrationRecord::Failed);
        _XMHandleSIPRegistrationFailure(record.GetAddressOfRecord(), XMSIPStatusCode_Framework_NoNetworkInterfaces);
      }
    }
  }
  
  CheckRegistrationProcess();
}

PString XMSIPEndPoint::GetAddressOfRecord(const PString & host, const PString & username)
{
  // use similar method as SIPEndPoint::Register()
  if (username.Find('@') == P_MAX_INDEX) {
    return username + '@' + host;
  } else {
    PString aor = username;
    if (!host.IsEmpty()) {
      aor += ";proxy=" + host;
    }
    return aor;
  }
}

void XMSIPEndPoint::OnRegistrationFailed(const PString & aor,
                                         SIP_PDU::StatusCodes reason,
                                         bool wasRegistering)
{
  SIPEndPoint::OnRegistrationFailed(aor, reason, wasRegistering);
  
  if (wasRegistering == false) { // not interested in unREGISTER
    return;
  }
  
  PWaitAndSignal m(registrationListMutex);
  
  // only check the registration complete process if a ToRegister
  // status disappears
  bool doCheckRegistrationProcess = false;
  
  unsigned count = activeRegistrations.GetSize();
  for (unsigned i = 0; i < count; i++) {
    XMSIPRegistrationRecord & record = activeRegistrations[i];
    
    if (aor == record.GetAddressOfRecord()) {
      if (record.GetStatus() == XMSIPRegistrationRecord::ToRegister) {
        doCheckRegistrationProcess = true;
      }
      record.SetStatus(XMSIPRegistrationRecord::Failed);
      _XMHandleSIPRegistrationFailure(record.GetAddressOfRecord(), (XMSIPStatusCode)reason);
      break;
    }
  }
  if (doCheckRegistrationProcess) {
    CheckRegistrationProcess();
  }
}

void XMSIPEndPoint::OnRegistered(const PString & aor,
                                 bool wasRegistering)
{
  SIPEndPoint::OnRegistered(aor, wasRegistering);
  
  if (wasRegistering == false) { // not interested in unREGISTER
    return;
  }
  
  PWaitAndSignal m(registrationListMutex);
  
  // only check the registration complete process if a ToRegister
  // status disappears
  bool doCheckRegistrationProcess = false;
    
  unsigned count = activeRegistrations.GetSize();
  for (unsigned i = 0; i < count; i++) {
    XMSIPRegistrationRecord & record = activeRegistrations[i];
    
    if (aor == record.GetAddressOfRecord()) {
      if (record.GetStatus() == XMSIPRegistrationRecord::ToRegister) {
        doCheckRegistrationProcess = true;
      }
      record.SetStatus(XMSIPRegistrationRecord::Registered);
      _XMHandleSIPRegistration(record.GetAddressOfRecord());
      break;
    }
  }
  if (doCheckRegistrationProcess) {
    CheckRegistrationProcess();
  }
}

void XMSIPEndPoint::CheckRegistrationProcess()
{
  // When starting the registrations, there should
  // only be records with status Registered and ToRegister
  // Records with status ToRegister will eventually move
  // either to Registered or Failed. The registration process
  // is complete once all ToRegister records have disappeared
  //
  // This method also assumes that the registrationsListMutex
  // is locked
  bool completed = true;
  unsigned count = activeRegistrations.GetSize();
  for (unsigned i = 0; i < count; i++) {
    XMSIPRegistrationRecord & record = activeRegistrations[i];
    
    if (record.GetStatus() == XMSIPRegistrationRecord::ToRegister) {
      completed = false;
      break;
    }
  }
  
  if (completed == true) {
    _XMHandleSIPRegistrationComplete();
  }
}

void XMSIPEndPoint::HandleNetworkStatusChange()
{
}

void XMSIPEndPoint::GetCallStatistics(XMCallStatisticsRecord *callStatistics)
{
  PSafePtr<SIPConnection> connection = GetSIPConnectionWithLock(connectionToken, PSafeReadOnly);
  
  if (connection != NULL)
  {
    // not supported at the moment
    callStatistics->roundTripDelay = UINT_MAX;
    
    XMOpalManager::ExtractCallStatistics(*connection, callStatistics);
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
  if (connection.GetToken() == connectionToken)
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
  if (!proxyURL.IsEmpty())
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
  if (!address.GetIpAddress(ip))
  {
    return url;
  }
  if (ip.IsAny())
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

XMSIPRegistrationRecord::XMSIPRegistrationRecord(const PString & _addressOfRecord,
                                                 const PString & _authorizationUsername,
                                                 const PString & _password)
: addressOfRecord(_addressOfRecord),
  authorizationUsername(_authorizationUsername),
  password(_password)
{
}

XMSIPRegistrationRecord::~XMSIPRegistrationRecord()
{
}

