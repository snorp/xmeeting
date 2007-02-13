/*
 * $Id: XMOpalManager.h,v 1.28 2007/02/13 11:56:09 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

/**
 * Due to problems with the C++ runtime system and especially dynamic_cast
 * when using ZeroLink, all C++ code is now directly linked with Opal.
 **/

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
	
	/* Getting access to the OPAL manager */
	static XMOpalManager * GetManager();
	
	/* Getting access to the endpoints */
	static XMH323EndPoint * GetH323EndPoint();
	static XMSIPEndPoint * GetSIPEndPoint();
	static XMEndPoint * GetCallEndPoint();
	
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
	virtual void OnEstablishedCall(OpalCall & call);
	virtual void OnClearedCall(OpalCall & call);
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
	void SetNATInformation(const PString & stunServer,
						   const PString & translationAddress);
	
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
    
    unsigned bandwidthLimit;
	
	unsigned defaultAudioPacketTime;
	unsigned currentAudioPacketTime;
    
    BOOL enableH264LimitedMode;
	
	PString connectionToken;
	PString remoteName;
	PString remoteNumber;
	PString remoteAddress;
	PString remoteApplication;
	XMCallProtocol callProtocol;
};

#endif // __XM_OPAL_MANAGER_H__
