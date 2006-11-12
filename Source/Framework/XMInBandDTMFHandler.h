/*
 * $Id: XMInBandDTMFHandler.h,v 1.1 2006/11/12 00:19:10 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_IN_BAND_DTMF_HANDLER_H__
#define __XM_IN_BAND_DTMF_HANDLER_H__

#include <ptlib.h>
#include <ptclib/dtmf.h>
#include <rtp/rtp.h>

class XMInBandDTMFHandler : public PObject
{
	PCLASSINFO(XMInBandDTMFHandler, PObject);
	
public:
	
	XMInBandDTMFHandler();
	
	BOOL SendTone(char tone, unsigned duration);
	
	const PNotifier & GetTransmitHandler() const;
	
protected:
    PDECLARE_NOTIFIER(RTP_DataFrame, XMInBandDTMFHandler, TransmitPacket);
	
	PNotifier transmitHandler;
	
private:
	PMutex mutex;
	PDTMFEncoder * tones;
	unsigned startTimestamp;
	
};

#endif // __XM_IN_BAND_DTMF_HANDLER_H__

