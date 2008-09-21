/*
 * $Id: XMSIPConnection.h,v 1.16 2008/09/21 19:37:32 hfriederich Exp $
 *
 * Copyright (c) 2006-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_SIP_CONNECTION_H__
#define __XM_SIP_CONNECTION_H__

#include <ptlib.h>
#include <sip/sipcon.h>
#include <sip/sippdu.h>

#include "XMInBandDTMFHandler.h"

class XMSIPConnection : public SIPConnection
{
	PCLASSINFO(XMSIPConnection, SIPConnection);
	
public:
	
	XMSIPConnection(OpalCall & call,
					SIPEndPoint & endpoint,
					const PString & token,
					const SIPURL & address,
					OpalTransport * transport,
					unsigned int options = 0,
                    OpalConnection::StringOptions * stringOptions = NULL);
	
	~XMSIPConnection();
	
	virtual void OnCreatingINVITE(SIP_PDU & invite);
    
    virtual bool OnSendSDPMediaDescription(const SDPSessionDescription & sdpIn,
                                           const OpalMediaType & mediaType,
                                           SDPSessionDescription & sdpOut);
	
	virtual OpalMediaStream * CreateMediaStream(const OpalMediaFormat & mediaFormat,
                                              bool isSource);
	
    // Propagate opening of media streams to the Obj-C world
	virtual bool OnOpenMediaStream(OpalMediaStream & stream);
		
    // Overridden to circumvent the default Opal bandwidth management
	virtual bool SetBandwidthAvailable(unsigned newBandwidth, bool force = false);
	virtual unsigned GetBandwidthUsed() const { return 0; }
	virtual bool SetBandwidthUsed(unsigned releasedBandwidth, unsigned requiredBandwidth) { return true; }
	
    // Overridden to being able to send in-band DTMF
	virtual bool SendUserInputTone(char tone, unsigned duration);
    virtual void OnPatchMediaStream(bool isSource, OpalMediaPatch & patch);
    
  void CleanUp();
  virtual void OnReleased();
	
private:
	
  unsigned initialBandwidth;
	XMInBandDTMFHandler *inBandDTMFHandler;
};

#endif // __XM_SIP_CONNECTION_H__

