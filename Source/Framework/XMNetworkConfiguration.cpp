/*
 * $Id: XMNetworkConfiguration.cpp,v 1.2 2007/09/03 11:36:34 hfriederich Exp $
 *
 * Copyright (c) 2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2007 Hannes Friederich. All rights reserved.
 */

#include "XMNetworkConfiguration.h"

#include <SystemConfiguration/SystemConfiguration.h>

PIPSocket::InterfaceTable XMInterfaceFilter::FilterInterfaces(const PIPSocket::Address & destination,
                                                              PIPSocket::InterfaceTable & interfaces) const
{
  PIPSocket::InterfaceTable newInterfaces;
  newInterfaces.DisallowDeleteObjects();
  
  for (PINDEX i = 0; i < interfaces.GetSize(); i++) {
    PIPSocket::InterfaceEntry & interface = interfaces[i];
    
    PIPSocket::Address localAddress = interface.GetAddress();
    
    if (localAddress.IsLoopback()) {
      continue; // Gets filtered later on
    }
    // don't use non-RFC1918 interfaces if destination is RFC1918
    if (destination.IsRFC1918() && !localAddress.IsRFC1918()) {
      continue;
    }
    
    if (IsReachable(localAddress, destination)) {
      // Valid interface, remove all others
      newInterfaces.Append(&interface);
      break;
    }
  }
  
  return newInterfaces;
}

BOOL XMInterfaceFilter::IsReachable(const PIPSocket::Address & localAddress,
                                    const PIPSocket::Address & remoteAddress) const
{
  in_addr addr = localAddress;
  struct sockaddr_in localAddr;
  memset(&localAddr, 0, sizeof(localAddr));
  localAddr.sin_len = sizeof(localAddr);
  localAddr.sin_family = AF_INET;
  localAddr.sin_addr = addr;
  
  addr = remoteAddress;
  struct sockaddr_in remoteAddr;
  memset(&remoteAddr, 0, sizeof(remoteAddr));
  remoteAddr.sin_len = sizeof(remoteAddr);
  remoteAddr.sin_family = AF_INET;
  remoteAddr.sin_addr = addr;
  
  SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithAddressPair(NULL, (const sockaddr *)&localAddr, 
                                                                                        (const sockaddr *)&remoteAddr);
  SCNetworkConnectionFlags flags;
  SCNetworkReachabilityGetFlags(reachabilityRef, &flags);
  
  BOOL result = FALSE;
  if(flags & kSCNetworkFlagsReachable) {
    result = TRUE;
  }
  
  CFRelease(reachabilityRef);
  
  return result;
}

