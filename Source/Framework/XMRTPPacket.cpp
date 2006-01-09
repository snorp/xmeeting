/*
 * $Id: XMRTPPacket.cpp,v 1.1 2006/01/09 22:22:57 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#include "XMRTPPacket.h"

XMRTPPacket::XMRTPPacket(PINDEX payloadSize)
: RTP_DataFrame(payloadSize)
{
}