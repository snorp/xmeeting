/*
 * $Id: XMH323Connection.h,v 1.2 2005/11/30 23:49:46 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_H323_CONNECTION_H__
#define __XM_H323_CONNECITON_H__

#include <ptlib.h>
#include <h323/h323con.h>

class XMH323Connection : public H323Connection
{
	PCLASSINFO(XMH323Connection, H323Connection);
	
public:
	
	XMH323Connection(OpalCall & call,
					 H323EndPoint & endpoint,
					 const PString & token,
					 const PString & alias,
					 const H323TransportAddress & address,
					 unsigned options = 0);
	
	virtual void OnSendCapabilitySet(H245_TerminalCapabilitySet & pdu);

	virtual BOOL OpenLogicalChannel(const H323Capability & capability,
									unsigned sessionID,
									H323Channel::Directions dir);
};

#endif // __XM_H323_CONNECTION_H__

