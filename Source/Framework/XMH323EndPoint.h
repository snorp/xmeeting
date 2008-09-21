/*
 * $Id: XMH323EndPoint.h,v 1.22 2008/09/21 19:37:31 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_H323_END_POINT_H__
#define __XM_H323_END_POINT_H__

#include <ptlib.h>
#include <h323/h323ep.h>

#include "XMTypes.h"

class XMH323Connection;

class XMH323EndPoint : public H323EndPoint
{
	PCLASSINFO(XMH323EndPoint, H323EndPoint);
  
public:
	XMH323EndPoint(OpalManager & manager);
	virtual ~XMH323EndPoint();
	
	// Protocol
	bool EnableListeners(bool flag);
	bool IsListening() const { return isListening; }
  
  // Gk Registration
	void SetGatekeeper(const PString & address,
                     const PString & terminalAlias1, 
                     const PString & terminalAlias2,
                     const PString & password);
  void HandleRegistrationConfirm();
  void HandleRegistrationFailure(XMGatekeeperRegistrationStatus status);
  void HandleUnregistration();
  virtual H323Gatekeeper * CreateGatekeeper(H323Transport * transport);
	virtual void OnRegistrationConfirm();
  PMutex & GetGatekeeperMutex() { return gatekeeperMutex; }
	
	// overriding some callbacks
	virtual H323Connection * CreateConnection(OpalCall & call,
                                            const PString & token,
                                            void * userData,
                                            OpalTransport & transport,
                                            const PString & alias,
                                            const H323TransportAddress & address,
                                            H323SignalPDU * setupPDU,
                                            unsigned options = 0,
                                            OpalConnection::StringOptions * stringOptions = NULL);
	
	// H.460 support
	virtual bool OnSendFeatureSet(unsigned, H225_FeatureSet &);
  virtual void OnReceiveFeatureSet(unsigned, const H225_FeatureSet &);
  
  // Called when the framework is closing
  void CleanUp();
  void AddReleasingConnection(XMH323Connection * connection);
  void RemoveReleasingConnection(XMH323Connection * connection);
	
private:
  
  bool isListening;
  
  PString gatekeeperAddress;
  bool notifyGkRegistrationComplete;
  PMutex gatekeeperMutex;
  
  PMutex releasingConnectionsMutex;
  PList<XMH323Connection> releasingConnections;
};

#endif // __XM_H323_END_POINT_H__