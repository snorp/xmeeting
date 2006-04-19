/*
 * $Id: XMSIPConnection.cpp,v 1.1 2006/04/19 08:30:41 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#include "XMSIPConnection.h"

#include <opal/mediafmt.h>
#include <sip/sipep.h>
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
	cout << "XMSIPCONNECTION created" << endl;
}

XMSIPConnection::~XMSIPConnection()
{
}

BOOL XMSIPConnection::SetUpConnection()
{
	SIPURL transportAddress = targetAddress;
	
	PTRACE(2, "SIP\tSetUpConnection: " << remotePartyAddress);
	// Do a DNS SRV lookup
/*	
    PIPSocketAddressAndPortVector addrs;
    if (PDNS::LookupSRV(targetAddress.GetHostName(), "_sip._udp", targetAddress.GetPort(), addrs)) {
		transportAddress.SetHostName(addrs[0].address.AsString());
		transportAddress.SetPort(addrs [0].port);
    }
 */
	
	originating = TRUE;
	
	delete transport;
	transport = endpoint.CreateTransport(transportAddress.GetHostAddress());
	lastTransportAddress = transportAddress.GetHostAddress();
	if (transport == NULL) {
		Release(EndedByTransportFail);
		return FALSE;
	}
	
	if (!transport->WriteConnect(XMWriteINVITE, this)) {
		PTRACE(1, "SIP\tCould not write to " << targetAddress << " - " << transport->GetErrorText());
		Release(EndedByTransportFail);
		return FALSE;
	}
	
	releaseMethod = ReleaseWithCANCEL;
	return TRUE;
}

BOOL XMSIPConnection::XMWriteINVITE(OpalTransport & transport, void *param)
{
	XMSIPConnection & connection = *(XMSIPConnection *)param;
	
	connection.SetLocalPartyAddress();
	
	SIPTransaction * invite = new SIPInvite(connection, transport);
	
	// Adjust the SDP video formats
	SDPSessionDescription & sdp = invite->GetSDP();
	AdjustSessionDescription(sdp);
	
	if (invite->Start()) {
		connection.invitations.Append(invite);
		return TRUE;
	}

	return FALSE;
}

BOOL XMSIPConnection::OnSendSDPMediaDescription(const SDPSessionDescription & sdpIn,
												SDPMediaDescription::MediaType mediaType,
												unsigned sessionID,
												SDPSessionDescription & sdpOut)
{
	if(sessionID != 2)
	{
		return SIPConnection::OnSendSDPMediaDescription(sdpIn, mediaType, sessionID, sdpOut);
	}
	else
	{
		h261VideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, _XMGetMaxH261BitRate());
		h261VideoFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption, 3003);
		h261VideoFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::CIFWidth);
		h261VideoFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::CIFHeight);
		h263VideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, _XMGetMaxH263BitRate());
		h263VideoFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption, 3003);
		h263VideoFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::CIFWidth);
		h263VideoFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::CIFHeight);
		h264VideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, _XMGetMaxH264BitRate());
		h264VideoFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption, 3003);
		h264VideoFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::CIFWidth);
		h264VideoFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::CIFHeight);
		
		const SDPMediaDescriptionList & mediaDescriptionList = sdpIn.GetMediaDescriptions();
		if(mediaDescriptionList.GetSize() >= 2)
		{
			SDPMediaDescription & videoDescription = mediaDescriptionList[1];
			const SDPMediaFormatList & videoMediaFormatList = videoDescription.GetSDPMediaFormats();
			
			unsigned i;
			unsigned count = videoMediaFormatList.GetSize();
			
			for(i = 0; i < count; i++)
			{
				SDPMediaFormat & mediaFormat = videoMediaFormatList[i];
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
			}
		}

		BOOL result = SIPConnection::OnSendSDPMediaDescription(sdpIn, mediaType, sessionID, sdpOut);
		
		SDPMediaDescriptionList outMediaDescriptionList = sdpOut.GetMediaDescriptions();
		if(outMediaDescriptionList.GetSize() >= 2)
		{
			SDPMediaDescription & videoDescription = outMediaDescriptionList[1];
			const SDPMediaFormatList & videoMediaFormatList = videoDescription.GetSDPMediaFormats();
			
			if(videoMediaFormatList.GetSize() != 0)
			{
				SDPMediaFormat & mediaFormat = videoMediaFormatList[0];
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
			}
		}
	
		return result;
	}
}

BOOL XMSIPConnection::OnReceivedSDPMediaDescription(SDPSessionDescription & sdp,
													SDPMediaDescription::MediaType mediaType,
													unsigned sessionID)
{
	if(sessionID == 2)
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
		h263PlusVideoFormat.SetOptionInteger(OpalMediaFormat:MaxBitRateOption, _XMGetMaxH263BitRate());
		h263PlusVideoFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption, 3003);
		h263PlusVideoFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::CIFWidth);
		h263PlusVideoFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::CIFHeight);
		h264VideoFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, _XMGetMaxH264BitRate());
		h264VideoFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption, 3003);
		h264VideoFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::CIFWidth);
		h264VideoFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::CIFHeight);
		
		const SDPMediaDescriptionList & mediaDescriptionList = sdp.GetMediaDescriptions();
		if(mediaDescriptionList.GetSize() >= 2)
		{
			SDPMediaDescription & videoDescription = mediaDescriptionList[1];
			const SDPMediaFormatList & videoMediaFormatList = videoDescription.GetSDPMediaFormats();
			
			if(videoMediaFormatList.GetSize() != 0)
			{
				SDPMediaFormat & mediaFormat = videoMediaFormatList[0];

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
			}
		}
	}
	return SIPConnection::OnReceivedSDPMediaDescription(sdp, mediaType, sessionID);
}

void XMSIPConnection::AdjustMediaFormats(OpalMediaFormatList & mediaFormats) const
{
	PINDEX index = mediaFormats.FindFormat(XM_MEDIA_FORMAT_H264);
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
	if(sessionID == 2)
	{
		if(mediaFormat == XM_MEDIA_FORMAT_H261)
		{
			return SIPConnection::CreateMediaStream(h261VideoFormat, sessionID, isSource);
		}
		else if(mediaFormat == XM_MEDIA_FORMAT_H263)
		{
			return SIPConnection::CreateMediaStream(h263VideoFormat, sessionID, isSource);
		}
		else if(mediaFormat == XM_MEDIA_FORMAT_H264)
		{
			return SIPConnection::CreateMediaStream(h264VideoFormat, sessionID, isSource);
		}
	}
	
	return SIPConnection::CreateMediaStream(mediaFormat, sessionID, isSource);
}

void XMSIPConnection::AdjustSessionDescription(SDPSessionDescription & sdp)
{
	const SDPMediaDescriptionList & mediaDescription = sdp.GetMediaDescriptions();
	if(mediaDescription.GetSize() < 2)
	{
		return;
	}

	SDPMediaDescription & videoDescription = mediaDescription[1];
	const SDPMediaFormatList & videoMediaFormats = videoDescription.GetSDPMediaFormats();
	
	unsigned i;
	unsigned count = videoMediaFormats.GetSize();
	
	for(i = 0; i < count; i++)
	{
		SDPMediaFormat & videoMediaFormat = videoMediaFormats[i];
		
		RTP_DataFrame::PayloadTypes payloadType = videoMediaFormat.GetPayloadType();
		
		if(payloadType == RTP_DataFrame::H261)
		{
			videoMediaFormat.SetFMTP(_XMGetFMTP_H261());
		}
		else if(payloadType == RTP_DataFrame::H263)
		{
			videoMediaFormat.SetFMTP(_XMGetFMTP_H263());
		}
		else if(payloadType == RTP_DataFrame::DynamicBase)
		{
			videoMediaFormat.SetFMTP(_XMGetFMTP_H264());
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
