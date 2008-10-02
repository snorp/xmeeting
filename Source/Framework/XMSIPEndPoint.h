/*
 * $Id: XMSIPEndPoint.h,v 1.22 2008/10/02 07:50:22 hfriederich Exp $
 *
 * Copyright (c) 2006-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2007 Hannes Friederich. All rights reserved.
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
  
  XMSIPRegistrationRecord(const PString & addressOfRecord,
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
  
  const PString & GetAddressOfRecord() const { return addressOfRecord; }
  const PString & GetAuthorizationUsername() const { return authorizationUsername; }
  void SetAuthorizationUsername(const PString & _authorizationUsername) { authorizationUsername = _authorizationUsername; }
  const PString & GetPassword() const { return password; }
  void SetPassword(const PString & _password) { password = _password; }
  Status GetStatus() const { return status; }
  void SetStatus(Status _status) { status = _status; }
  
private:
    
  PString addressOfRecord;
  PString authorizationUsername;
  PString password;
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
  void PrepareRegistrationSetup(bool proxyChanged);
  void UseRegistration(const PString & host,
                       const PString & username,
                       const PString & authorizationUsername,
                       const PString & password,
                       bool proxyChanged);
  void FinishRegistrationSetup(bool proxyChanged);
  virtual void OnRegistrationFailed(const PString & aor,
                                    SIP_PDU::StatusCodes reason,
                                    bool wasRegistering);
  virtual void OnRegistered(const PString & aor,
                            bool wasRegistering);
  
  void HandleNetworkStatusChange();
  
  virtual SIPConnection * CreateConnection(OpalCall & call,
                                           const PString & token,
                                           void * userData,
                                           const SIPURL & destination,
                                           OpalTransport * transport,
                                           SIP_PDU * invite,
                                           unsigned int options = 0,
                                           OpalConnection::StringOptions * stringOptions = NULL);
  
  virtual SIPURL GetDefaultRegisteredPartyName(const OpalTransport & transport);
  
  // Called when framework is closing
  void CleanUp();
  void AddReleasingConnection(XMSIPConnection * connection);
  void RemoveReleasingConnection(XMSIPConnection * connection);
  
private:
  static PString GetAddressOfRecord(const PString & host, const PString & username);
  void CheckRegistrationProcess();
  
	bool isListening;
  
  PString connectionToken;
  
  PLIST(XMSIPRegistrationList, XMSIPRegistrationRecord);
  
  PMutex registrationListMutex;
  XMSIPRegistrationList activeRegistrations;
  
  PMutex transportMutex;
  
  PList<XMSIPConnection> releasingConnections;
  PMutex releasingConnectionsMutex;
};

#endif // __XM_SIP_END_POINT_H__
