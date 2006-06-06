/*
 * $Id: XMOpalManager.cpp,v 1.28 2006/06/06 16:38:48 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#include "XMOpalManager.h"

#include "XMTypes.h"
#include "XMCallbackBridge.h"
#include "XMMediaFormats.h"
#include "XMSoundChannel.h"
#include "XMTransmitterMediaPatch.h"
#include "XMReceiverMediaPatch.h"
#include "XMProcess.h"

#include <ptlib.h>

#define XM_MAX_BANDWIDTH 1100000

using namespace std;

#pragma mark Init & Deallocation

static XMOpalManager * managerInstance = NULL;

void XMOpalManager::InitOpal(const PString & pTracePath)
{
	static XMProcess *theProcess = NULL;
	
	if(theProcess == NULL)
	{
		PProcess::PreInitialise(0, 0, 0);
		theProcess = new XMProcess;
		
		if(pTracePath != NULL)
		{
			PTrace::Initialise(5, pTracePath, PTrace::Timestamp|PTrace::Thread|PTrace::FileAndLine);
		}
	}
}

XMOpalManager::XMOpalManager()
{
	managerInstance = this;
	
	callEndPoint = NULL;
	h323EndPoint = NULL;
	sipEndPoint = NULL;
	
	connectionToken = "";
	remoteName = "";
	remoteNumber = "";
	remoteAddress = "";
	remoteApplication = "";
}

XMOpalManager::~XMOpalManager()
{
	delete callEndPoint;
	delete h323EndPoint;
	delete sipEndPoint;
}

void XMOpalManager::Initialise()
{
	callEndPoint = new XMEndPoint(*this);
	h323EndPoint = new XMH323EndPoint(*this);
	sipEndPoint = new XMSIPEndPoint(*this);
	AddRouteEntry("xm:.*   = h323:<da>");
	AddRouteEntry("h323:.* = xm:<da>");
	AddRouteEntry("xm:.*   = sip:<da>");
	AddRouteEntry("sip:.*  = xm:<da>");
	
	SetAutoStartTransmitVideo(TRUE);
	SetAutoStartReceiveVideo(TRUE);
}

#pragma mark -
#pragma mark Accessing the manager

XMOpalManager * XMOpalManager::GetManagerInstance()
{
	return managerInstance;
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

XMSIPEndPoint * XMOpalManager::SIPEndPoint()
{
	return sipEndPoint;
}

#pragma mark Getting / Setting Call Information

void XMOpalManager::GetCallInformation(PString & theRemoteName,
									   PString & theRemoteNumber,
									   PString & theRemoteAddress,
									   PString & theRemoteApplication) const
{
	theRemoteName = remoteName;
	theRemoteNumber = remoteNumber;
	theRemoteAddress = remoteAddress;
	theRemoteApplication = remoteApplication;
}

void XMOpalManager::SetCallInformation(const PString & theConnectionToken,
									   const PString & theRemoteName,
									   const PString & theRemoteNumber,
									   const PString & theRemoteAddress,
									   const PString & theRemoteApplication,
									   XMCallProtocol theCallProtocol)
{
	BOOL isValid = FALSE;
	
	if(connectionToken == "")
	{
		connectionToken = theConnectionToken;
		callProtocol = theCallProtocol;
		isValid = TRUE;
	}
	else if(connectionToken == theConnectionToken)
	{
		isValid = TRUE;
	}
	
	if(isValid == TRUE)
	{
		remoteName = theRemoteName;
		remoteNumber = theRemoteNumber;
		remoteAddress = theRemoteAddress;
		remoteApplication = theRemoteApplication;
		
		if(remoteName == "" &&
		   remoteNumber == "" &&
		   remoteAddress == "" &&
		   remoteApplication == "")
		{
			connectionToken = "";
			callProtocol = XMCallProtocol_UnknownProtocol;
		}
	}
}

#pragma mark Getting Call Statistics

void XMOpalManager::GetCallStatistics(XMCallStatisticsRecord *callStatistics)
{
	switch(callProtocol)
	{
		case XMCallProtocol_H323:
			h323EndPoint->GetCallStatistics(callStatistics);
			return;
		case XMCallProtocol_SIP:
			sipEndPoint->GetCallStatistics(callStatistics);
			return;
		default:
			return;
	}
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
	unsigned callID = call.GetToken().AsUnsigned();
	_XMHandleCallCleared(callID, (XMCallEndReason)call.GetCallEndReason());
	OpalManager::OnClearedCall(call);
}

void XMOpalManager::OnReleased(OpalConnection & connection)
{
	OpalManager::OnReleased(connection);
}

BOOL XMOpalManager::OnOpenMediaStream(OpalConnection & connection, OpalMediaStream & stream)
{	
	BOOL result = OpalManager::OnOpenMediaStream(connection, stream);
	
	if(result == TRUE)
	{
		// first, we want to find out whether we are interested in this media stream or not
		// We are only interested in the external codecs and not the internal PCM-16 format
		// and XM_MEDIA_FORMAT_VIDEO
		OpalMediaFormat mediaFormat = stream.GetMediaFormat();
		if(!(mediaFormat == OpalPCM16 ||
			 mediaFormat == XM_MEDIA_FORMAT_VIDEO))
		{
			callID = connection.GetCall().GetToken().AsUnsigned();
			
			if(_XMIsVideoMediaFormat(mediaFormat))
			{
				if(!stream.IsSource())
				{
					XMVideoSize videoSize = _XMGetMediaFormatSize(mediaFormat);
					const char *mediaFormatName = _XMGetMediaFormatName(mediaFormat);
					
					_XMHandleVideoStreamOpened(callID, mediaFormatName, videoSize, false);
				}
			}
			else
			{
				_XMHandleAudioStreamOpened(callID, mediaFormat, stream.IsSource());
			}
		}
	}
	
	return result;
}

void XMOpalManager::OnClosedMediaStream(const OpalMediaStream & stream)
{
	// first, we want to find out whether we are interested in this media stream or not
	// We are only interested in the external codecs and not the internal PCM-16 format
	// and XM_MEDIA_FORMAT_VIDEO
	OpalMediaFormat mediaFormat = stream.GetMediaFormat();
	if(!(mediaFormat == OpalPCM16 ||
		 mediaFormat == XM_MEDIA_FORMAT_VIDEO))
	{
		
		if(_XMIsVideoMediaFormat(mediaFormat))
		{
			_XMHandleVideoStreamClosed(callID, stream.IsSource());
		}
		else
		{
			_XMHandleAudioStreamClosed(callID, stream.IsSource());
		}
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

static unsigned bandwidthLimit = XM_MAX_BANDWIDTH;
static unsigned availableBandwidth = XM_MAX_BANDWIDTH;

void XMOpalManager::SetBandwidthLimit(unsigned limit)
{
	if(limit == 0 || limit > XM_MAX_BANDWIDTH)
	{
		limit = XM_MAX_BANDWIDTH;
	}
	
	bandwidthLimit = limit;
}

unsigned XMOpalManager::GetBandwidthLimit()
{
	return bandwidthLimit;
}

unsigned XMOpalManager::GetVideoBandwidthLimit()
{
	// taking away 64kbit/s for audio
	return XMOpalManager::GetAvailableBandwidth() - 64000;
}

unsigned XMOpalManager::GetAvailableBandwidth()
{
	return availableBandwidth;
}

void XMOpalManager::SetAvailableBandwidth(unsigned bandwidth)
{
	if(availableBandwidth > bandwidth)
	{
		availableBandwidth = bandwidth;
	}
}

void XMOpalManager::ResetAvailableBandwidth()
{
	availableBandwidth = XM_MAX_BANDWIDTH;
}

void XMOpalManager::XMSetSTUNServer(const PString & server)
{	
	PSTUNClient::NatTypes natType = SetSTUNServer(server);
	
	if(server.IsEmpty())
	{
		_XMHandleSTUNInformation(XMNATType_UnknownNAT, "");
	}
	else if(natType == PSTUNClient::UnknownNat)
	{
		_XMHandleSTUNInformation(XMNATType_Error, "");
	}
	else if(GetTranslationAddress().IsValid())
	{
		_XMHandleSTUNInformation((XMNATType)natType, GetTranslationAddress().AsString());
	}
	else
	{
		_XMHandleSTUNInformation(XMNATType_Error, "");
	}
}

#pragma mark Video Setup Methods

void XMOpalManager::SetVideoFunctionality(BOOL newEnableVideoTransmit, BOOL newEnableVideoReceive)
{
	enableVideoTransmit = newEnableVideoTransmit;
	enableVideoReceive = newEnableVideoReceive;
}

#pragma mark -
#pragma mark Information about current Calls

unsigned XMOpalManager::GetKeyFrameIntervalForCurrentCall()
{
	switch (callProtocol)
	{
		case XMCallProtocol_H323:
			return 200;
		case XMCallProtocol_SIP:
			return 60;
		default:
			return 0;
	}
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
	