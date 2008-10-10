/*
 * $Id: XMMediaFormats.cpp,v 1.35 2008/10/10 07:32:15 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#include <ptlib.h>
#include <ptlib/videoio.h>
#include <asn/h245.h>

#include "XMMediaFormats.h"
#include "XMBridge.h"

#define XM_CIF_WIDTH PVideoDevice::CIFWidth
#define XM_CIF_HEIGHT PVideoDevice::CIFHeight
#define XM_QCIF_WIDTH PVideoDevice::QCIFWidth
#define XM_QCIF_HEIGHT PVideoDevice::QCIFHeight
#define XM_SQCIF_WIDTH 128
#define XM_SQCIF_HEIGHT PVideoDevice::SQCIFHeight

#define XM_MAX_FRAME_WIDTH XM_CIF_WIDTH
#define XM_MAX_FRAME_HEIGHT XM_CIF_HEIGHT
#define XM_MAX_FRAME_RATE 30

#define XM_MAX_H261_BITRATE 960000
#define XM_MAX_H263_BITRATE 960000
#define XM_MAX_H264_BITRATE 768000
#define XM_DEFAULT_SIP_VIDEO_BITRATE 320000

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
const char *_XMMediaFormatIdentifier_Speex = "*Speex*";
const char *_XMMediaFormatIdentifier_GSM = "*GSM*";

// Video MediaFormats

const char *_XMMediaFormatIdentifier_H261 = "*xm-h.261*";
const char *_XMMediaFormatIdentifier_H263 = "*xm-h.263*";
const char *_XMMediaFormatIdentifier_H264 = "*xm-h.264*";

const char *_XMMediaFormat_H261 = "XM-H.261";
const char *_XMMediaFormat_H263 = "XM-H.263-1996";
const char *_XMMediaFormat_H263Plus = "XM-H.263-1998";
const char *_XMMediaFormat_H264 = "XM-H.264";

const char *_XMMediaFormatName_H261 = "H.261";
const char *_XMMediaFormatName_H263 = "H.263";
const char *_XMMediaFormatName_H264 = "H.264";

const char *_XMMediaFormatEncoding_H261 = "H261";
const char *_XMMediaFormatEncoding_H263 = "H263";
const char *_XMMediaFormatEncoding_H263Plus = "H263-1998";
//const char *_XMMediaFormatEncoding_H264 = "H264";
const char *_XMMediaFormatEncoding_H264 = NULL;

const char * const ProfileOption = "Profile";
const char * const LevelOption = "Level";
const char * const PacketizationOption = "Packetization";
const char * const H264LimitedModeOption = "H264LimitedMode";

#pragma mark -
#pragma mark MediaFormat Definitions

class XMMediaFormat_H261 : public OpalVideoFormat
{
public:
  XMMediaFormat_H261();
  static const PString & CIFOption()  { static PString s = "CIF MPI";  return s; }
  static const PString & QCIFOption() { static PString s = "QCIF MPI"; return s; }
};

XMMediaFormat_H261::XMMediaFormat_H261()
: OpalVideoFormat(_XMMediaFormat_H261,
                  RTP_DataFrame::H261,
                  _XMMediaFormatEncoding_H261,
                  XM_CIF_WIDTH,
                  XM_CIF_HEIGHT,
                  XM_MAX_FRAME_RATE,
                  XM_MAX_H261_BITRATE)
{
  AddOption(new OpalMediaOptionUnsigned(CIFOption(),  false, OpalMediaOption::MaxMerge, 1, 0, 30));
  AddOption(new OpalMediaOptionUnsigned(QCIFOption(), false, OpalMediaOption::MaxMerge, 1, 0, 30));
}

class XMMediaFormat_H263 : public OpalVideoFormat
{
public:
  XMMediaFormat_H263(bool isH263Plus);
  static const PString & SQCIFOption()      { static PString s = "SQCIF MPI";    return s; }
  static const PString & QCIFOption()       { static PString s = "QCIF MPI";     return s; }
  static const PString & CIFOption()        { static PString s = "CIF MPI";      return s; }
  static const PString & CIF4Option()       { static PString s = "CIF4 MPI";     return s; }
  static const PString & CIF16Option()      { static PString s = "CIF16 MPI";    return s; }
  static const PString & CanRFC2429Option() { static PString s = "Can RFC 2429"; return s; }
  static const PString & IsRFC2429Option()  { static PString s = "Is RFC 2429";  return s; }
};

XMMediaFormat_H263::XMMediaFormat_H263(bool isH263Plus)
: OpalVideoFormat((isH263Plus ? _XMMediaFormat_H263Plus : _XMMediaFormat_H263),
                  (isH263Plus ? (RTP_DataFrame::PayloadTypes)98 : RTP_DataFrame::H263),
                  (isH263Plus ? _XMMediaFormatEncoding_H263Plus : _XMMediaFormatEncoding_H263),
                  XM_CIF_WIDTH,
                  XM_CIF_HEIGHT,
                  XM_MAX_FRAME_RATE,
                  XM_MAX_H263_BITRATE)
{
  AddOption(new OpalMediaOptionUnsigned(SQCIFOption(),     false, OpalMediaOption::MaxMerge, 1, 0, 30));
  AddOption(new OpalMediaOptionUnsigned(QCIFOption(),      false, OpalMediaOption::MaxMerge, 1, 0, 30));
  AddOption(new OpalMediaOptionUnsigned(CIFOption(),       false, OpalMediaOption::MaxMerge, 1, 0, 30));
  AddOption(new OpalMediaOptionUnsigned(CIF4Option(),      false, OpalMediaOption::MaxMerge, 0, 0, 30));
  AddOption(new OpalMediaOptionUnsigned(CIF16Option(),     false, OpalMediaOption::MaxMerge, 0, 0, 30));
  AddOption(new OpalMediaOptionBoolean(CanRFC2429Option(), false, OpalMediaOption::MinMerge, false));
  AddOption(new OpalMediaOptionBoolean(IsRFC2429Option(),  false, OpalMediaOption::MinMerge, false));
  
  if (isH263Plus) {
    SetOptionBoolean(CanRFC2429Option(), true);
    SetOptionBoolean(IsRFC2429Option(), true);
  }
}

class XMMediaFormat_H264 : public OpalVideoFormat
{
public:
  XMMediaFormat_H264();
};

const OpalVideoFormat & XMGetMediaFormat_H261()
{
  static const XMMediaFormat_H261 format;
  return format;
}

const OpalVideoFormat & XMGetMediaFormat_H263()
{
	static const XMMediaFormat_H263 format(false);
	return format;
}

const OpalVideoFormat & XMGetMediaFormat_H263Plus()
{
	static const XMMediaFormat_H263 format(true);
	return format;
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

XMCodecIdentifier _XMGetMediaFormatCodec(const OpalMediaFormat & mediaFormat)
{
  if (mediaFormat == XM_MEDIA_FORMAT_H261) {
    return XMCodecIdentifier_H261;
  } else if (mediaFormat == XM_MEDIA_FORMAT_H263 || mediaFormat == XM_MEDIA_FORMAT_H263PLUS) {
    return XMCodecIdentifier_H263;
  } else if (mediaFormat == XM_MEDIA_FORMAT_H264) {
    return XMCodecIdentifier_H264;
  }
	
  return XMCodecIdentifier_UnknownCodec;
}

XMVideoSize _XMGetMediaFormatSize(const OpalMediaFormat & mediaFormat)
{
  unsigned width = mediaFormat.GetOptionInteger(OpalVideoFormat::FrameWidthOption());
  unsigned height = mediaFormat.GetOptionInteger(OpalVideoFormat::FrameHeightOption());
	
  if (width == XM_CIF_WIDTH && height == XM_CIF_HEIGHT) {
    return XMVideoSize_CIF;
  } else if (width == XM_QCIF_WIDTH && height == XM_QCIF_HEIGHT) {
    return XMVideoSize_QCIF;
  } else if (width == XM_SQCIF_WIDTH && height == XM_SQCIF_HEIGHT) {
    return XMVideoSize_SQCIF;
  } else if (width != 0 && height != 0) {
    return XMVideoSize_Custom;
  } else {
    return XMVideoSize_NoVideo;
  }
}

const char *_XMGetMediaFormatName(const OpalMediaFormat & mediaFormat)
{
  if (mediaFormat == XM_MEDIA_FORMAT_H261) {
    return _XMMediaFormatName_H261;
  } else if (mediaFormat == XM_MEDIA_FORMAT_H263 || mediaFormat == XM_MEDIA_FORMAT_H263PLUS) {
    return _XMMediaFormatName_H263;
  } else if (mediaFormat == XM_MEDIA_FORMAT_H264) {
    return _XMMediaFormatName_H264;
  }
	
  // if nothing found, simply return the media format string itself
  return mediaFormat;
}

unsigned _XMGetMaxH261Bitrate()
{
  return XM_MAX_H261_BITRATE;
}

unsigned _XMGetMaxH263Bitrate()
{
  return XM_MAX_H263_BITRATE;
}

unsigned _XMGetMaxH264Bitrate()
{
  return XM_MAX_H264_BITRATE;
}

#pragma mark -
#pragma mark XMBridge Functions

bool _XMHasCodecInstalled(XMCodecIdentifier codecIdentifier)
{
  const char *formatString = _XMMediaFormatForCodecIdentifier(codecIdentifier);
    
  if (formatString == NULL) {
    return false;
  }
    
  return OpalMediaFormat::GetAllRegisteredMediaFormats().HasFormat(formatString);
}

const char *_XMMediaFormatForCodecIdentifier(XMCodecIdentifier codecIdentifier)
{
  switch (codecIdentifier) {
    case XMCodecIdentifier_G711_uLaw:
      return _XMMediaFormatIdentifier_G711_uLaw;
    case XMCodecIdentifier_G711_ALaw:
      return _XMMediaFormatIdentifier_G711_ALaw;
    case XMCodecIdentifier_Speex:
      return _XMMediaFormatIdentifier_Speex;
    case XMCodecIdentifier_GSM:
      return _XMMediaFormatIdentifier_GSM;
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
#pragma mark XM_H323_H261_Capability methods

XM_H323_H261_Capability::XM_H323_H261_Capability()
{
  SetPayloadType(XM_MEDIA_FORMAT_H261.GetPayloadType());
}

PObject * XM_H323_H261_Capability::Clone() const
{
  return new XM_H323_H261_Capability(*this);
}

PObject::Comparison XM_H323_H261_Capability::Compare(const PObject & obj) const
{
  Comparison result = H323Capability::Compare(obj);
  if (result != EqualTo) {
    return result;
  }
	
  if (PIsDescendant(&obj, XM_H323_H261_Capability)) {	
    const XM_H323_H261_Capability & other = (const XM_H323_H261_Capability &)obj;
    
    const OpalMediaFormat & mediaFormat = GetMediaFormat();
    const OpalMediaFormat & otherFormat = other.GetMediaFormat();
    
    bool cif = (mediaFormat.GetOptionInteger(XMMediaFormat_H261::CIFOption()) > 0);
    bool qcif = (mediaFormat.GetOptionInteger(XMMediaFormat_H261::QCIFOption()) > 0);
    bool otherCIF = (otherFormat.GetOptionInteger(XMMediaFormat_H261::CIFOption()) > 0);
    bool otherQCIF = (otherFormat.GetOptionInteger(XMMediaFormat_H261::QCIFOption()) > 0);
    
    if ((cif && otherCIF) || (qcif && otherQCIF)) {
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
  return XM_MEDIA_FORMAT_H261;
}

bool XM_H323_H261_Capability::OnSendingPDU(H245_VideoCapability & cap) const
{
  const OpalMediaFormat & mediaFormat = GetMediaFormat();
  unsigned cifMPI     = mediaFormat.GetOptionInteger(XMMediaFormat_H261::CIFOption());
  unsigned qcifMPI    = mediaFormat.GetOptionInteger(XMMediaFormat_H261::QCIFOption());
  unsigned maxBitRate = mediaFormat.GetOptionInteger(OpalMediaFormat::MaxBitRateOption())/100;

  cap.SetTag(H245_VideoCapability::e_h261VideoCapability);
	
  H245_H261VideoCapability & h261 = cap;
	
  if (qcifMPI > 0) {
    h261.IncludeOptionalField(H245_H261VideoCapability::e_qcifMPI);
    h261.m_qcifMPI = qcifMPI;
  }
  if (cifMPI > 0) {
    h261.IncludeOptionalField(H245_H261VideoCapability::e_cifMPI);
    h261.m_cifMPI = cifMPI;
  }
	
  h261.m_temporalSpatialTradeOffCapability = false;
  h261.m_maxBitRate = maxBitRate;
  h261.m_stillImageTransmission = false;
	
  return true;
}

bool XM_H323_H261_Capability::OnSendingPDU(H245_VideoMode & pdu) const
{
  const OpalMediaFormat & mediaFormat = GetMediaFormat();
  unsigned cifMPI     = mediaFormat.GetOptionInteger(XMMediaFormat_H261::CIFOption());
  unsigned maxBitRate = mediaFormat.GetOptionInteger(OpalMediaFormat::MaxBitRateOption())/100;
  
  pdu.SetTag(H245_VideoMode::e_h261VideoMode);
  H245_H261VideoMode & mode = pdu;
  mode.m_resolution.SetTag(cifMPI > 0 ? H245_H261VideoMode_resolution::e_cif : H245_H261VideoMode_resolution::e_qcif);
  mode.m_bitRate = maxBitRate;
  mode.m_stillImageTransmission = false;
	
  return true;
}

bool XM_H323_H261_Capability::OnReceivedPDU(const H245_VideoCapability & cap)
{
  if (cap.GetTag() != H245_VideoCapability::e_h261VideoCapability) {
    return false;
  }
	
  OpalMediaFormat & mediaFormat = GetWritableMediaFormat();
  
  const H245_H261VideoCapability & h261 = cap;
  unsigned cifMPI = 0;
  unsigned qcifMPI = 0;
  if (h261.HasOptionalField(H245_H261VideoCapability::e_cifMPI)) {
    cifMPI = h261.m_cifMPI;
  }
  if (h261.HasOptionalField(H245_H261VideoCapability::e_qcifMPI)) {
    qcifMPI = h261.m_qcifMPI;
  }
  
  mediaFormat.SetOptionInteger(XMMediaFormat_H261::CIFOption(), cifMPI);
  mediaFormat.SetOptionInteger(XMMediaFormat_H261::QCIFOption(), qcifMPI);
  
  if (cifMPI > 0) {
    mediaFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption(), OpalMediaFormat::VideoClockRate*100*cifMPI/2997);
    mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption(), XM_CIF_WIDTH);
    mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption(), XM_CIF_HEIGHT);
  } else {
    mediaFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption(), OpalMediaFormat::VideoClockRate*100*qcifMPI/2997);
    mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption(), XM_QCIF_WIDTH);
    mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption(), XM_QCIF_HEIGHT);
  }
	
  unsigned maxBitRate = std::min((unsigned)mediaFormat.GetOptionInteger(OpalMediaFormat::MaxBitRateOption()), (h261.m_maxBitRate)*100);
  mediaFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption(), maxBitRate);

  return true;
}

#pragma mark -
#pragma mark XM_H323_H263_Capability methods

XM_H323_H263_Capability::XM_H323_H263_Capability()
: isH263PlusCapability(false)
{
  SetPayloadType(XM_MEDIA_FORMAT_H263.GetPayloadType());
}

XM_H323_H263_Capability::XM_H323_H263_Capability(bool isH263Plus)
: isH263PlusCapability(isH263Plus)
{
  SetPayloadType(XM_MEDIA_FORMAT_H263.GetPayloadType());
  if (isH263Plus == true) {
    SetPayloadType(XM_MEDIA_FORMAT_H263PLUS.GetPayloadType());
  }
}

PObject * XM_H323_H263_Capability::Clone() const
{	
  XM_H323_H263_Capability *h263Capability = new XM_H323_H263_Capability(*this);
  return h263Capability;
}

PObject::Comparison XM_H323_H263_Capability::Compare(const PObject & obj) const
{	
  Comparison result = H323Capability::Compare(obj);
  if (result != EqualTo) {
    return result;
  }
  
  if (PIsDescendant(&obj, XM_H323_H263_Capability)) {
    const XM_H323_H263_Capability & other = (const XM_H323_H263_Capability &)obj;
    
    const OpalMediaFormat & mediaFormat = GetMediaFormat();
    const OpalMediaFormat & otherFormat = other.GetMediaFormat();
   
    bool cif16      = (mediaFormat.GetOptionInteger(XMMediaFormat_H263::CIF16Option()) > 0);
    bool cif4       = (mediaFormat.GetOptionInteger(XMMediaFormat_H263::CIF4Option())  > 0);
    bool cif        = (mediaFormat.GetOptionInteger(XMMediaFormat_H263::CIFOption())   > 0);
    bool qcif       = (mediaFormat.GetOptionInteger(XMMediaFormat_H263::QCIFOption())  > 0);
    bool sqcif      = (mediaFormat.GetOptionInteger(XMMediaFormat_H263::SQCIFOption()) > 0);
    bool otherCIF16 = (otherFormat.GetOptionInteger(XMMediaFormat_H263::CIF16Option()) > 0);
    bool otherCIF4  = (otherFormat.GetOptionInteger(XMMediaFormat_H263::CIF4Option())  > 0);
    bool otherCIF   = (otherFormat.GetOptionInteger(XMMediaFormat_H263::CIFOption())   > 0);
    bool otherQCIF  = (otherFormat.GetOptionInteger(XMMediaFormat_H263::QCIFOption())  > 0);
    bool otherSQCIF = (otherFormat.GetOptionInteger(XMMediaFormat_H263::SQCIFOption()) > 0);
    
    if ((cif16 && otherCIF16) || (cif4 && otherCIF4) || (cif && otherCIF) ||
        (qcif && otherQCIF) || (sqcif && otherSQCIF)) {
      if (isH263PlusCapability == other.isH263PlusCapability) {
        return EqualTo;
      }
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
  if (isH263PlusCapability) {
    return XM_MEDIA_FORMAT_H263PLUS;
  } else {
    return XM_MEDIA_FORMAT_H263;
  }
}

bool XM_H323_H263_Capability::OnSendingPDU(H245_VideoCapability & cap) const
{
  const OpalMediaFormat & mediaFormat = GetMediaFormat();
  unsigned cifMPI     = mediaFormat.GetOptionInteger(XMMediaFormat_H263::CIFOption());
  unsigned qcifMPI    = mediaFormat.GetOptionInteger(XMMediaFormat_H263::QCIFOption());
  unsigned sqcifMPI   = mediaFormat.GetOptionInteger(XMMediaFormat_H263::SQCIFOption());
  unsigned maxBitRate = mediaFormat.GetOptionInteger(OpalMediaFormat::MaxBitRateOption())/100;
  
  cap.SetTag(H245_VideoCapability::e_h263VideoCapability);
	
  H245_H263VideoCapability & h263 = cap;
	
  if (sqcifMPI > 0) {
    h263.IncludeOptionalField(H245_H263VideoCapability::e_sqcifMPI);
    h263.m_sqcifMPI = sqcifMPI;
  }
  if (qcifMPI > 0) {
    h263.IncludeOptionalField(H245_H263VideoCapability::e_qcifMPI);
    h263.m_qcifMPI = qcifMPI;
  }
  if (cifMPI > 0) {
    h263.IncludeOptionalField(H245_H263VideoCapability::e_cifMPI);
    h263.m_cifMPI = cifMPI;
  }
	
  h263.m_maxBitRate = maxBitRate;
  h263.m_unrestrictedVector = false;
  h263.m_arithmeticCoding = false;
  h263.m_advancedPrediction = false;
  h263.m_pbFrames = false;
  h263.m_temporalSpatialTradeOffCapability = false;
	
  h263.IncludeOptionalField(H245_H263VideoCapability::e_hrd_B);
  h263.m_hrd_B = 0;
	
  h263.IncludeOptionalField(H245_H263VideoCapability::e_bppMaxKb);
  h263.m_bppMaxKb = 0;
	
  if (isH263PlusCapability) {
    h263.IncludeOptionalField(H245_H263VideoCapability::e_h263Options);
  }
	
  return true;
}

bool XM_H323_H263_Capability::OnSendingPDU(H245_VideoMode & pdu) const
{
  const OpalMediaFormat & mediaFormat = GetMediaFormat();
  unsigned cifMPI     = mediaFormat.GetOptionInteger(XMMediaFormat_H263::CIFOption());
  unsigned qcifMPI    = mediaFormat.GetOptionInteger(XMMediaFormat_H263::QCIFOption());
  unsigned maxBitRate = mediaFormat.GetOptionInteger(OpalMediaFormat::MaxBitRateOption())/100;
  
  pdu.SetTag(H245_VideoMode::e_h263VideoMode);
  H245_H263VideoMode & mode = pdu;
  mode.m_resolution.SetTag(cifMPI > 0 ? H245_H263VideoMode_resolution::e_cif
                           :(qcifMPI > 0 ? H245_H263VideoMode_resolution::e_qcif
                             : H245_H263VideoMode_resolution::e_sqcif));
  mode.m_bitRate = maxBitRate;
  mode.m_unrestrictedVector = false;
  mode.m_arithmeticCoding = false;
  mode.m_advancedPrediction = false;
  mode.m_pbFrames = false;
  mode.m_errorCompensation = false;
	
  return true;
}

bool XM_H323_H263_Capability::OnReceivedPDU(const H245_VideoCapability & cap)
{
  if (cap.GetTag() != H245_VideoCapability::e_h263VideoCapability) {
    return false;
  }
	
  const H245_H263VideoCapability & h263 = cap;
  
  if (h263.HasOptionalField(H245_H263VideoCapability::e_h263Options)) {
    isH263PlusCapability = true;
    SetPayloadType(XM_MEDIA_FORMAT_H263PLUS.GetPayloadType());
  } else {
    isH263PlusCapability = false;
    SetPayloadType(XM_MEDIA_FORMAT_H263.GetPayloadType());
  }
	
  OpalMediaFormat & mediaFormat = GetWritableMediaFormat();
  
  bool canRFC2429 = mediaFormat.GetOptionBoolean(XMMediaFormat_H263::CanRFC2429Option());
    
  // "Reset" the media format
  if (isH263PlusCapability == true) {
    mediaFormat = XM_MEDIA_FORMAT_H263PLUS;
  } else {
    mediaFormat = XM_MEDIA_FORMAT_H263;
  }
  mediaFormat.SetOptionBoolean(XMMediaFormat_H263::CanRFC2429Option(), canRFC2429);
  
  unsigned sqcifMPI = 0;
  unsigned qcifMPI  = 0;
  unsigned cifMPI   = 0;
  unsigned cif4MPI  = 0;
  unsigned cif16MPI = 0;
  
  if (h263.HasOptionalField(H245_H263VideoCapability::e_cif16MPI)) {
    cif16MPI = h263.m_cif16MPI;
  }
  if (h263.HasOptionalField(H245_H263VideoCapability::e_cif4MPI)) {
    cif4MPI = h263.m_cif4MPI;
  }
  if (h263.HasOptionalField(H245_H263VideoCapability::e_cifMPI)) {
    cifMPI = h263.m_cifMPI;
  }
  if (h263.HasOptionalField(H245_H263VideoCapability::e_qcifMPI)) {
    qcifMPI = h263.m_qcifMPI;
  }
  if (h263.HasOptionalField(H245_H263VideoCapability::e_sqcifMPI)) {
    sqcifMPI = h263.m_sqcifMPI;
  }
  
  mediaFormat.SetOptionInteger(XMMediaFormat_H263::CIF16Option(), cif16MPI);
  mediaFormat.SetOptionInteger(XMMediaFormat_H263::CIF4Option(),  cif4MPI);
  mediaFormat.SetOptionInteger(XMMediaFormat_H263::CIFOption(),   cifMPI);
  mediaFormat.SetOptionInteger(XMMediaFormat_H263::QCIFOption(),  qcifMPI);
  mediaFormat.SetOptionInteger(XMMediaFormat_H263::SQCIFOption(), sqcifMPI);
  
  if (cifMPI) {
    mediaFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption(), OpalMediaFormat::VideoClockRate*100*cifMPI/2997);
    mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption(), XM_CIF_WIDTH);
    mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption(), XM_CIF_HEIGHT);
  } else if (qcifMPI) {
    mediaFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption(), OpalMediaFormat::VideoClockRate*100*qcifMPI/2997);
    mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption(), XM_QCIF_WIDTH);
    mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption(), XM_QCIF_HEIGHT);
  } else {
    mediaFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption(), OpalMediaFormat::VideoClockRate*100*sqcifMPI/2997);
    mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption(), XM_SQCIF_WIDTH);
    mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption(), XM_SQCIF_HEIGHT);
  }
	
  
	unsigned maxBitRate = std::min((unsigned)mediaFormat.GetOptionInteger(OpalMediaFormat::MaxBitRateOption()), (h263.m_maxBitRate)*100);
  mediaFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption(), maxBitRate);
	
	return true;
}

/*void XM_H323_H263_Capability::OnSendingPDU(H245_MediaPacketizationCapability & mediaPacketizationCapability) const
{
	if (isH263PlusCapability)
	{
		// Enter RFC2429 media packetization information
		bool alreadyPresent = false;
		if (mediaPacketizationCapability.HasOptionalField(H245_MediaPacketizationCapability::e_rtpPayloadType))
		{
			alreadyPresent = true;
		}
		else
		{
			mediaPacketizationCapability.IncludeOptionalField(H245_MediaPacketizationCapability::e_rtpPayloadType);
		}
		
		H245_ArrayOf_RTPPayloadType & arrayOfRTPPayloadType = mediaPacketizationCapability.m_rtpPayloadType;
		
		PINDEX index = 0;
		if (alreadyPresent == true)
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
}

void XM_H323_H263_Capability::OnReceivedPDU(const H245_MediaPacketizationCapability & mediaPacketizationCapability)
{
    if (mediaPacketizationCapability.HasOptionalField(H245_MediaPacketizationCapability::e_rtpPayloadType))
    {
        const H245_ArrayOf_RTPPayloadType & arrayOfRTPPayloadType = mediaPacketizationCapability.m_rtpPayloadType;
        
        for (PINDEX i = 0; i < arrayOfRTPPayloadType.GetSize(); i++) {
            const H245_RTPPayloadType & payloadType = arrayOfRTPPayloadType[i];
            const H245_RTPPayloadType_payloadDescriptor & payloadDescriptor = payloadType.m_payloadDescriptor;
            if (payloadDescriptor.GetTag() == H245_RTPPayloadType_payloadDescriptor::e_rfc_number);
            {
                const PASN_Integer & integer = payloadDescriptor;
                if (integer.GetValue() == 2429) {
                    SetCanRFC2429(true);
                    return;
                }
            }
        }
    }
}

void XM_H323_H263_Capability::OnSendingPDU(H245_H2250LogicalChannelParameters_mediaPacketization & mediaPacketization) const
{	
	if (isH263PlusCapability)
	{
		mediaPacketization.SetTag(H245_H2250LogicalChannelParameters_mediaPacketization::e_rtpPayloadType);
		
		H245_RTPPayloadType & rtpPayloadType = mediaPacketization;
		
		H245_RTPPayloadType_payloadDescriptor & payloadDescriptor = rtpPayloadType.m_payloadDescriptor;
		
		payloadDescriptor.SetTag(H245_RTPPayloadType_payloadDescriptor::e_rfc_number);
		PASN_Integer & rfcValue = payloadDescriptor;
		rfcValue.SetValue(2429);
		
		rtpPayloadType.IncludeOptionalField(H245_RTPPayloadType::e_payloadType);
		rtpPayloadType.m_payloadType = GetPayloadType();
	}
}

void XM_H323_H263_Capability::OnReceivedPDU(const H245_H2250LogicalChannelParameters_mediaPacketization & mediaPacketization)
{		
	if (mediaPacketization.GetTag() != H245_H2250LogicalChannelParameters_mediaPacketization::e_rtpPayloadType)
	{
		return;
	}
	
	const H245_RTPPayloadType & rtpPayloadType = mediaPacketization;
	const H245_RTPPayloadType_payloadDescriptor & payloadDescriptor = rtpPayloadType.m_payloadDescriptor;
	
	if (payloadDescriptor.GetTag() != H245_RTPPayloadType_payloadDescriptor::e_rfc_number)
	{
		return;
	}
	
	const PASN_Integer & rfcValue = payloadDescriptor;
	
	if (rfcValue.GetValue() == 2429)
	{
        SetIsRFC2429(true);
	}
    
    if (rtpPayloadType.HasOptionalField(H245_RTPPayloadType::e_payloadType)) {
        unsigned payloadType = rtpPayloadType.m_payloadType;
        SetPayloadType((RTP_DataFrame::PayloadTypes)payloadType);
    }
}*/

#pragma mark -
#pragma mark XM_H323_H263PLUS_Capability Methods

XM_H323_H263PLUS_Capability::XM_H323_H263PLUS_Capability()
: XM_H323_H263_Capability(true)
{
}

#pragma mark -
#pragma mark XM_H323_H264_Capability Methods

XM_H323_H264_Capability::XM_H323_H264_Capability()
{
	maxBitRate = XM_MAX_H264_BITRATE/100;
	
	profile = XM_H264_PROFILE_CODE_BASELINE;
	level = XM_H264_LEVEL_CODE_2;
    
    packetizationMode = XM_H264_PACKETIZATION_MODE_SINGLE_NAL;
    h264LimitedMode = false;
    
    SetPayloadType(XM_MEDIA_FORMAT_H264.GetPayloadType());
}

PObject * XM_H323_H264_Capability::Clone() const
{
	XM_H323_H264_Capability *cap = new XM_H323_H264_Capability(*this);
	return cap;
}

PObject::Comparison XM_H323_H264_Capability::Compare(const PObject & obj) const
{
	if (!PIsDescendant(&obj, XM_H323_H264_Capability))
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
	return XM_MEDIA_FORMAT_H264;
}

bool XM_H323_H264_Capability::OnSendingPDU(H245_VideoCapability & cap) const
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
	
	return true;
}

bool XM_H323_H264_Capability::OnSendingPDU(H245_VideoMode & pdu) const
{
	return true;
}

bool XM_H323_H264_Capability::OnReceivedPDU(const H245_VideoCapability & cap)
{
	if (cap.GetTag() != H245_VideoCapability::e_genericVideoCapability)
	{
		return false;
	}
	
	const H245_GenericCapability & h264 = cap;
	
	const H245_CapabilityIdentifier & h264CapabilityIdentifier = h264.m_capabilityIdentifier;
	if (h264CapabilityIdentifier.GetTag() != H245_CapabilityIdentifier::e_standard)
	{
		return false;
	}
	
	const PASN_ObjectId & h264ObjectId = h264CapabilityIdentifier;
	if (h264ObjectId != "0.0.8.241.0.0.1")
	{
		return false;
	}
	
	OpalMediaFormat & mediaFormat = GetWritableMediaFormat();
	
	if (!h264.HasOptionalField(H245_GenericCapability::e_maxBitRate))
	{
		return false;
	}
	maxBitRate = std::min(maxBitRate, (unsigned)h264.m_maxBitRate);
	
	if (!h264.HasOptionalField(H245_GenericCapability::e_collapsing))
	{
		return false;
	}
	
	const H245_ArrayOf_GenericParameter & h264Collapsing = h264.m_collapsing;
	unsigned size = h264Collapsing.GetSize();
	unsigned i;
	for (i = 0; i < size; i++)
	{
		const H245_GenericParameter & parameter = h264Collapsing[i];
		
		const H245_ParameterIdentifier & parameterIdentifier = parameter.m_parameterIdentifier;
		if (parameterIdentifier.GetTag() != H245_ParameterIdentifier::e_standard)
		{
			break;
		}
		
		const PASN_Integer & parameterInteger = parameterIdentifier;
		
		const H245_ParameterValue & parameterValue = parameter.m_parameterValue;
		
		switch (parameterInteger)
		{
			case 41:
				if (parameterValue.GetTag() == H245_ParameterValue::e_booleanArray)
				{
					const PASN_Integer & profileValueInteger = parameterValue;
					SetProfile(profileValueInteger);
				}
				break;
			case 42:
				if (parameterValue.GetTag() == H245_ParameterValue::e_unsignedMin)
				{
					const PASN_Integer & levelValueInteger = parameterValue;
					SetLevel(levelValueInteger);
				}
				break;
			default:
				break;
		}
	}
	
	unsigned width = 0;
	unsigned height = 0;
	
	if (level < XM_H264_LEVEL_CODE_1_1)
	{
		width = PVideoDevice::QCIFWidth;
		height = PVideoDevice::QCIFHeight;
		if (maxBitRate > 640)
		{
			maxBitRate = 640;
		}
	}
	else if (level < XM_H264_LEVEL_CODE_1_2)
	{
		width = PVideoDevice::QCIFWidth;
		height = PVideoDevice::QCIFHeight;
		if (maxBitRate > 1280)
		{
			maxBitRate = 1280;
		}
	}
	else if (level < XM_H264_LEVEL_CODE_1_3)
	{
		width = PVideoDevice::CIFWidth;
		height = PVideoDevice::CIFHeight;
		if (maxBitRate > 3840)
		{
			maxBitRate = 3840;
		}
	}
	else if (level < XM_H264_LEVEL_CODE_2)
	{
		width = PVideoDevice::CIFWidth;
		height = PVideoDevice::CIFHeight;
		if (maxBitRate > 7680)
		{
			maxBitRate = 7680;
		}
	}
	else
	{
		width = PVideoDevice::CIFWidth;
		height = PVideoDevice::CIFHeight;
		if (maxBitRate > 20000)
		{
			maxBitRate = 20000;
		}
	}
	
	mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption(), width);
	mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption(), height);
	mediaFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption(), maxBitRate*100);

	return true;
}

/*void XM_H323_H264_Capability::OnSendingPDU(H245_MediaPacketizationCapability & mediaPacketizationCapability) const
{
	// Signal H.264 packetization modes understood by this endpoint
	bool alreadyPresent = false;
	if (mediaPacketizationCapability.HasOptionalField(H245_MediaPacketizationCapability::e_rtpPayloadType))
	{
		alreadyPresent = true;
	}
	else
	{
		mediaPacketizationCapability.IncludeOptionalField(H245_MediaPacketizationCapability::e_rtpPayloadType);
	}
	
	H245_ArrayOf_RTPPayloadType & arrayOfRTPPayloadType = mediaPacketizationCapability.m_rtpPayloadType;

	PINDEX index = 0;
	if (alreadyPresent == true)
	{
		index = arrayOfRTPPayloadType.GetSize();
    }
	
	arrayOfRTPPayloadType.SetSize(index + 2);
	
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
}

void XM_H323_H264_Capability::OnReceivedPDU(const H245_MediaPacketizationCapability & mediaPacketizationCapability)
{
	SetPacketizationMode(XM_H264_PACKETIZATION_MODE_SINGLE_NAL);
	
	if (mediaPacketizationCapability.HasOptionalField(H245_MediaPacketizationCapability::e_rtpPayloadType))
	{
		const H245_ArrayOf_RTPPayloadType & arrayOfRTPPayloadType = mediaPacketizationCapability.m_rtpPayloadType;
		PINDEX size = arrayOfRTPPayloadType.GetSize();
		PINDEX i;
		
		for (i = 0; i < size; i++)
		{
			const H245_RTPPayloadType & payloadType = arrayOfRTPPayloadType[i];
			const H245_RTPPayloadType_payloadDescriptor & payloadDescriptor = payloadType.m_payloadDescriptor;
			if (payloadDescriptor.GetTag() == H245_RTPPayloadType_payloadDescriptor::e_oid)
			{
				const PASN_ObjectId & objectId = payloadDescriptor;
				if (objectId == "0.0.8.241.0.0.0.1")
				{
					SetPacketizationMode(XM_H264_PACKETIZATION_MODE_NON_INTERLEAVED);
                    break;
				}
			}
		}
	}
}*/

// TODO: FIXME
/*bool XM_H323_H264_Capability::IsValidCapabilityForSending(const PString & remoteApplication) const
{
	if (((profile & XM_H264_PROFILE_CODE_BASELINE) != 0) &&
	   (level <= XM_H264_LEVEL_CODE_2))
	{
		if (h264LimitedMode == false && 
		   packetizationMode != XM_H264_PACKETIZATION_MODE_NON_INTERLEAVED)
		{
			return false;
		}
		return true;
	}
	return false;
}*/

unsigned XM_H323_H264_Capability::GetProfile() const
{	
	return XM_H264_PROFILE_BASELINE;
}

unsigned XM_H323_H264_Capability::GetLevel() const
{
	if (level < XM_H264_LEVEL_CODE_1_B)
	{
		return XM_H264_LEVEL_1;
	} 
	else if (level < XM_H264_LEVEL_CODE_1_1)
	{
		return XM_H264_LEVEL_1_B;
	}
	else if (level < XM_H264_LEVEL_CODE_1_2)
	{
		return XM_H264_LEVEL_1_1;
	}
	else if (level < XM_H264_LEVEL_CODE_1_3)
	{
		return XM_H264_LEVEL_1_2;
	}
	else if (level < XM_H264_LEVEL_CODE_2)
	{
		return XM_H264_LEVEL_1_3;
	}
	
	return XM_H264_LEVEL_2;
}

void XM_H323_H264_Capability::SetProfile(WORD _profile)
{
    profile = _profile;
    _XMSetH264Profile(GetWritableMediaFormat(), GetProfile());
}

void XM_H323_H264_Capability::SetLevel(unsigned _level)
{
    level = _level;
    _XMSetH264Level(GetWritableMediaFormat(), GetLevel());
}

void XM_H323_H264_Capability::SetPacketizationMode(unsigned _packetizationMode)
{
    packetizationMode = _packetizationMode;
    _XMSetH264PacketizationMode(GetWritableMediaFormat(), packetizationMode);
}

#pragma mark -
#pragma mark XM_SDP_H261_Capability methods

/*bool XM_SDP_H261_Capability::OnSendingSDP(SDPMediaFormat & sdpMediaFormat) const
{
    // Produces an RFC 4587 compliant FMTP string
    // In addition to that, also an MaxBR option is included to signal maximum bandwidth
    
    unsigned maxBitRate = mediaFormat.GetOptionInteger(OpalMediaFormat::MaxBitRateOption()) / 100;
    XMVideoSize videoSize = _XMGetMediaFormatSize(mediaFormat);
    unsigned frameTime = mediaFormat.GetOptionInteger(OpalMediaFormat::FrameTimeOption());
    unsigned mpi = round((frameTime * 2997.0) / (OpalMediaFormat::VideoClockRate * 100.0));
	
	if (videoSize >= XMVideoSize_CIF)
	{
		sdpMediaFormat.SetFMTP(psprintf("CIF=%d;QCIF=%d;MaxBR=%d", mpi, mpi, maxBitRate));
	}
	else if (videoSize >= XMVideoSize_QCIF)
	{
		sdpMediaFormat.SetFMTP(psprintf("QCIF=%d;MaxBR=%d", mpi, maxBitRate));
	}
    else
    {
        return false;
    }
    
    return true;
}

bool XM_SDP_H261_Capability::OnReceivedSDP(const SDPMediaFormat & sdpMediaFormat,
                                           const SDPMediaDescription & mediaDescription,
                                           const SDPSessionDescription & sessionDescription)
{
    const PString & fmtp = sdpMediaFormat.GetFMTP();
	const PStringArray tokens = fmtp.Tokenise(" ;");
	
    unsigned cifMPI = 0;
    unsigned qcifMPI = 0;
    unsigned bitrate = 0;
    
	unsigned i;
	unsigned count = tokens.GetSize();
	for (i = 0; i < count; i++)
	{
		const PString & str = tokens[i];
		
		if (str.Left(4) == "CIF=")
		{
			PString mpiStr = str(4, 1000);
			cifMPI = mpiStr.AsUnsigned();
		}
		else if (str.Left(5) == "QCIF=")
		{
            PString mpiStr = str(5, 1000);
            qcifMPI = mpiStr.AsUnsigned();
		}
		else if (str.Left(6) == "MaxBR=")
		{
			PString brStr = str(6, 1000);
			bitrate = brStr.AsUnsigned() * 100;
		}
	}
	
    if (cifMPI != 0) 
    {
        mediaFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption(), OpalMediaFormat::VideoClockRate*100*cifMPI/2997);
        mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption(), XM_CIF_WIDTH);
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption(), XM_CIF_HEIGHT);
    }
    else if (qcifMPI != 0)
    {
        mediaFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption(), OpalMediaFormat::VideoClockRate*100*qcifMPI/2997);
        mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption(), XM_QCIF_WIDTH);
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption(), XM_QCIF_HEIGHT);
    }
    else
    {
        // Assuming 30fps CIF
        mediaFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption(), OpalMediaFormat::VideoClockRate*100/2997);
        mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption(), XM_CIF_WIDTH);
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption(), XM_CIF_HEIGHT);
    }
    
    if (bitrate == 0)
    {
        bitrate = sessionDescription.GetBandwidthValue() * 1000;
        if (bitrate == 0) {
            bitrate = XM_DEFAULT_SIP_VIDEO_BITRATE;
        }
    }
    bitrate = std::min(mediaFormat.GetBandwidth(), bitrate);
    mediaFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption(), bitrate);
    
    return true;
}

#pragma mark -
#pragma mark XM_SDP_H263_Capability methods

bool XM_SDP_H263_Capability::OnSendingSDP(SDPMediaFormat & sdpMediaFormat) const
{
    // Produces an RFC 4629 compliant FMTP string, although this doesn't apply for
    // RFC2190 encoding
    // In addition to that, also an MaxBR option is included to signal maximum bandwidth
    
    unsigned maxBitRate = mediaFormat.GetOptionInteger(OpalMediaFormat::MaxBitRateOption()) / 100;
    XMVideoSize videoSize = _XMGetMediaFormatSize(mediaFormat);
    unsigned frameTime = mediaFormat.GetOptionInteger(OpalMediaFormat::FrameTimeOption());
    unsigned mpi = round((frameTime * 2997.0) / (OpalMediaFormat::VideoClockRate * 100.0));
	
	if (videoSize >= XMVideoSize_CIF)
	{
		sdpMediaFormat.SetFMTP(psprintf("CIF=%d;QCIF=%d;SQCIF=%d;MaxBR=%d", mpi, mpi, mpi, maxBitRate));
	}
	else if (videoSize >= XMVideoSize_QCIF)
	{
		sdpMediaFormat.SetFMTP(psprintf("QCIF=%d;SQCIF=%d;MaxBR=%d", mpi, mpi, maxBitRate));
	}
    else if (videoSize >= XMVideoSize_SQCIF)
    {
        sdpMediaFormat.SetFMTP(psprintf("SQCIF=%d;MaxBR=%d", mpi, maxBitRate));
    }
    else
    {
        return false;
    }
    
    return true;
}

bool XM_SDP_H263_Capability::OnReceivedSDP(const SDPMediaFormat & sdpMediaFormat,
                                           const SDPMediaDescription & mediaDescription,
                                           const SDPSessionDescription & sessionDescription)
{
    const PString & fmtp = sdpMediaFormat.GetFMTP();
	const PStringArray tokens = fmtp.Tokenise(" ;");
	
    unsigned cifMPI = 0;
    unsigned qcifMPI = 0;
    unsigned sqcifMPI = 0;
    unsigned bitrate = 0;
    
	unsigned i;
	unsigned count = tokens.GetSize();
	for (i = 0; i < count; i++)
	{
		const PString & str = tokens[i];
		
		if (str.Left(4) == "CIF=")
		{
			PString mpiStr = str(4, 1000);
			cifMPI = mpiStr.AsUnsigned();
		}
		else if (str.Left(5) == "QCIF=")
		{
            PString mpiStr = str(5, 1000);
            qcifMPI = mpiStr.AsUnsigned();
		}
        else if (str.Left(6) == "SQCIF=")
        {
            PString mpiStr = str(6, 1000);
            sqcifMPI = mpiStr.AsUnsigned();
        }
		else if (str.Left(6) == "MaxBR=")
		{
			PString brStr = str(6, 1000);
			bitrate = brStr.AsUnsigned() * 100;
		}
	}
	
    if (cifMPI != 0) 
    {
        mediaFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption(), OpalMediaFormat::VideoClockRate*100*cifMPI/2997);
        mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption(), XM_CIF_WIDTH);
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption(), XM_CIF_HEIGHT);
    }
    else if (qcifMPI != 0)
    {
        mediaFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption(), OpalMediaFormat::VideoClockRate*100*qcifMPI/2997);
        mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption(), XM_QCIF_WIDTH);
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption(), XM_QCIF_HEIGHT);
    }
    else if (sqcifMPI != 0)
    {
        mediaFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption(), OpalMediaFormat::VideoClockRate*100*sqcifMPI/2997);
        mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption(), XM_SQCIF_WIDTH);
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption(), XM_SQCIF_HEIGHT);
    }
    else
    {
        // Assuming 30fps CIF
        mediaFormat.SetOptionInteger(OpalMediaFormat::FrameTimeOption(), OpalMediaFormat::VideoClockRate*100/2997);
        mediaFormat.SetOptionInteger(OpalVideoFormat::FrameWidthOption(), XM_CIF_WIDTH);
		mediaFormat.SetOptionInteger(OpalVideoFormat::FrameHeightOption(), XM_CIF_HEIGHT);
    }
    
    if (bitrate == 0)
    {
        bitrate = sessionDescription.GetBandwidthValue() * 1000;
        if (bitrate == 0) {
            bitrate = XM_DEFAULT_SIP_VIDEO_BITRATE;
        }
    }
    bitrate = std::min(mediaFormat.GetBandwidth(), bitrate);
    mediaFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption(), bitrate);
    
    return true;
}*/

#pragma mark -
#pragma mark Packetization and Codec Option Functions

bool _XMGetIsRFC2429(const OpalMediaFormat & mediaFormat)
{
  if (mediaFormat.HasOption(XMMediaFormat_H263::IsRFC2429Option())) {
    return mediaFormat.GetOptionBoolean(XMMediaFormat_H263::IsRFC2429Option());
  }
  return false;
}

/*void _XMSetCanRFC2429(OpalMediaFormat & mediaFormat, bool canRFC2429)
{
    if (mediaFormat.HasOption(CanRFC2429Option)) {
        mediaFormat.SetOptionBoolean(CanRFC2429Option, canRFC2429);
    } else {
        mediaFormat.AddOption(new OpalMediaOptionBoolean(CanRFC2429Option, false, OpalMediaOption::AlwaysMerge, canRFC2429));
    }
}

bool _XMGetIsRFC2429(const OpalMediaFormat & mediaFormat)
{
    bool isRFC2429 = false;
    if (mediaFormat.HasOption(IsRFC2429Option)) {
        isRFC2429 = mediaFormat.GetOptionBoolean(IsRFC2429Option);
    }
    return isRFC2429;
}

void _XMSetIsRFC2429(OpalMediaFormat & mediaFormat, bool isRFC2429)
{
    if (mediaFormat.HasOption(IsRFC2429Option)) {
        mediaFormat.SetOptionBoolean(IsRFC2429Option, isRFC2429);
    } else {
        mediaFormat.AddOption(new OpalMediaOptionBoolean(IsRFC2429Option, false, OpalMediaOption::AlwaysMerge, isRFC2429));
    }
}*/

unsigned _XMGetH264Profile(const OpalMediaFormat & mediaFormat)
{
    unsigned profile = XM_H264_PROFILE_BASELINE;
    if (mediaFormat.HasOption(ProfileOption)) {
        profile = mediaFormat.GetOptionInteger(ProfileOption);
    }
    return profile;
}

void _XMSetH264Profile(OpalMediaFormat & mediaFormat, unsigned profile)
{
    if (mediaFormat.HasOption(ProfileOption)) {
        mediaFormat.SetOptionInteger(ProfileOption, profile);
    } else {
        mediaFormat.AddOption(new OpalMediaOptionInteger(ProfileOption, false, OpalMediaOption::AlwaysMerge, profile));
    }
}

unsigned _XMGetH264Level(const OpalMediaFormat & mediaFormat)
{
    unsigned level = XM_H264_LEVEL_1;
    if (mediaFormat.HasOption(LevelOption)) {
        level = mediaFormat.GetOptionInteger(LevelOption);
    }
    return level;
}

void _XMSetH264Level(OpalMediaFormat & mediaFormat, unsigned level)
{
    if (mediaFormat.HasOption(LevelOption)) {
        mediaFormat.SetOptionInteger(LevelOption, level);
    } else {
        mediaFormat.AddOption(new OpalMediaOptionInteger(LevelOption, false, OpalMediaOption::AlwaysMerge, level));
    }
}

unsigned _XMGetH264PacketizationMode(const OpalMediaFormat & mediaFormat)
{
    unsigned packetizationMode = XM_H264_PACKETIZATION_MODE_SINGLE_NAL;
    if (mediaFormat.HasOption(PacketizationOption)) {
        packetizationMode = mediaFormat.GetOptionInteger(PacketizationOption);
    }
    return packetizationMode;
}

void _XMSetH264PacketizationMode(OpalMediaFormat & mediaFormat, unsigned packetizationMode)
{
    if (mediaFormat.HasOption(PacketizationOption)) {
        mediaFormat.SetOptionInteger(PacketizationOption, packetizationMode);
    } else {
         mediaFormat.AddOption(new OpalMediaOptionInteger(PacketizationOption, false, OpalMediaOption::AlwaysMerge, packetizationMode));
    }
}

bool _XMGetEnableH264LimitedMode(const OpalMediaFormat & mediaFormat)
{
    bool enableLimitedMode = false;
    if (mediaFormat.HasOption(H264LimitedModeOption)) {
        enableLimitedMode = mediaFormat.GetOptionBoolean(H264LimitedModeOption);
    }
    return enableLimitedMode;
}

void _XMSetEnableH264LimitedMode(OpalMediaFormat & mediaFormat, bool enableH264LimitedMode)
{
    if (mediaFormat.HasOption(H264LimitedModeOption)) {
        mediaFormat.SetOptionBoolean(H264LimitedModeOption, enableH264LimitedMode);
    } else {
        mediaFormat.AddOption(new OpalMediaOptionBoolean(H264LimitedModeOption, false, OpalMediaOption::AlwaysMerge, enableH264LimitedMode));
    }
}
