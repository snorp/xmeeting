/*
 * $Id: XMPacketBuilder.h,v 1.1 2005/10/12 21:07:40 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_PACKET_BUILDER_H__
#define __XM_PACKET_BUILDER_H__

#include <QuickTime/QuickTime.h>

/**
 * Registering the XMPacketBuilder QuickTime Component
 * so that it can be used where it is needed.
 **/
Boolean XMRegisterPacketBuilder();

/**
 * Fills out componentDescription so that the resulting description
 * can be used to find the XMPacketBuilder component
 **/
Boolean XMGetPacketBuilderComponentDescription(ComponentDescription *componentDescription);

#endif // __XM_PACKET_BUILDER_H__