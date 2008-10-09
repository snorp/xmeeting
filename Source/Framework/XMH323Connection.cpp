/*
 * $Id: XMH323Connection.cpp,v 1.39 2008/10/09 20:18:21 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#include "XMH323Connection.h"

#include <asn/h245.h>
#include <codec/rfc2833.h>
#include <opal/patch.h>

#include "XMOpalManager.h"
#include "XMMediaFormats.h"
#include "XMH323EndPoint.h"
#include "XMH323Channel.h"
#include "XMBridge.h"

XMH323Connection::XMH323Connection(OpalCall & call,
                                   H323EndPoint & endPoint,
                                   const PString & token,
                                   const PString & alias,
                                   const H323TransportAddress & address,
                                   unsigned options,
                                   OpalConnection::StringOptions * stringOptions)
: H323Connection(call, endPoint, token, alias, address, options, stringOptions),
  initialBandwidth(XMOpalManager::GetManager()->GetBandwidthLimit()/100),
  inBandDTMFHandler(NULL)
{	
  bandwidthAvailable = initialBandwidth;
}

XMH323Connection::~XMH323Connection()
{
  delete inBandDTMFHandler;
}

void XMH323Connection::OnSendCapabilitySet(H245_TerminalCapabilitySet & pdu)
{
  // TODO: Recheck if this still is necessary
  /*H323Connection::OnSendCapabilitySet(pdu);
	
  const H323Capabilities & localCaps = GetLocalCapabilities();

  for (unsigned i = 0; i < localCaps.GetSize(); i++) {
    H323Capability & h323Capability = localCaps[i];
		
    // Override default Opal behaviour to obtain better NetMeeting compatibility
    if(PIsDescendant(&h323Capability, H323AudioCapability)) {
      H323AudioCapability & audioCap = (H323AudioCapability &)h323Capability;
      audioCap.SetTxFramesInPacket(30);
    }
  }*/
}

void XMH323Connection::SelectDefaultLogicalChannel(const OpalMediaType & mediaType)
{
	// overridden to achieve better capability select behaviour for the video capabilities
	
	/*if(mediaType != OpalDefaultVideoMediaType)
	{
        // Use default capability selection
		H323Connection::SelectDefaultLogicalChannel(mediaType);
		return;
	}*/
	
	/*if(FindChannel(mediaType, false))
	{
        // There exists already a channel for this media type
		return;
	}*/
    
    // Go through the list of local capabilities and search for matching remote capabilities.
    // Among these, pick the one that is ranked highest according to the CompareTo() implementation
	/*for(unsigned i = 0; i < localCapabilities.GetSize(); i++)
	{
		H323Capability & localCapability = localCapabilities[i];
        if(PIsDescendant(&localCapability, XMH323VideoCapability)) // Should always be true
        {
            XMH323VideoCapability & localVideoCapability = (XMH323VideoCapability &)localCapability;
            XMH323VideoCapability *chosenCapability = NULL;
            for(unsigned j = 0; j < remoteCapabilities.GetSize(); j++)
            {
                H323Capability & remoteCapability = remoteCapabilities[j];
                // The two capabilities must be equal (Compare() must return EqualTo)
                // However, The two H.263 capabilities don't return EqualTo when comparing to a H.263 capability
                // of the other flavour. Else, merging of capabilities might not work correctly.
                // To correctly handle all kinds of remote capability sets, they are still treated as compatible
                // capabilities
                if(localVideoCapability == remoteCapability || 
                    (PIsDescendant(&localVideoCapability, XM_H323_H263_Capability) && PIsDescendant(&remoteCapability, XM_H323_H263_Capability)))
                {
                    // Pick the "highest" available capability
                    XMH323VideoCapability & remoteVideoCapability = (XMH323VideoCapability &)remoteCapability;
                    if(chosenCapability == NULL ||
                       remoteVideoCapability.CompareTo(*chosenCapability) == PObject::GreaterThan)
                    {
                        chosenCapability = &remoteVideoCapability;
                    }
                }
            }
        
            // Try to open a channel for the capability. If successful, we're done
            //unsigned sessionID = GetRTPSessionIDForMediaType(mediaType);
            unsigned sessionID = 0;
            if(chosenCapability != NULL && OpenLogicalChannel(*chosenCapability, sessionID, H323Channel::IsTransmitter))
            {
                break;
            }
        }
	}*/
}

bool XMH323Connection::OpenLogicalChannel(const H323Capability & capability,
                                          unsigned sessionID,
                                          H323Channel::Directions dir)
{
  // Override default behaviour to add additional checks if the format is valid for
  // sending. Both the capability and the manager have to agree that it is possible
  // to send the media format described in the capability.
  if(PIsDescendant(&capability, XMH323VideoCapability)) {
    XMH323VideoCapability & videoCapability = (XMH323VideoCapability &)capability;
    if (!videoCapability.IsValidCapabilityForSending() || !XMOpalManager::GetManager()->IsValidFormatForSending(videoCapability.GetMediaFormat())) {
      return false;
    }
  }
  return H323Connection::OpenLogicalChannel(capability, sessionID, dir);
}

H323_RTPChannel * XMH323Connection::CreateRTPChannel(const H323Capability & capability,
                                                     H323Channel::Directions dir,
                                                     RTP_Session & rtp)
{
  // Use a special channel for the video streams, to allow sending flow control information
  if (capability.GetMediaFormat().GetMediaType() == OpalMediaType::Video()) {
    return new XMH323Channel(*this, capability, dir, rtp);
  }
  return H323Connection::CreateRTPChannel(capability, dir, rtp);
}

bool XMH323Connection::OnClosingLogicalChannel(H323Channel & channel)
{
  // TODO: CONSIDER AGAIN!
  // Called if the remote party requests to close the channel.
  // In contrast to the default Opal implementation, we actually
  // DO close the channel. Don't know if this is a bug in Opal or not.
  //RemoveMediaStream(channel.GetMediaStream());
  //channel.Close();
  return H323Connection::OnClosingLogicalChannel(channel);
  //return true;
}

bool XMH323Connection::OnOpenMediaStream(OpalMediaStream & mediaStream)
{
  if(!H323Connection::OnOpenMediaStream(mediaStream)) {
    return false;
  }
  
  // inform the subsystem
  XMOpalManager::GetManager()->OnOpenRTPMediaStream(*this, mediaStream);
	return true;
}

void XMH323Connection::OnClosedMediaStream(const OpalMediaStream & stream)
{
  H323Connection::OnClosedMediaStream(stream);
  XMOpalManager::GetManager()->OnClosedRTPMediaStream(*this, stream);
}

bool XMH323Connection::SetBandwidthAvailable(unsigned newBandwidth, bool force)
{
  bandwidthAvailable = std::min(initialBandwidth, newBandwidth);
  return true;
}

bool XMH323Connection::SendUserInputTone(char tone, unsigned duration)
{
  // Separate RFC2833 is not implemented. Therefore it is used within
  // XMeeting to signal in-band DTMF
  if(sendUserInputMode == OpalConnection::SendUserInputAsSeparateRFC2833 && inBandDTMFHandler != NULL) {
    inBandDTMFHandler->SendTone(tone, duration);
    return true;
  }
	
  return H323Connection::SendUserInputTone(tone, duration);
}

void XMH323Connection::OnPatchMediaStream(bool isSource, OpalMediaPatch & patch)
{
  H323Connection::OnPatchMediaStream(isSource, patch);
	
  // Add the in-band DTMF handler if this is an audio sending stream
  if(!isSource && patch.GetSource().GetMediaFormat().GetMediaType() == OpalMediaType::Audio()) {
    if(inBandDTMFHandler == NULL) {
      inBandDTMFHandler = new XMInBandDTMFHandler();
    }
    patch.AddFilter(inBandDTMFHandler->GetTransmitHandler(), OpalPCM16);
  }
}

void XMH323Connection::CleanUp()
{
  // The normal timeout for the endSession command is 10s, which is acceptable
  // in the normal case. However, if the framework is to be closed, we don't
  // want to wait that long
  endSessionReceived.Signal();
}

void XMH323Connection::CleanUpOnCallEnd()
{
  // Since CleanUpOnCallEnd() may block for a while, we're storing
  // a reference to this connection in the end point.
  XMH323EndPoint * h323EndPoint = XMOpalManager::GetH323EndPoint();
  h323EndPoint->AddReleasingConnection(this);
  H323Connection::CleanUpOnCallEnd();
  h323EndPoint->RemoveReleasingConnection(this);
}
