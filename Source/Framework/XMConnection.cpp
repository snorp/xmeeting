/*
 * $Id: XMConnection.cpp,v 1.19 2007/02/13 12:57:52 hfriederich Exp $
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

#include <opal/patch.h>
#include <h224/h224handler.h>
#include <h224/h281handler.h>

XMConnection::XMConnection(OpalCall & call,
						   XMEndPoint & theEndPoint,
						   const PString & token)
: OpalConnection(call, theEndPoint, token),
  endpoint(theEndPoint),
  h261VideoFormat(XM_MEDIA_FORMAT_H261),
  h263VideoFormat(XM_MEDIA_FORMAT_H263),
  h263PlusVideoFormat(XM_MEDIA_FORMAT_H263PLUS),
  h264VideoFormat(XM_MEDIA_FORMAT_H264)
{
    if(theEndPoint.GetEnableSilenceSuppression())
    {
        silenceDetector = new OpalPCM16SilenceDetector;
    }
    
    if(theEndPoint.GetEnableEchoCancellation())
    {
        echoCanceler = new OpalEchoCanceler;
    }
    enableVideo = theEndPoint.GetEnableVideo();
    
    h224Handler = NULL;
    h281Handler = NULL;
    
    // Update the video media format options.
    // At the moment, only bandwidth is actively propagated
    bandwidthAvailable = XMOpalManager::GetManager()->GetBandwidthLimit() / 100;
    h261VideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, XMOpalManager::GetH261BandwidthLimit());
    h263VideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, XMOpalManager::GetH263BandwidthLimit());
    h263PlusVideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, XMOpalManager::GetH263BandwidthLimit());
    h264VideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, XMOpalManager::GetH264BandwidthLimit());
    _XMSetEnableH264LimitedMode(h264VideoFormat, XMOpalManager::GetManager()->GetEnableH264LimitedMode());
}

XMConnection::~XMConnection()
{
	if(h224Handler != NULL) {
		h224Handler->RemoveClient(*h281Handler);
		delete h281Handler;
		delete h224Handler;
		
		h224Handler = NULL;
		h281Handler = NULL;
	}
}

BOOL XMConnection::OnIncomingConnection(unsigned int options, OpalConnection::StringOptions * stringOptions)
{
    return endpoint.OnIncomingConnection(*this, options, stringOptions);
}

BOOL XMConnection::SetUpConnection()
{
	if(ownerCall.GetConnection(0) == this) {
		// We are A-Party
		phase = SetUpPhase;
        unsigned options = OpalConnection::AdjustMediaFormatOptionsEnable;
		if(!OnIncomingConnection(options, NULL)) {
			Release(EndedByCallerAbort);
			return FALSE;
		}
		
		if(!ownerCall.OnSetUp(*this)) {
			Release(EndedByNoAccept);
			return FALSE;
		}
		
		return TRUE;
	}
	else
	{
		PSafePtr<OpalConnection> otherConnection = ownerCall.GetOtherPartyConnection(*this);
		if(otherConnection == NULL) {
			return FALSE;
		}
		
		remotePartyName = ownerCall.GetOtherPartyConnection(*this)->GetRemotePartyName();
		remotePartyAddress = ownerCall.GetOtherPartyConnection(*this)->GetRemotePartyAddress();
		remoteApplication = ownerCall.GetOtherPartyConnection(*this)->GetRemoteApplication();
		
		if(phase < AlertingPhase)
		{
			phase = AlertingPhase;
			endpoint.OnShowIncoming(*this);
			OnAlerting();
		}
		return TRUE;
	}
}

BOOL XMConnection::SetAlerting(const PString & calleeName,
							   BOOL withMedia)
{
	phase = AlertingPhase;
	remotePartyName = calleeName;
	endpoint.OnShowOutgoing(*this);
	return TRUE;
}

BOOL XMConnection::SetConnected()
{
	if(mediaStreams.IsEmpty())
	{
		phase = ConnectedPhase;
	}
	else
	{
		phase = EstablishedPhase;
		OnEstablished();
	}
	
	return TRUE;
}

OpalMediaFormatList XMConnection::GetMediaFormats() const
{
	OpalMediaFormatList mediaFormats;
	
	mediaFormats += OpalPCM16;
	
	if(enableVideo == TRUE)
	{
		mediaFormats += XM_MEDIA_FORMAT_H261;
        mediaFormats += XM_MEDIA_FORMAT_H263;
        mediaFormats += XM_MEDIA_FORMAT_H263PLUS;
        mediaFormats += XM_MEDIA_FORMAT_H264;
	}
	
	mediaFormats += OpalH224;
	
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
        BOOL enableH264LimitedMode = _XMGetEnableH264LimitedMode(h264VideoFormat);
        _XMSetEnableH264LimitedMode(mediaFormat, enableH264LimitedMode);
    }
}

BOOL XMConnection::SetBandwidthAvailable(unsigned newBandwidth, BOOL force)
{
    bandwidthAvailable = std::min(XMOpalManager::GetManager()->GetBandwidthLimit(), newBandwidth);
    
    // Also adjust the bandwidth limits of the video formats
    unsigned videoLimit = (100*bandwidthAvailable - 64000);
    h261VideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, std::min(videoLimit, XMOpalManager::GetH261BandwidthLimit()));
    h263VideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, std::min(videoLimit, XMOpalManager::GetH263BandwidthLimit()));
    h263PlusVideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, std::min(videoLimit, XMOpalManager::GetH263BandwidthLimit()));
    h264VideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, std::min(videoLimit, XMOpalManager::GetH264BandwidthLimit()));
    return TRUE;
}

void XMConnection::AcceptIncoming()
{
	if (!LockReadOnly())
	{
		return;
	}
	if (phase != AlertingPhase)
	{
		UnlockReadOnly();
		return;
	}
	
	LockReadWrite();
	phase = ConnectedPhase;
	UnlockReadWrite();
	UnlockReadOnly();

	OnConnected();
	
	if (!LockReadOnly())
	{
		return;
	}
	if (mediaStreams.IsEmpty())
	{
		UnlockReadOnly();
		return;
	}

	LockReadWrite();
	phase = EstablishedPhase;
	UnlockReadWrite();
	UnlockReadOnly();
	
	OnEstablished();
}

OpalMediaStream * XMConnection::CreateMediaStream(const OpalMediaFormat & mediaFormat,
												  BOOL isSource)
{
	if(mediaFormat.GetMediaType() == OpalDefaultVideoMediaType)
	{
		return new XMMediaStream(mediaFormat, isSource);
	}
	
	if(mediaFormat == OpalH224)
	{
		OpalH224Handler *h224Handler = GetH224Handler();
		return new OpalH224MediaStream(*h224Handler, mediaFormat, isSource);
	}
	
	// if not audio, use the default handling
	if(mediaFormat.GetMediaType() != OpalDefaultAudioMediaType)
	{
		return OpalConnection::CreateMediaStream(mediaFormat, isSource);
	}
	
	// audio stream
	PSoundChannel *soundChannel = CreateSoundChannel(isSource);
	if(soundChannel == NULL)
	{
		return NULL;
	}
	return new OpalAudioMediaStream(mediaFormat, isSource, 2, soundChannel);
}

BOOL XMConnection::OnOpenMediaStream(OpalMediaStream & mediaStream)
{
	if(!OpalConnection::OnOpenMediaStream(mediaStream))
	{
		return FALSE;
	}
	
	if (phase == ConnectedPhase)
	{
		SetPhase(EstablishedPhase);
		OnEstablished();
	}
	
	return TRUE;
}

void XMConnection::OnPatchMediaStream(BOOL isSource, OpalMediaPatch & patch)
{
	if(patch.GetSource().GetMediaType() == OpalDefaultAudioMediaType)
	{
		if(isSource && silenceDetector != NULL) {
			silenceDetector->SetParameters(endpoint.GetManager().GetSilenceDetectParams());
			patch.AddFilter(silenceDetector->GetReceiveHandler(), OpalPCM16);
		}
		if(echoCanceler != NULL)
		{
			int clockRate = patch.GetSource().GetMediaFormat().GetClockRate();
			echoCanceler->SetParameters(endpoint.GetManager().GetEchoCancelParams());
			echoCanceler->SetClockRate(clockRate);
			patch.AddFilter(isSource ? echoCanceler->GetReceiveHandler() : echoCanceler->GetSendHandler(), OpalPCM16);
		}
	}
	
	OpalConnection::OnPatchMediaStream(isSource, patch);
}

PSoundChannel * XMConnection::CreateSoundChannel(BOOL isSource)
{
	return endpoint.CreateSoundChannel(*this, isSource);
}

BOOL XMConnection::SendUserInputString(const PString & value)
{
	// add handler here
	return TRUE;
}

BOOL XMConnection::GetMediaInformation(const OpalMediaType & mediaType, MediaInformation & info) const
{
	if(mediaType == OpalDefaultAudioMediaType)
	{
		// add RFC2833 payload code
		info.payloadType = OpalRFC2833.GetPayloadType();
		return TRUE;
	}
	
	return TRUE;
}

OpalH224Handler * XMConnection::GetH224Handler()
{
	if(h224Handler == NULL) {
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