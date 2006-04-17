/*
 * $Id: XMH323Channel.h,v 1.3 2006/04/17 17:51:22 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_H323_CHANNEL_H__
#define __XM_H323_CHANNEL_H__

#include <ptlib.h>
#include <h323/channels.h>

class XMH323Channel : public H323_RTPChannel
{
	PCLASSINFO(XMH323Channel, H323_RTPChannel);
	
	XMH323Channel(H323Connection & connection,
				  const H323Capability & capability,
				  Directions direction,
				  RTP_Session & rtp);
	
	virtual BOOL OnReceivedPDU(const H245_H2250LogicalChannelParameters & param, unsigned & errorCode);
	virtual BOOL OnSendingPDU(H245_H2250LogicalChannelParameters & param) const;
};

#endif // __XM_H323_CHANNEL_H__

