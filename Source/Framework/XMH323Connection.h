/*
 * $Id: XMH323Connection.h,v 1.19 2007/03/28 07:25:18 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_H323_CONNECTION_H__
#define __XM_H323_CONNECITON_H__

#include <ptlib.h>
#include <h323/h323con.h>

#include <h323/h323neg.h>

#include "XMInBandDTMFHandler.h"

class XMH323Connection : public H323Connection
{
	PCLASSINFO(XMH323Connection, H323Connection);
	
public:
	
	XMH323Connection(OpalCall & call,
					 H323EndPoint & endpoint,
					 const PString & token,
					 const PString & alias,
					 const H323TransportAddress & address,
					 unsigned options = 0,
                     OpalConnection::StringOptions * stringOptions = NULL);
	~XMH323Connection();
	
	virtual void OnSendCapabilitySet(H245_TerminalCapabilitySet & pdu);

	virtual void SelectDefaultLogicalChannel(const OpalMediaType & mediaType);
	
	virtual BOOL OpenLogicalChannel(const H323Capability & capability,
									unsigned sessionID,
									H323Channel::Directions dir);
    
	virtual H323_RTPChannel * CreateRTPChannel(const H323Capability & capability,
                                               H323Channel::Directions dir,
                                               RTP_Session & rtp,
                                               unsigned sessionID);
	
	virtual BOOL OnClosingLogicalChannel(H323Channel & channel);
	
    // Propagate opening of media streams to the Obj-C world
	virtual BOOL OnOpenMediaStream(OpalMediaStream & stream);
	
	// Overridden to circumvent the default Opal bandwidth management
	virtual BOOL SetBandwidthAvailable(unsigned newBandwidth, BOOL force = FALSE);
	virtual unsigned GetBandwidthUsed() const { return 0; }
	virtual BOOL SetBandwidthUsed(unsigned releasedBandwidth, unsigned requiredBandwidth) { return TRUE; }
	
    // Overridden to being able to send in-band DTMF
	virtual BOOL SendUserInputTone(char tone, unsigned duration);
    virtual void OnPatchMediaStream(BOOL isSource, OpalMediaPatch & patch);
    
    // Improved clean up when closing the framework
    void CleanUp();
    virtual void CleanUpOnCallEnd();
	
private:
	
    unsigned initialBandwidth;
	XMInBandDTMFHandler * inBandDTMFHandler;
};

#endif // __XM_H323_CONNECTION_H__

