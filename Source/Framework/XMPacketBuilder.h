/*
 * $Id: XMPacketBuilder.h,v 1.3 2006/01/20 17:17:04 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_PACKET_BUILDER_H__
#define __XM_PACKET_BUILDER_H__

#include <QuickTime/QuickTime.h>

#define kXMPacketBuilderComponentType kRTPPacketBuilderType
#define kXMPacketBuilderComponentSubType 'XMet'
#define kXMPacketBuilderComponentManufacturer 'XMet'

/**
 * Registering the XMPacketBuilder QuickTime Component
 * so that it can be used where it is needed.
 **/
Boolean XMRegisterPacketBuilder();

#endif // __XM_PACKET_BUILDER_H__