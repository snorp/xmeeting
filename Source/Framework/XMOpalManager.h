/*
 * $Id: XMOpalManager.h,v 1.39 2007/10/03 07:22:42 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_OPAL_MANAGER_H__
#define __XM_OPAL_MANAGER_H__

#include <ptlib.h>
#include <opal/manager.h>

#include "XMTypes.h"

#include "XMMediaFormats.h"

class XMEndPoint;
class XMH323EndPoint;
class XMSIPEndPoint;

class XMOpalManager : public OpalManager
{
	PCLASSINFO(XMOpalManager, OpalManager);
	
public:
	static void InitOpal(const PString & pTracePath);
	static void CloseOpal();
	
	XMOpalManager();
	~XMOpalManager();
	
	/* Getting access to the OPAL manager */
	static XMOpalManager * GetManager();
	
	/* Getting access to the endpoints */
	static XMH323EndPoint * GetH323EndPoint();
	static XMSIPEndPoint * GetSIPEndPoint();
	static XMEndPoint * GetCallEndPoint();
  
  /* Handle network status changes */
  void HandleNetworkStatusChange();
    
    /* Initiating a call */
    unsigned InitiateCall(XMCallProtocol protocol, const char * remoteParty, 
                          const char *origAddressString, XMCallEndReason * callEndReason);
    void HandleCallInitiationFailed(XMCallEndReason endReason);
	
	/* getting/setting call information */
    void LockCallInformation();
    void UnlockCallInformation();
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
    static void ExtractCallStatistics(const OpalConnection & connection,
                                      XMCallStatisticsRecord *callStatistics);
	
	/* overriding some callbacks */
	virtual void OnEstablishedCall(OpalCall & call);
	virtual void OnReleased(OpalConnection & connection);
	virtual OpalMediaPatch * CreateMediaPatch(OpalMediaStream & source, BOOL requiresPatchThread = TRUE);
    
    void OnOpenRTPMediaStream(const OpalConnection & connection, const OpalMediaStream & stream);
    void OnClosedRTPMediaStream(const OpalConnection & connection, const OpalMediaStream & stream);
	
	/* General setup methods */
	void SetUserName(const PString & name);

	/* Bandwidth usage */
    unsigned GetBandwidthLimit() const { return bandwidthLimit; }
	void SetBandwidthLimit(unsigned limit) { bandwidthLimit = limit; }
	unsigned GetVideoBandwidthLimit() const { return bandwidthLimit - 64000; }
	
    /* NAT methods */
	void SetNATInformation(const PStringArray & stunServers,
						   const PString & translationAddress,
                           BOOL networkStatusChanged);
	
	/* Audio setup methods */
	void SetAudioPacketTime(unsigned audioPacketTime);
	void SetCurrentAudioPacketTime(unsigned audioPacketTime);
	unsigned GetCurrentAudioPacketTime();
    
    /* H.264 methods */
    BOOL GetEnableH264LimitedMode() const { return enableH264LimitedMode; }
    void SetEnableH264LimitedMode(BOOL _enable) { enableH264LimitedMode = _enable; }
	
	/* getting /setting information about current call */
	void SetCallProtocol(XMCallProtocol theCallProtocol) { callProtocol = theCallProtocol; }
	unsigned GetKeyFrameIntervalForCurrentCall(XMCodecIdentifier codecIdentifier) const;
	BOOL IsValidFormatForSending(const OpalMediaFormat & mediaFormat) const;
	
	/* User input mode information */
	BOOL SetUserInputMode(XMUserInputMode userInputMode);
	
	/* Debug log information */
	static void LogMessage(const PString & message);
    
    /* Convenience function to define current codec bandwidth limits */
    static unsigned GetH261BandwidthLimit();
    static unsigned GetH263BandwidthLimit();
    static unsigned GetH264BandwidthLimit();
	
private:
      
    void HandleSTUNInformation(PSTUNClient::NatTypes natType,
                               const PString & externalAddress);
    BOOL HasNetworkInterfaces() const;
    
    PStringArray stunServers;
    
    unsigned bandwidthLimit;
	
	unsigned defaultAudioPacketTime;
	unsigned currentAudioPacketTime;
    
    BOOL enableH264LimitedMode;
	
    PMutex callInformationMutex;
	PString connectionToken;
	PString remoteName;
	PString remoteNumber;
	PString remoteAddress;
	PString remoteApplication;
    PString origRemoteAddress;
	XMCallProtocol callProtocol;
    
    XMCallEndReason *callEndReason;
};

#endif // __XM_OPAL_MANAGER_H__
