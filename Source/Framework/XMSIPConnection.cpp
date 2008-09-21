/*
 * $Id: XMSIPConnection.cpp,v 1.26 2008/09/21 19:37:32 hfriederich Exp $
 *
 * Copyright (c) 2006-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2007 Hannes Friederich. All rights reserved.
 */

#include "XMSIPConnection.h"

#include <opal/mediafmt.h>
#include <opal/patch.h>
#include <sip/sipep.h>
#include <ptclib/enum.h>
#include <codec/rfc2833.h>
#include "XMOpalManager.h"
#include "XMMediaFormats.h"
#include "XMRFC2833Handler.h"
#include "XMSIPEndPoint.h"

XMSIPConnection::XMSIPConnection(OpalCall & call,
								 SIPEndPoint & endpoint,
								 const PString & token,
								 const SIPURL & address,
								 OpalTransport * transport,
								 unsigned int options,
                                 OpalConnection::StringOptions * stringOptions)

: SIPConnection(call, endpoint, token, address, transport, options, stringOptions)
{
	initialBandwidth = (XMOpalManager::GetManager()->GetBandwidthLimit() / 100);
    bandwidthAvailable = initialBandwidth;
    
    // Delete the default RFC2833 handler and replace it with our own implementation
	delete rfc2833Handler;
	rfc2833Handler = new XMRFC2833Handler(*this, PCREATE_NOTIFIER(OnUserInputInlineRFC2833));
	
	inBandDTMFHandler = NULL;
}

XMSIPConnection::~XMSIPConnection()
{
    delete inBandDTMFHandler;
}

void XMSIPConnection::OnCreatingINVITE(SIP_PDU & invite)
{
    /* Add bandwidth information to SDP */
	/*if(invite.HasSDP()) {
		SDPSessionDescription & sdp = invite.GetSDP();
		unsigned bandwidth = bandwidthAvailable / 10;
        sdp.SetBandwidthModifier(SDPSessionDescription::ApplicationSpecificBandwidthModifier());
        sdp.SetBandwidthValue(bandwidth);
	}*/
}

bool XMSIPConnection::OnSendSDPMediaDescription(const SDPSessionDescription & sdpIn,
												const OpalMediaType & mediaType,
												SDPSessionDescription & sdpOut)
{
	// adjusting bandwidth information,
	// taking the lower value of remote (if set)
	// and own bandwidth limit
	/*PString bandwidthModifier = sdpIn.GetBandwidthModifier();
	if(bandwidthModifier.IsEmpty())
	{
		bandwidthModifier = SDPSessionDescription::ConferenceTotalBandwidthModifier();
	}
	sdpOut.SetBandwidthModifier(bandwidthModifier);
	
	unsigned remoteBandwidth = sdpIn.GetBandwidthValue();
	unsigned localBandwidth = bandwidthAvailable/10;
	if(remoteBandwidth != 0 && remoteBandwidth < localBandwidth)
	{
		SetBandwidthAvailable(10*remoteBandwidth);
	}
	sdpOut.SetBandwidthValue(bandwidthAvailable/10);
	
    return SIPConnection::OnSendSDPMediaDescription(sdpIn, mediaType, sdpOut);*/
  return false;
}

OpalMediaStream * XMSIPConnection::CreateMediaStream(const OpalMediaFormat & mediaFormat,
													 bool isSource)
{
	// Adjust some audio parameters if needed
	/*const SDPMediaDescriptionList & mediaDescriptionList = remoteSDP.GetMediaDescriptions();
	for(PINDEX i = 0; i < mediaDescriptionList.GetSize(); i++)
	{
		SDPMediaDescription & description = mediaDescriptionList[i];
		if(description.GetMediaType() == OpalDefaultAudioMediaType)
		{
			PINDEX packetTime = description.GetPacketTime();
			if(packetTime != 0)
			{
				XMOpalManager::GetManager()->SetCurrentAudioPacketTime(packetTime);
			}
			break;
		}
	}
	
	return SIPConnection::CreateMediaStream(mediaFormat, isSource);*/
  return false;
}

bool XMSIPConnection::OnOpenMediaStream(OpalMediaStream & mediaStream)
{
	if(!SIPConnection::OnOpenMediaStream(mediaStream))
	{
		return false;
	}
    
    XMOpalManager::GetManager()->OnOpenRTPMediaStream(*this, mediaStream);
	
	return true;
}

bool XMSIPConnection::SetBandwidthAvailable(unsigned newBandwidth, bool force)
{
	bandwidthAvailable = std::min(initialBandwidth, newBandwidth);
    GetCall().GetOtherPartyConnection(*this)->SetBandwidthAvailable(bandwidthAvailable, force);
	return true;
}

bool XMSIPConnection::SendUserInputTone(char tone, unsigned duration)
{
    // Separate RFC2833 is not implemented. Therefore it is used within
    // XMeeting to signal in-band DTMF
	if(sendUserInputMode == OpalConnection::SendUserInputAsSeparateRFC2833 &&
	   inBandDTMFHandler != NULL)
	{
		inBandDTMFHandler->SendTone(tone, duration);
		return true;
	}
	
	return SIPConnection::SendUserInputTone(tone, duration);
}

void XMSIPConnection::OnPatchMediaStream(bool isSource, OpalMediaPatch & patch)
{
	SIPConnection::OnPatchMediaStream(isSource, patch);
	
    // Add the in-band DTMF handler if this is an audio sending stream
	/*if(!isSource && patch.GetSource().GetMediaFormat().GetMediaType() == OpalDefaultAudioMediaType)
	{
		if(inBandDTMFHandler == NULL)
		{
			inBandDTMFHandler = new XMInBandDTMFHandler();
		}
		patch.AddFilter(inBandDTMFHandler->GetTransmitHandler(), OpalPCM16);
	}*/
}

void XMSIPConnection::CleanUp()
{
    // Abort all pending transactions
    /*PWaitAndSignal m(jobProcessingMutex);
    for (PINDEX i = transactions.GetSize(); i > 0; i--) {
        const PString & key = transactions.GetKeyAt(i-1);
        transactions[key].Abort();
    }*/
}

void XMSIPConnection::OnReleased()
{
  XMSIPEndPoint * sipEndPoint = XMOpalManager::GetSIPEndPoint();
  sipEndPoint->AddReleasingConnection(this);
  SIPConnection::OnReleased();
  sipEndPoint->RemoveReleasingConnection(this);
}
