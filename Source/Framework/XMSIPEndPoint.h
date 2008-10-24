/*
 * $Id: XMSIPEndPoint.h,v 1.25 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2006-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2008 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_SIP_END_POINT_H__
#define __XM_SIP_END_POINT_H__

#include <ptlib.h>
#include <sip/sipcon.h>
#include <sip/sipep.h>

#include "XMTypes.h"

class XMSIPConnection;

class XMSIPRegistrationRecord : public PObject
{
  PCLASSINFO(XMSIPRegistrationRecord, PObject);
  
public:
  
  XMSIPRegistrationRecord(const PString & domain, 
                          const PString & username,
                          const PString & authorizationUsername,
                          const PString & password);
  ~XMSIPRegistrationRecord();
  
  enum Status {
    ToRegister,
    Registered,
    Failed,
    ToUnregister,
    ToRemove
  };
  
  const PString & GetDomain() const { return domain; }
  const PString & GetUsername() const { return username; }
  const PString & GetAuthorizationUsername() const { return authorizationUsername; }
  void SetAuthorizationUsername(const PString & _authorizationUsername) { authorizationUsername = _authorizationUsername; }
  const PString & GetPassword() const { return password; }
  void SetPassword(const PString & _password) { password = _password; }
  const PString & GetAddressOfRecord() const { return addressOfRecord; }
  void SetAddressOfRecord(const PString & _addressOfRecord) { addressOfRecord = _addressOfRecord; }
  Status GetStatus() const { return status; }
  void SetStatus(Status _status) { status = _status; }
  
private:
    
  PString domain;
  PString username;
  PString authorizationUsername;
  PString password;
  PString addressOfRecord;
  Status status;
};

class XMSIPEndPoint : public SIPEndPoint
{
  PCLASSINFO(XMSIPEndPoint, SIPEndPoint);
  
public:
  XMSIPEndPoint(OpalManager & manager);
  virtual ~XMSIPEndPoint();
  
  // Protocol
  bool EnableListeners(bool enable);
  bool IsListening() const { return isListening; }
  bool UseProxy(const PString & hostname,
                const PString & username,
                const PString & password);
  
  // Registrations
  void PrepareRegistrations(bool proxyChanged);
  void UseRegistration(const PString & domain,
                       const PString & username,
                       const PString & authorizationUsername,
                       const PString & password,
                       bool proxyChanged);
  void FinishRegistrations(bool proxyChanged);
  void RetryFailedRegistrations();
  virtual void OnRegistrationFailed(const PString & aor,
                                    SIP_PDU::StatusCodes reason,
                                    bool wasRegistering);
  virtual void OnRegistered(const PString & aor,
                            bool wasRegistering);
  
  virtual SIPConnection * CreateConnection(OpalCall & call,
                                           const PString & token,
                                           void * userData,
                                           const SIPURL & destination,
                                           OpalTransport * transport,
                                           SIP_PDU * invite,
                                           unsigned int options = 0,
                                           OpalConnection::StringOptions * stringOptions = NULL);
  
  // interface handling
  void OnStartInterfaceListRefresh();
  void OnEndInterfaceListRefresh();
  
  // Called when framework is closing
  void CleanUp();
  void AddReleasingConnection(XMSIPConnection * connection);
  void RemoveReleasingConnection(XMSIPConnection * connection);
  
private:
  static PString GetAddressOfRecord(const PString & domain, const PString & username);
  void DoRegister(XMSIPRegistrationRecord & registrationRecord);
  void RemoveRegisterHandler(XMSIPRegistrationRecord & record);
                       
  void CheckRegistrationProcess();
  
	bool isListening;
  
  PLIST(XMSIPRegistrationList, XMSIPRegistrationRecord);
  
  PMutex registrationListMutex;
  XMSIPRegistrationList activeRegistrations;
  bool notifyRegistrationsFinished;
  bool isRefreshingInterfaces;
  
  PList<XMSIPConnection> releasingConnections;
  PMutex releasingConnectionsMutex;
};

#endif // __XM_SIP_END_POINT_H__
