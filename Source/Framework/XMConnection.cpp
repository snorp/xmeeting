/*
 * $Id: XMConnection.cpp,v 1.4 2005/10/17 17:00:27 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
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
}

XMConnection::~XMConnection()
{
}

BOOL XMConnection::SetUpConnection()
{
	remotePartyName = ownerCall.GetOtherPartyConnection(*this)->GetRemotePartyName();
	remotePartyAddress = ownerCall.GetOtherPartyConnection(*this)->GetRemotePartyAddress();
	remoteApplication = ownerCall.GetOtherPartyConnection(*this)->GetRemoteApplication();
	
	phase = AlertingPhase;
	endpoint.OnShowIncoming(*this);
	OnAlerting();
	
	return TRUE;
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

void XMConnection::InitiateCall()
{
	phase = SetUpPhase;
	if(!OnIncomingConnection())
	{
		Release(EndedByCallerAbort);
	}
	else
	{
		if(!ownerCall.OnSetUp(*this))
		{
			Release(EndedByNoAccept);
		}
	}
}

void XMConnection::AcceptIncoming()
{
	if (!LockReadOnly())
		return;
	
	if (phase != AlertingPhase) {
		UnlockReadOnly();
		return;
	}
	
	LockReadWrite();
	phase = ConnectedPhase;
	UnlockReadWrite();
	UnlockReadOnly();
	
	OnConnected();
	
	if (!LockReadOnly())
		return;
	
	if (mediaStreams.IsEmpty()) {
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
	return new OpalAudioMediaStream(mediaFormat, sessionID, isSource, 20, soundChannel);
}

BOOL XMConnection::OnOpenMediaStream(OpalMediaStream & mediaStream)
{
	if(!OpalConnection::OnOpenMediaStream(mediaStream))
	{
		return FALSE;
	}
	
	if(mediaStream.IsSource())
	{    
		/*OpalMediaPatch * patch = mediaStream.GetPatch();
		if (patch != NULL && mediaStream.GetSessionID() == OpalMediaFormat::DefaultAudioSessionID) 
		{
			silenceDetector->SetParameters(endPoint.GetManager().GetSilenceDetectParams());
			patch->AddFilter(silenceDetector->GetReceiveHandler(), OpalPCM16);
		}*/
	}
	
	return TRUE;
}

PSoundChannel * XMConnection::CreateSoundChannel(BOOL isSource)
{
	return endpoint.CreateSoundChannel(*this, isSource);
}