/*
 * $Id: XMOpalManager.cpp,v 1.17 2005/10/31 22:11:50 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#include "XMOpalManager.h"

#include "XMTypes.h"
#include "XMCallbackBridge.h"
#include "XMMediaFormats.h"
#include "XMSoundChannel.h"
#include "XMTransmitterMediaPatch.h"
#include "XMReceiverMediaPatch.h"
#include "XMProcess.h"

#include <codec/h261codec.h>

using namespace std;

#pragma mark Init & Deallocation

void XMOpalManager::InitOpal()
{
	static XMProcess *theProcess = NULL;
	
	if(theProcess == NULL)
	{
		PProcess::PreInitialise(0, 0, 0);
		theProcess = new XMProcess;
		
		/* temporarily initialise PTracing */
		PTrace::Initialise(5, "/tmp/XMeeting.log", PTrace::Timestamp|PTrace::Thread|PTrace::FileAndLine);
	}
}

XMOpalManager::XMOpalManager()
{
	callEndPoint = NULL;
	h323EndPoint = NULL;
}

XMOpalManager::~XMOpalManager()
{
	delete callEndPoint;
	delete h323EndPoint;
}

void XMOpalManager::Initialise()
{
	callEndPoint = new XMEndPoint(*this);
	h323EndPoint = new XMH323EndPoint(*this);
	AddRouteEntry("xm:.*   = h323:<da>");
	AddRouteEntry("h323:.* = xm:<da>");
	
	SetAutoStartTransmitVideo(TRUE);
	SetAutoStartReceiveVideo(TRUE);
}

#pragma mark Access to Endpoints

XMEndPoint * XMOpalManager::CallEndPoint()
{
	return callEndPoint;
}

XMH323EndPoint * XMOpalManager::H323EndPoint()
{
	return h323EndPoint;
}

#pragma mark overriding some callbacks

void XMOpalManager::OnEstablishedCall(OpalCall & call)
{	
	BOOL isIncomingCall = TRUE;
	OpalEndPoint & endPoint = call.GetConnection(0, PSafeReadOnly)->GetEndPoint();
	if(PIsDescendant(&endPoint, XMEndPoint))
	{
		isIncomingCall = FALSE;
	}
	unsigned callID = call.GetToken().AsUnsigned();
	_XMHandleCallEstablished(callID, isIncomingCall);
	OpalManager::OnEstablishedCall(call);
}

void XMOpalManager::OnClearedCall(OpalCall & call)
{
	XMSoundChannel::StopChannels();
	unsigned callID = call.GetToken().AsUnsigned();
	_XMHandleCallCleared(callID, (XMCallEndReason)call.GetCallEndReason());
	OpalManager::OnClearedCall(call);
}

BOOL XMOpalManager::OnOpenMediaStream(OpalConnection & connection, OpalMediaStream & stream)
{	
	BOOL result = OpalManager::OnOpenMediaStream(connection, stream);
	
	if(result == TRUE)
	{
		// first, we want to find out whether we are interested in this media stream or not
		// We are only interested in the external codecs and not the internal PCM-16 format
		// and XM_MEDIA_FORMAT_VIDEO
		PString format = stream.GetMediaFormat();
		if(!(format == OpalPCM16 ||
			 format == XM_MEDIA_FORMAT_VIDEO))
		{
			callID = connection.GetCall().GetToken().AsUnsigned();
			_XMHandleMediaStreamOpened(callID, stream.IsSource(), format);
		}
	}
	
	return result;
}

void XMOpalManager::OnClosedMediaStream(const OpalMediaStream & stream)
{
	// first, we want to find out whether we are interested in this media stream or not
	// We are only interested in the external codecs and not the internal PCM-16 format
	// and XM_MEDIA_FORMAT_VIDEO
	PString format = stream.GetMediaFormat();
	if(!(format == OpalPCM16 ||
		 format == XM_MEDIA_FORMAT_VIDEO))
	{
		_XMHandleMediaStreamClosed(callID, stream.IsSource(), format);
	}
	
	OpalManager::OnClosedMediaStream(stream);
}

OpalMediaPatch * XMOpalManager::CreateMediaPatch(OpalMediaStream & source)
{
	if(IsOutgoingMedia(source))
	{
		return new XMTransmitterMediaPatch(source);
	}
	else
	{
		return new XMReceiverMediaPatch(source);
	}
}

#pragma mark General Setup Methods

void XMOpalManager::SetUserName(const PString & username)
{
	OpalManager::SetDefaultUserName(username);
	h323EndPoint->SetDefaultDisplayName(username);
}

#pragma mark Network Setup Methods

void XMOpalManager::SetBandwidthLimit(unsigned limit)
{
	if(limit == 0)
	{
		limit = UINT_MAX;
	}
	
	// taking away the approximative amount of audio bandwidth
	unsigned videoLimit = limit - 64000;
	
	_XMSetMaxVideoBitrate(videoLimit);
}

#pragma mark Video Setup Methods

void XMOpalManager::SetVideoFunctionality(BOOL newEnableVideoTransmit, BOOL newEnableVideoReceive)
{
	enableVideoTransmit = newEnableVideoTransmit;
	enableVideoReceive = newEnableVideoReceive;
}

#pragma mark Private Methods

BOOL XMOpalManager::IsOutgoingMedia(OpalMediaStream & stream)
{
	OpalMediaFormat mediaFormat = stream.GetMediaFormat();
	OpalMediaFormatList outgoingMediaFormats = callEndPoint->GetMediaFormats();
	
	if(outgoingMediaFormats.FindFormat(mediaFormat) != P_MAX_INDEX)
	{
		return TRUE;
	}
	
	return FALSE;
}
	