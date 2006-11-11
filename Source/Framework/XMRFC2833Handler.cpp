/*
 * $Id: XMRFC2833Handler.cpp,v 1.1 2006/11/11 13:23:57 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#include "XMRFC2833Handler.h"

XMRFC2833Handler::XMRFC2833Handler(const PNotifier & notifier)
: OpalRFC2833Proto(notifier)
{
}

void XMRFC2833Handler::ReceivedPacket(RTP_DataFrame & frame, INT value)
{
	OpalRFC2833Proto::ReceivedPacket(frame, value);
	
	if(frame.GetPayloadType() == payloadType)
	{
		frame.SetPayloadSize(0);
	}
}

