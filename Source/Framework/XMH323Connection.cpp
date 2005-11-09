/*
 * $Id: XMH323Connection.cpp,v 1.2 2005/11/09 20:00:27 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#include "XMH323Connection.h"

#include <asn/h245.h>

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
	H323Connection::OnSendCapabilitySet(pdu);
}