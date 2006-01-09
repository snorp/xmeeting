/*
 * $Id: XMRTPPacket.h,v 1.1 2006/01/09 22:22:57 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_RTP_PACKET_H__
#define __XM_RTP_PACKET_H__

#include <ptlib.h>
#include <rtp/rtp.h>

class XMRTPPacket : public RTP_DataFrame
{
	PCLASSINFO(XMRTPPacket, RTP_DataFrame);
	
public:
	
	XMRTPPacket(PINDEX payloadSize = 2000);
	
	XMRTPPacket *prev;
	XMRTPPacket *next;
};

#endif // __XM_RTP_PACKET_H__