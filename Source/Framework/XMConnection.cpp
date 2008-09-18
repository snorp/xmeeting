/*
 * $Id: XMConnection.cpp,v 1.26 2008/09/18 23:08:50 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
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

XMConnection::XMConnection(OpalCall & call, XMEndPoint & _endpoint)
: OpalLocalConnection(call, _endpoint, NULL),
  endpoint(_endpoint),
  h261VideoFormat(XM_MEDIA_FORMAT_H261),
  h263VideoFormat(XM_MEDIA_FORMAT_H263),
  h263PlusVideoFormat(XM_MEDIA_FORMAT_H263PLUS),
  h264VideoFormat(XM_MEDIA_FORMAT_H264)
{
    /*if (theEndPoint.GetEnableSilenceSuppression())
    {
        silenceDetector = new OpalPCM16SilenceDetector;
    }*/
    
    /*if (theEndPoint.GetEnableEchoCancellation())
    {
        echoCanceler = new OpalEchoCanceler;
    }
    enableVideo = theEndPoint.GetEnableVideo();*/
    
    h224Handler = NULL;
    h281Handler = NULL;
    
    // Update the video media format options.
    // At the moment, only bandwidth is actively propagated
    bandwidthAvailable = XMOpalManager::GetManager()->GetBandwidthLimit() / 100;
    h261VideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption(), XMOpalManager::GetH261BandwidthLimit());
    h263VideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption(), XMOpalManager::GetH263BandwidthLimit());
    h263PlusVideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption(), XMOpalManager::GetH263BandwidthLimit());
    h264VideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption(), XMOpalManager::GetH264BandwidthLimit());
    _XMSetEnableH264LimitedMode(h264VideoFormat, XMOpalManager::GetManager()->GetEnableH264LimitedMode());
}

XMConnection::~XMConnection()
{
	if (h224Handler != NULL) {
		//h224Handler->RemoveClient(*h281Handler);
		//delete h281Handler;
		//delete h224Handler;
		
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
	OpalMediaFormatList mediaFormats;
	
	mediaFormats += OpalPCM16;
	
	/*if (enableVideo == true)
	{
		mediaFormats += XM_MEDIA_FORMAT_H261;
        mediaFormats += XM_MEDIA_FORMAT_H263;
        mediaFormats += XM_MEDIA_FORMAT_H263PLUS;
        mediaFormats += XM_MEDIA_FORMAT_H264;
	}
	
	mediaFormats += OpalH224;*/
	
	return mediaFormats;
}

void XMConnection::AdjustMediaFormatOptions(OpalMediaFormat & mediaFormat) const
{
    if (mediaFormat == XM_MEDIA_FORMAT_H261) {
        mediaFormat.Merge(h261VideoFormat);
    } else if (mediaFormat == XM_MEDIA_FORMAT_H263) {
        mediaFormat.Merge(h263VideoFormat);
    } else if (mediaFormat == XM_MEDIA_FORMAT_H263PLUS) {
        mediaFormat.Merge(h263PlusVideoFormat);
    } else if (mediaFormat == XM_MEDIA_FORMAT_H264) {
        mediaFormat.Merge(h264VideoFormat);
        bool enableH264LimitedMode = _XMGetEnableH264LimitedMode(h264VideoFormat);
        _XMSetEnableH264LimitedMode(mediaFormat, enableH264LimitedMode);
    }
}

bool XMConnection::SetBandwidthAvailable(unsigned newBandwidth, bool force)
{
    bandwidthAvailable = std::min(XMOpalManager::GetManager()->GetBandwidthLimit(), newBandwidth);
    
    // Also adjust the bandwidth limits of the video formats
    unsigned videoLimit = (100*bandwidthAvailable - 64000);
    h261VideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption(), std::min(videoLimit, XMOpalManager::GetH261BandwidthLimit()));
    h263VideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption(), std::min(videoLimit, XMOpalManager::GetH263BandwidthLimit()));
    h263PlusVideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption(), std::min(videoLimit, XMOpalManager::GetH263BandwidthLimit()));
    h264VideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption(), std::min(videoLimit, XMOpalManager::GetH264BandwidthLimit()));
    return true;
}

OpalMediaStream * XMConnection::CreateMediaStream(const OpalMediaFormat & mediaFormat,
                                                  unsigned sessionID,
                                                  bool isSource)
{
	/*if (mediaFormat.GetMediaType() == OpalDefaultVideoMediaType)
	{
		return new XMMediaStream(*this, mediaFormat, isSource);
	}*/
	
	/*if (mediaFormat == OpalH224)
	{
		OpalH224Handler *h224Handler = GetH224Handler();
		return new OpalH224MediaStream(*this, *h224Handler, mediaFormat, isSource);
	}*/
	
	// if not audio, use the default handling
	/*if (mediaFormat.GetMediaType() != OpalDefaultAudioMediaType)
	{
		return OpalConnection::CreateMediaStream(mediaFormat, isSource);
	}*/
	
	// audio stream
	PSoundChannel *soundChannel = CreateSoundChannel(isSource);
	if (soundChannel == NULL)
	{
		return NULL;
	}
	return new OpalAudioMediaStream(*this, mediaFormat, sessionID, isSource, 2, soundChannel);
}

bool XMConnection::OnOpenMediaStream(OpalMediaStream & mediaStream)
{
	if (!OpalConnection::OnOpenMediaStream(mediaStream))
	{
		return false;
	}
	
	/*if (phase == ConnectedPhase)
	{
		SetPhase(EstablishedPhase);
		OnEstablished();
	}*/
	
	return true;
}

void XMConnection::OnPatchMediaStream(bool isSource, OpalMediaPatch & patch)
{
	/*if (patch.GetSource().GetMediaType() == OpalDefaultAudioMediaType)
	{
		if (isSource && silenceDetector != NULL) {
			silenceDetector->SetParameters(endpoint.GetManager().GetSilenceDetectParams());
			patch.AddFilter(silenceDetector->GetReceiveHandler(), OpalPCM16);
		}
		if (echoCanceler != NULL)
		{
			int clockRate = patch.GetSource().GetMediaFormat().GetClockRate();
			echoCanceler->SetParameters(endpoint.GetManager().GetEchoCancelParams());
			echoCanceler->SetClockRate(clockRate);
			patch.AddFilter(isSource ? echoCanceler->GetReceiveHandler() : echoCanceler->GetSendHandler(), OpalPCM16);
		}
	}*/
	
	OpalConnection::OnPatchMediaStream(isSource, patch);
}

void XMConnection::OnClosedMediaStream(const OpalMediaStream & stream)
{
    OpalConnection::OnClosedMediaStream(stream);
    XMOpalManager::GetManager()->OnClosedRTPMediaStream(*this, stream);
}

PSoundChannel * XMConnection::CreateSoundChannel(bool isSource)
{
	return endpoint.CreateSoundChannel(*this, isSource);
}

bool XMConnection::SendUserInputString(const PString & value)
{
	// add handler here
	return true;
}

/*bool XMConnection::GetMediaInformation(const OpalMediaType & mediaType, MediaInformation & info) const
{
	if (mediaType == OpalDefaultAudioMediaType)
	{
		// add RFC2833 payload code
		info.payloadType = OpalRFC2833.GetPayloadType();
		return true;
	}
	
	return true;
}*/

OpalH224Handler * XMConnection::GetH224Handler()
{
	if (h224Handler == NULL) {
		//h281Handler = new OpalH281Handler();
		//h224Handler = new OpalH224Handler();
		//h224Handler->AddClient(*h281Handler);
		//_XMHandleFECCChannelOpened();
	}
	
	return h224Handler;
}

OpalH281Handler * XMConnection::GetH281Handler()
{
	return h281Handler;
}