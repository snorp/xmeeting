/*
 * $Id: XMSIPConnection.h,v 1.9 2007/02/08 08:43:34 hfriederich Exp $
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
	
	virtual OpalMediaFormatList GetMediaFormats() const;
	virtual void AdjustMediaFormats(OpalMediaFormatList & mediaFormats) const;
	
	virtual OpalMediaStream * CreateMediaStream(const OpalMediaFormat & mediaFormat,
												BOOL isSource);
	
	virtual BOOL OnOpenMediaStream(OpalMediaStream & stream);
	
	virtual void OnPatchMediaStream(BOOL isSource, OpalMediaPatch & patch);
	
	virtual void OnReceivedACK(SIP_PDU & pdu);
	
	virtual void OnReceivedAuthenticationRequired(SIPTransaction & transaction,
												  SIP_PDU & response);
	
	virtual BOOL SetBandwidthAvailable(unsigned newBandwidth, BOOL force = FALSE);
	virtual unsigned GetBandwidthUsed() const;
	virtual BOOL SetBandwidthUsed(unsigned releasedBandwidth, unsigned requiredBandwidth);
	
	virtual BOOL SendUserInputTone(char tone, unsigned duration);
	
private:
	
	static void AdjustSessionDescription(SDPSessionDescription & sdp);
	
	OpalVideoFormat h261VideoFormat;
	OpalVideoFormat h263VideoFormat;
	OpalVideoFormat h263PlusVideoFormat;
	OpalVideoFormat h264VideoFormat;
	
	XMInBandDTMFHandler *inBandDTMFHandler;
};

#endif // __XM_SIP_CONNECTION_H__

