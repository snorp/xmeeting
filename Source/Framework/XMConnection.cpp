/*
 * $Id: XMConnection.cpp,v 1.2 2005/10/12 21:07:40 hfriederich Exp $
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
  endPoint(theEndPoint)
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
	//endpoint.OnShowIncoming(*this);
	OnAlerting();
	
	return TRUE;
}

BOOL XMConnection::SetAlerting(const PString & calleeName,
							   BOOL withMedia)
{
	cout << "SetAlerting called" << endl;
	phase = AlertingPhase;
	remotePartyName = calleeName;
	// return endpoint.OnShowOutgoing(*this);
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
	return endPoint.GetMediaFormats();
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

BOOL XMConnection::IsMediaBypassPossible(unsigned sessionID) const
{
	return OpalConnection::IsMediaBypassPossible(sessionID);
}

BOOL XMConnection::OpenSourceMediaStream(const OpalMediaFormatList & mediaFormats,
										 unsigned sessionID)
{
	//cout << "OpenSourceMediaStream " << mediaFormats << " and " << sessionID << endl;
	return OpalConnection::OpenSourceMediaStream(mediaFormats, sessionID);
}

OpalMediaStream * XMConnection::OpenSinkMediaStream(OpalMediaStream & source)
{
	//cout << "OpenSinkMediaStream " << source << endl;
	return OpalConnection::OpenSinkMediaStream(source);
}

void XMConnection::StartMediaStreams()
{
	cout << "StartMediaStreams()" << endl;
	OpalConnection::StartMediaStreams();
}

void XMConnection::CloseMediaStreams()
{
	cout << "CloseMediaStreams()" << endl;
	OpalConnection::CloseMediaStreams();
}

void XMConnection::RemoveMediaStreams()
{
	cout << "RemoveMediaStreams()" << endl;
	OpalConnection::RemoveMediaStreams();
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
	return endPoint.CreateSoundChannel(*this, isSource);
}

void XMConnection::OnClosedMediaStream(OpalMediaStream & stream)
{
	cout << "OnClosedpenMediaStream " << stream << endl;
	OpalConnection::OnClosedMediaStream(stream);
}