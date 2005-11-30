/*
 * $Id: XMH323Connection.cpp,v 1.3 2005/11/30 23:49:46 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#include "XMH323Connection.h"

#include <asn/h245.h>
#include "XMMediaFormats.h"

XMH323Connection::XMH323Connection(OpalCall & call,
								   H323EndPoint & endPoint,
								   const PString & token,
								   const PString & alias,
								   const H323TransportAddress & address,
								   unsigned options)
: H323Connection(call, endPoint, token, alias, address, options)
{
}

void XMH323Connection::OnSendCapabilitySet(H245_TerminalCapabilitySet & pdu)
{
	cout << "***********\nCapabilitySet: " << endl << pdu << endl;
	H323Connection::OnSendCapabilitySet(pdu);
}

BOOL XMH323Connection::OpenLogicalChannel(const H323Capability & capability,
										  unsigned sessionID,
										  H323Channel::Directions dir)
{
	if(PIsDescendant(&capability, XM_H323_H263_Capability))
	{
		cout << "Is H.263" << endl;
		return FALSE;
	}
	return H323Connection::OpenLogicalChannel(capability, sessionID, dir);
}