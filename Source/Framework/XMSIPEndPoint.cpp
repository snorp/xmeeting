/*
 * $Id: XMSIPEndPoint.cpp,v 1.44 2008/10/12 12:24:12 hfriederich Exp $
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
  notifyRegistrationsFinished(false),
  isRefreshingInterfaces(false)
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

PStringArray XMSIPEndPoint::GetDefaultListeners() const {
  // Disable TCP for now, as this confuses some registrars if multiple contacts in one REGISTER
  return PStringArray("udp$*:5060");
}

bool XMSIPEndPoint::UseProxy(const PString & hostname,
                             const PString & username,
                             const PString & password)
{
  SIPURL oldProxy = GetProxy();
  
  PString adjustedUsername;
  
  unsigned location = username.Find('@');
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

#pragma mark -
#pragma mark Registration Methods

void XMSIPEndPoint::PrepareRegistrations(bool proxyChanged)
{
  PWaitAndSignal m(registrationListMutex);
  notifyRegistrationsFinished = true;
  
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

void XMSIPEndPoint::UseRegistration(const PString & domain,
                                    const PString & username,
                                    const PString & authorizationUsername,
                                    const PString & password,
                                    bool proxyChanged)
{
  PWaitAndSignal m(registrationListMutex);
  
  // if the proxy changed, all registrations need to be re-done using the new proxy information
  if (proxyChanged == false) {
    // searching for a record with the same information
    // if found, marking this record as registered/needs to register.
    // if not, create a new record and add it to the list
    unsigned count = activeRegistrations.GetSize();
    for (unsigned i = 0; i < count; i++) {
      XMSIPRegistrationRecord & record = activeRegistrations[i];
      
      if (record.GetDomain() == domain && record.GetUsername() == username) {
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
  XMSIPRegistrationRecord *record = new XMSIPRegistrationRecord(domain, username, authorizationUsername, password);
  record->SetStatus(XMSIPRegistrationRecord::ToRegister);
  activeRegistrations.Append(record);
}

void XMSIPEndPoint::FinishRegistrations(bool proxyChanged)
{
  if (proxyChanged) {
    // Unregister all registrations and re-register with the new proxy information (below)
    UnregisterAll();
  }
  
  bool hasNetworkInterfaces = XMOpalManager::GetManager()->HasNetworkInterfaces();
  
  PWaitAndSignal m(registrationListMutex);
  
  // first, unregister and remove all failed / no longer needed registrations
  unsigned count = activeRegistrations.GetSize();
  for (int i = (count-1); i >= 0; i--) { // go backwards since objects may be removed within the loop
    XMSIPRegistrationRecord & record = activeRegistrations[i];
    
    switch (record.GetStatus()) {
      case XMSIPRegistrationRecord::ToUnregister:
        _XMHandleSIPUnregistration(record.GetAddressOfRecord());
        Unregister(record.GetAddressOfRecord());
        activeRegistrations.RemoveAt(i);
        break;
      case XMSIPRegistrationRecord::ToRemove:
        RemoveRegisterHandler(record);
        activeRegistrations.RemoveAt(i);
        break;
      default:
        break;
    }
  }
  
  // register all remaining registrations
  count = activeRegistrations.GetSize();
  for (unsigned i = 0; i < count; i++) {
    XMSIPRegistrationRecord & record = activeRegistrations[i];
    
    if (record.GetStatus() == XMSIPRegistrationRecord::ToRegister) {
      if (hasNetworkInterfaces) {
        DoRegister(record);
      } else {
        record.SetStatus(XMSIPRegistrationRecord::Failed);
        _XMHandleSIPRegistrationFailure(record.GetDomain(), record.GetUsername(),
                                        GetAddressOfRecord(record.GetDomain(), record.GetUsername()),
                                        XMSIPStatusCode_Framework_NoNetworkInterfaces);
      }
    }
  }
  
  CheckRegistrationProcess();
}

void XMSIPEndPoint::RetryFailedRegistrations()
{
  if (!XMOpalManager::GetManager()->HasNetworkInterfaces()) {
    return;
  }
  
  PWaitAndSignal m(registrationListMutex);
  
  unsigned count = activeRegistrations.GetSize();
  for (unsigned i = 0; i < count; i++) {
    XMSIPRegistrationRecord & record = activeRegistrations[i];
    
    if (record.GetStatus() == XMSIPRegistrationRecord::Failed) {
      // only retry the registration if there is no handler associated
      bool found = false;
      for (PSafePtr<SIPHandler> handler(activeSIPHandlers, PSafeReadOnly); handler != NULL; ++handler) {
        if (handler->GetMethod() == SIP_PDU::Method_REGISTER &&
            handler->GetAddressOfRecord() == SIPURL(record.GetAddressOfRecord())) {
          found = true;
          break;
        }
      }
      if (!found) {
        DoRegister(record);
      }
    }
  }
}

PString XMSIPEndPoint::GetAddressOfRecord(const PString & domain, const PString & username)
{
  // use similar method as SIPEndPoint::Register()
  PString aor = "sip:" + username;
  if (username.Find('@') == P_MAX_INDEX) {
    return aor + '@' + domain;
  } else {
    if (!domain.IsEmpty()) {
      aor += ";proxy=" + domain;
    }
    return aor;
  }
}

void XMSIPEndPoint::DoRegister(XMSIPRegistrationRecord & record)
{
  PString aor = record.GetAddressOfRecord();
  if (aor.IsEmpty()) {
    aor = GetAddressOfRecord(record.GetDomain(), record.GetUsername());
  }
  
  SIPRegister::Params params;
  
  params.m_addressOfRecord = aor;
  params.m_authID          = record.GetAuthorizationUsername();
  params.m_password        = record.GetPassword();
  params.m_expire          = GetRegistrarTimeToLive().GetSeconds();
  
  Register(params, aor);
  
  // store the address of record
  record.SetAddressOfRecord(aor);
}

void XMSIPEndPoint::RemoveRegisterHandler(XMSIPRegistrationRecord & record)
{
  for (PSafePtr<SIPHandler> handler(activeSIPHandlers, PSafeReadWrite); handler != NULL; ++handler) {
    if (handler->GetMethod() == SIP_PDU::Method_REGISTER &&
        handler->GetAddressOfRecord() == SIPURL(record.GetAddressOfRecord())) {
      handler->OnFailed(SIP_PDU::IllegalStatusCode);
      break;
    }
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
  
  if (isRefreshingInterfaces && reason == SIP_PDU::Local_BadTransportAddress) {
    // there may be no interface present if an interface change happens.
    // Don't report this
    return;
  }
  
  unsigned count = activeRegistrations.GetSize();
  for (unsigned i = 0; i < count; i++) {
    XMSIPRegistrationRecord & record = activeRegistrations[i];
    
    if (aor == record.GetAddressOfRecord()) {
      if (record.GetStatus() == XMSIPRegistrationRecord::ToRegister) {
        record.SetStatus(XMSIPRegistrationRecord::Failed);
        if (reason == SIP_PDU::Failure_UnAuthorised) {
          // If a wrong password was entered, the handler isn't destroyed, but no
          // re-registration attempt is made. Hence force destruction of the handler
          RemoveRegisterHandler(record);
        }
        // if IllegalStatusCode is returned, the error is probably that the registrar address is on the local LAN,
        // but there is no ARP entry for this address -> No PDU is ever sent out.
        // Treat this as a timeout
        if (reason == SIP_PDU::IllegalStatusCode) {
          reason = SIP_PDU::Failure_RequestTimeout;
        }
        _XMHandleSIPRegistrationFailure(record.GetDomain(), record.GetUsername(), record.GetAddressOfRecord(), (XMSIPStatusCode)reason);
      }
      break;
    }
  }
  
  CheckRegistrationProcess();
}

void XMSIPEndPoint::OnRegistered(const PString & aor,
                                 bool wasRegistering)
{
  SIPEndPoint::OnRegistered(aor, wasRegistering);
  
  if (wasRegistering == false) { // not interested in unREGISTER
    return;
  }
  
  PWaitAndSignal m(registrationListMutex);
    
  unsigned count = activeRegistrations.GetSize();
  for (unsigned i = 0; i < count; i++) {
    XMSIPRegistrationRecord & record = activeRegistrations[i];
    
    if (aor == record.GetAddressOfRecord()) {
      // only report a successful registration once
      if (record.GetStatus() == XMSIPRegistrationRecord::ToRegister) {
        record.SetStatus(XMSIPRegistrationRecord::Registered);
        _XMHandleSIPRegistration(record.GetDomain(), record.GetUsername(), record.GetAddressOfRecord());
      }
      break;
    }
  }
  
  CheckRegistrationProcess();
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
  if (notifyRegistrationsFinished == false) {
    return;
  }
  
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
    notifyRegistrationsFinished = false;
  }
}

#pragma mark -
#pragma mark Callbacks

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

SIPURL XMSIPEndPoint::GetDefaultRegisteredPartyName(const OpalTransport & transport)
{
  // If using a proxy, use the proxy user name and domain name
  SIPURL proxyURL = GetProxy();
  if (!proxyURL.IsEmpty()) {
    return proxyURL;
  }
  
  // Get the default value
  SIPURL url = SIPEndPoint::GetDefaultRegisteredPartyName(transport);
  
  // If the superclass returns IP "0.0.0.0", make the
  // OpalTransportAddress empty. This in turn indicates
  // to the callers that they should use the current
  // transport's local address
  OpalTransportAddress address = url.GetHostAddress();
  PIPSocket::Address ip;
  if (!address.GetIpAddress(ip)) {
    return url;
  }
  if (ip.IsAny()) {
    url = SIPURL(GetDefaultLocalPartyName(), OpalTransportAddress());
  }
  return url;
}

#pragma mark -
#pragma mark Interface Handling

void XMSIPEndPoint::OnStartInterfaceListRefresh()
{
  PWaitAndSignal m(registrationListMutex);
  isRefreshingInterfaces = true;
}

void XMSIPEndPoint::OnEndInterfaceListRefresh()
{
  PWaitAndSignal m(registrationListMutex);
  isRefreshingInterfaces = false;
}

#pragma mark -
#pragma mark Clean Up

void XMSIPEndPoint::CleanUp()
{
  // Clean up all connections
  PWaitAndSignal m(releasingConnectionsMutex);
  for (unsigned i = 0; i < releasingConnections.GetSize(); i++) {
    releasingConnections[i].CleanUp();
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

XMSIPRegistrationRecord::XMSIPRegistrationRecord(const PString & _domain,
                                                 const PString & _username,
                                                 const PString & _authorizationUsername,
                                                 const PString & _password)
: domain(_domain),
  username(_username),
  authorizationUsername(_authorizationUsername),
  password(_password),
  addressOfRecord(""),
  status(ToRegister)
{
}

XMSIPRegistrationRecord::~XMSIPRegistrationRecord()
{
}

