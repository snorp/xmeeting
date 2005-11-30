/*
 * $Id: XMMediaFormats.cpp,v 1.8 2005/11/30 23:49:46 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#include "XMMediaFormats.h"

#include <asn/h245.h>
#include "XMBridge.h"

#define XM_H261_ENCODING_NAME "H261"
#define XM_H263_ENCODING_NAME "H263"
#define XM_H264_ENCODING_NAME "H264"

#define XM_MAX_FRAME_WIDTH PVideoDevice::CIFWidth
#define XM_MAX_FRAME_HEIGHT PVideoDevice::CIFHeight
#define XM_MAX_FRAME_RATE 30

#define XM_MAX_H261_BITRATE 19200
#define XM_MAX_H263_BITRATE 19200
#define XM_MAX_H264_BITRATE 19200

#pragma mark MediaFormat Strings

// Audio MediaFormats

const char *_XMMediaFormatIdentifier_G711_uLaw = "*g.711-ulaw*";
const char *_XMMediaFormatIdentifier_G711_ALaw = "*g.711-alaw*";

// Video MediaFormats

const char *_XMMediaFormatIdentifier_H261 = "*h.261*";
const char *_XMMediaFormatIdentifier_H263 = "*h.263*";
const char *_XMMediaFormatIdentifier_H264 = "*H.264*";

const char *_XMMediaFormat_Video = "XMVideo";

const char *_XMMediaFormat_H261_QCIF = "H.261 (QCIF)";
const char *_XMMediaFormat_H261_CIF = "H.261 (CIF)";
const char *_XMMediaFormat_H261_UNKNOWN = "H.261 (UNKNOWN)";

const char *_XMMediaFormat_H263_SQCIF = "H.263 (SQCIF)";
const char *_XMMediaFormat_H263_QCIF = "H.263 (QCIF)";
const char *_XMMediaFormat_H263_CIF = "H.263 (CIF)";
const char *_XMMediaFormat_H263_4CIF = "H.263 (4CIF)";
const char *_XMMediaFormat_H263_16CIF = "H.263 (16CIF)";
const char *_XMMediaFormat_H263_UNKNOWN = "H.263 (UNKNOWN)";

const char *_XMMediaFormat_H264_QCIF = "H.264 (QCIF)";
const char *_XMMediaFormat_H264_CIF = "H.264 (CIF)";

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

const OpalVideoFormat & XMGetMediaFormat_H263_SQCIF()
{
	static const OpalVideoFormat XMMediaFormat_H263_SQCIF(_XMMediaFormat_H263_SQCIF,
														  RTP_DataFrame::H263,
														  XM_H263_ENCODING_NAME,
														  128,
														  PVideoDevice::SQCIFHeight,
														  XM_MAX_FRAME_RATE,
														  XM_MAX_H263_BITRATE);
	return XMMediaFormat_H263_SQCIF;
}

const OpalVideoFormat & XMGetMediaFormat_H263_QCIF()
{
	static const OpalVideoFormat XMMediaFormat_H263_QCIF(_XMMediaFormat_H263_QCIF,
														RTP_DataFrame::H263,
														XM_H263_ENCODING_NAME,
														PVideoDevice::CIFWidth,
														PVideoDevice::CIFHeight,
														XM_MAX_FRAME_RATE,
														XM_MAX_H263_BITRATE);
	return XMMediaFormat_H263_QCIF;
}

const OpalVideoFormat & XMGetMediaFormat_H263_CIF()
{
	static const OpalVideoFormat XMMediaFormat_H263_CIF(_XMMediaFormat_H263_CIF,
														RTP_DataFrame::H263,
														XM_H263_ENCODING_NAME,
														PVideoDevice::CIFWidth,
														PVideoDevice::CIFHeight,
														XM_MAX_FRAME_RATE,
														XM_MAX_H263_BITRATE);
	return XMMediaFormat_H263_CIF;
}

const OpalVideoFormat & XMGetMediaFormat_H263_4CIF()
{
	static const OpalVideoFormat XMMediaFormat_H263_4CIF(_XMMediaFormat_H263_4CIF,
														 RTP_DataFrame::H263,
														 XM_H263_ENCODING_NAME,
														 PVideoDevice::CIF4Width,
														 PVideoDevice::CIF4Height,
														 XM_MAX_FRAME_RATE,
														 XM_MAX_H263_BITRATE);
	return XMMediaFormat_H263_4CIF;
}

const OpalVideoFormat & XMGetMediaFormat_H263_16CIF()
{
	static const OpalVideoFormat XMMediaFormat_H263_16CIF(_XMMediaFormat_H263_16CIF,
														  RTP_DataFrame::H263,
														  XM_H263_ENCODING_NAME,
														  PVideoDevice::CIF16Width,
														  PVideoDevice::CIF16Height,
														  XM_MAX_FRAME_RATE,
														  XM_MAX_H263_BITRATE);
	return XMMediaFormat_H263_16CIF;
}

const OpalVideoFormat & XMGetMediaFormat_H264_QCIF()
{
	static const OpalVideoFormat XMMediaFormat_H264_QCIF(_XMMediaFormat_H264_QCIF,
														RTP_DataFrame::H261,
														XM_H264_ENCODING_NAME,
														PVideoDevice::CIFWidth,
														PVideoDevice::CIFHeight,
														XM_MAX_FRAME_RATE,
														XM_MAX_H264_BITRATE);
	return XMMediaFormat_H264_QCIF;
}

const OpalVideoFormat & XMGetMediaFormat_H264_CIF()
{
	static const OpalVideoFormat XMMediaFormat_H264_CIF(_XMMediaFormat_H264_CIF,
														RTP_DataFrame::H261,
														XM_H264_ENCODING_NAME,
														PVideoDevice::CIFWidth,
														PVideoDevice::CIFHeight,
														XM_MAX_FRAME_RATE,
														XM_MAX_H264_BITRATE);
	return XMMediaFormat_H264_CIF;
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

#pragma mark Identifying MediaFormats

BOOL _XMIsVideoMediaFormat(const OpalMediaFormat & mediaFormat)
{
	if(mediaFormat == XM_MEDIA_FORMAT_H261_QCIF ||
	   mediaFormat == XM_MEDIA_FORMAT_H261_CIF ||
	   mediaFormat == XM_MEDIA_FORMAT_H263_SQCIF ||
	   mediaFormat == XM_MEDIA_FORMAT_H263_QCIF ||
	   mediaFormat == XM_MEDIA_FORMAT_H263_CIF ||
	   mediaFormat == XM_MEDIA_FORMAT_H263_4CIF ||
	   mediaFormat == XM_MEDIA_FORMAT_H263_16CIF)
	{
		return TRUE;
	}
	
	return FALSE;
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

#pragma mark XM_H263_VIDEO_SQCIF methods

XM_H263_VIDEO_SQCIF::XM_H263_VIDEO_SQCIF()
: OpalVideoTranscoder(XM_MEDIA_FORMAT_H263_SQCIF, XM_MEDIA_FORMAT_VIDEO)
{
}

XM_H263_VIDEO_SQCIF::~XM_H263_VIDEO_SQCIF()
{
}

PINDEX XM_H263_VIDEO_SQCIF::GetOptimalDataFrameSize(BOOL input) const
{
	return RTP_DataFrame::MaxEthernetPayloadSize;
}

BOOL XM_H263_VIDEO_SQCIF::ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst)
{
	return TRUE;
}

#pragma mark XM_H263_VIDEO_QCIF methods

XM_H263_VIDEO_QCIF::XM_H263_VIDEO_QCIF()
: OpalVideoTranscoder(XM_MEDIA_FORMAT_H263_QCIF, XM_MEDIA_FORMAT_VIDEO)
{
}

XM_H263_VIDEO_QCIF::~XM_H263_VIDEO_QCIF()
{
}

PINDEX XM_H263_VIDEO_QCIF::GetOptimalDataFrameSize(BOOL input) const
{
	return RTP_DataFrame::MaxEthernetPayloadSize;
}

BOOL XM_H263_VIDEO_QCIF::ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst)
{
	return TRUE;
}

#pragma mark XM_H263_VIDEO_CIF methods

XM_H263_VIDEO_CIF::XM_H263_VIDEO_CIF()
: OpalVideoTranscoder(XM_MEDIA_FORMAT_H263_CIF, XM_MEDIA_FORMAT_VIDEO)
{
}

XM_H263_VIDEO_CIF::~XM_H263_VIDEO_CIF()
{
}

PINDEX XM_H263_VIDEO_CIF::GetOptimalDataFrameSize(BOOL input) const
{
	return RTP_DataFrame::MaxEthernetPayloadSize;
}

BOOL XM_H263_VIDEO_CIF::ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst)
{
	return TRUE;
}

#pragma mark XM_H263_VIDEO_4CIF methods

XM_H263_VIDEO_4CIF::XM_H263_VIDEO_4CIF()
: OpalVideoTranscoder(XM_MEDIA_FORMAT_H263_4CIF, XM_MEDIA_FORMAT_VIDEO)
{
}

XM_H263_VIDEO_4CIF::~XM_H263_VIDEO_4CIF()
{
}

PINDEX XM_H263_VIDEO_4CIF::GetOptimalDataFrameSize(BOOL input) const
{
	return RTP_DataFrame::MaxEthernetPayloadSize;
}

BOOL XM_H263_VIDEO_4CIF::ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst)
{
	return TRUE;
}

#pragma mark XM_H263_VIDEO_16CIF methods

XM_H263_VIDEO_16CIF::XM_H263_VIDEO_16CIF()
: OpalVideoTranscoder(XM_MEDIA_FORMAT_H263_16CIF, XM_MEDIA_FORMAT_VIDEO)
{
}

XM_H263_VIDEO_16CIF::~XM_H263_VIDEO_16CIF()
{
}

PINDEX XM_H263_VIDEO_16CIF::GetOptimalDataFrameSize(BOOL input) const
{
	return RTP_DataFrame::MaxEthernetPayloadSize;
}

BOOL XM_H263_VIDEO_16CIF::ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst)
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

#pragma mark XM_VIDEO_H263_SQCIF methods

XM_VIDEO_H263_SQCIF::XM_VIDEO_H263_SQCIF()
: OpalVideoTranscoder(XM_MEDIA_FORMAT_VIDEO, XM_MEDIA_FORMAT_H263_SQCIF)
{
}

XM_VIDEO_H263_SQCIF::~XM_VIDEO_H263_SQCIF()
{
}

PINDEX XM_VIDEO_H263_SQCIF::GetOptimalDataFrameSize(BOOL input) const
{
	return RTP_DataFrame::MaxEthernetPayloadSize;
}

BOOL XM_VIDEO_H263_SQCIF::ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst)
{
	return TRUE;
}

#pragma mark XM_VIDEO_H263_QCIF methods

XM_VIDEO_H263_QCIF::XM_VIDEO_H263_QCIF()
: OpalVideoTranscoder(XM_MEDIA_FORMAT_VIDEO, XM_MEDIA_FORMAT_H263_QCIF)
{
}

XM_VIDEO_H263_QCIF::~XM_VIDEO_H263_QCIF()
{
}

PINDEX XM_VIDEO_H263_QCIF::GetOptimalDataFrameSize(BOOL input) const
{
	return RTP_DataFrame::MaxEthernetPayloadSize;
}

BOOL XM_VIDEO_H263_QCIF::ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst)
{
	return TRUE;
}

#pragma mark XM_VIDEO_H263_CIF methods

XM_VIDEO_H263_CIF::XM_VIDEO_H263_CIF()
: OpalVideoTranscoder(XM_MEDIA_FORMAT_VIDEO, XM_MEDIA_FORMAT_H263_CIF)
{
}

XM_VIDEO_H263_CIF::~XM_VIDEO_H263_SQCIF()
{
}

PINDEX XM_VIDEO_H263_CIF::GetOptimalDataFrameSize(BOOL input) const
{
	return RTP_DataFrame::MaxEthernetPayloadSize;
}

BOOL XM_VIDEO_H263_CIF::ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst)
{
	return TRUE;
}

#pragma mark XM_VIDEO_H263_4CIF methods

XM_VIDEO_H263_4CIF::XM_VIDEO_H263_4CIF()
: OpalVideoTranscoder(XM_MEDIA_FORMAT_VIDEO, XM_MEDIA_FORMAT_H263_4CIF)
{
}

XM_VIDEO_H263_4CIF::~XM_VIDEO_H263_4CIF()
{
}

PINDEX XM_VIDEO_H263_4CIF::GetOptimalDataFrameSize(BOOL input) const
{
	return RTP_DataFrame::MaxEthernetPayloadSize;
}

BOOL XM_VIDEO_H263_4CIF::ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst)
{
	return TRUE;
}

#pragma mark XM_VIDEO_H263_16CIF methods

XM_VIDEO_H263_16CIF::XM_VIDEO_H263_16CIF()
: OpalVideoTranscoder(XM_MEDIA_FORMAT_VIDEO, XM_MEDIA_FORMAT_H263_16CIF)
{
}

XM_VIDEO_H263_16CIF::~XM_VIDEO_H263_16CIF()
{
}

PINDEX XM_VIDEO_H263_16CIF::GetOptimalDataFrameSize(BOOL input) const
{
	return RTP_DataFrame::MaxEthernetPayloadSize;
}

BOOL XM_VIDEO_H263_16CIF::ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst)
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
	
	temporalSpatialTradeOffCapability = FALSE;
	maxBitRate = _XMGetMaxVideoBitrate() / 100; // H.245 uses bitrate units of 100bits/s
	stillImageTransmission = FALSE;
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
	if(cifMPI > 0)
	{
		return _XMMediaFormat_H261_CIF;
	}
	if(qcifMPI > 0)
	{
		return _XMMediaFormat_H261_QCIF;
	}
	
	return _XMMediaFormat_H261_UNKNOWN;
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

#pragma mark XM_H323_H263_Capability methods


XM_H323_H263_Capability::XM_H323_H263_Capability(XMVideoSize videoSize)
{
	sqcifMPI = 0;
	qcifMPI = 0;
	cifMPI = 0;
	cif4MPI = 0;
	cif16MPI = 0;
	
	switch(videoSize)
	{
		case XMVideoSize_SQCIF:
			sqcifMPI = 1;
			break;
		case XMVideoSize_QCIF:
			qcifMPI = 1;
			break;
		case XMVideoSize_CIF:
			cifMPI = 1;
			break;
		case XMVideoSize_4CIF:
			cif4MPI = 1;
			break;
		case XMVideoSize_16CIF:
			cif16MPI = 1;
			break;
		default:
			break;
	}
	
	maxBitRate = _XMGetMaxVideoBitrate() / 100;
	unrestrictedVector = FALSE;
	arithmeticCoding = FALSE;
	advancedPrediction = FALSE;
	pbFrames = FALSE;
	temporalSpatialTradeOffCapability = FALSE;
	hrd_B = 0;
	bppMaxKb = 0;
	slowSqcifMPI = 0;
	slowQcifMPI = 0;
	slowCifMPI = 0;
	slowCif4MPI = 0;
	slowCif16MPI = 0;
	errorCompensation = FALSE;
}

PObject * XM_H323_H263_Capability::Clone() const
{
	return new XM_H323_H263_Capability(*this);
}

PObject::Comparison XM_H323_H263_Capability::Compare(const PObject & obj) const
{
	if(!PIsDescendant(&obj, XM_H323_H263_Capability))
	{
		return LessThan;
	}
	
	Comparison result = H323Capability::Compare(obj);
	if(result != EqualTo)
	{
		return result;
	}
	
	const XM_H323_H263_Capability & other = (const XM_H323_H263_Capability &)obj;
	
	if((sqcifMPI && other.sqcifMPI) ||
	   (qcifMPI && other.qcifMPI) ||
	   (cifMPI && other.cifMPI) ||
	   (cif4MPI && other.cif4MPI) ||
	   (cif16MPI && other.cif16MPI) ||
	   (slowSqcifMPI && other.slowSqcifMPI) ||
	   (slowQcifMPI && other.slowQcifMPI) ||
	   (slowCifMPI && other.slowCifMPI) ||
	   (slowCif4MPI && other.slowCif4MPI) ||
	   (slowCif16MPI && other.slowCif16MPI))
	{
		return EqualTo;
	}
	
	if((!cif16MPI && other.cif16MPI) ||
	   (!cif4MPI && other.cif4MPI) ||
	   (!cifMPI && other.cifMPI) ||
	   (!qcifMPI && other.qcifMPI) ||
	   (!sqcifMPI && other.sqcifMPI) ||
	   (!slowCif16MPI && other.slowCif16MPI) ||
	   (!slowCif4MPI && other.slowCif4MPI) ||
	   (!slowCifMPI && other.slowCifMPI) ||
	   (!slowQcifMPI && other.slowQcifMPI) ||
	   (!slowSqcifMPI && other.slowSqcifMPI))
	{
		return LessThan;
	}
	
	return GreaterThan;
}

unsigned XM_H323_H263_Capability::GetSubType() const
{
	return H245_VideoCapability::e_h263VideoCapability;
}

PString XM_H323_H263_Capability::GetFormatName() const
{
	if(cif16MPI > 0)
	{
		return _XMMediaFormat_H263_16CIF;
	}
	if(cif4MPI > 0)
	{
		return _XMMediaFormat_H263_4CIF;
	}
	if(cifMPI > 0)
	{
		return _XMMediaFormat_H263_CIF;
	}
	if(qcifMPI > 0)
	{
		return _XMMediaFormat_H263_QCIF;
	}
	if(sqcifMPI > 0)
	{
		return _XMMediaFormat_H263_SQCIF;
	}
	
	if(slowCif16MPI > 0)
	{
		return _XMMediaFormat_H263_16CIF;
	}
	if(slowCif4MPI > 0)
	{
		return _XMMediaFormat_H263_4CIF;
	}
	if(slowCifMPI > 0)
	{
		return _XMMediaFormat_H263_CIF;
	}
	if(slowQcifMPI > 0)
	{
		return _XMMediaFormat_H263_QCIF;
	}
	if(slowSqcifMPI > 0)
	{
		return _XMMediaFormat_H263_SQCIF;
	}
	
	return _XMMediaFormat_H263_UNKNOWN;
}

BOOL XM_H323_H263_Capability::OnSendingPDU(H245_VideoCapability & cap) const
{
	cap.SetTag(H245_VideoCapability::e_h263VideoCapability);
	
	H245_H263VideoCapability & h263 = cap;
	
	if(sqcifMPI > 0)
	{
		h263.IncludeOptionalField(H245_H263VideoCapability::e_sqcifMPI);
		h263.m_sqcifMPI = sqcifMPI;
	}
	if(qcifMPI > 0)
	{
		h263.IncludeOptionalField(H245_H263VideoCapability::e_qcifMPI);
		h263.m_qcifMPI = qcifMPI;
	}
	if(cifMPI > 0)
	{
		h263.IncludeOptionalField(H245_H263VideoCapability::e_cifMPI);
		h263.m_cifMPI = cifMPI;
	}
	if(cif4MPI > 0)
	{
		h263.IncludeOptionalField(H245_H263VideoCapability::e_cif4MPI);
		h263.m_cif4MPI = cif4MPI;
	}
	if(cif16MPI > 0)
	{
		h263.IncludeOptionalField(H245_H263VideoCapability::e_cif16MPI);
		h263.m_cif16MPI = cif16MPI;
	}
	
	h263.m_maxBitRate = maxBitRate;
	h263.m_unrestrictedVector = unrestrictedVector;
	h263.m_arithmeticCoding = arithmeticCoding;
	h263.m_advancedPrediction = advancedPrediction;
	h263.m_pbFrames = pbFrames;
	h263.m_temporalSpatialTradeOffCapability = temporalSpatialTradeOffCapability;
	
	if(hrd_B > 0)
	{
		h263.IncludeOptionalField(H245_H263VideoCapability::e_hrd_B);
		h263.m_hrd_B = hrd_B;
	}
	if(bppMaxKb > 0)
	{
		h263.IncludeOptionalField(H245_H263VideoCapability::e_bppMaxKb);
		h263.m_bppMaxKb = bppMaxKb;
	}
	if(slowSqcifMPI > 0 && sqcifMPI == 0)
	{
		h263.IncludeOptionalField(H245_H263VideoCapability::e_slowSqcifMPI);
		h263.m_slowSqcifMPI = slowSqcifMPI;
	}
	if(slowQcifMPI > 0 && qcifMPI == 0)
	{
		h263.IncludeOptionalField(H245_H263VideoCapability::e_slowQcifMPI);
		h263.m_slowQcifMPI = slowQcifMPI;
	}
	if(slowCifMPI > 0 && cifMPI == 0)
	{
		h263.IncludeOptionalField(H245_H263VideoCapability::e_slowCifMPI);
		h263.m_slowCifMPI = slowCifMPI;
	}
	if(slowCif4MPI > 0 && cif4MPI == 0)
	{
		h263.IncludeOptionalField(H245_H263VideoCapability::e_slowCif4MPI);
		h263.m_slowCif4MPI = slowCif4MPI;
	}
	if(slowCif16MPI > 0 && cif16MPI == 0)
	{
		h263.IncludeOptionalField(H245_H263VideoCapability::e_slowCif16MPI);
		h263.m_slowCif16MPI = slowCif16MPI;
	}
	
	if(errorCompensation == TRUE)
	{
		h263.IncludeOptionalField(H245_H263VideoCapability::e_errorCompensation);
		h263.m_errorCompensation = TRUE;
	}
	
	return TRUE;
}

BOOL XM_H323_H263_Capability::OnSendingPDU(H245_VideoMode & pdu) const
{
	pdu.SetTag(H245_VideoMode::e_h263VideoMode);
	H245_H263VideoMode & mode = pdu;
	mode.m_resolution.SetTag(cif16MPI > 0 ? H245_H263VideoMode_resolution::e_cif16
							 :(cif4MPI > 0 ? H245_H263VideoMode_resolution::e_cif4
							   :(cifMPI > 0 ? H245_H263VideoMode_resolution::e_cif
								 :(qcifMPI > 0 ? H245_H263VideoMode_resolution::e_qcif
								   : H245_H263VideoMode_resolution::e_sqcif))));
	mode.m_bitRate = maxBitRate;
	mode.m_unrestrictedVector = unrestrictedVector;
	mode.m_arithmeticCoding = arithmeticCoding;
	mode.m_advancedPrediction = advancedPrediction;
	mode.m_pbFrames = pbFrames;
	mode.m_errorCompensation = errorCompensation;
	
	return TRUE;
}

BOOL XM_H323_H263_Capability::OnReceivedPDU(const H245_VideoCapability & cap)
{
	if(cap.GetTag() != H245_VideoCapability::e_h263VideoCapability)
	{
		return FALSE;
	}
	
	const H245_H263VideoCapability & h263 = cap;
	
	OpalMediaFormat & mediaFormat = GetWritableMediaFormat();
	
	if(h263.HasOptionalField(H245_H263VideoCapability::e_sqcifMPI))
	{
		sqcifMPI = h263.m_sqcifMPI;
		slowSqcifMPI = 0;
		mediaFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption, OpalMediaFormat::VideoClockRate*100*sqcifMPI/2997);
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, 128);
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::SQCIFHeight);
	}
	else if(h263.HasOptionalField(H245_H263VideoCapability::e_slowSqcifMPI))
	{
		sqcifMPI = 0;
		slowSqcifMPI = h263.m_slowSqcifMPI;
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, 128);
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::SQCIFHeight);
	}
	else
	{
		sqcifMPI = 0;
		slowSqcifMPI = 0;
	}
	if(h263.HasOptionalField(H245_H263VideoCapability::e_qcifMPI))
	{
		qcifMPI = h263.m_qcifMPI;
		slowQcifMPI = 0;
		mediaFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption, OpalMediaFormat::VideoClockRate*100*qcifMPI/2997);
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::QCIFWidth);
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::QCIFHeight);
	}
	else if(h263.HasOptionalField(H245_H263VideoCapability::e_slowQcifMPI))
	{
		qcifMPI = 0;
		slowQcifMPI = h263.m_slowQcifMPI;
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::QCIFWidth);
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::QCIFHeight);
	}
	else
	{
		qcifMPI = 0;
		slowQcifMPI = 0;
	}
	if(h263.HasOptionalField(H245_H263VideoCapability::e_cifMPI))
	{
		cifMPI = h263.m_cifMPI;
		mediaFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption, OpalMediaFormat::VideoClockRate*100*cifMPI/2997);
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::CIFWidth);
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::CIFHeight);
	}
	else if(h263.HasOptionalField(H245_H263VideoCapability::e_slowCifMPI))
	{
		cifMPI = 0;
		slowCifMPI = h263.m_slowCifMPI;
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::CIFWidth);
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::CIFHeight);
	}
	else
	{
		cifMPI = 0;
		slowCifMPI = 0;
	}
	if(h263.HasOptionalField(H245_H263VideoCapability::e_cif4MPI))
	{
		cif4MPI = h263.m_cif4MPI;
		slowCif4MPI = 0;
		mediaFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption, OpalMediaFormat::VideoClockRate*100*cif4MPI/2997);
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::CIF4Width);
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::CIF4Height);
	}
	else if(h263.HasOptionalField(H245_H263VideoCapability::e_slowCif4MPI))
	{
		cif4MPI = 0;
		slowCif4MPI = h263.m_slowCif4MPI;
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::CIF4Width);
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::CIF4Height);
	}
	else
	{
		cif4MPI = 0;
		slowCif4MPI = 0;
	}
	if(h263.HasOptionalField(H245_H263VideoCapability::e_cif16MPI))
	{
		cif16MPI = h263.m_cif16MPI;
		slowCif16MPI = 0;
		mediaFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption, OpalMediaFormat::VideoClockRate*100*cif16MPI/2997);
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::CIF16Width);
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::CIF16Height);
	}
	else if(h263.HasOptionalField(H245_H263VideoCapability::e_slowCif16MPI))
	{
		cif16MPI = 0;
		slowCif16MPI = h263.m_slowCif16MPI;
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::CIF16Width);
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::CIF16Height);
	}
	else
	{
		cif16MPI = 0;
		slowCif16MPI = 0;
	}
	
	maxBitRate = h263.m_maxBitRate;
	unrestrictedVector = h263.m_unrestrictedVector;
	arithmeticCoding = h263.m_arithmeticCoding;
	advancedPrediction = h263.m_advancedPrediction;
	pbFrames = h263.m_pbFrames;
	temporalSpatialTradeOffCapability = h263.m_temporalSpatialTradeOffCapability;
	
	hrd_B = h263.m_hrd_B;
	bppMaxKb = h263.m_bppMaxKb;
	
	errorCompensation = h263.m_errorCompensation;
	
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
		case XMCodecIdentifier_H263:
			return _XMMediaFormatIdentifier_H263;
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
		case XMCodecIdentifier_H263:
			if(videoSize == XMVideoSize_QCIF)
			{
				return _XMMediaFormat_H263_QCIF;
			}
			else if(videoSize == XMVideoSize_CIF)
			{
				return _XMMediaFormat_H263_CIF;
			}
			break;
		case XMCodecIdentifier_H264:
			if(videoSize == XMVideoSize_QCIF)
			{
				return _XMMediaFormat_H264_QCIF;
			}
			else if(videoSize == XMVideoSize_CIF)
			{
				return _XMMediaFormat_H264_CIF;
			}
			break;
		default:
			break;
	}
	
	return NULL;
}