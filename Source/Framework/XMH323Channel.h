/*
 * $Id: XMH323Channel.h,v 1.7 2007/02/13 11:56:09 hfriederich Exp $
 *
 * Copyright (c) 2006-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2007 Hannes Friederich. All rights reserved.
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
				  RTP_Session & rtp,
                  unsigned sessionID);
	
	virtual void OnFlowControl(long bitRateRestriction);
};

#endif // __XM_H323_CHANNEL_H__

