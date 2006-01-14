/*
 * $Id: XMH323Connection.cpp,v 1.6 2006/01/14 13:25:59 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#include "XMH323Connection.h"

#include <asn/h245.h>

#include "XMMediaFormats.h"
#include "XMTransmitterMediaPatch.h"

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
	
	H245_MultiplexCapability & multiplexCapability = pdu.m_multiplexCapability;
	H245_H2250Capability & h2250Capability = (H245_H2250Capability &)multiplexCapability;
	H245_MediaPacketizationCapability & mediaPacketizationCapability = h2250Capability.m_mediaPacketizationCapability;
	mediaPacketizationCapability.IncludeOptionalField(H245_MediaPacketizationCapability::e_rtpPayloadType);
	H245_ArrayOf_RTPPayloadType & arrayOfRTPPayloadType = mediaPacketizationCapability.m_rtpPayloadType;
	arrayOfRTPPayloadType.SetSize(3);
	
	// Signal the ability to handle RFC 2429 packets (H.263).
	// Using RFC 2429 does work also without that signal, but it's better if this is present
	H245_RTPPayloadType & h263PayloadType = arrayOfRTPPayloadType[0];
	H245_RTPPayloadType_payloadDescriptor & h263Descriptor = h263PayloadType.m_payloadDescriptor;
	h263Descriptor.SetTag(H245_RTPPayloadType_payloadDescriptor::e_rfc_number);
	PASN_Integer & h263Integer = (PASN_Integer &)h263Descriptor;
	h263Integer.SetValue(2429);
	
	// Signal the H.264 packetization modes understood by this endpoint
	H245_RTPPayloadType & h264PayloadTypeSingleNAL = arrayOfRTPPayloadType[1];
	H245_RTPPayloadType_payloadDescriptor & h264DescriptorSingleNAL = h264PayloadTypeSingleNAL.m_payloadDescriptor;
	h264DescriptorSingleNAL.SetTag(H245_RTPPayloadType_payloadDescriptor::e_oid);
	PASN_ObjectId & h264ObjectIdSingleNAL = (PASN_ObjectId &)h264DescriptorSingleNAL;
	h264ObjectIdSingleNAL.SetValue("0.0.8.241.0.0.0.0");
	
	H245_RTPPayloadType & h264PayloadTypeNonInterleaved = arrayOfRTPPayloadType[2];
	H245_RTPPayloadType_payloadDescriptor & h264DescriptorNonInterleaved = h264PayloadTypeNonInterleaved.m_payloadDescriptor;
	h264DescriptorNonInterleaved.SetTag(H245_RTPPayloadType_payloadDescriptor::e_oid);
	PASN_ObjectId & h264ObjectIdNonInterleaved = (PASN_ObjectId &)h264DescriptorNonInterleaved;
	h264ObjectIdNonInterleaved.SetValue("0.0.8.241.0.0.0.1");
	
	hasSentLocalCapabilities = TRUE;
}

BOOL XMH323Connection::OnReceivedCapabilitySet(const H323Capabilities & remoteCaps,
											   const H245_MultiplexCapability *muxCap,
											   H245_TerminalCapabilitySetReject & reject)
{
	BOOL result = H323Connection::OnReceivedCapabilitySet(remoteCaps, muxCap, reject);
	
	XMTransmitterMediaPatch::SetH264PacketizationMode(XM_H264_PACKETIZATION_MODE_SINGLE_NAL);
	
	if(result == TRUE && muxCap != NULL && muxCap->GetTag() == H245_MultiplexCapability::e_h2250Capability)
	{
		const H245_H2250Capability & h2250Capability = *muxCap;
		const H245_MediaPacketizationCapability & mediaPacketizationCapability = h2250Capability.m_mediaPacketizationCapability;
		
		if(mediaPacketizationCapability.HasOptionalField(H245_MediaPacketizationCapability::e_rtpPayloadType))
		{
			const H245_ArrayOf_RTPPayloadType & arrayOfRTPPayloadType = mediaPacketizationCapability.m_rtpPayloadType;
			PINDEX size = arrayOfRTPPayloadType.GetSize();
			PINDEX i;
			
			for(i = 0; i < size; i++)
			{
				const H245_RTPPayloadType & payloadType = arrayOfRTPPayloadType[i];
				const H245_RTPPayloadType_payloadDescriptor & payloadDescriptor = payloadType.m_payloadDescriptor;
				if(payloadDescriptor.GetTag() == H245_RTPPayloadType_payloadDescriptor::e_oid)
				{
					const PASN_ObjectId & objectId = payloadDescriptor;
					if(objectId == "0.0.8.241.0.0.0.1")
					{
						XMTransmitterMediaPatch::SetH264PacketizationMode(XM_H264_PACKETIZATION_MODE_NON_INTERLEAVED);
						break;
					}
				}
			}
		}
	}
	
	return result;
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
		RTP_DataFrame::PayloadTypes payloadType;
		if(isValidCapability == TRUE)
		{
			if(h263Capability.IsH263PlusCapability())
			{
				payloadType = RTP_DataFrame::DynamicBase;
			}
			else
			{
				payloadType = RTP_DataFrame::H263;
			}
			XMTransmitterMediaPatch::SetH263PayloadType(payloadType);
		}
	}
	else if(PIsDescendant(&capability, XM_H323_H264_Capability))
	{
		XM_H323_H264_Capability & h264Capability = (XM_H323_H264_Capability &)capability;
		isValidCapability = h264Capability.IsValidCapabilityForSending();
		if(isValidCapability == TRUE && XMTransmitterMediaPatch::GetH264PacketizationMode() == XM_H264_PACKETIZATION_MODE_NON_INTERLEAVED)
		{
			XMTransmitterMediaPatch::SetH264Parameters(h264Capability.GetProfile(), h264Capability.GetLevel());
		}
		else
		{
			isValidCapability = FALSE;
		}
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
		/*H323Capability * capability = localCapabilities.FindCapability(XM_MEDIA_FORMAT_H263);
		
		if(capability != NULL)
		{
			XM_H323_H263_Capability *h263Capability = (XM_H323_H263_Capability *)capability;
			h263Capability->SetIsH263PlusCapability(TRUE);
		}*/
	}
}
