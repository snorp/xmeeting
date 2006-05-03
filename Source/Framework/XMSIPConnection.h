/*
 * $Id: XMSIPConnection.h,v 1.3 2006/05/03 19:54:40 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_SIP_CONNECTION_H__
#define __XM_SIP_CONNECTION_H__

#include <ptlib.h>
#include <sip/sipcon.h>
#include <sip/sippdu.h>

class XMSIPConnection : public SIPConnection
{
	PCLASSINFO(XMSIPConnection, SIPConnection);
	
public:
	
	XMSIPConnection(OpalCall & call,
					SIPEndPoint & endpoint,
					const PString & token,
					const SIPURL & address,
					OpalTransport * transport);
	
	~XMSIPConnection();
	
	virtual BOOL SetUpConnection();
	static BOOL XMWriteINVITE(OpalTransport & transport, void *param);
	
	virtual BOOL OnSendSDPMediaDescription(const SDPSessionDescription & sdpIn,
										   SDPMediaDescription::MediaType mediaType,
										   unsigned sessionID,
										   SDPSessionDescription & sdpOut);
	virtual BOOL OnReceivedSDPMediaDescription(SDPSessionDescription & sdp,
											   SDPMediaDescription::MediaType mediaType,
											   unsigned sessionID);
	
	virtual OpalMediaFormatList GetMediaFormats() const;
	virtual void AdjustMediaFormats(OpalMediaFormatList & mediaFormats) const;
	
	virtual OpalMediaStream * CreateMediaStream(const OpalMediaFormat & mediaFormat,
												unsigned sessionID,
												BOOL isSource);
	
	virtual BOOL OnOpenMediaStream(OpalMediaStream & stream);
	
	virtual void OnReceivedACK(SIP_PDU & pdu);
	
	virtual void OnReceivedAuthenticationRequired(SIPTransaction & transaction,
												  SIP_PDU & response);
	
private:
	
	static void AdjustSessionDescription(SDPSessionDescription & sdp);
	
	OpalVideoFormat h261VideoFormat;
	OpalVideoFormat h263VideoFormat;
	OpalVideoFormat h263PlusVideoFormat;
	OpalVideoFormat h264VideoFormat;
	unsigned bandwidthUsed;
};

#endif // __XM_SIP_CONNECTION_H__

