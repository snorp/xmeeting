/*
 * $Id: XMPacketReassembler.h,v 1.1 2005/10/11 09:03:10 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_PACKET_REASSEMBLER__
#define __XM_PACKET_REASSEMBLER__

#include <QuickTime/QuickTime.h>

/**
 * Registering the XMPacketBuilder QuickTime Component
 * so that it can be used where it is needed.
 **/
 Boolean XMRegisterPacketReassembler();
 
 /**
 * Fills out componentDescription so that the resulting description
  * can be used to find the XMPacketBuilder component
  **/
 Boolean XMGetPacketReassemblerComponentDescription(ComponentDescription *componentDescription);

#endif // __XM_PACKET_REASSEMBLER__

