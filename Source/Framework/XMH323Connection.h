/*
 * $Id: XMH323Connection.h,v 1.26 2008/10/10 07:32:15 hfriederich Exp $
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
    
  virtual H323_RTPChannel * CreateRTPChannel(const H323Capability & capability,
                                             H323Channel::Directions dir,
                                             RTP_Session & rtp);
	
  virtual bool OnClosingLogicalChannel(H323Channel & channel);
	
  // Propagate opening/closing of media streams to the Obj-C world
  virtual bool OnOpenMediaStream(OpalMediaStream & stream);
  virtual void OnClosedMediaStream(const OpalMediaStream & stream);
	
  // Overridden to circumvent the default Opal bandwidth management
  virtual bool SetBandwidthAvailable(unsigned newBandwidth, bool force = false);
  virtual unsigned GetBandwidthUsed() const { return 0; }
  virtual bool SetBandwidthUsed(unsigned releasedBandwidth, unsigned requiredBandwidth) { return true; }
	
  // Overridden to being able to send in-band DTMF
  virtual bool SendUserInputTone(char tone, unsigned duration);
  virtual void OnPatchMediaStream(bool isSource, OpalMediaPatch & patch);
    
  // Improved clean up when closing the framework
  void CleanUp();
  virtual void CleanUpOnCallEnd();
	
private:
	
  unsigned initialBandwidth;
  XMInBandDTMFHandler * inBandDTMFHandler;
};

#endif // __XM_H323_CONNECTION_H__

