/*
 * $Id: XMSIPConnection.cpp,v 1.13 2006/11/10 21:43:06 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#include "XMSIPConnection.h"

#include <opal/mediafmt.h>
#include <sip/sipep.h>
#include <ptclib/enum.h>
#include "XMOpalManager.h"
#include "XMMediaFormats.h"

XMSIPConnection::XMSIPConnection(OpalCall & call,
								 SIPEndPoint & endpoint,
								 const PString & token,
								 const SIPURL & address,
								 OpalTransport * transport)
: SIPConnection(call, endpoint, token, address, transport),
  h261VideoFormat(_XMMediaFormat_H261, RTP_DataFrame::H261, _XMMediaFormatEncoding_H261, 352, 288, 30, _XMGetMaxH261BitRate()),
  h263VideoFormat(_XMMediaFormat_H263, RTP_DataFrame::H263, _XMMediaFormatEncoding_H263, 352, 288, 30, _XMGetMaxH263BitRate()),
  h263PlusVideoFormat(_XMMediaFormat_H263Plus, (RTP_DataFrame::PayloadTypes)96, _XMMediaFormatEncoding_H263Plus, 352, 288, 30, _XMGetMaxH263BitRate()),
  h264VideoFormat(_XMMediaFormat_H264, (RTP_DataFrame::PayloadTypes)97, _XMMediaFormatEncoding_H264, 352, 288, 30, _XMGetMaxH264BitRate())
{
	SetBandwidthAvailable(XMOpalManager::GetBandwidthLimit() / 100);
}

XMSIPConnection::~XMSIPConnection()
{
}

/**
 * This methods is mostly a copy from
 * SIPConnection::SetUpConnection() with the only
 * difference that a difference method is called
 * for CreateConnection()
 **/
BOOL XMSIPConnection::SetUpConnection()
{
	SIPURL transportAddress = targetAddress;
	
	PTRACE(2, "SIP\tSetUpConnection: " << remotePartyAddress);
	
	// Do a DNS SRV lookup
#if P_DNS
    PIPSocketAddressAndPortVector addrs;
    if (PDNS::LookupSRV(targetAddress.GetHostName(), "_sip._udp", targetAddress.GetPort(), addrs))
	{
		transportAddress.SetHostName(addrs[0].address.AsString());
		transportAddress.SetPort(addrs [0].port);
    }
#endif
	PStringList routeSet = GetRouteSet();
	if (!routeSet.IsEmpty()) 
	{
		transportAddress = routeSet[0];
	}
	
	originating = TRUE;
	
	delete transport;
	XMSIPEndPoint & xmEP = (XMSIPEndPoint &)endpoint;
	transport = xmEP.XMCreateTransport(transportAddress.GetHostAddress());
	lastTransportAddress = transportAddress.GetHostAddress();
	if (transport == NULL)
	{
		Release(EndedByTransportFail);
		return FALSE;
	}
	
	if (!transport->WriteConnect(WriteINVITE, this))
	{
		PTRACE(1, "SIP\tCould not write to " << targetAddress << " - " << transport->GetErrorText());
		Release(EndedByTransportFail);
		return FALSE;
	}
	
	releaseMethod = ReleaseWithCANCEL;
	return TRUE;
}

void XMSIPConnection::OnCreatingINVITE(SIP_PDU & invite)
{
	if(invite.HasSDP()) {
		SDPSessionDescription & sdp = invite.GetSDP();
		AdjustSessionDescription(sdp);
	}
}

BOOL XMSIPConnection::OnSendSDPMediaDescription(const SDPSessionDescription & sdpIn,
												SDPMediaDescription::MediaType mediaType,
												unsigned sessionID,
												SDPSessionDescription & sdpOut)
{
	// adjusting bandwidth information,
	// taking the lower value of remote (if set)
	// and own bandwidth limit
	PString bandwidthModifier = sdpIn.GetBandwidthModifier();
	if(bandwidthModifier.IsEmpty())
	{
		bandwidthModifier = SDPSessionDescription::ConferenceTotalBandwidthModifier;
	}
	sdpOut.SetBandwidthModifier(bandwidthModifier);
	
	unsigned remoteBandwidth = sdpIn.GetBandwidthValue();
	unsigned localBandwidth = bandwidthAvailable/10;
	if(remoteBandwidth != 0 && remoteBandwidth < localBandwidth)
	{
		SetBandwidthAvailable(10*remoteBandwidth);
	}
	sdpOut.SetBandwidthValue(bandwidthAvailable/10);
	
	if(mediaType != SDPMediaDescription::Video)
	{
		return SIPConnection::OnSendSDPMediaDescription(sdpIn, mediaType, sessionID, sdpOut);
	}
	else
	{
		// Set default values
		h261VideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, _XMGetMaxH261BitRate());
		h261VideoFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption, 3003);
		h261VideoFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::CIFWidth);
		h261VideoFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::CIFHeight);
		h263VideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, _XMGetMaxH263BitRate());
		h263VideoFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption, 3003);
		h263VideoFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::CIFWidth);
		h263VideoFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::CIFHeight);
		h263PlusVideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, _XMGetMaxH263BitRate());
		h263PlusVideoFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption, 3003);
		h263PlusVideoFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::CIFWidth);
		h263PlusVideoFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::CIFHeight);
		h264VideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, _XMGetMaxH264BitRate());
		h264VideoFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption, 3003);
		h264VideoFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::CIFWidth);
		h264VideoFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::CIFHeight);
		
		// Extract remote media format information
		const SDPMediaDescriptionList & mediaDescriptionList = sdpIn.GetMediaDescriptions();
		for(PINDEX i = 0; i < mediaDescriptionList.GetSize(); i++)
		{
			SDPMediaDescription & description = mediaDescriptionList[i];
			if(description.GetMediaType() == SDPMediaDescription::Video)
			{
				const SDPMediaFormatList & videoMediaFormatList = description.GetSDPMediaFormats();
			
				unsigned j;
				unsigned count = videoMediaFormatList.GetSize();
			
				for(j = 0; j < count; j++)
				{
					SDPMediaFormat & mediaFormat = videoMediaFormatList[j];
					
					if(mediaFormat.GetEncodingName() == _XMMediaFormatEncoding_H261)
					{
						unsigned maxBitRate;
						unsigned maxVideoBitRate = (bandwidthAvailable-640);
						XMVideoSize videoSize;
						unsigned mpi;
					
						_XMParseFMTP_H261(mediaFormat.GetFMTP(), maxBitRate, videoSize, mpi);
						
						if(maxBitRate > maxVideoBitRate)
						{
							maxBitRate = maxVideoBitRate;
						}
					
						h261VideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, maxBitRate);
						h261VideoFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption, 90000*mpi*100/2997);
					
						if(videoSize == XMVideoSize_CIF)
						{
							h261VideoFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::CIFWidth);
							h261VideoFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::CIFHeight);
						}
						else
						{
							h261VideoFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::QCIFWidth);
							h261VideoFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::QCIFHeight);
						}
					}
					else if(mediaFormat.GetEncodingName() == _XMMediaFormatEncoding_H263)
					{
						unsigned maxBitRate;
						unsigned maxVideoBitRate = (bandwidthAvailable - 640);
						XMVideoSize videoSize;
						unsigned mpi;
					
						_XMParseFMTP_H263(mediaFormat.GetFMTP(), maxBitRate, videoSize, mpi);
						
						if(maxBitRate > maxVideoBitRate)
						{
							maxBitRate = maxVideoBitRate;
						}
						
						h263VideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, maxBitRate);
						h263VideoFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption, 90000*mpi*100/2997);
					
						if(videoSize == XMVideoSize_CIF)
						{
							h263VideoFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::CIFWidth);
							h263VideoFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::CIFHeight);
						}
						else if(videoSize == XMVideoSize_QCIF)
						{
							h263VideoFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::QCIFWidth);
							h263VideoFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::QCIFHeight);
						}
						else
						{
							h263VideoFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, 128);
							h263VideoFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::SQCIFHeight);
						}
					}
					/*else if(mediaFormat.GetEncodingName() == _XMMediaFormatEncoding_H263Plus)
					{
						unsigned maxBitRate;
						XMVideoSize videoSize;
						unsigned mpi;
					
						_XMParseFMTP_H263(mediaFormat.GetFMTP(), maxBitRate, videoSize, mpi);
					
						h263PlusVideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, maxBitRate);
						h263PlusVideoFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption, 90000*mpi*100/2997);
					
						if(videoSize == XMVideoSize_CIF)
						{
							h263PlusVideoFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::CIFWidth);
							h263PlusVideoFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::CIFHeight);
						}
						else if(videoSize == XMVideoSize_QCIF)
						{
							h263PlusVideoFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::QCIFWidth);
							h263PlusVideoFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::QCIFHeight);
						}
						else
						{
							h263PlusVideoFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, 128);
							h263PlusVideoFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::SQCIFHeight);
						}
					}*/
				}
			}
		}

		// calling super class implementation
		BOOL result = SIPConnection::OnSendSDPMediaDescription(sdpIn, mediaType, sessionID, sdpOut);
		
		// adjust FMTP information on the SDP list sent
		SDPMediaDescriptionList outMediaDescriptionList = sdpOut.GetMediaDescriptions();
		
		for(PINDEX i = 0; i < outMediaDescriptionList.GetSize(); i++)
		{
			SDPMediaDescription & description = outMediaDescriptionList[i];
			if(description.GetMediaType() == SDPMediaDescription::Video)
			{
				const SDPMediaFormatList & videoMediaFormatList = description.GetSDPMediaFormats();
			
				for(PINDEX j = 0; j < videoMediaFormatList.GetSize(); j++)
				{
					SDPMediaFormat & mediaFormat = videoMediaFormatList[j];
					
					if(mediaFormat.GetEncodingName() == _XMMediaFormatEncoding_H261)
					{
						unsigned maxBitRate = h261VideoFormat.GetOptionInteger(OpalMediaFormat::MaxBitRateOption);
						unsigned mpi = h261VideoFormat.GetOptionInteger(OpalMediaFormat::FrameTimeOption) / 3003;
						XMVideoSize videoSize;
						if(h261VideoFormat.GetOptionInteger(OpalVideoFormat::FrameWidthOption) == PVideoDevice::CIFWidth)
						{
							videoSize = XMVideoSize_CIF;
						}
						else
						{
							videoSize = XMVideoSize_QCIF;
						}
						mediaFormat.SetFMTP(_XMGetFMTP_H261(maxBitRate, videoSize, mpi));
					}
					else if(mediaFormat.GetEncodingName() == _XMMediaFormatEncoding_H263)
					{
						unsigned maxBitRate = h263VideoFormat.GetOptionInteger(OpalMediaFormat::MaxBitRateOption);
						unsigned mpi = h263VideoFormat.GetOptionInteger(OpalMediaFormat::FrameTimeOption) / 3003;
						XMVideoSize videoSize;
						if(h263VideoFormat.GetOptionInteger(OpalVideoFormat::FrameWidthOption) == PVideoDevice::CIFWidth)
						{
							videoSize = XMVideoSize_CIF;
						}
						else if(h263VideoFormat.GetOptionInteger(OpalVideoFormat::FrameWidthOption) == PVideoDevice::QCIFWidth)
						{
							videoSize = XMVideoSize_QCIF;
						}
						else
						{
							videoSize = XMVideoSize_SQCIF;
						}
					
						mediaFormat.SetFMTP(_XMGetFMTP_H263(maxBitRate, videoSize, mpi));
					}
					/*else if(mediaFormat.GetEncodingName() == _XMMediaFormatEncoding_H263Plus)
					{
						unsigned maxBitRate = h263PlusVideoFormat.GetOptionInteger(OpalMediaFormat::MaxBitRateOption);
						unsigned mpi = h263PlusVideoFormat.GetOptionInteger(OpalMediaFormat::FrameTimeOption) / 3003;
						XMVideoSize videoSize;
						if(h263PlusVideoFormat.GetOptionInteger(OpalVideoFormat::FrameWidthOption) == PVideoDevice::CIFWidth)
						{
							videoSize = XMVideoSize_CIF;
						}
						else if(h263PlusVideoFormat.GetOptionInteger(OpalVideoFormat::FrameWidthOption) == PVideoDevice::QCIFWidth)
						{
							videoSize = XMVideoSize_QCIF;
						}
						else
						{
							videoSize = XMVideoSize_SQCIF;
						}
						
						mediaFormat.SetFMTP(_XMGetFMTP_H263(maxBitRate, videoSize, mpi));
					}*/
				}
			}
		}
	
		return result;
	}
}

BOOL XMSIPConnection::OnReceivedSDPMediaDescription(SDPSessionDescription & sdp,
													SDPMediaDescription::MediaType mediaType,
													unsigned sessionID)
{
	if(mediaType == SDPMediaDescription::Video)
	{
		// Resetting media formats to default values
		h261VideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, _XMGetMaxH261BitRate());
		h261VideoFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption, 3003);
		h261VideoFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::CIFWidth);
		h261VideoFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::CIFHeight);
		h263VideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, _XMGetMaxH263BitRate());
		h263VideoFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption, 3003);
		h263VideoFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::CIFWidth);
		h263VideoFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::CIFHeight);
		h263PlusVideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, _XMGetMaxH263BitRate());
		h263PlusVideoFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption, 3003);
		h263PlusVideoFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::CIFWidth);
		h263PlusVideoFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::CIFHeight);
		h264VideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, _XMGetMaxH264BitRate());
		h264VideoFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption, 3003);
		h264VideoFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::CIFWidth);
		h264VideoFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::CIFHeight);
		
		const SDPMediaDescriptionList & mediaDescriptionList = sdp.GetMediaDescriptions();
		for(PINDEX i = 0; i < mediaDescriptionList.GetSize(); i++)
		{
			SDPMediaDescription & description = mediaDescriptionList[i];
			if(description.GetMediaType() == SDPMediaDescription::Video)
			{
				const SDPMediaFormatList & videoMediaFormatList = description.GetSDPMediaFormats();
			
				for(PINDEX j = 0; j < videoMediaFormatList.GetSize(); j++)
				{
					SDPMediaFormat & mediaFormat = videoMediaFormatList[j];

					if(mediaFormat.GetEncodingName() == _XMMediaFormatEncoding_H261)
					{
						unsigned maxBitRate;
						XMVideoSize videoSize;
						unsigned mpi;
					
						_XMParseFMTP_H261(mediaFormat.GetFMTP(), maxBitRate, videoSize, mpi);
					
						h261VideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, maxBitRate);
						h261VideoFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption, 90000*mpi*100/2997);
					
						if(videoSize == XMVideoSize_CIF)
						{
							h261VideoFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::CIFWidth);
							h261VideoFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::CIFHeight);
						}
						else
						{
							h261VideoFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::QCIFWidth);
							h261VideoFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::QCIFHeight);
						}
					}
					else if(mediaFormat.GetEncodingName() == _XMMediaFormatEncoding_H263)
					{
						unsigned maxBitRate;
						XMVideoSize videoSize;
						unsigned mpi;
					
						_XMParseFMTP_H263(mediaFormat.GetFMTP(), maxBitRate, videoSize, mpi);
					
						h263VideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, maxBitRate);
						h263VideoFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption, 90000*mpi*100/2997);
					
						if(videoSize == XMVideoSize_CIF)
						{
							h263VideoFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::CIFWidth);
							h263VideoFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::CIFHeight);
						}
						else if(videoSize == XMVideoSize_QCIF)
						{
							h263VideoFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::QCIFWidth);
							h263VideoFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::QCIFHeight);
						}
						else
						{
							h263VideoFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, 128);
							h263VideoFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::SQCIFHeight);
						}
					}
					/*else if(mediaFormat.GetEncodingName() == _XMMediaFormatEncoding_H263Plus)
					{
						unsigned maxBitRate;
						XMVideoSize videoSize;
						unsigned mpi;
						
						_XMParseFMTP_H263(mediaFormat.GetFMTP(), maxBitRate, videoSize, mpi);
						
						h263PlusVideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, maxBitRate);
						h263PlusVideoFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption, 90000*mpi*100/2997);
						
						if(videoSize == XMVideoSize_CIF)
						{
							h263PlusVideoFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::CIFWidth);
							h263PlusVideoFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::CIFHeight);
						}
						else if(videoSize == XMVideoSize_QCIF)
						{
							h263PlusVideoFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::QCIFWidth);
							h263PlusVideoFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::QCIFHeight);
						}
						else
						{
							h263PlusVideoFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, 128);
							h263PlusVideoFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::SQCIFHeight);
						}
					}*/
				}
			}
		}
	}

	return SIPConnection::OnReceivedSDPMediaDescription(sdp, mediaType, sessionID);
}

OpalMediaFormatList XMSIPConnection::GetMediaFormats() const
{
	OpalMediaFormatList mediaFormats = SIPConnection::GetMediaFormats();
	
	// At the moment, neither H.263+ and H.264 are supported for SIP.
	// H.263+ will probably never come unless QuickTime can actually handle
	// H.263+ (PLUSPTYPE)
	PINDEX index = mediaFormats.FindFormat(XM_MEDIA_FORMAT_H263PLUS);
	if(index != P_MAX_INDEX)
	{
		mediaFormats.RemoveAt(index);
	}
	index = mediaFormats.FindFormat(XM_MEDIA_FORMAT_H264);
	if(index != P_MAX_INDEX)
	{
		mediaFormats.RemoveAt(index);
	}
	return mediaFormats;
}

void XMSIPConnection::AdjustMediaFormats(OpalMediaFormatList & mediaFormats) const
{
	PINDEX index = mediaFormats.FindFormat(XM_MEDIA_FORMAT_H263PLUS);
	if(index != P_MAX_INDEX)
	{
		mediaFormats.RemoveAt(index);
	}
	index = mediaFormats.FindFormat(XM_MEDIA_FORMAT_H264);
	if(index != P_MAX_INDEX)
	{
		mediaFormats.RemoveAt(index);
	}
	SIPConnection::AdjustMediaFormats(mediaFormats);
}

OpalMediaStream * XMSIPConnection::CreateMediaStream(const OpalMediaFormat & mediaFormat,
													unsigned sessionID,
													 BOOL isSource)
{
	// First, adjust some audio parameters if needed
	const SDPMediaDescriptionList & mediaDescriptionList = remoteSDP.GetMediaDescriptions();
	for(PINDEX i = 0; i < mediaDescriptionList.GetSize(); i++)
	{
		SDPMediaDescription & description = mediaDescriptionList[i];
		if(description.GetMediaType() == SDPMediaDescription::Audio)
		{
			PINDEX packetTime = description.GetPacketTime();
			if(packetTime != 0)
			{
				XMOpalManager::GetManagerInstance()->SetCurrentAudioPacketTime(packetTime);
			}
			break;
		}
	}
	
	if(sessionID == 2)
	{
		if(mediaFormat == XM_MEDIA_FORMAT_H261)
		{
			return SIPConnection::CreateMediaStream(h261VideoFormat, sessionID, isSource);
		}
		else if(mediaFormat == XM_MEDIA_FORMAT_H263)
		{
			_XMSetIsReceivingRFC2429(FALSE); // prevent XMMediaTransmitter from assuming RFC2429
			return SIPConnection::CreateMediaStream(h263VideoFormat, sessionID, isSource);
		}
		/*else if(mediaFormat == XM_MEDIA_FORMAT_H263PLUS)
		{
			return SIPConnection::CreateMediaStream(h263PlusVideoFormat, sessionID, isSource);
		}
		else if(mediaFormat == XM_MEDIA_FORMAT_H264)
		{
			return SIPConnection::CreateMediaStream(h264VideoFormat, sessionID, isSource);
		}*/
	}
	
	return SIPConnection::CreateMediaStream(mediaFormat, sessionID, isSource);
}

void XMSIPConnection::AdjustSessionDescription(SDPSessionDescription & sdp)
{
	unsigned bandwidth = XMOpalManager::GetAvailableBandwidth() / 1000;
	sdp.SetBandwidthModifier(SDPSessionDescription::ApplicationSpecificBandwidthModifier);
	sdp.SetBandwidthValue(bandwidth);
	
	const SDPMediaDescriptionList & mediaDescriptionList = sdp.GetMediaDescriptions();

	for(PINDEX i = 0; i < mediaDescriptionList.GetSize(); i++)
	{

		SDPMediaDescription & description = mediaDescriptionList[i];
		if(description.GetMediaType() == SDPMediaDescription::Video)
		{
			const SDPMediaFormatList & videoMediaFormats = description.GetSDPMediaFormats();
	
			unsigned j;
			unsigned count = videoMediaFormats.GetSize();
	
			for(j = 0; j < count; j++)
			{
				SDPMediaFormat & videoMediaFormat = videoMediaFormats[j];
				
				RTP_DataFrame::PayloadTypes payloadType = videoMediaFormat.GetPayloadType();
				
				if(payloadType == RTP_DataFrame::H261)
				{
					videoMediaFormat.SetFMTP(_XMGetFMTP_H261());
				}
				else if(payloadType == RTP_DataFrame::H263)
				{
					videoMediaFormat.SetFMTP(_XMGetFMTP_H263());
				}
				/*else if(payloadType == (RTP_DataFrame::PayloadTypes)96)
				{
					videoMediaFormat.SetFMTP(_XMGetFMTP_H263());
				}
				else if(payloadType == (RTP_DataFrame::PayloadTypes)97)
				{
					videoMediaFormat.SetFMTP(_XMGetFMTP_H264());
				}*/
			}
		}
	}
}

BOOL XMSIPConnection::OnOpenMediaStream(OpalMediaStream & mediaStream)
{
	if(!SIPConnection::OnOpenMediaStream(mediaStream))
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

void XMSIPConnection::OnReceivedACK(SIP_PDU & pdu)
{
	SIPConnection::OnReceivedACK(pdu);
	if(phase == EstablishedPhase)
	{
		releaseMethod = ReleaseWithBYE;
	}
}

void XMSIPConnection::OnReceivedAuthenticationRequired(SIPTransaction & transaction,
													   SIP_PDU & response)
{
	BOOL isProxy = response.GetStatusCode() == SIP_PDU::Failure_ProxyAuthenticationRequired;
	SIPURL proxy;
	SIPAuthentication auth;
	PString lastUsername;
	PString lastNonce;
	
	if (transaction.GetMethod() != SIP_PDU::Method_INVITE)
	{
		return;
	}
	
	// Received authentication required response, try to find authentication
	// for the given realm if no proxy
	if (!auth.Parse(response.GetMIME()(isProxy ? "Proxy-Authenticate" : "WWW-Authenticate"),isProxy)) 
	{
		Release(EndedBySecurityDenial);
		return;
	}
	
	// Save the username, realm and nonce
	lastUsername = auth.GetUsername();
	lastNonce = auth.GetNonce();
	
	// Try to find authentication parameters for the given realm,
	// if not, use the proxy authentication parameters (if any)
	if (!endpoint.GetAuthentication(auth.GetAuthRealm(), authentication))
	{
		if (!endpoint.GetProxy().IsEmpty())
		{
			authentication.SetUsername(endpoint.GetProxy().GetUserName());
			authentication.SetPassword(endpoint.GetProxy().GetPassword());
		}
		else
		{
			Release(EndedBySecurityDenial);
			return;
		}
	}
	
	if (!authentication.Parse(response.GetMIME()(isProxy ? "Proxy-Authenticate": "WWW-Authenticate"), isProxy))
	{
		Release(EndedBySecurityDenial);
		return;
	}
	
	if (!authentication.IsValid() || (authentication.IsValid() && lastUsername == authentication.GetUsername () 
									  && lastNonce    == authentication.GetNonce ())) 
	{
		Release(EndedBySecurityDenial);
		return;
	}
	
	// Restart the transaction with new authentication info
	// and start with a fresh To tag
	// Section 8.1.3.5 of RFC3261 tells that the authenticated
	// request SHOULD have the same value of the Call-ID, To and From.
	PINDEX j;
	if ((j = remotePartyAddress.Find (';')) != P_MAX_INDEX)
	{
		remotePartyAddress = remotePartyAddress.Left(j);
	}
	
	if (proxy.IsEmpty())
	{
		proxy = endpoint.GetProxy();
	}
	
	// Default routeSet if there is a proxy
	if (!proxy.IsEmpty() && routeSet.GetSize() == 0)
	{
		routeSet += "sip:" + proxy.GetHostName() + ':' + PString(proxy.GetPort()) + ";lr";
	}
	
	SIPTransaction * invite = new SIPInvite(*this, *transport);
	
	if(invite->HasSDP() == FALSE)
	{
		// should not happen. Simply ignore
		delete invite;
		return;
	}
	
	AdjustSessionDescription(invite->GetSDP());
	
	if (invite->Start())
	{
		invitations.Append(invite);
	}
	else 
	{
		delete invite;
	}
}

BOOL XMSIPConnection::SetBandwidthAvailable(unsigned newBandwidth, BOOL force)
{
	bandwidthAvailable = newBandwidth;
	XMOpalManager::SetAvailableBandwidth(100*newBandwidth);
	return TRUE;
}

unsigned XMSIPConnection::GetBandwidthUsed() const
{
	return 0;
}

BOOL XMSIPConnection::SetBandwidthUsed(unsigned releasedBandwidth, unsigned requiredBandwidth)
{
	return TRUE;
}
