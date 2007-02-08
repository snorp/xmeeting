/*
 * $Id: XMConnection.cpp,v 1.17 2007/02/08 08:43:34 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

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
  endpoint(theEndPoint)
{
	  if(theEndPoint.EnableSilenceSuppression())
	  {
		  silenceDetector = new OpalPCM16SilenceDetector;
	  }
	  if(theEndPoint.EnableEchoCancellation())
	  {
		  echoCanceler = new OpalEchoCanceler;
	  }
	  
	  h224Handler = NULL;
	  h281Handler = NULL;
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
		if(!OnIncomingConnection(0, NULL)) {
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
	return endpoint.GetMediaFormats();
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

BOOL XMConnection::IsMediaBypassPossible(const OpalMediaType & mediaType) const
{
	return OpalConnection::IsMediaBypassPossible(mediaType);
}

OpalMediaStream * XMConnection::CreateMediaStream(const OpalMediaFormat & mediaFormat,
												  BOOL isSource)
{
	// check for "XMeeting" formats
	if(_XMIsVideoMediaFormat(mediaFormat))
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