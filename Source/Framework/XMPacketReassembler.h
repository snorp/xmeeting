/*
 * $Id: XMPacketReassembler.h,v 1.2 2006/01/09 22:22:57 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_PACKET_REASSEMBLER__
#define __XM_PACKET_REASSEMBLER__

#include <QuickTime/QuickTime.h>

#define kXMPacketReassemblerComponentType kRTPReassemblerType
#define kXMPacketReassemblerComponentSubType 'XMet'
#define kXMPacketReassemblerComponentManufacturer 'XMet'

/**
 * Registering the XMPacketReassembler QuickTime Component
 * so that it can be used where it is needed.
 **/
 Boolean XMRegisterPacketReassembler();

#endif // __XM_PACKET_REASSEMBLER__

