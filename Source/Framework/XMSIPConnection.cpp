/*
 * $Id: XMSIPConnection.cpp,v 1.30 2008/10/15 23:25:16 hfriederich Exp $
 *
 * Copyright (c) 2006-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2007 Hannes Friederich. All rights reserved.
 */

#include "XMSIPConnection.h"

#include <opal/mediafmt.h>
#include <opal/patch.h>
#include <sip/sipep.h>
#include <ptclib/enum.h>
#include <codec/rfc2833.h>
#include "XMOpalManager.h"
#include "XMMediaFormats.h"
#include "XMSIPEndPoint.h"

XMSIPConnection::XMSIPConnection(OpalCall & call,
								 SIPEndPoint & endpoint,
								 const PString & token,
								 const SIPURL & address,
								 OpalTransport * transport,
								 unsigned int options,
                                 OpalConnection::StringOptions * stringOptions)

: SIPConnection(call, endpoint, token, address, transport, options, stringOptions)
{
	initialBandwidth = (XMOpalManager::GetManager()->GetBandwidthLimit() / 100);
  bandwidthAvailable = initialBandwidth;
	
  inBandDTMFHandler = NULL;
}

XMSIPConnection::~XMSIPConnection()
{
  delete inBandDTMFHandler;
}

bool XMSIPConnection::OnOpenMediaStream(OpalMediaStream & mediaStream)
{
  if(!SIPConnection::OnOpenMediaStream(mediaStream)) {
    return false;
  }
  
  // inform the subsystem
  XMOpalManager::GetManager()->OnOpenRTPMediaStream(*this, mediaStream);
	return true;
}

void XMSIPConnection::OnClosedMediaStream(const OpalMediaStream & stream)
{
  SIPConnection::OnClosedMediaStream(stream);
  XMOpalManager::GetManager()->OnClosedRTPMediaStream(*this, stream);
}

bool XMSIPConnection::SetBandwidthAvailable(unsigned newBandwidth, bool force)
{
  bandwidthAvailable = std::min(initialBandwidth, newBandwidth);
  return true;
}

bool XMSIPConnection::SendUserInputTone(char tone, unsigned duration)
{
  // Separate RFC2833 is not implemented. Therefore it is used within
  // XMeeting to signal in-band DTMF
  if(sendUserInputMode == OpalConnection::SendUserInputAsSeparateRFC2833 && inBandDTMFHandler != NULL) {
    inBandDTMFHandler->SendTone(tone, duration);
    return true;
  }
	
  return SIPConnection::SendUserInputTone(tone, duration);
}

void XMSIPConnection::OnPatchMediaStream(bool isSource, OpalMediaPatch & patch)
{
  SIPConnection::OnPatchMediaStream(isSource, patch);
	
  // Add the in-band DTMF handler if this is an audio sending stream
  if(!isSource && patch.GetSource().GetMediaFormat().GetMediaType() == OpalMediaType::Audio()) {
    if(inBandDTMFHandler == NULL) {
      inBandDTMFHandler = new XMInBandDTMFHandler();
    }
    patch.AddFilter(inBandDTMFHandler->GetTransmitHandler(), OpalPCM16);
  }
}

void XMSIPConnection::CleanUp()
{
  // TODO: Abort all pending transactions
}

void XMSIPConnection::OnReleased()
{
  XMSIPEndPoint * sipEndPoint = XMOpalManager::GetSIPEndPoint();
  sipEndPoint->AddReleasingConnection(this);
  SIPConnection::OnReleased();
  sipEndPoint->RemoveReleasingConnection(this);
}
