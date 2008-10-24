/*
 * $Id: XMConnection.cpp,v 1.41 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#include "XMopalManager.h"
#include "XMConnection.h"
#include "XMEndPoint.h"
#include "XMMediaFormats.h"
#include "XMMediaStream.h"
#include "XMCallbackBridge.h"

#include <ptlib.h>
#include <opal/patch.h>
#include <h224/h224handler.h>
#include <h224/h281handler.h>

class XMPCM16SilenceDetector : public OpalPCM16SilenceDetector
{
  PCLASSINFO(XMPCM16SilenceDetector, OpalPCM16SilenceDetector);
  
public:
  XMPCM16SilenceDetector(const OpalSilenceDetector::Params & params);
  virtual void ReceivedPacket(RTP_DataFrame & frame, INT);
  
private:
  unsigned silenceStartTimestamp;
};

XMConnection::XMConnection(OpalCall & call, XMEndPoint & _endpoint)
: OpalLocalConnection(call, _endpoint, NULL),
  endpoint(_endpoint),
  h261VideoFormat(XM_MEDIA_FORMAT_H261),
  h263VideoFormat(XM_MEDIA_FORMAT_H263),
  h263PlusVideoFormat(XM_MEDIA_FORMAT_H263PLUS),
  h264VideoFormat(XM_MEDIA_FORMAT_H264)
{
  if (endpoint.GetEnableSilenceSuppression()) {
    silenceDetector = new XMPCM16SilenceDetector(endpoint.GetManager().GetSilenceDetectParams());
  }
    
  if (endpoint.GetEnableEchoCancellation()) {
    echoCanceler = new OpalEchoCanceler;
    echoCanceler->SetParameters(endpoint.GetManager().GetEchoCancelParams());
  }
  
  enableVideo = _endpoint.GetEnableVideo();
    
  h224Handler = NULL;
  h281Handler = NULL;
  
  // update the bandwidth information.
  // internal bw is given in units of 100bit/s, both ways.
  // XMeeting uses unit bit/s, one way
  SetBandwidthAvailable(XMOpalManager::GetManager()->GetBandwidthLimit()/50);
}

XMConnection::~XMConnection()
{
	if (h224Handler != NULL) {
		h224Handler->RemoveClient(*h281Handler);
		delete h281Handler;
		delete h224Handler;
		
		h224Handler = NULL;
		h281Handler = NULL;
	}
}

void XMConnection::Release(OpalConnection::CallEndReason callEndReason) {
  if (originating == true && callEndReason == EndedByNoAccept) {
    // This is the release code submitted if ownerCall.OnSetUp() fails in SetUpConnection().
    // Try to find out the call end reason of the other party connection, and
    // inform the framework
    OpalConnection::CallEndReason frameworkCallEndReason = NumCallEndReasons;
    PSafePtr<OpalConnection> otherConnection = GetOtherPartyConnection();
    if (otherConnection != NULL) {
      frameworkCallEndReason = otherConnection->GetCallEndReason();
    }
    if (frameworkCallEndReason == NumCallEndReasons) {
      frameworkCallEndReason = EndedByLocalUser;
    }
    XMOpalManager::GetManager()->HandleCallInitiationFailed((XMCallEndReason)frameworkCallEndReason);
  }
  OpalLocalConnection::Release(callEndReason);
}

OpalMediaFormatList XMConnection::GetMediaFormats() const
{
  // Polycom MGC (Accord MGC) has problems decoding QuickTime H.263. Disable sending H.263 to this MGC for now.
  bool excludeH263 = false;
  PSafePtr<OpalConnection> otherConnection = GetOtherPartyConnection();
  if (otherConnection != NULL) {
    const OpalProductInfo & info = otherConnection->GetRemoteProductInfo();
    if (info.name.Find("ACCORD MGC") != P_MAX_INDEX) {
      excludeH263 = true;
    }
  }
  
	OpalMediaFormatList mediaFormats;
	
	mediaFormats += OpalPCM16;
	
  if (enableVideo == true) {
    mediaFormats += h261VideoFormat;
    if (!excludeH263) {
      mediaFormats += h263VideoFormat;
      mediaFormats += h263PlusVideoFormat;
    }
    mediaFormats += h264VideoFormat;
  }
	
  mediaFormats += GetOpalH224_H323AnnexQ();
  mediaFormats += GetOpalH224_HDLCTunneling();
  
  // Needed to ensure correct media format preference
  AdjustMediaFormats(mediaFormats);
  
  return mediaFormats;
}

OpalMediaStream * XMConnection::CreateMediaStream(const OpalMediaFormat & mediaFormat,
                                                  unsigned sessionID,
                                                  bool isSource)
{
  if (mediaFormat.GetMediaType() == OpalMediaType::Video()) {
    return new XMMediaStream(*this, mediaFormat, sessionID, isSource);
  }
	
  if (mediaFormat.GetMediaType() == OpalH224MediaType::MediaType()) {
    OpalH224Handler *h224Handler = GetH224Handler();
    return new OpalH224MediaStream(*this, *h224Handler, mediaFormat, sessionID, isSource);
	}
	
  // if not audio, use the default handling
  if (mediaFormat.GetMediaType() != OpalMediaType::Audio()) {    
    return OpalConnection::CreateMediaStream(mediaFormat, sessionID, isSource);
  }
  
 	// audio stream
	PSoundChannel *soundChannel = CreateSoundChannel(isSource);
  if (soundChannel == NULL) {
    return NULL;
  }
  return new OpalAudioMediaStream(*this, mediaFormat, sessionID, isSource, 2, soundChannel);
}

void XMConnection::OnPatchMediaStream(bool isSource, OpalMediaPatch & patch)
{
  // add the silence detector and echo canceler if needed
  if (patch.GetSource().GetMediaFormat().GetMediaType() == OpalMediaType::Audio()) {
    if (isSource && silenceDetector != NULL) {
      patch.AddFilter(silenceDetector->GetReceiveHandler(), OpalPCM16);
    }
    if (echoCanceler != NULL) {
      int clockRate = patch.GetSource().GetMediaFormat().GetClockRate();
      echoCanceler->SetClockRate(clockRate);
      patch.AddFilter(isSource ? echoCanceler->GetReceiveHandler() : echoCanceler->GetSendHandler(), OpalPCM16);
    }
  }
	
  OpalConnection::OnPatchMediaStream(isSource, patch);
}

PSoundChannel * XMConnection::CreateSoundChannel(bool isSource)
{
  return endpoint.CreateSoundChannel(*this, isSource);
}

bool XMConnection::SetBandwidthAvailable(unsigned newBandwidth, bool force)
{
  bandwidthAvailable = newBandwidth;
  
  unsigned limit = XMOpalManager::GetManager()->GetVideoBandwidthLimit(h261VideoFormat, bandwidthAvailable*50);
  h261VideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption(), limit);
  limit = XMOpalManager::GetManager()->GetVideoBandwidthLimit(h263VideoFormat, bandwidthAvailable*50);
  h263VideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption(), limit);
  limit = XMOpalManager::GetManager()->GetVideoBandwidthLimit(h263PlusVideoFormat, bandwidthAvailable*50);
  h263PlusVideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption(), limit);
  limit = XMOpalManager::GetManager()->GetVideoBandwidthLimit(h264VideoFormat, bandwidthAvailable*50);
  h264VideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption(), limit);
  
  return true;
}

OpalH224Handler * XMConnection::GetH224Handler()
{
  if (h224Handler == NULL) {
    h281Handler = new OpalH281Handler();
    h224Handler = new OpalH224Handler();
    h224Handler->AddClient(*h281Handler);
    _XMHandleFECCChannelOpened();
  }
	
	return h224Handler;
}

OpalH281Handler * XMConnection::GetH281Handler()
{
  return h281Handler;
}

#pragma mark -
#pragma mark Silence Detector

XMPCM16SilenceDetector::XMPCM16SilenceDetector(const OpalSilenceDetector::Params & params)
: OpalPCM16SilenceDetector(params),
  silenceStartTimestamp(0)
{
}

void XMPCM16SilenceDetector::ReceivedPacket(RTP_DataFrame & frame, INT dummy)
{
  // ensure that data is sent at least every 10 s,
  // avoids closing of NAT pinholes
  unsigned size = frame.GetPayloadSize();
  
  OpalPCM16SilenceDetector::ReceivedPacket(frame, dummy);
  if (inTalkBurst) {
    // reset the silence start timestamp
    silenceStartTimestamp = 0;
  } else {
    unsigned timestamp = frame.GetTimestamp();
    if (silenceStartTimestamp == 0) {
      silenceStartTimestamp = timestamp;
      return;
    }
    
    unsigned silenceTime = timestamp - silenceStartTimestamp;
        
    if (silenceTime >= 10 * OpalMediaFormat::AudioClockRate) {
      frame.SetPayloadSize(size);
      silenceStartTimestamp = 0;
    }
  }
}