/*
 * $Id: XMH323Channel.cpp,v 1.12 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2006-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2008 Hannes Friederich. All rights reserved.
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
                             RTP_Session & rtp)
: H323_RTPChannel(connection, capability, direction, rtp)
{
  // Ensure the dynamic payload type is set if needed.
  RTP_DataFrame::PayloadTypes payloadType = capability.GetPayloadType();
  if(payloadType >= RTP_DataFrame::DynamicBase) {
    SetDynamicRTPPayloadType(payloadType);
  }
}

void XMH323Channel::OnFlowControl(long bitRateRestriction)
{
  if(PIsDescendant(capability, H323VideoCapability)) {
    unsigned requestedLimit = bitRateRestriction*100;
    // obtain the maximum allowed bandwidth for this
    unsigned maxVideoBandwidth = XMOpalManager::GetManager()->GetVideoBandwidthLimit(capability->GetMediaFormat(), 
                                                                                     connection.GetBandwidthAvailable()*50);
    requestedLimit = std::min(requestedLimit, maxVideoBandwidth);
		
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
  } else {
    H323_RTPChannel::OnFlowControl(bitRateRestriction);
  }
}