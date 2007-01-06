/*
 * $Id: XMNetworkConfiguration.cpp,v 1.1 2007/01/06 20:41:17 hfriederich Exp $
 *
 * Copyright (c) 2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2007 Hannes Friederich. All rights reserved.
 */

#include "XMNetworkConfiguration.h"

#include <SystemConfiguration/SystemConfiguration.h>

int XMGetReachabilityStatusForAddresses(const in_addr *localAddress,
										const in_addr *remoteAddress)
{
	struct sockaddr_in localAddr;
	memset(&localAddr, 0, sizeof(localAddr));
	localAddr.sin_len = sizeof(localAddr);
	localAddr.sin_family = AF_INET;
	localAddr.sin_addr = *localAddress;

	struct sockaddr_in remoteAddr;
	memset(&remoteAddr, 0, sizeof(remoteAddr));
	remoteAddr.sin_len = sizeof(remoteAddr);
	remoteAddr.sin_family = AF_INET;
	remoteAddr.sin_addr = *remoteAddress;
	
	SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithAddressPair(NULL, (const sockaddr *)&localAddr, 
																						  (const sockaddr *)&remoteAddr);
	SCNetworkConnectionFlags flags;
	SCNetworkReachabilityGetFlags(reachabilityRef, &flags);
	
	int result = XM_NOT_REACHABLE;
	if(flags & kSCNetworkFlagsReachable) {
		if(flags & kSCNetworkFlagsIsDirect) {
			result = XM_DIRECT_REACHABLE;
		} else {
			result = XM_REACHABLE;
		}
	}
	CFRelease(reachabilityRef);
	
	return result;
}

