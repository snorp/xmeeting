/*
 * $Id: XMH323Connection.h,v 1.8 2006/05/16 21:32:36 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_H323_CONNECTION_H__
#define __XM_H323_CONNECITON_H__

#include <ptlib.h>
#include <h323/h323con.h>

#include <h323/h323neg.h>

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
	~XMH323Connection();
	
	virtual void OnSendCapabilitySet(H245_TerminalCapabilitySet & pdu);
	virtual BOOL OnReceivedCapabilitySet(const H323Capabilities & remoteCaps,
										 const H245_MultiplexCapability *muxCap,
										 H245_TerminalCapabilitySetReject & reject);
	
	virtual void OnSetLocalCapabilities();

	virtual void SelectDefaultLogicalChannel(unsigned sessionID);
	
	virtual BOOL OpenLogicalChannel(const H323Capability & capability,
									unsigned sessionID,
									H323Channel::Directions dir);
	virtual H323Channel * CreateRealTimeLogicalChannel(const H323Capability & capability,
													   H323Channel::Directions dir,
													   unsigned sessionID,
													   const H245_H2250LogicalChannelParameters * param,
													   RTP_QOS * rtpqos = NULL);
	
	virtual BOOL OnCreateLogicalChannel(const H323Capability & capability,
										H323Channel::Directions dir,
										unsigned & errorCode);
	
	virtual BOOL OnOpenMediaStream(OpalMediaStream & stream);
	
	// improved bandwidth management
	virtual BOOL SetBandwidthAvailable(unsigned newBandwidth, BOOL force = FALSE);
	virtual unsigned GetBandwidthUsed() const;
	virtual BOOL SetBandwidthUsed(unsigned releasedBandwidth, unsigned requiredBandwidth);
	
private:
	BOOL hasSetLocalCapabilities;
	BOOL hasSentLocalCapabilities;
};

#endif // __XM_H323_CONNECTION_H__

