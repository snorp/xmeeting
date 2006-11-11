/*
 * $Id: XMH323Connection.cpp,v 1.19 2006/11/11 13:23:57 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#include "XMH323Connection.h"

#include <asn/h245.h>
#include <codec/rfc2833.h>

#include "XMOpalManager.h"
#include "XMMediaFormats.h"
#include "XMTransmitterMediaPatch.h"
#include "XMH323Channel.h"
#include "XMBridge.h"
#include "XMRFC2833Handler.h"

XMH323Connection::XMH323Connection(OpalCall & call,
								   H323EndPoint & endPoint,
								   const PString & token,
								   const PString & alias,
								   const H323TransportAddress & address,
								   unsigned options)
: H323Connection(call, endPoint, token, alias, address, options)
{
	hasSetLocalCapabilities = FALSE;
	hasSentLocalCapabilities = FALSE;
	
	// setting correct initial bandwidth
	SetBandwidthAvailable(XMOpalManager::GetBandwidthLimit() / 100);
	
	delete rfc2833Handler;
	rfc2833Handler = new XMRFC2833Handler(PCREATE_NOTIFIER(OnUserInputInlineRFC2833));
}

XMH323Connection::~XMH323Connection()
{
}

void XMH323Connection::OnSendCapabilitySet(H245_TerminalCapabilitySet & pdu)
{
	H323Connection::OnSendCapabilitySet(pdu);
	
	const H323Capabilities & localCaps = GetLocalCapabilities();
	
	PINDEX i;
	PINDEX count = localCaps.GetSize();
	
	for(i = 0; i < count; i++)
	{
		H323Capability & h323Capability = localCaps[i];
		
		if(PIsDescendant(&h323Capability, XMH323VideoCapability))
		{
			XMH323VideoCapability & videoCap = (XMH323VideoCapability &)h323Capability;
			videoCap.OnSendingTerminalCapabilitySet(pdu);
		}
	}
	
	hasSentLocalCapabilities = TRUE;
}

BOOL XMH323Connection::OnReceivedCapabilitySet(const H323Capabilities & remoteCaps,
											   const H245_MultiplexCapability *muxCap,
											   H245_TerminalCapabilitySetReject & reject)
{
	BOOL result = H323Connection::OnReceivedCapabilitySet(remoteCaps, muxCap, reject);
	
	unsigned i;
	unsigned count = remoteCaps.GetSize();
	for(i = 0; i < count; i++)
	{
		H323Capability & h323Capability = remoteCaps[i];
		
		if(PIsDescendant(&h323Capability, XMH323VideoCapability))
		{
			XMH323VideoCapability & videoCap = (XMH323VideoCapability &)h323Capability;
			const H245_H2250Capability & h2250Capability = (const H245_H2250Capability &)*muxCap;
			videoCap.OnReceivedTerminalCapabilitySet(h2250Capability);
		}
	}

	return result;
}

void XMH323Connection::OnSetLocalCapabilities()
{	
	// Only call OnSetLocalCapabilities if not already done
	if(hasSetLocalCapabilities == FALSE)
	{
		H323Connection::OnSetLocalCapabilities();
		hasSetLocalCapabilities = TRUE;
	}
}

void XMH323Connection::SelectDefaultLogicalChannel(unsigned sessionID)
{
	// overridden to achieve better capability select behaviour
	
	if(sessionID == OpalMediaFormat::DefaultAudioSessionID)
	{
		H323Connection::SelectDefaultLogicalChannel(sessionID);
		return;
	}
	
	if(FindChannel(sessionID, FALSE))
	{
		return;
	}
		
	for(PINDEX i = 0; i < localCapabilities.GetSize(); i++)
	{
		H323Capability & localCapability = localCapabilities[i];
		if(localCapability.GetDefaultSessionID() == sessionID)
		{
			if(PIsDescendant(&localCapability, XMH323VideoCapability))
			{
				XMH323VideoCapability & localVideoCapability = (XMH323VideoCapability &)localCapability;
				XMH323VideoCapability *chosenCapability = NULL;
				for(PINDEX j = 0; j < remoteCapabilities.GetSize(); j++)
				{
					H323Capability & remoteCapability = remoteCapabilities[j];
					if(localVideoCapability == remoteCapability || 
					   (PIsDescendant(&localVideoCapability, XM_H323_H263_Capability) && PIsDescendant(&remoteCapability, XM_H323_H263_Capability)))
					{
						XMH323VideoCapability & remoteVideoCapability = (XMH323VideoCapability &)remoteCapability;
						if(chosenCapability == NULL)
						{
							chosenCapability = &remoteVideoCapability;
						}
						else if(remoteVideoCapability.CompareTo(*chosenCapability) == PObject::GreaterThan)
						{
							chosenCapability = &remoteVideoCapability;
						}
					}
				}
			
				if(chosenCapability != NULL && OpenLogicalChannel(*chosenCapability, sessionID, H323Channel::IsTransmitter))
				{
					break;
				}
			}
		}
	}
}

BOOL XMH323Connection::OpenLogicalChannel(const H323Capability & capability,
										  unsigned sessionID,
										  H323Channel::Directions dir)
{
	BOOL isValidCapability = TRUE;
	if(PIsDescendant(&capability, XMH323VideoCapability))
	{
		XMH323VideoCapability & videoCapability = (XMH323VideoCapability &)capability;
		isValidCapability = videoCapability.IsValidCapabilityForSending();
		if(isValidCapability)
		{
			XMOpalManager & manager = (XMOpalManager &)GetEndPoint().GetManager();
			isValidCapability = manager.IsValidCapabilityForSending(videoCapability);
		}
	}
	
	if(isValidCapability == FALSE)
	{
		return FALSE;
	}
	
	BOOL result = H323Connection::OpenLogicalChannel(capability, sessionID, dir);
	return result;
}

H323Channel *XMH323Connection::CreateRealTimeLogicalChannel(const H323Capability & capability,
															H323Channel::Directions dir,
															unsigned sessionID,
															const H245_H2250LogicalChannelParameters * param,
															RTP_QOS * rtpqos)
{
	if(PIsDescendant(&capability, XMH323VideoCapability))
	{
		RTP_Session * session;
		
		if (param != NULL) 
		{
			// We only support unicast IP at this time.
			if (param->m_mediaControlChannel.GetTag() != H245_TransportAddress::e_unicastAddress)
			{
				return NULL;
			}
			
			const H245_UnicastAddress & uaddr = param->m_mediaControlChannel;
			if (uaddr.GetTag() != H245_UnicastAddress::e_iPAddress)
			{
				return NULL;
			}
			
			sessionID = param->m_sessionID;
		}
		
		session = UseSession(GetControlChannel(), sessionID, rtpqos);
		if (session == NULL)
		{
			return NULL;
		}
		
		((RTP_UDP *) session)->Reopen(dir == H323Channel::IsReceiver);
		
		XMH323Channel *theChannel = new XMH323Channel(*this, capability, dir, *session);
		
		if(PIsDescendant(&capability, XM_H323_H263_Capability))
		{
			XM_H323_H263_Capability & h323Cap = (XM_H323_H263_Capability &)capability;
			if(h323Cap.IsH263PlusCapability())
			{
				theChannel->SetDynamicRTPPayloadType(96);
			}
		}
		else if(PIsDescendant(&capability, XM_H323_H264_Capability))
		{
			theChannel->SetDynamicRTPPayloadType(97);
		}
		
		return theChannel;
	}
	
	H323Channel *channel = H323Connection::CreateRealTimeLogicalChannel(capability,
																		dir,
																		sessionID,
																		param,
																		rtpqos);
	return channel;
}

BOOL XMH323Connection::OnCreateLogicalChannel(const H323Capability & capability,
											  H323Channel::Directions dir,
											  unsigned & errorCode)
{
	BOOL isValidCapability = TRUE;
	
	if(PIsDescendant(&capability, XMH323VideoCapability))
	{
		XMH323VideoCapability & videoCapability = (XMH323VideoCapability &)capability;
		
		isValidCapability = videoCapability.IsValidCapabilityForReceiving();
	}
	
	if(isValidCapability == FALSE)
	{
		errorCode = H245_OpenLogicalChannelReject_cause::e_dataTypeALCombinationNotSupported;
		return FALSE;
	}
	
	return H323Connection::OnCreateLogicalChannel(capability, dir, errorCode);
}

BOOL XMH323Connection::OnClosingLogicalChannel(H323Channel & channel)
{
	RemoveMediaStream(channel.GetMediaStream());
	channel.Close();
	return TRUE;
}

BOOL XMH323Connection::OnOpenMediaStream(OpalMediaStream & mediaStream)
{
	if(!H323Connection::OnOpenMediaStream(mediaStream))
	{
		return FALSE;
	}
	
	if(phase == ConnectedPhase)
	{
		SetPhase(EstablishedPhase);
		OnEstablished();
	}
	
	return TRUE;
}

BOOL XMH323Connection::SetBandwidthAvailable(unsigned newBandwidth, BOOL force)
{
	bandwidthAvailable = newBandwidth;
	XMOpalManager::SetAvailableBandwidth(100*newBandwidth);
	return TRUE;
}

unsigned XMH323Connection::GetBandwidthUsed() const
{
	return 0;
}

BOOL XMH323Connection::SetBandwidthUsed(unsigned releasedBandwidth, unsigned requiredBandwidth)
{
	return TRUE;
}