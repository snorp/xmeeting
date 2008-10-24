/*
 * $Id: XMH323Connection.cpp,v 1.44 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#include "XMH323Connection.h"

#include <asn/h245.h>
#include <codec/rfc2833.h>
#include <opal/patch.h>

#include "XMOpalManager.h"
#include "XMMediaFormats.h"
#include "XMH323EndPoint.h"
#include "XMH323Channel.h"
#include "XMBridge.h"
#include "XMReceiverMediaPatch.h"
#include "XMConnection.h"

XMH323Connection::XMH323Connection(OpalCall & call,
                                   H323EndPoint & endPoint,
                                   const PString & token,
                                   const PString & alias,
                                   const H323TransportAddress & address,
                                   unsigned options,
                                   OpalConnection::StringOptions * stringOptions)
: H323Connection(call, endPoint, token, alias, address, options, stringOptions),
  releaseCause(Q931::ErrorInCauseIE),
  inBandDTMFHandler(NULL)
{	
  // restrict the available bandwidth to 2x2 MBit/s to avoid troubles with some gatekeeperss
  // (this value is sent in the ARQ)
  // bandwidth limit is given in units of 100bit/s
  unsigned totalBandwidthLimit = XMOpalManager::GetManager()->GetBandwidthLimit();
  initialBandwidth = std::min(totalBandwidthLimit/50, (unsigned)40000);
  SetBandwidthAvailable(initialBandwidth);
}

XMH323Connection::~XMH323Connection()
{
  delete inBandDTMFHandler;
}

H323_RTPChannel * XMH323Connection::CreateRTPChannel(const H323Capability & capability,
                                                     H323Channel::Directions dir,
                                                     RTP_Session & rtp)
{
  // Use a special channel for the video streams, to allow sending flow control information
  if (capability.GetMediaFormat().GetMediaType() == OpalMediaType::Video()) {
    return new XMH323Channel(*this, capability, dir, rtp);
  }
  return H323Connection::CreateRTPChannel(capability, dir, rtp);
}

bool XMH323Connection::OnClosingLogicalChannel(H323Channel & channel)
{
  // TODO: CONSIDER AGAIN!
  // Called if the remote party requests to close the channel.
  // In contrast to the default Opal implementation, we actually
  // DO close the channel. Don't know if this is a bug in Opal or not.
  //RemoveMediaStream(channel.GetMediaStream());
  //channel.Close();
  return H323Connection::OnClosingLogicalChannel(channel);
  //return true;
}

bool XMH323Connection::OnOpenMediaStream(OpalMediaStream & mediaStream)
{
  if (!H323Connection::OnOpenMediaStream(mediaStream)) {
    return false;
  }
  
  // inform the subsystem
  XMOpalManager::GetManager()->OnOpenRTPMediaStream(*this, mediaStream);
	return true;
}

void XMH323Connection::OnClosedMediaStream(const OpalMediaStream & stream)
{
  H323Connection::OnClosedMediaStream(stream);
  XMOpalManager::GetManager()->OnClosedRTPMediaStream(*this, stream);
}

bool XMH323Connection::SetBandwidthAvailable(unsigned newBandwidth, bool force)
{
  bandwidthAvailable = std::min(initialBandwidth, newBandwidth);
  
  PSafePtr<OpalConnection> conn = GetOtherPartyConnection();
  if (conn != NULL) {
    conn->SetBandwidthAvailable(bandwidthAvailable);
  }
  return true;
}

bool XMH323Connection::SendUserInputTone(char tone, unsigned duration)
{
  // Separate RFC2833 is not implemented. Therefore it is used within
  // XMeeting to signal in-band DTMF
  if (sendUserInputMode == OpalConnection::SendUserInputAsSeparateRFC2833 && inBandDTMFHandler != NULL) {
    inBandDTMFHandler->SendTone(tone, duration);
    return true;
  }
	
  return H323Connection::SendUserInputTone(tone, duration);
}

void XMH323Connection::OnPatchMediaStream(bool isSource, OpalMediaPatch & patch)
{
  H323Connection::OnPatchMediaStream(isSource, patch);
	
  // Add the in-band DTMF handler if this is an audio sending stream
  if (!isSource && patch.GetSource().GetMediaFormat().GetMediaType() == OpalMediaType::Audio()) {
    if (inBandDTMFHandler == NULL) {
      inBandDTMFHandler = new XMInBandDTMFHandler();
    }
    patch.AddFilter(inBandDTMFHandler->GetTransmitHandler(), OpalPCM16);
  }
  
  // add the video frame decoding failed notifier
  if (isSource && patch.GetSource().GetMediaFormat().GetMediaType() == OpalMediaType::Video()) {
    if (PIsDescendant(&patch, XMReceiverMediaPatch)) {
      ((XMReceiverMediaPatch &)patch).SetDecodingFailureNotifier(PCREATE_NOTIFIER(OnDecodingVideoFailed));
    }
  }
}

void XMH323Connection::OnReceivedReleaseComplete(const H323SignalPDU & pdu)
{
  releaseCause = pdu.GetQ931().GetCause();
  H323Connection::OnReceivedReleaseComplete(pdu);
  releaseCause = Q931::ErrorInCauseIE;
}

void XMH323Connection::Release(OpalConnection::CallEndReason callEndReason)
{
  if (callEndReason == OpalConnection::EndedByQ931Cause && releaseCause == Q931::CallRejected) {
    callEndReason = OpalConnection::EndedByRefusal;
  }
  H323Connection::Release(callEndReason);
}

void XMH323Connection::OnDecodingVideoFailed(OpalMediaFormat & mediaFormat, INT ignore)
{
  excludedFormats += mediaFormat;
  
  // Request a mode change, use the existing audio / H.224 channels and all available video formats
  PString modePrefix = "";
  OpalMediaStreamPtr audioStream = GetMediaStream(OpalMediaType::Audio(), true);
  OpalMediaStreamPtr h224Stream = GetMediaStream(OpalH224MediaType::MediaType(), true);
  if (audioStream != NULL) {
    modePrefix += audioStream->GetMediaFormat().GetName() + "\t";
  }
  if (h224Stream != NULL) {
    modePrefix += h224Stream->GetMediaFormat().GetName() + "\t";
  }
  PString modes = "";
  OpalMediaFormatList mediaFormats = GetMediaFormats();
  mediaFormats -= excludedFormats;
  for (PINDEX i = 0; i < mediaFormats.GetSize(); i++) {
    const OpalMediaFormat & mediaFormat = mediaFormats[i];
    if (mediaFormat.GetMediaType() == OpalMediaType::Video()) {
      modes += modePrefix + mediaFormat.GetName() + "\n";
    }
  }
  PTRACE(1, "XMH323Con\tRequest mode change since can't decode incoming video stream");
  RequestModeChange(modes);
}

void XMH323Connection::CleanUp()
{
  // The normal timeout for the endSession command is 10s, which is acceptable
  // in the normal case. However, if the framework is to be closed, we don't
  // want to wait that long
  endSessionReceived.Signal();
}

void XMH323Connection::CleanUpOnCallEnd()
{
  // Since CleanUpOnCallEnd() may block for a while, we're storing
  // a reference to this connection in the end point.
  XMH323EndPoint * h323EndPoint = XMOpalManager::GetH323EndPoint();
  h323EndPoint->AddReleasingConnection(this);
  H323Connection::CleanUpOnCallEnd();
  h323EndPoint->RemoveReleasingConnection(this);
}
