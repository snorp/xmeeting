/*
 * $Id: XMMediaFormats.cpp,v 1.13 2006/03/13 23:46:23 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#include <asn/h245.h>
#include <codec/h261codec.h>

#include "XMMediaFormats.h"
#include "XMBridge.h"
#include "XMTransmitterMediaPatch.h"

#define XM_CIF_WIDTH PVideoDevice::CIFWidth
#define XM_CIF_HEIGHT PVideoDevice::CIFHeight
#define XM_QCIF_WIDTH PVideoDevice::QCIFWidth
#define XM_QCIF_HEIGHT PVideoDevice::QCIFHeight
#define XM_SQCIF_WIDTH 128
#define XM_SQCIF_HEIGHT PVideoDevice::SQCIFHeight

#define XM_H261_ENCODING_NAME "H261"
#define XM_H263_ENCODING_NAME "H263"
#define XM_H264_ENCODING_NAME "H264"

#define XM_MAX_FRAME_WIDTH XM_CIF_WIDTH
#define XM_MAX_FRAME_HEIGHT XM_CIF_HEIGHT
#define XM_MAX_FRAME_RATE 30

#define XM_MAX_H261_BITRATE 9600
#define XM_MAX_H263_BITRATE 9600
#define XM_MAX_H264_BITRATE 7680

#define XM_H264_PROFILE_CODE_BASELINE 64
#define XM_H264_PROFILE_CODE_MAIN 32

#define XM_H264_LEVEL_CODE_1	15
#define XM_H264_LEVEL_CODE_1_B  19
#define XM_H264_LEVEL_CODE_1_1	22
#define XM_H264_LEVEL_CODE_1_2	29
#define XM_H264_LEVEL_CODE_1_3	36
#define XM_H264_LEVEL_CODE_2	43

#pragma mark MediaFormat Strings

const char *_XMMediaFormatIdentifier_G711_uLaw = "*g.711-ulaw*";
const char *_XMMediaFormatIdentifier_G711_ALaw = "*g.711-alaw*";

// Video MediaFormats

const char *_XMMediaFormatIdentifier_H261 = "*qth.261*";
const char *_XMMediaFormatIdentifier_H263 = "*qth.263*";
const char *_XMMediaFormatIdentifier_H264 = "*qth.264*";

const char *_XMMediaFormat_Video = "XMVideo ";
const char *_XMMediaFormat_H261 = "QTH.261 ";
const char *_XMMediaFormat_H263 = "QTH.263 ";
const char *_XMMediaFormat_H264 = "QTH.264 ";

const char *_XMMediaFormatName_H261 = "H.261";
const char *_XMMediaFormatName_H263 = "H.263";
const char *_XMMediaFormatName_H264 = "H.264";

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

const OpalVideoFormat & XMGetMediaFormat_H261()
{
	static const OpalVideoFormat XMMediaFormat_H261(_XMMediaFormat_H261,
													RTP_DataFrame::H261,
													XM_H261_ENCODING_NAME,
													XM_MAX_FRAME_WIDTH,
													XM_MAX_FRAME_HEIGHT,
													XM_MAX_FRAME_RATE,
													XM_MAX_H261_BITRATE);
	return XMMediaFormat_H261;
}

const OpalVideoFormat & XMGetMediaFormat_H263()
{
	static const OpalVideoFormat XMMediaFormat_H263(_XMMediaFormat_H263,
													RTP_DataFrame::H263,
													XM_H263_ENCODING_NAME,
													XM_MAX_FRAME_WIDTH,
													XM_MAX_FRAME_HEIGHT,
													XM_MAX_FRAME_RATE,
													XM_MAX_H263_BITRATE);
	return XMMediaFormat_H263;
}

const OpalVideoFormat & XMGetMediaFormat_H264()
{
	static const OpalVideoFormat XMMediaFormat_H264(_XMMediaFormat_H264,
													RTP_DataFrame::DynamicBase,
													XM_H264_ENCODING_NAME,
													XM_MAX_FRAME_WIDTH,
													XM_MAX_FRAME_HEIGHT,
													XM_MAX_FRAME_RATE,
													XM_MAX_H264_BITRATE);
	return XMMediaFormat_H264;
}

#pragma mark Identifying MediaFormats

BOOL _XMIsVideoMediaFormat(const OpalMediaFormat & mediaFormat)
{
	if(mediaFormat == XM_MEDIA_FORMAT_H261 ||
	   mediaFormat == XM_MEDIA_FORMAT_H263 ||
	   mediaFormat == XM_MEDIA_FORMAT_H264)
	{
		return TRUE;
	}
	
	return FALSE;
}

XMCodecIdentifier _XMGetMediaFormatCodec(const OpalMediaFormat & mediaFormat)
{
	if(mediaFormat == XM_MEDIA_FORMAT_H261)
	{
		return XMCodecIdentifier_H261;
	}
	else if(mediaFormat == XM_MEDIA_FORMAT_H263)
	{
		return XMCodecIdentifier_H263;
	}
	else if(mediaFormat == XM_MEDIA_FORMAT_H264)
	{
		return XMCodecIdentifier_H264;
	}
	
	return XMCodecIdentifier_UnknownCodec;
}

XMVideoSize _XMGetMediaFormatSize(const OpalMediaFormat & mediaFormat)
{
	unsigned width = mediaFormat.GetOptionInteger(OpalVideoFormat::FrameWidthOption);
	unsigned height = mediaFormat.GetOptionInteger(OpalVideoFormat::FrameHeightOption);
	
	if(width == XM_CIF_WIDTH && height == XM_CIF_HEIGHT)
	{
		return XMVideoSize_CIF;
	}
	else if(width == XM_QCIF_WIDTH && height == XM_QCIF_HEIGHT)
	{
		return XMVideoSize_QCIF;
	}
	else if(width == XM_SQCIF_WIDTH && height == XM_SQCIF_HEIGHT)
	{
		return XMVideoSize_SQCIF;
	}
	else
	{
		cout << "XMGetMediaFormatInfo with invalid size " << width << " " << height << endl;
		return XMVideoSize_NoVideo;
	}
}

const char *_XMGetMediaFormatName(const OpalMediaFormat & mediaFormat)
{
	if(mediaFormat == XM_MEDIA_FORMAT_H261)
	{
		return _XMMediaFormatName_H261;
	}
	else if(mediaFormat == XM_MEDIA_FORMAT_H263)
	{
		return _XMMediaFormatName_H263;
	}
	else if(mediaFormat == XM_MEDIA_FORMAT_H264)
	{
		return _XMMediaFormatName_H264;
	}
	
	// if nothing found, simply return the media format string itself
	return mediaFormat;
}

#pragma mark XMBridge Functions

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
		case XMCodecIdentifier_H264:
			return _XMMediaFormatIdentifier_H264;
		default:
			return NULL;
	}
}

#pragma mark XM_H261_VIDEO methods

XM_H261_VIDEO::XM_H261_VIDEO()
: OpalVideoTranscoder(XM_MEDIA_FORMAT_H261, XM_MEDIA_FORMAT_VIDEO)
{
}

XM_H261_VIDEO::~XM_H261_VIDEO()
{
}

PINDEX XM_H261_VIDEO::GetOptimalDataFrameSize(BOOL input) const
{
	return RTP_DataFrame::MaxEthernetPayloadSize;
}

BOOL XM_H261_VIDEO::ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst)
{
	return TRUE;
}

#pragma mark XM_H263_VIDEO methods

XM_H263_VIDEO::XM_H263_VIDEO()
: OpalVideoTranscoder(XM_MEDIA_FORMAT_H263, XM_MEDIA_FORMAT_VIDEO)
{
}

XM_H263_VIDEO::~XM_H263_VIDEO()
{
}

PINDEX XM_H263_VIDEO::GetOptimalDataFrameSize(BOOL input) const
{
	return RTP_DataFrame::MaxEthernetPayloadSize;
}

BOOL XM_H263_VIDEO::ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst)
{
	return TRUE;
}

#pragma mark XM_H264_VIDEO methods

XM_H264_VIDEO::XM_H264_VIDEO()
: OpalVideoTranscoder(XM_MEDIA_FORMAT_H264, XM_MEDIA_FORMAT_VIDEO)
{
}

XM_H264_VIDEO::~XM_H264_VIDEO()
{
}

PINDEX XM_H264_VIDEO::GetOptimalDataFrameSize(BOOL input) const
{
	return RTP_DataFrame::MaxEthernetPayloadSize;
}

BOOL XM_H264_VIDEO::ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst)
{
	return TRUE;
}

#pragma mark XM_VIDEO_H261 methods

XM_VIDEO_H261::XM_VIDEO_H261()
: OpalVideoTranscoder(XM_MEDIA_FORMAT_VIDEO, XM_MEDIA_FORMAT_H261)
{
}

XM_VIDEO_H261::~XM_VIDEO_H261()
{
}

PINDEX XM_VIDEO_H261::GetOptimalDataFrameSize(BOOL input) const
{
	return RTP_DataFrame::MaxEthernetPayloadSize;
}

BOOL XM_VIDEO_H261::ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst)
{	
	return TRUE;
}

#pragma mark XM_VIDEO_H263 methods

XM_VIDEO_H263::XM_VIDEO_H263()
: OpalVideoTranscoder(XM_MEDIA_FORMAT_VIDEO, XM_MEDIA_FORMAT_H263)
{
}

XM_VIDEO_H263::~XM_VIDEO_H263()
{
}

PINDEX XM_VIDEO_H263::GetOptimalDataFrameSize(BOOL input) const
{
	return RTP_DataFrame::MaxEthernetPayloadSize;
}

BOOL XM_VIDEO_H263::ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst)
{
	return TRUE;
}

#pragma mark XM_VIDEO_H264 methods

XM_VIDEO_H264::XM_VIDEO_H264()
: OpalVideoTranscoder(XM_MEDIA_FORMAT_VIDEO, XM_MEDIA_FORMAT_H264)
{
}

XM_VIDEO_H264::~XM_VIDEO_H264()
{
}

PINDEX XM_VIDEO_H264::GetOptimalDataFrameSize(BOOL input) const
{
	return RTP_DataFrame::MaxEthernetPayloadSize;
}

BOOL XM_VIDEO_H264::ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst)
{
	return TRUE;
}

#pragma mark XM_H323_H261_Capability methods

XM_H323_H261_Capability::XM_H323_H261_Capability()
{
	qcifMPI = 1;
	cifMPI = 1;
	
	maxBitRate = _XMGetVideoBandwidthLimit() / 100; // H.245 uses bitrate units of 100bits/s
	if(maxBitRate > XM_MAX_H261_BITRATE)
	{
		maxBitRate = XM_MAX_H261_BITRATE;
	}
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
	
	if(PIsDescendant(&obj, XM_H323_H261_Capability))
	{	
		const XM_H323_H261_Capability & other = (const XM_H323_H261_Capability &)obj;
	
		if (((cifMPI > 0) && (other.cifMPI > 0)) ||
			((qcifMPI > 0) && (other.qcifMPI > 0)))
		{
			return EqualTo;
		}
	}
	
	return LessThan;
}

unsigned XM_H323_H261_Capability::GetSubType() const
{
	return H245_VideoCapability::e_h261VideoCapability;
}

PString XM_H323_H261_Capability::GetFormatName() const
{
	return _XMMediaFormat_H261;
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
	
	h261.m_temporalSpatialTradeOffCapability = FALSE;
	h261.m_maxBitRate = maxBitRate;
	h261.m_stillImageTransmission = FALSE;
	
	return TRUE;
}

BOOL XM_H323_H261_Capability::OnSendingPDU(H245_VideoMode & pdu) const
{
	pdu.SetTag(H245_VideoMode::e_h261VideoMode);
	H245_H261VideoMode & mode = pdu;
	mode.m_resolution.SetTag(cifMPI > 0 ? H245_H261VideoMode_resolution::e_cif : 
										  H245_H261VideoMode_resolution::e_qcif);
	mode.m_bitRate = maxBitRate;
	mode.m_stillImageTransmission = FALSE;
	
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
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, XM_QCIF_WIDTH);
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, XM_QCIF_HEIGHT);
	}
	else
	{
		qcifMPI = 0;
	}
	
	if (h261.HasOptionalField(H245_H261VideoCapability::e_cifMPI)) {
		cifMPI = h261.m_cifMPI;
		mediaFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption, OpalMediaFormat::VideoClockRate*100*cifMPI/2997);
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, XM_CIF_WIDTH);
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, XM_CIF_HEIGHT);
	}
	else
	{
		cifMPI = 0;
	}
	
	maxBitRate = h261.m_maxBitRate;
	if(maxBitRate > XM_MAX_H261_BITRATE)
	{
		maxBitRate = XM_MAX_H261_BITRATE;
	}
	mediaFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, maxBitRate);

	return TRUE;
}

BOOL XM_H323_H261_Capability::IsValidCapabilityForSending() const
{
	return TRUE;
}

BOOL XM_H323_H261_Capability::IsValidCapabilityForReceiving() const
{
	return TRUE;
}

PObject::Comparison XM_H323_H261_Capability::CompareTo(const XMH323VideoCapability & obj) const
{
	if(PIsDescendant(&obj, XM_H323_H261_Capability))
	{	
		const XM_H323_H261_Capability & other = (const XM_H323_H261_Capability &)obj;
		
		if((cifMPI > 0) && (other.cifMPI > 0))
		{
			return EqualTo;
		}
		else if(cifMPI > 0)
		{
			return GreaterThan;
		}
		else if(other.cifMPI > 0)
		{
			return LessThan;
		}
		else if((qcifMPI > 0) && (other.qcifMPI > 0))
		{
			return EqualTo;
		}
		else if(qcifMPI > 0)
		{
			return GreaterThan;
		}
		else if(other.qcifMPI > 0)
		{
			return LessThan;
		}
		else
		{
			return EqualTo;
		}
	}
	
	return LessThan;
}

#pragma mark XM_H323_H263_Capability methods

XM_H323_H263_Capability::XM_H323_H263_Capability()
{
	sqcifMPI = 1;
	qcifMPI = 1;
	cifMPI = 1;
	cif4MPI = 0;
	cif16MPI = 0;
	
	maxBitRate = _XMGetVideoBandwidthLimit() / 100;
	if(maxBitRate > XM_MAX_H263_BITRATE)
	{
		maxBitRate = XM_MAX_H263_BITRATE;
	}
	
	slowSqcifMPI = 0;
	slowQcifMPI = 0;
	slowCifMPI = 0;
	slowCif4MPI = 0;
	slowCif16MPI = 0;
	isH263PlusCapability = FALSE;
}

PObject * XM_H323_H263_Capability::Clone() const
{
	XM_H323_H263_Capability *h263Capability = new XM_H323_H263_Capability(*this);
	return h263Capability;
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

	if(((sqcifMPI > 0) && (other.sqcifMPI > 0)) ||
	   ((qcifMPI > 0) && (other.qcifMPI > 0)) ||
	   ((cifMPI > 0) && (other.cifMPI > 0)) ||
	   ((cif4MPI > 0) && (other.cif4MPI > 0)) ||
	   ((cif16MPI > 0) && (other.cif16MPI > 0)) ||
	   ((slowSqcifMPI > 0) && (other.slowSqcifMPI > 0)) ||
	   ((slowQcifMPI > 0) && (other.slowQcifMPI > 0)) ||
	   ((slowCifMPI > 0) && (other.slowCifMPI > 0)) ||
	   ((slowCif4MPI > 0) && (other.slowCif4MPI > 0)) ||
	   ((slowCif16MPI > 0) && (other.slowCif16MPI > 0)))
	{
		return EqualTo;
	}
	
	return LessThan;
}

unsigned XM_H323_H263_Capability::GetSubType() const
{
	return H245_VideoCapability::e_h263VideoCapability;
}

PString XM_H323_H263_Capability::GetFormatName() const
{
	return XM_MEDIA_FORMAT_H263;
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
	h263.m_unrestrictedVector = FALSE;
	h263.m_arithmeticCoding = FALSE;
	h263.m_advancedPrediction = FALSE;
	h263.m_pbFrames = FALSE;
	h263.m_temporalSpatialTradeOffCapability = FALSE;
	
	h263.IncludeOptionalField(H245_H263VideoCapability::e_hrd_B);
	h263.m_hrd_B = 0;
	
	h263.IncludeOptionalField(H245_H263VideoCapability::e_bppMaxKb);
	h263.m_bppMaxKb = 0;
	
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
	mode.m_bitRate = FALSE;
	mode.m_unrestrictedVector = FALSE;
	mode.m_arithmeticCoding = FALSE;
	mode.m_advancedPrediction = FALSE;
	mode.m_pbFrames = FALSE;
	mode.m_errorCompensation = FALSE;
	
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
		//mediaFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption, OpalMediaFormat::VideoClockRate*100*cif4MPI/2997);
		//mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::CIF4Width);
		//mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::CIF4Height);
	}
	else if(h263.HasOptionalField(H245_H263VideoCapability::e_slowCif4MPI))
	{
		cif4MPI = 0;
		slowCif4MPI = h263.m_slowCif4MPI;
		//mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::CIF4Width);
		//mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::CIF4Height);
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
		//mediaFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption, OpalMediaFormat::VideoClockRate*100*cif16MPI/2997);
		//mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::CIF16Width);
		//mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::CIF16Height);
	}
	else if(h263.HasOptionalField(H245_H263VideoCapability::e_slowCif16MPI))
	{
		cif16MPI = 0;
		slowCif16MPI = h263.m_slowCif16MPI;
		//mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, PVideoDevice::CIF16Width);
		//mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, PVideoDevice::CIF16Height);
	}
	else
	{
		cif16MPI = 0;
		slowCif16MPI = 0;
	}
	
	maxBitRate = h263.m_maxBitRate;
	if(maxBitRate > XM_MAX_H263_BITRATE)
	{
		maxBitRate = XM_MAX_H263_BITRATE;
	}
	
	if(h263.HasOptionalField(H245_H263VideoCapability::e_h263Options))
	{
		isH263PlusCapability = TRUE;
	}
	else
	{
		isH263PlusCapability = FALSE;
	}
	
	mediaFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, maxBitRate);
	
	return TRUE;
}

BOOL XM_H323_H263_Capability::IsValidCapabilityForSending() const
{
	return TRUE;
}

BOOL XM_H323_H263_Capability::IsValidCapabilityForReceiving() const
{
	return TRUE;
}

PObject::Comparison XM_H323_H263_Capability::CompareTo(const XMH323VideoCapability & obj) const
{
	
	if(PIsDescendant(&obj, XM_H323_H263_Capability))
	{	
		PObject::Comparison result;
		const XM_H323_H263_Capability & other = (const XM_H323_H263_Capability &)obj;
		
		if((cifMPI > 0) && (other.cifMPI > 0))
		{
			result = EqualTo;
		}
		else if(cifMPI > 0)
		{
			result = GreaterThan;
		}
		else if(other.cifMPI > 0)
		{
			result = LessThan;
		}
		else if((qcifMPI > 0) && (other.qcifMPI > 0))
		{
			result = EqualTo;
		}
		else if(qcifMPI > 0)
		{
			result = GreaterThan;
		}
		else if(other.qcifMPI > 0)
		{
			result = LessThan;
		}
		else if((sqcifMPI > 0) && (other.sqcifMPI > 0))
		{
			result = EqualTo;
		}
		else if(sqcifMPI > 0)
		{
			result = GreaterThan;
		}
		else if(other.sqcifMPI > 0)
		{
			result = LessThan;
		}
		else if((slowCifMPI > 0) && (other.slowCifMPI > 0))
		{
			result = EqualTo;
		}
		else if(slowCifMPI > 0)
		{
			result = GreaterThan;
		}
		else if(other.slowCifMPI > 0)
		{
			result = LessThan;
		}
		else if((slowQcifMPI > 0) && (other.slowQcifMPI > 0))
		{
			result = EqualTo;
		}
		else if(slowQcifMPI > 0)
		{
			result = GreaterThan;
		}
		else if(other.slowQcifMPI > 0)
		{
			result = LessThan;
		}
		else if((slowSqcifMPI > 0) && (other.slowSqcifMPI > 0))
		{
			result = EqualTo;
		}
		else if(slowSqcifMPI > 0)
		{
			result = GreaterThan;
		}
		else if(other.slowSqcifMPI > 0)
		{
			result = LessThan;
		}
		else
		{
			result = EqualTo;
		}
		
		if(result == EqualTo)
		{
			BOOL ownIsPlus = IsH263PlusCapability();
			BOOL otherIsPlus = other.IsH263PlusCapability();
			
			if(ownIsPlus && !otherIsPlus)
			{
				result = GreaterThan;
			}
			else if(!ownIsPlus && otherIsPlus)
			{
				result = LessThan;
			}
		}
		
		return result;
	}
	
	return LessThan;
}

BOOL XM_H323_H263_Capability::IsH263PlusCapability() const
{
	return isH263PlusCapability;
}

void XM_H323_H263_Capability::SetIsH263PlusCapability(BOOL flag)
{
	isH263PlusCapability = flag;
}

#pragma mark XM_H323_H264_Capability Methods

XM_H323_H264_Capability::XM_H323_H264_Capability()
{
	maxBitRate = _XMGetVideoBandwidthLimit() / 100;
	
	if(maxBitRate > XM_MAX_H264_BITRATE)
	{
		maxBitRate = XM_MAX_H264_BITRATE;
	}
	
	profile = XM_H264_PROFILE_CODE_BASELINE;
	level = XM_H264_LEVEL_CODE_2;
}

PObject * XM_H323_H264_Capability::Clone() const
{
	XM_H323_H264_Capability *cap = new XM_H323_H264_Capability(*this);
	return cap;
}

PObject::Comparison XM_H323_H264_Capability::Compare(const PObject & obj) const
{
	if(!PIsDescendant(&obj, XM_H323_H264_Capability))
	{
		return LessThan;
	}
	
	Comparison result = H323Capability::Compare(obj);
	return result;
}

unsigned XM_H323_H264_Capability::GetSubType() const
{
	return H245_VideoCapability::e_genericVideoCapability;
}

PString XM_H323_H264_Capability::GetFormatName() const
{
	return _XMMediaFormat_H264;
}

BOOL XM_H323_H264_Capability::OnSendingPDU(H245_VideoCapability & cap) const
{
	cap.SetTag(H245_VideoCapability::e_genericVideoCapability);
	
	H245_GenericCapability & h264 = cap;
	
	H245_CapabilityIdentifier & h264CapabilityIdentifier = h264.m_capabilityIdentifier;
	h264CapabilityIdentifier.SetTag(H245_CapabilityIdentifier::e_standard);
	PASN_ObjectId & h264ObjectId = h264CapabilityIdentifier;
	h264ObjectId.SetValue("0.0.8.241.0.0.1");
	
	h264.IncludeOptionalField(H245_GenericCapability::e_maxBitRate);
	h264.m_maxBitRate = maxBitRate;
	
	h264.IncludeOptionalField(H245_GenericCapability::e_collapsing);
	H245_ArrayOf_GenericParameter & h264Collapsing = h264.m_collapsing;
	h264Collapsing.SetSize(2);
	
	H245_GenericParameter & h264Profile = h264Collapsing[0];
	H245_ParameterIdentifier & profileIdentifier = h264Profile.m_parameterIdentifier;
	profileIdentifier.SetTag(H245_ParameterIdentifier::e_standard);
	PASN_Integer & profileIdentifierInteger = profileIdentifier;
	profileIdentifierInteger.SetValue(41);
	H245_ParameterValue & profileValue = h264Profile.m_parameterValue;
	profileValue.SetTag(H245_ParameterValue::e_booleanArray);
	PASN_Integer & profileValueInteger = profileValue;
	profileValueInteger.SetValue(profile);
	
	H245_GenericParameter & h264Level = h264Collapsing[1];
	H245_ParameterIdentifier & levelIdentifier = h264Level.m_parameterIdentifier;
	levelIdentifier.SetTag(H245_ParameterIdentifier::e_standard);
	PASN_Integer & levelIdentifierInteger = levelIdentifier;
	levelIdentifierInteger.SetValue(42);
	H245_ParameterValue & levelValue = h264Level.m_parameterValue;
	levelValue.SetTag(H245_ParameterValue::e_unsignedMin);
	PASN_Integer & levelValueInteger = levelValue;
	levelValueInteger.SetValue(level);
	
	return TRUE;
}

BOOL XM_H323_H264_Capability::OnSendingPDU(H245_VideoMode & pdu) const
{
	cout << "On sending H.264 VideoMode" << endl;
	
	return TRUE;
}

BOOL XM_H323_H264_Capability::OnReceivedPDU(const H245_VideoCapability & cap)
{
	if(cap.GetTag() != H245_VideoCapability::e_genericVideoCapability)
	{
		return FALSE;
	}
	
	const H245_GenericCapability & h264 = cap;
	
	const H245_CapabilityIdentifier & h264CapabilityIdentifier = h264.m_capabilityIdentifier;
	if(h264CapabilityIdentifier.GetTag() != H245_CapabilityIdentifier::e_standard)
	{
		return FALSE;
	}
	
	const PASN_ObjectId & h264ObjectId = h264CapabilityIdentifier;
	if(h264ObjectId != "0.0.8.241.0.0.1")
	{
		return FALSE;
	}
	
	OpalMediaFormat & mediaFormat = GetWritableMediaFormat();
	
	if(!h264.HasOptionalField(H245_GenericCapability::e_maxBitRate))
	{
		return FALSE;
	}
	maxBitRate = h264.m_maxBitRate;
	if(maxBitRate > XM_MAX_H264_BITRATE)
	{
		maxBitRate = XM_MAX_H264_BITRATE;
	}
	
	if(!h264.HasOptionalField(H245_GenericCapability::e_collapsing))
	{
		return FALSE;
	}
	
	const H245_ArrayOf_GenericParameter & h264Collapsing = h264.m_collapsing;
	PINDEX size = h264Collapsing.GetSize();
	PINDEX i;
	for(i = 0; i < size; i++)
	{
		const H245_GenericParameter & parameter = h264Collapsing[i];
		
		const H245_ParameterIdentifier & parameterIdentifier = parameter.m_parameterIdentifier;
		if(parameterIdentifier.GetTag() != H245_ParameterIdentifier::e_standard)
		{
			break;
		}
		
		const PASN_Integer & parameterInteger = parameterIdentifier;
		
		const H245_ParameterValue & parameterValue = parameter.m_parameterValue;
		
		switch(parameterInteger)
		{
			case 41:
				if(parameterValue.GetTag() == H245_ParameterValue::e_booleanArray)
				{
					const PASN_Integer & profileValueInteger = parameterValue;
					profile = profileValueInteger;
				}
				break;
			case 42:
				if(parameterValue.GetTag() ==H245_ParameterValue::e_unsignedMin)
				{
					const PASN_Integer & levelValueInteger = parameterValue;
					level = levelValueInteger;
				}
				break;
			default:
				break;
		}
	}
	
	unsigned width = 0;
	unsigned height = 0;
	
	if(level < XM_H264_LEVEL_CODE_1_1)
	{
		width = PVideoDevice::QCIFWidth;
		height = PVideoDevice::QCIFHeight;
		if(maxBitRate > 640)
		{
			maxBitRate = 640;
		}
	}
	else if(level < XM_H264_LEVEL_CODE_1_2)
	{
		width = PVideoDevice::QCIFWidth;
		height = PVideoDevice::QCIFHeight;
		if(maxBitRate > 1280)
		{
			maxBitRate = 1280;
		}
	}
	else if(level < XM_H264_LEVEL_CODE_1_3)
	{
		width = PVideoDevice::CIFWidth;
		height = PVideoDevice::CIFHeight;
		if(maxBitRate > 3840)
		{
			maxBitRate = 3840;
		}
	}
	else if(level < XM_H264_LEVEL_CODE_2)
	{
		width = PVideoDevice::CIFWidth;
		height = PVideoDevice::CIFHeight;
		if(maxBitRate > 7680)
		{
			maxBitRate = 7680;
		}
	}
	else
	{
		width = PVideoDevice::CIFWidth;
		height = PVideoDevice::CIFHeight;
		if(maxBitRate > 20000)
		{
			maxBitRate = 20000;
		}
	}
	
	mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption, width);
	mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption, height);
	mediaFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, maxBitRate);

	return TRUE;
}

BOOL XM_H323_H264_Capability::IsValidCapabilityForSending() const
{
	if(((profile & XM_H264_PROFILE_CODE_BASELINE) != 0) &&
	   (level <= XM_H264_LEVEL_CODE_2))
	{
		if(XMTransmitterMediaPatch::GetH264EnableLimitedMode() == FALSE && 
		   XMTransmitterMediaPatch::GetH264PacketizationMode() != XM_H264_PACKETIZATION_MODE_NON_INTERLEAVED)
		{
			return FALSE;
		}
		return TRUE;
	}
	return FALSE;
}

BOOL XM_H323_H264_Capability::IsValidCapabilityForReceiving() const
{
	if(profile <= (XM_H264_PROFILE_CODE_MAIN | XM_H264_PROFILE_CODE_BASELINE) &&
	   level <= XM_H264_LEVEL_CODE_2)
	{
		return TRUE;
	}
	return FALSE;
}

PObject::Comparison XM_H323_H264_Capability::CompareTo(const XMH323VideoCapability & obj) const
{
	if(PIsDescendant(&obj, XM_H323_H264_Capability))
	{	
		const XM_H323_H264_Capability & other = (const XM_H323_H264_Capability &)obj;
		
		if(((profile & XM_H264_PROFILE_CODE_BASELINE) != 0) && 
		   ((other.profile & XM_H264_PROFILE_CODE_BASELINE) == 0))
		{
			return GreaterThan;
		}
		else if(((profile & XM_H264_PROFILE_CODE_BASELINE) == 0) &&
				((other.profile & XM_H264_PROFILE_CODE_BASELINE) != 0))
		{
			return LessThan;
		}
		else
		{
			if(level == other.level)
			{
				return EqualTo;
			}
			else if(level > other.level)
			{
				return GreaterThan;
			}
			else
			{
				return LessThan;
			}
		}
		
	}
	return LessThan;
}

unsigned XM_H323_H264_Capability::GetProfile() const
{	
	return XM_H264_PROFILE_BASELINE;
}

unsigned XM_H323_H264_Capability::GetLevel() const
{
	if(level < XM_H264_LEVEL_CODE_1_B)
	{
		return XM_H264_LEVEL_1;
	} 
	else if(level < XM_H264_LEVEL_CODE_1_1)
	{
		return XM_H264_LEVEL_1_B;
	}
	else if(level < XM_H264_LEVEL_CODE_1_2)
	{
		return XM_H264_LEVEL_1_1;
	}
	else if(level < XM_H264_LEVEL_CODE_1_3)
	{
		return XM_H264_LEVEL_1_2;
	}
	else if(level < XM_H264_LEVEL_CODE_2)
	{
		return XM_H264_LEVEL_1_3;
	}
	
	return XM_H264_LEVEL_2;
}