/*
 * $Id: XMRTPH263PlusPacketizer.h,v 1.2 2008/10/11 19:03:25 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_RTP_H263PLUS_PACKETIZER_H__
#define __XM_RTP_H263PLUS_PACKETIZER_H__

#include <QuickTime/QuickTime.h>

#define kXMRTPH263PlusPacketizerComponentType kRTPMediaPacketizerType
#define kXMRTPH263PlusPacketizerComponentSubType '+263'
#define kXMRTPH263PlusPacketizerComponentManufacturer 'XMet'

#define kXMRTPH263PlusPacketizerType '+263'

/**
 * Registering the XMRTPH263PlusPacketizer QuickTime Component
 * so that it can be used when needed.
 **/
Boolean XMRegisterRTPH263PlusPacketizer();

#endif // __XM_RTP_H263PLUS_PACKETIZER_H__