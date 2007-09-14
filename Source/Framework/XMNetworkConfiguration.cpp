/*
 * $Id: XMNetworkConfiguration.cpp,v 1.3 2007/09/14 13:03:09 hfriederich Exp $
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
    if (interface.GetAddress() == destination) {
      newInterfaces.Append(&interface);
      return newInterfaces;
    }
  }
  
  PIPSocket::RouteTable routeTable;
  PIPSocket::GetRouteTable(routeTable);
  PIPSocket::RouteEntry * route = NULL;
  DWORD address = (DWORD) destination;
  
  for (PINDEX i = 0; i < routeTable.GetSize(); i++) {
    PIPSocket::RouteEntry & routeEntry = routeTable[i];
    DWORD network = (DWORD) routeEntry.GetNetwork();
    DWORD netmask = (DWORD) routeEntry.GetNetMask();
    
    if ((address & netmask) == network) {
      if (route == NULL) {
        route = &routeEntry;
      } else if (netmask > route->GetNetMask()) {
        route = &routeEntry;
      }
    }
  }
  
  if (route != NULL) {
    for (PINDEX i = 0; i < interfaces.GetSize(); i++) {
      PIPSocket::InterfaceEntry & interface = interfaces[i];
      if (interface.GetName() == route->GetInterface()) {
        newInterfaces.Append(&interface);
        break;
      }
    }
  }
  
  return newInterfaces;
}

