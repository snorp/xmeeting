/*
 * $Id: XMMediaFormats.cpp,v 1.4 2005/10/25 21:41:35 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#include "XMMediaFormats.h"

#include <asn/h245.h>
#include "XMBridge.h"

#define XM_H261_ENCODING_NAME "H261"

#define XM_MAX_FRAME_WIDTH PVideoDevice::CIFWidth
#define XM_MAX_FRAME_HEIGHT PVideoDevice::CIFHeight
#define XM_MAX_FRAME_RATE 30

#define XM_MAX_H261_BITRATE 19200

#pragma mark MediaFormat Strings

// Audio MediaFormats

const char *_XMMediaFormatIdentifier_G711_uLaw = "*g.711-ulaw*";
const char *_XMMediaFormatIdentifier_G711_ALaw = "*g.711-alaw*";

// Video MediaFormats

const char *_XMMediaFormatIdentifier_H261 = "*h.261*";

const char *_XMMediaFormat_Video = "XMVideo";
const char *_XMMediaFormat_H261_QCIF = "H.261 (QCIF)";
const char *_XMMediaFormat_H261_CIF = "H.261 (CIF)";

#pragma mark MediaFormat Definitions

const OpalVideoFormat & XMGetMediaFormat_Video()
{
	static const OpalVideoFormat XMMediaFormat_Video(_XMMediaFormat_Video,
													 RTP_DataFrame::MaxPayloadType,
													 _XMMediaFormat_Video,
													 XM_MAX_FRAME_WIDTH,
													 XM_MAX_FRAME_HEIGHT,
													 XM_MAX_FRAME_RATE,
													 32*XM_MAX_FRAME_WIDTH*XM_MAX_FRAME_HEIGHT*XM_MAX_FRAME_RATE);
	return XMMediaFormat_Video;
}

const OpalVideoFormat & XMGetMediaFormat_H261_QCIF()
{
	static const OpalVideoFormat XMMediaFormat_H261_QCIF(_XMMediaFormat_H261_QCIF,
														 RTP_DataFrame::H261,
														 XM_H261_ENCODING_NAME,
														 PVideoDevice::QCIFWidth,
														 PVideoDevice::QCIFHeight,
														 XM_MAX_FRAME_RATE,
														 XM_MAX_H261_BITRATE);
	return XMMediaFormat_H261_QCIF;
}

const OpalVideoFormat & XMGetMediaFormat_H261_CIF()
{
	static const OpalVideoFormat XMMediaFormat_H261_CIF(_XMMediaFormat_H261_CIF,
														RTP_DataFrame::H261,
														XM_H261_ENCODING_NAME,
														PVideoDevice::CIFWidth,
														PVideoDevice::CIFHeight,
														XM_MAX_FRAME_RATE,
														XM_MAX_H261_BITRATE);
	return XMMediaFormat_H261_CIF;
}

#pragma mark Limiting the Video Bitrate

static unsigned _maxVideoBitrate;

void _XMSetMaxVideoBitrate(unsigned maxVideoBitrate)
{
	_maxVideoBitrate = maxVideoBitrate;
}

unsigned _XMGetMaxVideoBitrate()
{
	return _maxVideoBitrate;
}

#pragma mark XM_H261_VIDEO_QCIF methods

XM_H261_VIDEO_QCIF::XM_H261_VIDEO_QCIF()
: OpalVideoTranscoder(XM_MEDIA_FORMAT_H261_QCIF, XM_MEDIA_FORMAT_VIDEO)
{
}

XM_H261_VIDEO_QCIF::~XM_H261_VIDEO_QCIF()
{
}

PINDEX XM_H261_VIDEO_QCIF::GetOptimalDataFrameSize(BOOL input) const
{
	return RTP_DataFrame::MaxEthernetPayloadSize;
}

BOOL XM_H261_VIDEO_QCIF::ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst)
{
	return TRUE;
}

#pragma mark XM_H261_VIDEO_CIF methods

XM_H261_VIDEO_CIF::XM_H261_VIDEO_CIF()
: OpalVideoTranscoder(XM_MEDIA_FORMAT_H261_CIF, XM_MEDIA_FORMAT_VIDEO)
{
}

XM_H261_VIDEO_CIF::~XM_H261_VIDEO_CIF()
{
}

PINDEX XM_H261_VIDEO_CIF::GetOptimalDataFrameSize(BOOL input) const
{
	return RTP_DataFrame::MaxEthernetPayloadSize;
}

BOOL XM_H261_VIDEO_CIF::ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst)
{
	return TRUE;
}

#pragma mark XM_VIDEO_H261_QCIF methods

XM_VIDEO_H261_QCIF::XM_VIDEO_H261_QCIF()
: OpalVideoTranscoder(XM_MEDIA_FORMAT_VIDEO, XM_MEDIA_FORMAT_H261_QCIF)
{
}

XM_VIDEO_H261_QCIF::~XM_VIDEO_H261_QCIF()
{
}

PINDEX XM_VIDEO_H261_QCIF::GetOptimalDataFrameSize(BOOL input) const
{
	return RTP_DataFrame::MaxEthernetPayloadSize;
}

BOOL XM_VIDEO_H261_QCIF::ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst)
{	
	return TRUE;
}

#pragma mark XM_VIDEO_H261_CIF methods

XM_VIDEO_H261_CIF::XM_VIDEO_H261_CIF()
: OpalVideoTranscoder(XM_MEDIA_FORMAT_VIDEO, XM_MEDIA_FORMAT_H261_CIF)
{
}

XM_VIDEO_H261_CIF::~XM_VIDEO_H261_CIF()
{
}

PINDEX XM_VIDEO_H261_CIF::GetOptimalDataFrameSize(BOOL input) const
{
	return RTP_DataFrame::MaxEthernetPayloadSize;
}

BOOL XM_VIDEO_H261_CIF::ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst)
{
	return TRUE;
}

#pragma mark XM_H323_H261_Capability methods

XM_H323_H261_Capability::XM_H323_H261_Capability(XMVideoSize videoSize)
{
	if(videoSize == XMVideoSize_QCIF)
	{
		qcifMPI = 1;
		cifMPI = 0;
	}
	else
	{
		qcifMPI = 0;
		cifMPI = 1;
	}
	
	temporalSpatialTradeOffCapability = TRUE;
	maxBitRate = _XMGetMaxVideoBitrate();
	stillImageTransmission = TRUE;
}

PObject * XM_H323_H261_Capability::Clone() const
{
	return new XM_H323_H261_Capability(*this);
}

PObject::Comparison XM_H323_H261_Capability::Compare(const PObject & obj) const
{
	Comparison result = H323Capability::Compare(obj);
	if(result != EqualTo)
	{
		return result;
	}
	
	PAssert(PIsDescendant(&obj, XM_H323_H261_Capability), PInvalidCast);
	const XM_H323_H261_Capability & other = (const XM_H323_H261_Capability &)obj;
	
	if (((qcifMPI > 0) && (other.qcifMPI > 0)) ||
		((cifMPI > 0) && (other.cifMPI > 0)))
	{
		return EqualTo;
	}
	
	if(qcifMPI > 0)
	{
		return LessThan;
	}
	
	return GreaterThan;
}

unsigned XM_H323_H261_Capability::GetSubType() const
{
	return H245_VideoCapability::e_h261VideoCapability;
}

PString XM_H323_H261_Capability::GetFormatName() const
{
	return cifMPI > 0 ? _XMMediaFormat_H261_CIF : _XMMediaFormat_H261_QCIF;
}

BOOL XM_H323_H261_Capability::OnSendingPDU(H245_VideoCapability & cap) const
{
	cap.SetTag(H245_VideoCapability::e_h261VideoCapability);
	
	H245_H261VideoCapability & h261 = cap;
	
	if(qcifMPI > 0)
	{
		h261.IncludeOptionalField(H245_H261VideoCapability::e_qcifMPI);
		h261.m_qcifMPI = qcifMPI;
	}
	if(cifMPI > 0)
	{
		h261.IncludeOptionalField(H245_H261VideoCapability::e_cifMPI);
		h261.m_cifMPI = cifMPI;
	}
	
	h261.m_temporalSpatialTradeOffCapability = temporalSpatialTradeOffCapability;
	h261.m_maxBitRate = maxBitRate;
	h261.m_stillImageTransmission = stillImageTransmission;
	
	return TRUE;
}

BOOL XM_H323_H261_Capability::OnSendingPDU(H245_VideoMode & pdu) const
{
	pdu.SetTag(H245_VideoMode::e_h261VideoMode);
	H245_H261VideoMode & mode = pdu;
	mode.m_resolution.SetTag(cifMPI > 0 ? H245_H261VideoMode_resolution::e_cif : 
										  H245_H261VideoMode_resolution::e_qcif);
	mode.m_bitRate = maxBitRate;
	mode.m_stillImageTransmission = stillImageTransmission;
	
	return TRUE;
}

BOOL XM_H323_H261_Capability::OnReceivedPDU(const H245_VideoCapability & cap)
{
	if (cap.GetTag() != H245_VideoCapability::e_h261VideoCapability)
	{
		return FALSE;
	}
	
	OpalMediaFormat & mediaFormat = GetWritableMediaFormat();
	
	const H245_H261VideoCapability & h261 = cap;
	if (h261.HasOptionalField(H245_H261VideoCapability::e_qcifMPI))
	{
		qcifMPI = h261.m_qcifMPI;
		mediaFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption, OpalMediaFormat::VideoClockRate*100*qcifMPI/2997);
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::QCIFWidth);
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::QCIFHeight);
	}
	else
	{
		qcifMPI = 0;
	}
	
	if (h261.HasOptionalField(H245_H261VideoCapability::e_cifMPI)) {
		cifMPI = h261.m_cifMPI;
		mediaFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption, OpalMediaFormat::VideoClockRate*100*cifMPI/2997);
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::CIFWidth);
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::CIFHeight);
	}
	else
	{
		cifMPI = 0;
	}
	
	maxBitRate = h261.m_maxBitRate;
	mediaFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, maxBitRate*100);
	
	temporalSpatialTradeOffCapability = h261.m_temporalSpatialTradeOffCapability;
	stillImageTransmission = h261.m_stillImageTransmission;
	return TRUE;
}

#pragma mark XMBridge Functions

unsigned _XMMaxMediaFormatsPerCodecIdentifier()
{
	return 2;
}

const char *_XMMediaFormatForCodecIdentifier(XMCodecIdentifier codecIdentifier)
{
	switch(codecIdentifier)
	{
		case XMCodecIdentifier_G711_uLaw:
			return _XMMediaFormatIdentifier_G711_uLaw;
		case XMCodecIdentifier_G711_ALaw:
			return _XMMediaFormatIdentifier_G711_ALaw;
		case XMCodecIdentifier_H261:
			return _XMMediaFormatIdentifier_H261;
		default:
			return NULL;
	}
}

const char *_XMMediaFormatForCodecIdentifierWithVideoSize(XMCodecIdentifier codecIdentifier,
														  XMVideoSize videoSize)
{
	switch(codecIdentifier)
	{
		case XMCodecIdentifier_H261:
			// H.261 knows only QCIF and CIF
			if(videoSize == XMVideoSize_QCIF)
			{
				return _XMMediaFormat_H261_QCIF;
			}
			else if(videoSize == XMVideoSize_CIF)
			{
				return _XMMediaFormat_H261_CIF;
			}
			break;
		default:
			break;
	}
	
	return NULL;
}