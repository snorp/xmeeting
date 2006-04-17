/*
 * $Id: XMH323Channel.cpp,v 1.3 2006/04/17 17:51:22 hfriederich Exp $
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