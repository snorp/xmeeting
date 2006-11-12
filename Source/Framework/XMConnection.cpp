/*
 * $Id: XMConnection.cpp,v 1.16 2006/11/12 00:17:06 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#include "XMConnection.h"
#include "XMEndPoint.h"
#include "XMMediaFormats.h"
#include "XMMediaStream.h"

#include <opal/patch.h>

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
}

XMConnection::~XMConnection()
{
}

BOOL XMConnection::SetUpConnection()
{
	if(ownerCall.GetConnection(0) == this) {
		// We are A-Party
		phase = SetUpPhase;
		if(!OnIncomingConnection()) {
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

BOOL XMConnection::IsMediaBypassPossible(unsigned sessionID) const
{
	return OpalConnection::IsMediaBypassPossible(sessionID);
}

OpalMediaStream * XMConnection::CreateMediaStream(const OpalMediaFormat & mediaFormat,
											unsigned sessionID,
											BOOL isSource)
{
	// check for "XMeeting" formats
	if(mediaFormat == XM_MEDIA_FORMAT_VIDEO)
	{
		return new XMMediaStream(mediaFormat, sessionID, isSource);
	}
	
	// if not audio, use the default handling
	if(sessionID != OpalMediaFormat::DefaultAudioSessionID)
	{
		return OpalConnection::CreateMediaStream(mediaFormat, sessionID, isSource);
	}
	
	// audio stream
	PSoundChannel *soundChannel = CreateSoundChannel(isSource);
	if(soundChannel == NULL)
	{
		return NULL;
	}
	return new OpalAudioMediaStream(mediaFormat, sessionID, isSource, 2, soundChannel);
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
	if(patch.GetSource().GetSessionID() == OpalMediaFormat::DefaultAudioSessionID)
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

BOOL XMConnection::GetMediaInformation(unsigned sessionID, MediaInformation & info) const
{
	if(sessionID == OpalMediaFormat::DefaultAudioSessionID)
	{
		// add RFC2833 payload code, using 101 as usual
		info.rfc2833 = (RTP_DataFrame::PayloadTypes)101;
		return TRUE;
	}
	
	return FALSE;
}