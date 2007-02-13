/*
 * $Id: XMSIPConnection.h,v 1.11 2007/02/13 11:56:09 hfriederich Exp $
 *
 * Copyright (c) 2006-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_SIP_CONNECTION_H__
#define __XM_SIP_CONNECTION_H__

#include <ptlib.h>
#include <sip/sipcon.h>
#include <sip/sippdu.h>

#include "XMInBandDTMFHandler.h"

class XMSIPConnection : public SIPConnection
{
	PCLASSINFO(XMSIPConnection, SIPConnection);
	
public:
	
	XMSIPConnection(OpalCall & call,
					SIPEndPoint & endpoint,
					const PString & token,
					const SIPURL & address,
					OpalTransport * transport,
					unsigned int options = 0,
                    OpalConnection::StringOptions * stringOptions = NULL);
	
	~XMSIPConnection();
	
	virtual BOOL SetUpConnection();
	
	virtual void OnCreatingINVITE(SIP_PDU & invite);
	
	virtual BOOL OnSendSDPMediaDescription(const SDPSessionDescription & sdpIn,
										   const OpalMediaType & opalMediaType,
										   SDPSessionDescription & sdpOut);
	virtual BOOL OnReceivedSDPMediaDescription(SDPSessionDescription & sdp,
											   const OpalMediaType & opalMediaType);
	
	virtual OpalMediaStream * CreateMediaStream(const OpalMediaFormat & mediaFormat,
												BOOL isSource);
	
    // Propagate opening / closing of media streams to the Obj-C world
	virtual BOOL OnOpenMediaStream(OpalMediaStream & stream);
    virtual void OnClosedMediaStream(const OpalMediaStream & stream);
		
    // Overridden to circumvent the default Opal bandwidth management
	virtual BOOL SetBandwidthAvailable(unsigned newBandwidth, BOOL force = FALSE);
	virtual unsigned GetBandwidthUsed() const;
	virtual BOOL SetBandwidthUsed(unsigned releasedBandwidth, unsigned requiredBandwidth);
	
    // Overridden to being able to send in-band DTMF
	virtual BOOL SendUserInputTone(char tone, unsigned duration);
    virtual void OnPatchMediaStream(BOOL isSource, OpalMediaPatch & patch);
	
private:
	
	OpalVideoFormat h261VideoFormat;
	OpalVideoFormat h263VideoFormat;
	OpalVideoFormat h263PlusVideoFormat;
	OpalVideoFormat h264VideoFormat;
	
	XMInBandDTMFHandler *inBandDTMFHandler;
};

#endif // __XM_SIP_CONNECTION_H__

