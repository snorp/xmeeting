/*
 * $Id: XMH323Channel.cpp,v 1.2 2006/02/20 17:27:48 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#include "XMH323Channel.h"

#include <asn/h245.h>

#include "XMMediaFormats.h"
#include "XMTransmitterMediaPatch.h"
#include "XMReceiverMediaPatch.h"

XMH323Channel::XMH323Channel(H323Connection & connection,
							 const H323Capability & capability,
							 Directions direction,
							 RTP_Session & rtp)
: H323_RTPChannel(connection, capability, direction, rtp)
{
}

BOOL XMH323Channel::OnReceivedPDU(const H245_OpenLogicalChannel & openPDU,
								  unsigned & errorCode)
{
	BOOL result = H323_RealTimeChannel::OnReceivedPDU(openPDU, errorCode);
	
	if(result == TRUE)
	{
		if(!PIsDescendant(capability, XM_H323_H263_Capability))
		{
			return TRUE;
		}
		
		XMReceiverMediaPatch::SetIsRFC2429(FALSE);
		
		const H245_OpenLogicalChannel_forwardLogicalChannelParameters_multiplexParameters & multiplexParameters =
		openPDU.m_forwardLogicalChannelParameters.m_multiplexParameters;
		
		if(multiplexParameters.GetTag() != 
			H245_OpenLogicalChannel_forwardLogicalChannelParameters_multiplexParameters::e_h2250LogicalChannelParameters)
		{
			return TRUE;
		}
		
		const H245_H2250LogicalChannelParameters & h2250LogicalChannelParameters = multiplexParameters;
		
		if(!h2250LogicalChannelParameters.HasOptionalField(H245_H2250LogicalChannelParameters::e_mediaPacketization))
		{
			return TRUE;
		}
		
		const H245_H2250LogicalChannelParameters_mediaPacketization & mediaPacketization = 
			h2250LogicalChannelParameters.m_mediaPacketization;
		
		if(mediaPacketization.GetTag() != H245_H2250LogicalChannelParameters_mediaPacketization::e_rtpPayloadType)
		{
			return TRUE;
		}
		
		const H245_RTPPayloadType & rtpPayloadType = mediaPacketization;
		const H245_RTPPayloadType_payloadDescriptor & payloadDescriptor = rtpPayloadType.m_payloadDescriptor;
		
		if(payloadDescriptor.GetTag() != H245_RTPPayloadType_payloadDescriptor::e_rfc_number)
		{
			return TRUE;
		}
		
		const PASN_Integer & rfcValue = payloadDescriptor;
		
		if(rfcValue.GetValue() == 2429)
		{
			XMReceiverMediaPatch::SetIsRFC2429(TRUE);
		}
		
		return TRUE;
	}
	
	return result;
}

BOOL XMH323Channel::OnSendingPDU(H245_OpenLogicalChannel & openPDU) const
{
	BOOL result = H323_RealTimeChannel::OnSendingPDU(openPDU);
	
	if(result == FALSE)
	{
		return FALSE;
	}
	
	H245_OpenLogicalChannel_forwardLogicalChannelParameters_multiplexParameters & multiplexParameters =
		openPDU.m_forwardLogicalChannelParameters.m_multiplexParameters;
	
	if(multiplexParameters.GetTag() !=
	   H245_OpenLogicalChannel_forwardLogicalChannelParameters_multiplexParameters::e_h2250LogicalChannelParameters)
	{
		cout << "Not H2250LogicalChannelParameters" << endl;
		return FALSE;
	}
	
	H245_H2250LogicalChannelParameters & h2250LogicalChannelParameters = multiplexParameters;
	
	h2250LogicalChannelParameters.RemoveOptionalField(H245_H2250LogicalChannelParameters::e_silenceSuppression);
	
	if(PIsDescendant(capability, XM_H323_H263_Capability))
	{
		if(XMTransmitterMediaPatch::GetH263PayloadType() == RTP_DataFrame::H263)
		{
			return TRUE;
		}
		
		h2250LogicalChannelParameters.IncludeOptionalField(H245_H2250LogicalChannelParameters::e_mediaPacketization);
		H245_H2250LogicalChannelParameters_mediaPacketization & mediaPacketization = 
			h2250LogicalChannelParameters.m_mediaPacketization;
		
		mediaPacketization.SetTag(H245_H2250LogicalChannelParameters_mediaPacketization::e_rtpPayloadType);
		
		H245_RTPPayloadType & rtpPayloadType = mediaPacketization;
		
		H245_RTPPayloadType_payloadDescriptor & payloadDescriptor = rtpPayloadType.m_payloadDescriptor;
		
		payloadDescriptor.SetTag(H245_RTPPayloadType_payloadDescriptor::e_rfc_number);
		PASN_Integer & rfcValue = payloadDescriptor;
		rfcValue.SetValue(2429);
		
		rtpPayloadType.IncludeOptionalField(H245_RTPPayloadType::e_payloadType);
		rtpPayloadType.m_payloadType = RTP_DataFrame::DynamicBase;
		
	}
	
	return TRUE;
}