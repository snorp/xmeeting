/*
 * $Id: XMSIPEndPoint.h,v 1.17 2007/09/03 11:36:34 hfriederich Exp $
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

class XMSIPOptions;
class XMSIPConnection;

class XMSIPRegistrationRecord : public PObject
{
	PCLASSINFO(XMSIPRegistrationRecord, PObject);
	
public:
	
	XMSIPRegistrationRecord(const PString & registration,
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
	
	const PString & GetRegistration() const { return registration; }
	const PString & GetAuthorizationUsername() const { return authorizationUsername; }
	const PString & GetPassword() const { return password; }
	void SetPassword(const PString & _password) { password = _password; }
	Status GetStatus() const { return status; }
	void SetStatus(Status _status) { status = _status; }
	
private:
		
    PString registration;
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
	
	BOOL EnableListeners(BOOL enable);
	BOOL IsListening();
	
	void PrepareRegistrationSetup();
	void UseRegistration(const PString & host,
                         const PString & username,
                         const PString & authorizationUsername,
                         const PString & password);
	void FinishRegistrationSetup();
	
	void HandleNetworkStatusChange();
	
	void UseProxy(const PString & hostname,
				  const PString & username,
				  const PString & password);
	
	void GetCallStatistics(XMCallStatisticsRecord *callStatistics);
	
	virtual void OnRegistrationFailed(const PString & aor,
									  SIP_PDU::StatusCodes reason,
									  BOOL wasRegistering);
	virtual void OnRegistered(const PString & aor,
							  BOOL wasRegistering);
	
	virtual void OnEstablished(OpalConnection & connection);
	virtual void OnReleased(OpalConnection & connection);
	
	virtual SIPConnection * CreateConnection(OpalCall & call,
											 const PString & token,
											 void * userData,
											 const SIPURL & destination,
											 OpalTransport * transport,
											 SIP_PDU * invite,
											 unsigned int options = 0,
                                             OpalConnection::StringOptions * stringOptions = NULL);
	
	virtual SIPURL GetDefaultRegisteredPartyName();
    
    // Called when framework is closing
    void CleanUp();
    void AddReleasingConnection(XMSIPConnection * connection);
    void RemoveReleasingConnection(XMSIPConnection * connection);
	
private:
	BOOL isListening;
	
	PString connectionToken;
    
    PLIST(XMSIPRegistrationList, XMSIPRegistrationRecord);
	
	PMutex registrationListMutex;
	XMSIPRegistrationList activeRegistrations;
	
	PMutex transportMutex;
	PMutex probingOptionsMutex;
	PSyncPoint probingSyncPoint;
	SIPTransactionDict probingOptions;
	BOOL probingSuccessful;
    
    PList<XMSIPConnection> releasingConnections;
    PMutex releasingConnectionsMutex;
};

#endif // __XM_SIP_END_POINT_H__
