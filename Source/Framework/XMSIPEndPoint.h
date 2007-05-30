/*
 * $Id: XMSIPEndPoint.h,v 1.16 2007/05/30 08:41:17 hfriederich Exp $
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
	
	virtual BOOL AdjustInterfaceTable(PIPSocket::Address & remoteAddress,
									  PIPSocket::InterfaceTable & interfaceTable);
	
	// These methods are mostly copies of the existing methods
	// of the SIPEndPoint class. The main purpose is to establish the
	// following properties:
	// - Instead of sending out multiple REGISTER / INVITE to find out the
	//   correct interface to use, send OPTIONS requests first, lock on the
	//   interface and send the REGISTER / INVITEs afterwards. 
	// - Should the available interfaces change, re-REGISTER all registrations
	// - Should a refreshed REGISTER fail due to host not reachable, do a clean
    //   REGISTER refresh
	// - Ensure that a registration is refreshed before it expired. If the registration
	//   expired, do a clean refresh
	/*virtual SIPRegisterInfo * CreateRegisterInfo(const PString & originalHost,
												 const PString & adjustedUsername, 
												 const PString & authName, 
												 const PString & password, 
												 int expire, 
												 const PTimeInterval & minRetryTime, 
												 const PTimeInterval & maxRetryTime
												 );*/
	//virtual OpalTransport * CreateTransport(const OpalTransportAddress & addr, const OpalTransport * originalTransport);
	//static BOOL WriteSIPOptions(OpalTransport & transport, void * data);
	///virtual void OnReceivedResponse(SIPTransaction & transaction, SIP_PDU & response);
	//virtual void OnOptionsTimeout(XMSIPOptions *options);
	//void RegistrationRefresh(PTimer &timer, INT value);
	
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

/*class XMSIPRegisterInfo : public SIPRegisterInfo
{
	PCLASSINFO(XMSIPRegisterInfo, SIPRegisterInfo);
	
public:
	XMSIPRegisterInfo(XMSIPEndPoint & ep, 
					  const PString & originalHost,
					  const PString & adjustedUsername, 
					  const PString & authName, 
					  const PString & password, 
					  int expire,
					  const PTimeInterval & minRetryTime,
					  const PTimeInterval & maxRetryTime);
	~XMSIPRegisterInfo();
	
	virtual BOOL CreateTransport(OpalTransportAddress & addr);
	//BOOL WillExpireWithinTimeInterval(PTimeInterval interval);
};

class XMSIPOptions : public SIPTransaction
{
	PCLASSINFO(XMSIPOptions, SIPTransaction);
	
public:
	XMSIPOptions(SIPEndPoint & ep, OpalTransport & trans, const SIPURL & address);
	~XMSIPOptions();
	
	BOOL Start();
	
	virtual void OnTimeout(PTimer & timer, INT value);
	
protected:
	virtual void SetTerminated(States newState);
};*/

#endif // __XM_SIP_END_POINT_H__
