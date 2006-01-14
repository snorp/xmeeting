/*
 * $Id: XMRTPH264Packetizer.h,v 1.1 2006/01/14 13:25:59 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_H264_PACKETIZER_H__
#define __XM_H264_PACKETIZER_H__

#include <QuickTime/QuickTime.h>

#define kXMRTPH264PacketizerComponentType kRTPMediaPacketizerType
#define kXMRTPH264PacketizerComponentSubType 'h264'
#define kXMRTPH264PacketizerComponentManufacturer 'XMet'

#define kXMRTPH264PacketizerType 'h264'

/**
* Registering the XMH264Packetizer QuickTime Component
 * so that it can be used when needed.
 **/
Boolean XMRegisterRTPH264Packetizer();


#endif // __XM_H264_PACKETIZER_H__

