/*
 * $Id: XMH323Connection.cpp,v 1.4 2006/01/09 22:22:57 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#include "XMH323Connection.h"

#include <asn/h245.h>
#include "XMMediaFormats.h"

XMH323Connection::XMH323Connection(OpalCall & call,
								   H323EndPoint & endPoint,
								   const PString & token,
								   const PString & alias,
								   const H323TransportAddress & address,
								   unsigned options)
: H323Connection(call, endPoint, token, alias, address, options)
{
	hasSetLocalCapabilities = FALSE;
	hasSentLocalCapabilities = FALSE;
}

void XMH323Connection::OnSendCapabilitySet(H245_TerminalCapabilitySet & pdu)
{
	H323Connection::OnSendCapabilitySet(pdu);
	hasSentLocalCapabilities = TRUE;
}

BOOL XMH323Connection::OpenLogicalChannel(const H323Capability & capability,
										  unsigned sessionID,
										  H323Channel::Directions dir)
{
	BOOL isValidCapability = TRUE;
	if(PIsDescendant(&capability, XM_H323_H261_Capability))
	{
		XM_H323_H261_Capability & h261Capability = (XM_H323_H261_Capability &)capability;
		isValidCapability = h261Capability.IsValidCapabilityForSending();
	}
	else if(PIsDescendant(&capability, XM_H323_H263_Capability))
	{
		XM_H323_H263_Capability & h263Capability = (XM_H323_H263_Capability &)capability;
		isValidCapability = h263Capability.IsValidCapabilityForSending();
	}
	else if(PIsDescendant(&capability, XM_H323_H264_Capability))
	{
		XM_H323_H264_Capability & h264Capability = (XM_H323_H264_Capability &)capability;
		isValidCapability = h264Capability.IsValidCapabilityForSending();
	}
	
	if(isValidCapability == FALSE)
	{
		return FALSE;
	}
	return H323Connection::OpenLogicalChannel(capability, sessionID, dir);
}

H323Channel *XMH323Connection::CreateRealTimeLogicalChannel(const H323Capability & capability,
															H323Channel::Directions dir,
															unsigned sessionID,
															const H245_H2250LogicalChannelParameters * param,
															RTP_QOS * rtpqos)
{
	
	H323Channel *channel = H323Connection::CreateRealTimeLogicalChannel(capability,
																		dir,
																		sessionID,
																		param,
																		rtpqos);
	if(PIsDescendant(&capability, XM_H323_H264_Capability))
	{
		H323_RealTimeChannel *realTimeChannel = (H323_RealTimeChannel *)channel;
		realTimeChannel->SetDynamicRTPPayloadType(RTP_DataFrame::DynamicBase);
	}
	if(PIsDescendant(&capability, XM_H323_H263_Capability))
	{
		XM_H323_H263_Capability & h263Capability = (XM_H323_H263_Capability &)capability;
		
		if(h263Capability.IsH263PlusCapability())
		{
			H323_RealTimeChannel *realTimeChannel = (H323_RealTimeChannel *)channel;
			realTimeChannel->SetDynamicRTPPayloadType(RTP_DataFrame::DynamicBase);
		}
	}
	
	return channel;
}

BOOL XMH323Connection::OnCreateLogicalChannel(const H323Capability & capability,
											  H323Channel::Directions dir,
											  unsigned & errorCode)
{
	BOOL isValidCapability = TRUE;
	
	if(PIsDescendant(&capability, XM_H323_H261_Capability))
	{
		XM_H323_H261_Capability & h261Capability = (XM_H323_H261_Capability &)capability;
		
		isValidCapability = h261Capability.IsValidCapabilityForReceiving();
	}
	else if(PIsDescendant(&capability, XM_H323_H263_Capability))
	{
		XM_H323_H263_Capability & h263Capability = (XM_H323_H263_Capability &)capability;
		
		isValidCapability = h263Capability.IsValidCapabilityForReceiving();
	}
	else if(PIsDescendant(&capability, XM_H323_H264_Capability))
	{
		XM_H323_H264_Capability & h264Capability = (XM_H323_H264_Capability &)capability;
		
		isValidCapability = h264Capability.IsValidCapabilityForReceiving();
	}
	
	if(isValidCapability == FALSE)
	{
		errorCode = H245_OpenLogicalChannelReject_cause::e_dataTypeALCombinationNotSupported;
		return FALSE;
	}
	
	return H323Connection::OnCreateLogicalChannel(capability, dir, errorCode);
}

void XMH323Connection::OnSetLocalCapabilities()
{	
	// Only call OnSetLocalCapabilities if not already done
	if(hasSetLocalCapabilities == FALSE)
	{
		H323Connection::OnSetLocalCapabilities();
		hasSetLocalCapabilities = TRUE;
	}
	
	// If the capabilities have already been sent, we won't change
	// anything
	if(hasSentLocalCapabilities == TRUE)
	{
		return;
	}
	
	const PString & remoteApplication = GetRemoteApplication();
	
	BOOL enableH263Plus = FALSE;
	
	if(!remoteApplication.IsEmpty())
	{
		if(remoteApplication.Find("XMeeting") != P_MAX_INDEX)
		{
			enableH263Plus = TRUE;
		}
	}
	
	// Turn the H.263 into an H.263Plus capability if required.
	// This is required since many endpoint send a different
	// H.263 stream when using the H.263Plus capability. Often,
	// this stream cannot be decoded by QuickTime.
	// There is a chance to change the H.263 bitstream before
	// feeding it to QuickTime, however, this method does not
	// yet produce visually good and consistent results.
	if(enableH263Plus == TRUE)
	{
		H323Capability * capability = localCapabilities.FindCapability(XM_MEDIA_FORMAT_H263);
		
		if(capability != NULL)
		{
			XM_H323_H263_Capability *h263Capability = (XM_H323_H263_Capability *)capability;
			h263Capability->SetIsH263PlusCapability(TRUE);
		}
	}
}
