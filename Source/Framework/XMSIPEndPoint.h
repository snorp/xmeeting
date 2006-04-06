/*
 * $Id: XMSIPEndPoint.h,v 1.3 2006/04/06 23:15:32 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_SIP_END_POINT_H__
#define __XM_SIP_END_POINT_H__

#include <ptlib.h>
#include <sip/sipcon.h>
#include <sip/sipep.h>

#include "XMTypes.h"

class XMSIPRegistrarRecord : public PObject
{
	PCLASSINFO(XMSIPRegistrarRecord, PObject);
	
public:
	
	XMSIPRegistrarRecord(const PString & host,
						 const PString & username,
						 const PString & authorizationUsername,
						 const PString & password);
	~XMSIPRegistrarRecord();
	
	const PString & GetHost() const;
	const PString & GetUsername() const;
	const PString & GetAuthorizationUsername() const;
	const PString & GetPassword() const;
	void SetPassword(const PString & password);
	unsigned GetStatus() const;
	void SetStatus(unsigned status);
	
private:
		
	PString host;
	PString username;
	PString authorizationUsername;
	PString password;
	unsigned status;
};

class XMSIPEndPoint : public SIPEndPoint
{
	PCLASSINFO(XMSIPEndPoint, SIPEndPoint);
	
public:
	XMSIPEndPoint(OpalManager & manager);
	virtual ~XMSIPEndPoint();
	
	BOOL EnableListeners(BOOL enable);
	BOOL IsListening();
	
	void PrepareRegistrarSetup();
	void UseRegistrar(const PString & host,
					  const PString & username,
					  const PString & authorizationUsername,
					  const PString & password);
	void FinishRegistrarSetup();
	
	void GetCallStatistics(XMCallStatisticsRecord *callStatistics);
	
	virtual void OnRegistrationFailed(const PString & host,
									  const PString & username,
									  SIP_PDU::StatusCodes reason,
									  BOOL wasRegistering);
	virtual void OnRegistered(const PString & host,
							  const PString & username,
							  BOOL wasRegistering);
	
	virtual void OnEstablished(OpalConnection & connection);
	virtual void OnReleased(OpalConnection & connection);
	
	virtual SIPConnection * CreateConnection(OpalCall & call,
											 const PString & token,
											 void * userData,
											 const SIPURL & destination,
											 OpalTransport * transport,
											 SIP_PDU * invite);
	
private:
	BOOL isListening;
	
	PString connectionToken;
	
	class XMSIPRegistrarList : public PList<XMSIPRegistrarRecord>
	{
	};
	
	PMutex registrarListMutex;
	XMSIPRegistrarList activeRegistrars;
};


#endif // __XM_SIP_END_POINT_H__
