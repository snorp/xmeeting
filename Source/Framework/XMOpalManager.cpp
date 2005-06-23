/*
 * $Id: XMOpalManager.cpp,v 1.5 2005/06/23 12:35:56 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#include "XMProcess.h"
#include "XMTypes.h"
#include "XMOpalManager.h"
#include "XMCallbackBridge.h"
#include "XMVideoDevices.h"

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
	pcssEP = NULL;
	h323EP = NULL;
}

XMOpalManager::~XMOpalManager()
{
	delete pcssEP;
	delete h323EP;
}

void XMOpalManager::Initialise()
{
	pcssEP = new XMPCSSEndPoint(*this);
	h323EP = new XMH323EndPoint(*this);
	AddRouteEntry("pc:.*   = h323:<da>");
	AddRouteEntry("h323:.* = pc:<da>");
}

#pragma mark Access to Endpoints

XMH323EndPoint * XMOpalManager::H323EndPoint()
{
	return h323EP;
}

XMPCSSEndPoint * XMOpalManager::PCSSEndPoint()
{
	return pcssEP;
}

#pragma mark overriding some callbacks

BOOL XMOpalManager::OnIncomingConnection(OpalConnection & connection)
{	
	XMCallProtocol protocol;
	
	// determining which protocoll we are using
	// (currently only H.323)
	PString prefix = connection.GetEndPoint().GetPrefixName();
	if(prefix == "h323")
	{
		protocol = XMCallProtocol_H323;
	}
	else
	{
		protocol = XMCallProtocol_Unknown;
	}
	
	// telling the PCSSEndPoint which protocol we use so
	// that the endpoint can forward this information
	// when needed
	pcssEP->SetCallProtocol(protocol);
	
	return OpalManager::OnIncomingConnection(connection);
}

void XMOpalManager::OnEstablishedCall(OpalCall & call)
{	
	unsigned callID = call.GetToken().AsUnsigned();
	noteCallEstablished(callID);
	OpalManager::OnEstablishedCall(call);
}

void XMOpalManager::OnClearedCall(OpalCall & call)
{
	unsigned callID = call.GetToken().AsUnsigned();
	noteCallCleared(callID, (XMCallEndReason)call.GetCallEndReason());
	OpalManager::OnClearedCall(call);
}

void XMOpalManager::OnEstablished(OpalConnection & connection)
{
	cout << "XMOpalManager::OnEstablished" << endl;
	OpalManager::OnEstablished(connection);
}

void XMOpalManager::OnConnected(OpalConnection & connection)
{
	cout << "XMOpalManager::OnConnected" << endl;
	OpalManager::OnConnected(connection);
}

void XMOpalManager::OnReleased(OpalConnection & connection)
{
	cout << "XMOpalManager::OnReleased" << endl;
	OpalManager::OnReleased(connection);
	
	unsigned callID = connection.GetCall().GetToken().AsUnsigned();
	XMCallEndReason endReason = (XMCallEndReason)connection.GetCall().GetCallEndReason();
	cout << "endReason " << endReason << endl;
	noteCallCleared(callID, endReason);
}

BOOL XMOpalManager::OnOpenMediaStream(OpalConnection & connection, OpalMediaStream & stream)
{
	// first, we want to find out whether we are interested in this media stream or not
	// We are only interested in the external codecs and not the internal PCM-16
	// and RGB24/YUV420P formats
	PString format = stream.GetMediaFormat();
	if(!(format == OpalPCM16 
		 || format == "RGB24" 
		 || format == "YUV420P"))
	{
		unsigned callID = connection.GetCall().GetToken().AsUnsigned();
		noteMediaStreamOpened(callID, stream.IsSource(), format);
	}
	
	return OpalManager::OnOpenMediaStream(connection, stream);
}

void XMOpalManager::OnClosedMediaStream(OpalMediaStream & stream)
{
	//noteMediaStreamClosed(0, stream.IsSource(), stream.GetMediaFormat());
	cout << "media stream closed: " << stream.GetMediaFormat() << endl;
	OpalManager::OnClosedMediaStream(stream);
}

#pragma mark Network setup functions

void XMOpalManager::SetBandwidthLimit(unsigned limit)
{
	if(limit == 0)
	{
		limit = UINT_MAX;
	}
	else
	{
		limit *= 100;
	}
	cout << "setting bandwidth limit to " << limit << endl;
	h323EP->SetInitialBandwidth(limit);
}

#pragma mark Audio functions

const PString & XMOpalManager::GetSoundChannelPlayDevice()
{
	return pcssEP->GetSoundChannelPlayDevice();
}

BOOL XMOpalManager::SetSoundChannelPlayDevice(const PString & name)
{
	return pcssEP->SetSoundChannelPlayDevice(name);
}

const PString & XMOpalManager::GetSoundChannelRecordDevice()
{
	return pcssEP->GetSoundChannelRecordDevice();
}

BOOL XMOpalManager::SetSoundChannelRecordDevice(const PString & name)
{
	return pcssEP->SetSoundChannelRecordDevice(name);
}

unsigned XMOpalManager::GetSoundChannelBufferDepth()
{
	return pcssEP->GetSoundChannelBufferDepth();
}

void XMOpalManager::SetSoundChannelBufferDepth(unsigned depth)
{
	pcssEP->SetSoundChannelBufferDepth(depth);
}

#pragma mark Video setup functions

void XMOpalManager::SetVideoFunctionality(BOOL receiveVideo, BOOL transmitVideo)
{	
	if(receiveVideo)
	{
		autoStartReceiveVideo = TRUE;
		PVideoDevice::OpenArgs video = GetVideoOutputDevice();
		video.deviceName = "XMVideo";
		SetVideoOutputDevice(video);
	}
	else
	{
		autoStartReceiveVideo = FALSE;
	}
	
	if(transmitVideo)
	{
		autoStartTransmitVideo = TRUE;
		PVideoDevice::OpenArgs video = GetVideoInputDevice();
		video.deviceName = "XMVideo";
		SetVideoInputDevice(video);
	}
	else
	{
		autoStartTransmitVideo = FALSE;
	}
}