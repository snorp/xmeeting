/*
 * $Id: XMOpalManager.h,v 1.24 2006/11/02 22:28:54 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_OPAL_MANAGER_H__
#define __XM_OPAL_MANAGER_H__

#include <ptlib.h>
#include <opal/manager.h>

#include "XMTypes.h"
#include "XMEndPoint.h"
#include "XMH323EndPoint.h"
#include "XMSIPEndPoint.h"

#include "XMMediaFormats.h"

class XMEndPoint;

class XMOpalManager : public OpalManager
{
	PCLASSINFO(XMOpalManager, OpalManager);
	
public:
	static void InitOpal(const PString & pTracePath);
	static void CloseOpal();
	
	XMOpalManager();
	~XMOpalManager();
	
	void Initialise();
	
	/* Getting access to the OPAL manager */
	static XMOpalManager * GetManagerInstance();
	
	/* Getting access to the endpoints */
	XMH323EndPoint * H323EndPoint();
	XMSIPEndPoint * SIPEndPoint();
	XMEndPoint * CallEndPoint();
	
	/* getting/setting call information */
	void GetCallInformation(PString & remoteName,
							PString & remoteNumber,
							PString & remoteAddress,
							PString & remoteApplication) const;
	void SetCallInformation(const PString & connectionToken,
							const PString & remoteName,
							const PString & remoteNumber,
							const PString & remoteAddress,
							const PString & remoteApplication,
							XMCallProtocol callProtocol);
	
	/* getting call statistics */
	void GetCallStatistics(XMCallStatisticsRecord *callStatistics);
	
	/* overriding some callbacks */
	virtual BOOL OnIncomingConnection(OpalConnection & connection);
	virtual void OnEstablishedCall(OpalCall & call);
	virtual void OnClearedCall(OpalCall & call);
	virtual void OnReleased(OpalConnection & connection);
	virtual BOOL OnOpenMediaStream(OpalConnection & connection, OpalMediaStream & stream);
	virtual void OnClosedMediaStream(const OpalMediaStream & stream);
	virtual OpalMediaPatch * CreateMediaPatch(OpalMediaStream & source);
	
	virtual OpalH281Handler * CreateH281ProtocolHandler(OpalH224Handler & h224Handler) const;
	
	/* General setup methods */
	void SetUserName(const PString & name);

	/* Network setup methods */
	static void SetBandwidthLimit(unsigned limit);
	static unsigned GetBandwidthLimit();
	static unsigned GetVideoBandwidthLimit();
	static unsigned GetAvailableBandwidth();
	static void SetAvailableBandwidth(unsigned limit);
	static void ResetAvailableBandwidth();
	
	void SetNATInformation(const PString & stunServer,
						   const PString & translationAddress);
	
	/* Video setup methods */
	void SetVideoFunctionality(BOOL enableVideoTransmit, BOOL enableVideoReceive);
	
	/* getting /setting information about current call */
	void SetCallProtocol(XMCallProtocol theCallProtocol) { callProtocol = theCallProtocol; }
	unsigned GetKeyFrameIntervalForCurrentCall(XMCodecIdentifier codecIdentifier);
	BOOL IsValidCapabilityForSending(const XMH323VideoCapability & capability);
	
	/* User input mode information */
	BOOL SetUserInputMode(XMUserInputMode userInputMode);
	
	/* Debug log information */
	static void LogMessage(const PString & message);
	
private:
	BOOL IsOutgoingMedia(OpalMediaStream & stream);
	
	unsigned GetH323KeyFrameInterval(XMCodecIdentifier codecIdentifier);
	
	unsigned callID;
	
	BOOL enableVideoTransmit;
	BOOL enableVideoReceive;
	
	XMEndPoint *callEndPoint;
	XMH323EndPoint *h323EndPoint;
	XMSIPEndPoint *sipEndPoint;
	
	PString connectionToken;
	PString remoteName;
	PString remoteNumber;
	PString remoteAddress;
	PString remoteApplication;
	XMCallProtocol callProtocol;
};

#endif // __XM_OPAL_MANAGER_H__
