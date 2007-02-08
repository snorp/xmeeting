/*
 * $Id: XMH323Channel.cpp,v 1.6 2007/02/08 08:43:34 hfriederich Exp $
 *
 * Copyright (c) 2006-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2007 Hannes Friederich. All rights reserved.
 */

#include "XMH323Channel.h"

#include <asn/h245.h>
#include <opal/mediastrm.h>
#include <h323/h323pdu.h>

#include "XMOpalManager.h"
#include "XMMediaFormats.h"
#include "XMReceiverMediaPatch.h"
#include "XMCallbackBridge.h"

XMH323Channel::XMH323Channel(H323Connection & connection,
							 const H323Capability & capability,
							 Directions direction,
							 RTP_Session & rtp,
                             unsigned sessionID)
: H323_RTPChannel(connection, capability, direction, rtp, sessionID)
{
}

BOOL XMH323Channel::OnReceivedPDU(const H245_H2250LogicalChannelParameters & param, unsigned & errorCode)
{
	if(PIsDescendant(capability, XMH323VideoCapability))
	{
		XMH323VideoCapability *videoCap = (XMH323VideoCapability *)capability;
		
		videoCap->OnReceivedPDU(param);
	}
	
	return H323_RTPChannel::OnReceivedPDU(param, errorCode);
}

BOOL XMH323Channel::OnSendingPDU(H245_H2250LogicalChannelParameters & param) const
{
	BOOL result = H323_RTPChannel::OnSendingPDU(param);
	
	if(result == FALSE)
	{
		return FALSE;
	}
	
	if(PIsDescendant(capability, XMH323VideoCapability))
	{
		XMH323VideoCapability * videoCap = (XMH323VideoCapability *)capability;
		
		videoCap->OnSendingPDU(param);
	}
	
	return TRUE;
}

BOOL XMH323Channel::Start() 
{
	BOOL result = H323_RTPChannel::Start();
	if(result == TRUE) 
	{
		mediaStream->SetCommandNotifier(PCREATE_NOTIFIER(OnMediaCommand));
	}
	
	return result;
}

void XMH323Channel::OnFlowControl(long bitRateRestriction)
{
	if(PIsDescendant(capability, XMH323VideoCapability))
	{
		unsigned requestedLimit = bitRateRestriction*100;
		long videoBandwidthLimit = XMOpalManager::GetVideoBandwidthLimit();
		if(requestedLimit > videoBandwidthLimit)
		{
			requestedLimit = videoBandwidthLimit;
		}
		
		H323_RTPChannel::OnFlowControl(requestedLimit/100);
		_XMSetMaxVideoBitrate(requestedLimit);
		
		// Send a FlowControlIndication out
		H323ControlPDU pdu;
		H245_FlowControlIndication & indication = (H245_FlowControlIndication &)pdu.Build(H245_IndicationMessage::e_flowControlIndication);
		indication.m_scope.SetTag(H245_FlowControlIndication_scope::e_logicalChannelNumber);
		H245_LogicalChannelNumber & number = indication.m_scope;
		number = GetNumber();
		indication.m_restriction.SetTag(H245_FlowControlIndication_restriction::e_maximumBitRate);
		PASN_Integer & integer = indication.m_restriction;
		integer = (requestedLimit/100);
		connection.WriteControlPDU(pdu);
	}
	else
	{
		H323_RTPChannel::OnFlowControl(bitRateRestriction);
	}
}