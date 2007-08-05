/*
 * $Id: XMRFC2833Handler.h,v 1.2 2007/08/05 13:14:36 hfriederich Exp $
 *
 * Copyright (c) 2006-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_RFC2833_HANDLER_H__
#define __XM_RFC2833_HANDLER_H__

#include <ptlib.h>
#include <codec/rfc2833.h>

class XMRFC2833Handler : public OpalRFC2833Proto
{
	PCLASSINFO(XMRFC2833Handler, OpalRFC2833Proto);
	
public:
	
	XMRFC2833Handler(OpalConnection & connection,
                     const PNotifier & notifier);
	
protected:
	
	void ReceivedPacket(RTP_DataFrame & frame, INT i);
	
};

#endif // __XM_RFC2833_HANDLER_H__

