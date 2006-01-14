/*
 * $Id: XMRTPH263Packetizer.h,v 1.1 2006/01/14 13:25:59 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_RTP_H263_PACKETIZER_H__
#define __XM_RTP_H263_PACKETIZER_H__

#include <QuickTime/QuickTime.h>

#define kXMRTPH263PacketizerComponentType kRTPMediaPacketizerType
#define kXMRTPH263PacketizerComponentSubType 'h263'
#define kXMRTPH263PacketizerComponentManufacturer 'XMet'

#define kXMRTPH263PacketizerType 'h263'

/**
 * Registering the XMRTPH263Packetizer QuickTime Component
 * so that it can be used when needed.
 **/
Boolean XMRegisterRTPH263Packetizer();

#endif // __XM_RTP_H263_PACKETIZER_H__