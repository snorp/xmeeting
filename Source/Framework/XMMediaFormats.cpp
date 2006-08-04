/*
 * $Id: XMMediaFormats.cpp,v 1.21 2006/08/04 20:46:08 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#include <asn/h245.h>

#include "XMOpalManager.h"
#include "XMMediaFormats.h"
#include "XMBridge.h"
#include "XMTransmitterMediaPatch.h"

#define XM_CIF_WIDTH PVideoDevice::CIFWidth
#define XM_CIF_HEIGHT PVideoDevice::CIFHeight
#define XM_QCIF_WIDTH PVideoDevice::QCIFWidth
#define XM_QCIF_HEIGHT PVideoDevice::QCIFHeight
#define XM_SQCIF_WIDTH 128
#define XM_SQCIF_HEIGHT PVideoDevice::SQCIFHeight

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

#pragma mark -
#pragma mark MediaFormat Strings

const char *_XMMediaFormatIdentifier_G711_uLaw = "*g.711-ulaw*";
const char *_XMMediaFormatIdentifier_G711_ALaw = "*g.711-alaw*";

// Video MediaFormats

const char *_XMMediaFormatIdentifier_H261 = "*xm-h.261*";
const char *_XMMediaFormatIdentifier_H263 = "*xm-h.263*";
const char *_XMMediaFormatIdentifier_H264 = "*xm-h.264*";

const char *_XMMediaFormat_Video = "XM-Video";
const char *_XMMediaFormat_H261 = "XM-H.261";
const char *_XMMediaFormat_H263 = "XM-H.263";
const char *_XMMediaFormat_H263Plus = "XM-H.263-Plus";
const char *_XMMediaFormat_H264 = "XM-H.264";

const char *_XMMediaFormatName_H261 = "H.261";
const char *_XMMediaFormatName_H263 = "H.263";
const char *_XMMediaFormatName_H264 = "H.264";

const char *_XMMediaFormatEncoding_H261 = "H261";
const char *_XMMediaFormatEncoding_H263 = "H263";
const char *_XMMediaFormatEncoding_H263Plus = "H263-1998";
const char *_XMMediaFormatEncoding_H264 = "H264";

static BOOL isReceivingRFC2429 = FALSE;
static unsigned h264Profile = XM_H264_PROFILE_BASELINE;
static unsigned h264Level = XM_H264_LEVEL_1_3;
static unsigned h264PacketizationMode = XM_H264_PACKETIZATION_MODE_SINGLE_NAL;
static BOOL h264EnableLimitedMode = FALSE;

#pragma mark -
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
													_XMMediaFormatEncoding_H261,
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
													_XMMediaFormatEncoding_H263,
													XM_MAX_FRAME_WIDTH,
													XM_MAX_FRAME_HEIGHT,
													XM_MAX_FRAME_RATE,
													XM_MAX_H263_BITRATE);
	return XMMediaFormat_H263;
}

const OpalVideoFormat & XMGetMediaFormat_H263Plus()
{
	static const OpalVideoFormat XMMediaFormat_H263Plus(_XMMediaFormat_H263Plus,
														(RTP_DataFrame::PayloadTypes)96,
														_XMMediaFormatEncoding_H263Plus,
														XM_MAX_FRAME_WIDTH,
														XM_MAX_FRAME_HEIGHT,
														XM_MAX_FRAME_RATE,
														XM_MAX_H264_BITRATE);
	return XMMediaFormat_H263Plus;
}

const OpalVideoFormat & XMGetMediaFormat_H264()
{
	static const OpalVideoFormat XMMediaFormat_H264(_XMMediaFormat_H264,
													(RTP_DataFrame::PayloadTypes)97,
													_XMMediaFormatEncoding_H264,
													XM_MAX_FRAME_WIDTH,
													XM_MAX_FRAME_HEIGHT,
													XM_MAX_FRAME_RATE,
													XM_MAX_H264_BITRATE);
	return XMMediaFormat_H264;
}

#pragma mark -
#pragma mark Identifying MediaFormats

BOOL _XMIsVideoMediaFormat(const OpalMediaFormat & mediaFormat)
{
	if(mediaFormat == XM_MEDIA_FORMAT_H261 ||
	   mediaFormat == XM_MEDIA_FORMAT_H263 ||
	   mediaFormat == XM_MEDIA_FORMAT_H263PLUS ||
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
	else if(mediaFormat == XM_MEDIA_FORMAT_H263 ||
			mediaFormat == XM_MEDIA_FORMAT_H263PLUS)
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
		return XMVideoSize_NoVideo;
	}
}

const char *_XMGetMediaFormatName(const OpalMediaFormat & mediaFormat)
{
	if(mediaFormat == XM_MEDIA_FORMAT_H261)
	{
		return _XMMediaFormatName_H261;
	}
	else if(mediaFormat == XM_MEDIA_FORMAT_H263 ||
			mediaFormat == XM_MEDIA_FORMAT_H263PLUS)
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

#pragma mark -
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

#pragma mark -
#pragma mark XMVideoTranscoder methods

XMVideoTranscoder::XMVideoTranscoder(const OpalVideoFormat & src, const OpalVideoFormat & dst)
: OpalVideoTranscoder(src, dst)
{
}

XMVideoTranscoder::~XMVideoTranscoder()
{
}

PINDEX XMVideoTranscoder::GetOptimalDataFrameSize(BOOL input) const
{
	return RTP_DataFrame::MaxEthernetPayloadSize;
}

BOOL XMVideoTranscoder::ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst)
{
	return TRUE;
}

#pragma mark -
#pragma mark XM_H261_VIDEO methods

XM_H261_VIDEO::XM_H261_VIDEO()
: XMVideoTranscoder(XM_MEDIA_FORMAT_H261, XM_MEDIA_FORMAT_VIDEO)
{
}

XM_H261_VIDEO::~XM_H261_VIDEO()
{
}

#pragma mark -
#pragma mark XM_H263_VIDEO methods

XM_H263_VIDEO::XM_H263_VIDEO()
: XMVideoTranscoder(XM_MEDIA_FORMAT_H263, XM_MEDIA_FORMAT_VIDEO)
{
}

XM_H263_VIDEO::~XM_H263_VIDEO()
{
}

#pragma mark -
#pragma mark XM_H263PLUS_VIDEO methods

XM_H263PLUS_VIDEO::XM_H263PLUS_VIDEO()
: XMVideoTranscoder(XM_MEDIA_FORMAT_H263PLUS, XM_MEDIA_FORMAT_VIDEO)
{
}

XM_H263PLUS_VIDEO::~XM_H263PLUS_VIDEO()
{
}

#pragma mark -
#pragma mark XM_H264_VIDEO methods

XM_H264_VIDEO::XM_H264_VIDEO()
: XMVideoTranscoder(XM_MEDIA_FORMAT_H264, XM_MEDIA_FORMAT_VIDEO)
{
}

XM_H264_VIDEO::~XM_H264_VIDEO()
{
}

#pragma mark -
#pragma mark XM_VIDEO_H261 methods

XM_VIDEO_H261::XM_VIDEO_H261()
: XMVideoTranscoder(XM_MEDIA_FORMAT_VIDEO, XM_MEDIA_FORMAT_H261)
{
}

XM_VIDEO_H261::~XM_VIDEO_H261()
{
}

#pragma mark -
#pragma mark XM_VIDEO_H263 methods

XM_VIDEO_H263::XM_VIDEO_H263()
: XMVideoTranscoder(XM_MEDIA_FORMAT_VIDEO, XM_MEDIA_FORMAT_H263)
{
}

XM_VIDEO_H263::~XM_VIDEO_H263()
{
}

#pragma mark -
#pragma mark XM_VIDEO_H263PLUS methods

XM_VIDEO_H263PLUS::XM_VIDEO_H263PLUS()
: XMVideoTranscoder(XM_MEDIA_FORMAT_VIDEO, XM_MEDIA_FORMAT_H263PLUS)
{
}

XM_VIDEO_H263PLUS::~XM_VIDEO_H263PLUS()
{
}

#pragma mark -
#pragma mark XM_VIDEO_H264 methods

XM_VIDEO_H264::XM_VIDEO_H264()
: XMVideoTranscoder(XM_MEDIA_FORMAT_VIDEO, XM_MEDIA_FORMAT_H264)
{
}

XM_VIDEO_H264::~XM_VIDEO_H264()
{
}

#pragma mark -
#pragma mark XM_H323_H261_Capability methods

XM_H323_H261_Capability::XM_H323_H261_Capability()
{
	qcifMPI = 1;
	cifMPI = 1;
	
	maxBitRate = _XMGetMaxH261BitRate();
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

BOOL XM_H323_H261_Capability::OnSendingTerminalCapabilitySet(H245_TerminalCapabilitySet & terminalCapabilitySet) const
{
	return TRUE;
}

BOOL XM_H323_H261_Capability::OnReceivedTerminalCapabilitySet(const H245_H2250Capability & h2250Capability)
{
	return TRUE;
}

BOOL XM_H323_H261_Capability::OnSendingPDU(H245_H2250LogicalChannelParameters & param) const
{
	param.RemoveOptionalField(H245_H2250LogicalChannelParameters::e_silenceSuppression);
	return TRUE;
}

BOOL XM_H323_H261_Capability::OnReceivedPDU(const H245_H2250LogicalChannelParameters & param)
{
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

#pragma mark -
#pragma mark XM_H323_H263_Capability methods

XM_H323_H263_Capability::XM_H323_H263_Capability()
{
	XM_H323_H263_Capability(FALSE);
}

XM_H323_H263_Capability::XM_H323_H263_Capability(BOOL theIsH263PlusCapability)
{
	sqcifMPI = 1;
	qcifMPI = 1;
	cifMPI = 1;
	cif4MPI = 0;
	cif16MPI = 0;
	
	maxBitRate = _XMGetMaxH263BitRate();
	
	slowSqcifMPI = 0;
	slowQcifMPI = 0;
	slowCifMPI = 0;
	slowCif4MPI = 0;
	slowCif16MPI = 0;
	
	isH263PlusCapability = theIsH263PlusCapability;
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
		if(other.isH263PlusCapability == isH263PlusCapability)
		{
			return EqualTo;
		}
	}
	
	return LessThan;
}

unsigned XM_H323_H263_Capability::GetSubType() const
{
	return H245_VideoCapability::e_h263VideoCapability;
}

PString XM_H323_H263_Capability::GetFormatName() const
{
	if(isH263PlusCapability == TRUE)
	{
		return XM_MEDIA_FORMAT_H263PLUS;
	}
	else
	{
		return XM_MEDIA_FORMAT_H263;
	}
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
		//h263.IncludeOptionalField(H245_H263VideoCapability::e_cif4MPI);
		//h263.m_cif4MPI = cif4MPI;
	}
	if(cif16MPI > 0)
	{
		//h263.IncludeOptionalField(H245_H263VideoCapability::e_cif16MPI);
		//h263.m_cif16MPI = cif16MPI;
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
		//h263.IncludeOptionalField(H245_H263VideoCapability::e_slowCif4MPI);
		//h263.m_slowCif4MPI = slowCif4MPI;
	}
	if(slowCif16MPI > 0 && cif16MPI == 0)
	{
		//h263.IncludeOptionalField(H245_H263VideoCapability::e_slowCif16MPI);
		//h263.m_slowCif16MPI = slowCif16MPI;
	}
	
	if(isH263PlusCapability == TRUE)
	{
		h263.IncludeOptionalField(H245_H263VideoCapability::e_h263Options);
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
	
	if(h263.HasOptionalField(H245_H263VideoCapability::e_h263Options))
	{
		isH263PlusCapability = TRUE;
	}
	else
	{
		isH263PlusCapability = FALSE;
	}
	
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

	mediaFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption, maxBitRate);
	
	return TRUE;
}

BOOL XM_H323_H263_Capability::OnSendingTerminalCapabilitySet(H245_TerminalCapabilitySet & terminalCapabilitySet) const
{
	if(isH263PlusCapability)
	{
		// Enter RFC2429 media packetization information
		H245_MultiplexCapability & multiplexCapability = terminalCapabilitySet.m_multiplexCapability;
		H245_H2250Capability & h2250Capability = (H245_H2250Capability &)multiplexCapability;
		H245_MediaPacketizationCapability & mediaPacketizationCapability = h2250Capability.m_mediaPacketizationCapability;
		
		BOOL alreadyPresent = FALSE;
		if(mediaPacketizationCapability.HasOptionalField(H245_MediaPacketizationCapability::e_rtpPayloadType))
		{
			alreadyPresent = TRUE;
		}
		else
		{
			mediaPacketizationCapability.IncludeOptionalField(H245_MediaPacketizationCapability::e_rtpPayloadType);
		}
		
		H245_ArrayOf_RTPPayloadType & arrayOfRTPPayloadType = mediaPacketizationCapability.m_rtpPayloadType;
		
		PINDEX index = 0;
		if(alreadyPresent == TRUE)
		{
			index = arrayOfRTPPayloadType.GetSize();
			arrayOfRTPPayloadType.SetSize(index + 1);
		}
		else
		{
			arrayOfRTPPayloadType.SetSize(1);
		}
		
		H245_RTPPayloadType & h263PayloadType = arrayOfRTPPayloadType[index];
		H245_RTPPayloadType_payloadDescriptor & h263Descriptor = h263PayloadType.m_payloadDescriptor;
		h263Descriptor.SetTag(H245_RTPPayloadType_payloadDescriptor::e_rfc_number);
		PASN_Integer & h263Integer = (PASN_Integer &)h263Descriptor;
		h263Integer.SetValue(2429);
	}
	
	return TRUE;
}

BOOL XM_H323_H263_Capability::OnReceivedTerminalCapabilitySet(const H245_H2250Capability & h2250Capability)
{
	isReceivingRFC2429 = FALSE;
	
	return TRUE;
}

BOOL XM_H323_H263_Capability::OnSendingPDU(H245_H2250LogicalChannelParameters & param) const
{
	param.RemoveOptionalField(H245_H2250LogicalChannelParameters::e_silenceSuppression);
	
	if(isH263PlusCapability)
	{
		param.IncludeOptionalField(H245_H2250LogicalChannelParameters::e_mediaPacketization);
		H245_H2250LogicalChannelParameters_mediaPacketization & mediaPacketization = 
			param.m_mediaPacketization;
		
		mediaPacketization.SetTag(H245_H2250LogicalChannelParameters_mediaPacketization::e_rtpPayloadType);
		
		H245_RTPPayloadType & rtpPayloadType = mediaPacketization;
		
		H245_RTPPayloadType_payloadDescriptor & payloadDescriptor = rtpPayloadType.m_payloadDescriptor;
		
		payloadDescriptor.SetTag(H245_RTPPayloadType_payloadDescriptor::e_rfc_number);
		PASN_Integer & rfcValue = payloadDescriptor;
		rfcValue.SetValue(2429);
		
		rtpPayloadType.IncludeOptionalField(H245_RTPPayloadType::e_payloadType);
		rtpPayloadType.m_payloadType = 96;
	}
	
	return TRUE;
}

BOOL XM_H323_H263_Capability::OnReceivedPDU(const H245_H2250LogicalChannelParameters & param)
{	
	if(!param.HasOptionalField(H245_H2250LogicalChannelParameters::e_mediaPacketization))
	{
		return TRUE;
	}
	
	const H245_H2250LogicalChannelParameters_mediaPacketization & mediaPacketization = 
		param.m_mediaPacketization;
	
	if(mediaPacketization.GetTag() != H245_H2250LogicalChannelParameters_mediaPacketization::e_rtpPayloadType)
	{
		return TRUE;
	}
	
	const H245_RTPPayloadType & rtpPayloadType = mediaPacketization;
	const H245_RTPPayloadType_payloadDescriptor & payloadDescriptor = rtpPayloadType.m_payloadDescriptor;
	
	if(payloadDescriptor.GetTag() != H245_RTPPayloadType_payloadDescriptor::e_rfc_number)
	{
		return TRUE;
	}
	
	const PASN_Integer & rfcValue = payloadDescriptor;
	
	if(rfcValue.GetValue() == 2429)
	{
		isReceivingRFC2429 = TRUE;
	}
	
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
			if(isH263PlusCapability && !other.isH263PlusCapability)
			{
				result = GreaterThan;
			}
			else if(!isH263PlusCapability && other.isH263PlusCapability)
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

#pragma mark -
#pragma mark XM_H323_H263PLUS_Capability Methods

XM_H323_H263PLUS_Capability::XM_H323_H263PLUS_Capability()
: XM_H323_H263_Capability(TRUE)
{
}

#pragma mark -
#pragma mark XM_H323_H264_Capability Methods

XM_H323_H264_Capability::XM_H323_H264_Capability()
{
	maxBitRate = _XMGetMaxH264BitRate();
	
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

BOOL XM_H323_H264_Capability::OnSendingTerminalCapabilitySet(H245_TerminalCapabilitySet & terminalCapabilitySet) const
{
	// Signal H.264 packetization modes understood by this endpoint
	H245_MultiplexCapability & multiplexCapability = terminalCapabilitySet.m_multiplexCapability;
	H245_H2250Capability & h2250Capability = (H245_H2250Capability &)multiplexCapability;
	H245_MediaPacketizationCapability & mediaPacketizationCapability = h2250Capability.m_mediaPacketizationCapability;
	
	BOOL alreadyPresent = FALSE;
	if(mediaPacketizationCapability.HasOptionalField(H245_MediaPacketizationCapability::e_rtpPayloadType))
	{
		alreadyPresent = TRUE;
	}
	else
	{
		mediaPacketizationCapability.IncludeOptionalField(H245_MediaPacketizationCapability::e_rtpPayloadType);
	}
	
	H245_ArrayOf_RTPPayloadType & arrayOfRTPPayloadType = mediaPacketizationCapability.m_rtpPayloadType;

	PINDEX index = 0;
	if(alreadyPresent == TRUE)
	{
		index = arrayOfRTPPayloadType.GetSize();
		arrayOfRTPPayloadType.SetSize(index + 2);
	}
	else
	{
		arrayOfRTPPayloadType.SetSize(2);
	}
	
	H245_RTPPayloadType & h264PayloadTypeSingleNAL = arrayOfRTPPayloadType[index];
	H245_RTPPayloadType_payloadDescriptor & h264DescriptorSingleNAL = h264PayloadTypeSingleNAL.m_payloadDescriptor;
	h264DescriptorSingleNAL.SetTag(H245_RTPPayloadType_payloadDescriptor::e_oid);
	PASN_ObjectId & h264ObjectIdSingleNAL = (PASN_ObjectId &)h264DescriptorSingleNAL;
	h264ObjectIdSingleNAL.SetValue("0.0.8.241.0.0.0.0");
	
	H245_RTPPayloadType & h264PayloadTypeNonInterleaved = arrayOfRTPPayloadType[index+1];
	H245_RTPPayloadType_payloadDescriptor & h264DescriptorNonInterleaved = h264PayloadTypeNonInterleaved.m_payloadDescriptor;
	h264DescriptorNonInterleaved.SetTag(H245_RTPPayloadType_payloadDescriptor::e_oid);
	PASN_ObjectId & h264ObjectIdNonInterleaved = (PASN_ObjectId &)h264DescriptorNonInterleaved;
	h264ObjectIdNonInterleaved.SetValue("0.0.8.241.0.0.0.1");
	
	return TRUE;
}

BOOL XM_H323_H264_Capability::OnReceivedTerminalCapabilitySet(const H245_H2250Capability & h2250Capability)
{
	h264PacketizationMode = XM_H264_PACKETIZATION_MODE_SINGLE_NAL;
	
	const H245_MediaPacketizationCapability & mediaPacketizationCapability = h2250Capability.m_mediaPacketizationCapability;
	
	if(mediaPacketizationCapability.HasOptionalField(H245_MediaPacketizationCapability::e_rtpPayloadType))
	{
		const H245_ArrayOf_RTPPayloadType & arrayOfRTPPayloadType = mediaPacketizationCapability.m_rtpPayloadType;
		PINDEX size = arrayOfRTPPayloadType.GetSize();
		PINDEX i;
		
		for(i = 0; i < size; i++)
		{
			const H245_RTPPayloadType & payloadType = arrayOfRTPPayloadType[i];
			const H245_RTPPayloadType_payloadDescriptor & payloadDescriptor = payloadType.m_payloadDescriptor;
			if(payloadDescriptor.GetTag() == H245_RTPPayloadType_payloadDescriptor::e_oid)
			{
				const PASN_ObjectId & objectId = payloadDescriptor;
				if(objectId == "0.0.8.241.0.0.0.1")
				{
					h264PacketizationMode = XM_H264_PACKETIZATION_MODE_NON_INTERLEAVED;
				}
			}
		}
	}
	
	return TRUE;
}

BOOL XM_H323_H264_Capability::OnSendingPDU(H245_H2250LogicalChannelParameters & param) const
{
	param.RemoveOptionalField(H245_H2250LogicalChannelParameters::e_silenceSuppression);
	
	// Sending H.264, need to make sure which provile/level to use
	h264Profile = GetProfile();
	h264Level = GetLevel();
	
	return TRUE;
}

BOOL XM_H323_H264_Capability::OnReceivedPDU(const H245_H2250LogicalChannelParameters & param)
{
	return TRUE;
}

BOOL XM_H323_H264_Capability::IsValidCapabilityForSending() const
{
	if(((profile & XM_H264_PROFILE_CODE_BASELINE) != 0) &&
	   (level <= XM_H264_LEVEL_CODE_2))
	{
		if(h264EnableLimitedMode == FALSE && 
		   h264PacketizationMode != XM_H264_PACKETIZATION_MODE_NON_INTERLEAVED)
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

#pragma mark -
#pragma mark Packetization Functions

BOOL _XMIsReceivingRFC2429()
{
	return isReceivingRFC2429;
}

void _XMSetIsReceivingRFC2429(BOOL flag)
{
	isReceivingRFC2429 = flag;
}

unsigned _XMGetH264Profile()
{
	return h264Profile;
}

unsigned _XMGetH264Level()
{
	return h264Level;
}

unsigned _XMGetH264PacketizationMode()
{
	return h264PacketizationMode;
}

void _XMSetH264EnableLimitedMode(BOOL flag)
{
	h264EnableLimitedMode = flag;
}

#pragma mark -
#pragma mark SDP Functions

unsigned _XMGetMaxH261BitRate()
{
	unsigned maxBitRate = XMOpalManager::GetVideoBandwidthLimit() / 100;
	if(maxBitRate > XM_MAX_H261_BITRATE)
	{
		maxBitRate = XM_MAX_H261_BITRATE;
	}
	
	return maxBitRate;
}

PString _XMGetFMTP_H261(unsigned maxBitRate,
						XMVideoSize videoSize,
						unsigned mpi)
{
	if(maxBitRate == UINT_MAX)
	{
		maxBitRate = XMOpalManager::GetVideoBandwidthLimit() / 100; // SDP uses bitrate units of 100bits/s
	}
	if(maxBitRate > XM_MAX_H261_BITRATE)
	{
		maxBitRate = XM_MAX_H261_BITRATE;
	}
	
	if(videoSize == XMVideoSize_NoVideo)
	{
		return psprintf("CIF=%d QCIF=%d MaxBR=%d", mpi, mpi, maxBitRate);
	}
	else if(videoSize == XMVideoSize_CIF)
	{
		return psprintf("CIF=%d MaxBR=%d", mpi, maxBitRate);
	}
	else
	{
		return psprintf("QCIF=%d MaxBR=%d", mpi, maxBitRate);
	}
}

void _XMParseFMTP_H261(const PString & fmtp, unsigned & maxBitRate, XMVideoSize & videoSize, unsigned & mpi)
{
	maxBitRate = _XMGetMaxH261BitRate();
	videoSize = XMVideoSize_NoVideo;
	mpi = 1;
	
	const PStringArray tokens = fmtp.Tokenise(" ;");
	
	unsigned i;
	unsigned count = tokens.GetSize();
	
	for(i = 0; i < count; i++)
	{
		const PString & str = tokens[i];
		
		if(str.Left(4) == "CIF=")
		{
			PString mpiStr = str(4, 1000);
			mpi = mpiStr.AsUnsigned();
			videoSize = XMVideoSize_CIF;
		}
		else if(str.Left(5) == "QCIF=")
		{
			if(videoSize != XMVideoSize_CIF)
			{
				PString mpiStr = str(5, 1000);
				mpi = mpiStr.AsUnsigned();
				videoSize = XMVideoSize_QCIF;
			}
		}
		else if(str.Left(6) == "MaxBR=")
		{
			PString brStr = str(6, 1000);
			unsigned bitRate = brStr.AsUnsigned();
			if(bitRate < maxBitRate)
			{
				maxBitRate = bitRate;
			}
		}
	}
	
	if(videoSize == XMVideoSize_NoVideo)
	{
		videoSize = XMVideoSize_CIF;
	}
	
	if(mpi == 0)
	{
		mpi = 1;
	}
}

unsigned _XMGetMaxH263BitRate()
{
	unsigned maxBitRate = XMOpalManager::GetVideoBandwidthLimit() / 100;
	if(maxBitRate > XM_MAX_H263_BITRATE)
	{
		maxBitRate = XM_MAX_H263_BITRATE;
	}
	
	return maxBitRate;
}

PString _XMGetFMTP_H263(unsigned maxBitRate,
						XMVideoSize videoSize,
						unsigned mpi)
{
	if(maxBitRate == UINT_MAX)
	{
		maxBitRate = XMOpalManager::GetVideoBandwidthLimit() / 100;
	}
	if(maxBitRate > XM_MAX_H263_BITRATE)
	{
		maxBitRate = XM_MAX_H263_BITRATE;
	}
	
	if(videoSize == XMVideoSize_NoVideo)
	{
		return psprintf("CIF=%d QCIF=%d SQCIF=%d MaxBR=%d", mpi, mpi, mpi, maxBitRate);
	}
	else if(videoSize == XMVideoSize_CIF)
	{
		return psprintf("CIF=%d MaxBR=%d", mpi, maxBitRate);
	}
	else if(videoSize == XMVideoSize_QCIF)
	{
		return psprintf("QCIF=%d MaxBR=%d", mpi, maxBitRate);
	}
	else
	{
		return psprintf("SQCIF=%d MaxBR=%d", mpi, maxBitRate);
	}
}

void _XMParseFMTP_H263(const PString & fmtp, unsigned & maxBitRate, XMVideoSize & videoSize, unsigned & mpi)
{
	maxBitRate = _XMGetMaxH263BitRate();
	videoSize = XMVideoSize_NoVideo;
	mpi = 1;
	
	const PStringArray tokens = fmtp.Tokenise(" ;");
	
	unsigned i;
	unsigned count = tokens.GetSize();
	
	for(i = 0; i < count; i++)
	{
		const PString & str = tokens[i];
		
		if(str.Left(4) == "CIF=")
		{
			PString mpiStr = str(4, 1000);
			mpi = mpiStr.AsUnsigned();
			videoSize = XMVideoSize_CIF;
		}
		else if(str.Left(5) == "QCIF=")
		{
			if(videoSize != XMVideoSize_CIF)
			{
				PString mpiStr = str(5, 1000);
				mpi = mpiStr.AsUnsigned();
				videoSize = XMVideoSize_QCIF;
			}
		}
		else if(str.Left(6) == "SQCIF=")
		{
			if(videoSize != XMVideoSize_CIF &&
			   videoSize != XMVideoSize_QCIF)
			{
				PString mpiStr = str(6, 1000);
				mpi = mpiStr.AsUnsigned();
				videoSize = XMVideoSize_SQCIF;
			}
		}
		else if(str.Left(6) == "MaxBR=")
		{
			PString brStr = str(6, 1000);
			unsigned bitRate = brStr.AsUnsigned();
			if(bitRate < maxBitRate)
			{
				maxBitRate = bitRate;
			}
		}
	}
	
	if(videoSize == XMVideoSize_NoVideo)
	{
		videoSize = XMVideoSize_CIF;
	}
	
	if(mpi == 0)
	{
		mpi = 1;
	}
}

unsigned _XMGetMaxH264BitRate()
{
	unsigned maxBitRate = XMOpalManager::GetVideoBandwidthLimit() / 100;
	if(maxBitRate > XM_MAX_H264_BITRATE)
	{
		maxBitRate = XM_MAX_H264_BITRATE;
	}
	
	return maxBitRate;
}

PString _XMGetFMTP_H264(unsigned maxBitRate,
						XMVideoSize videoSize,
						unsigned mpi)
{
	return "";
}

void _XMParseFMTP_H264(const PString & fmtp, unsigned & maxBitRate, XMVideoSize & videoSize, unsigned & mpi)
{
}