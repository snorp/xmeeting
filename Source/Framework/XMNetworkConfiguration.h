/*
 * $Id: XMNetworkConfiguration.h,v 1.1 2007/01/06 20:41:17 hfriederich Exp $
 *
 * Copyright (c) 2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_NETWORK_CONFIGURATION_H__
#define __XM_NETWORK_CONFIGURATION_H__

#define XM_NOT_REACHABLE 0
#define XM_REACHABLE 1
#define XM_DIRECT_REACHABLE 2

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

/**
 * Returns the current reachablility status (as defined above)
 * for the given address pair
 **/
int XMGetReachabilityStatusForAddresses(const in_addr *localAddress,
										const in_addr *remoteAddress);

#endif // __XM_NETWORK_CONFIGURATION_H__

