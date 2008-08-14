/*
 * $Id: XMRFC2833Handler.cpp,v 1.3 2008/08/14 19:57:05 hfriederich Exp $
 *
 * Copyright (c) 2006-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2007 Hannes Friederich. All rights reserved.
 */

#include "XMRFC2833Handler.h"

XMRFC2833Handler::XMRFC2833Handler(OpalRTPConnection & connection,
                                   const PNotifier & notifier)
: OpalRFC2833Proto(connection, notifier)
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

