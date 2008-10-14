/*
 * $Id: XMMediaFormats.cpp,v 1.39 2008/10/14 22:41:52 hfriederich Exp $
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
#define XM_SQCIF_WIDTH PVideoDevice::SQCIFWidth
#define XM_SQCIF_HEIGHT PVideoDevice::SQCIFHeight

#define XM_MAX_FRAME_WIDTH XM_CIF_WIDTH
#define XM_MAX_FRAME_HEIGHT XM_CIF_HEIGHT
#define XM_MAX_FRAME_RATE 30

#define XM_MAX_H261_BITRATE 960000
#define XM_MAX_H263_BITRATE 960000
#define XM_MAX_H264_BITRATE 2000000

#define XM_H264_PROFILE_CODE_BASELINE 64
#define XM_H264_PROFILE_CODE_MAIN     32

#define XM_H264_LEVEL_CODE_1	  15
#define XM_H264_LEVEL_CODE_1_B  19
#define XM_H264_LEVEL_CODE_1_1	22
#define XM_H264_LEVEL_CODE_1_2	29
#define XM_H264_LEVEL_CODE_1_3	36
#define XM_H264_LEVEL_CODE_2	  43

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
const char *_XMMediaFormatEncoding_H264 = "H264";

#pragma mark -
#pragma mark MediaFormat Definitions

class XMMediaFormat_H261 : public OpalVideoFormatInternal
{
  PCLASSINFO(XMMediaFormat_H261, OpalVideoFormatInternal);
  
public:
  XMMediaFormat_H261();
  virtual PObject* Clone() const;
  virtual bool ToNormalisedOptions();
  virtual bool ToCustomisedOptions();
  
  static const PString & QCIFOption() { static PString s = "QCIF MPI"; return s; }
  static const PString & CIFOption()  { static PString s = "CIF MPI";  return s; }
};

XMMediaFormat_H261::XMMediaFormat_H261()
: OpalVideoFormatInternal(_XMMediaFormat_H261,
                          RTP_DataFrame::H261,
                          _XMMediaFormatEncoding_H261,
                          XM_CIF_WIDTH,
                          XM_CIF_HEIGHT,
                          XM_MAX_FRAME_RATE,
                          XM_MAX_H261_BITRATE,
                          0)
{
  OpalMediaOption *cifOption =  new OpalMediaOptionUnsigned(CIFOption(),  false, OpalMediaOption::MaxMerge, 1, 0, 30);
  cifOption->SetFMTPName("CIF");
  cifOption->SetFMTPDefault("0");
  AddOption(cifOption);
  
  OpalMediaOption *qcifOption = new OpalMediaOptionUnsigned(QCIFOption(), false, OpalMediaOption::MaxMerge, 1, 0, 30);
  qcifOption->SetFMTPName("QCIF");
  qcifOption->SetFMTPDefault("0");
  AddOption(qcifOption);
  
  SetOptionInteger(OpalVideoFormat::FrameWidthOption(), XM_CIF_WIDTH);
  SetOptionInteger(OpalVideoFormat::FrameWidthOption(), XM_CIF_WIDTH);
  SetOptionInteger(OpalVideoFormat::MinRxFrameWidthOption(), XM_QCIF_WIDTH);
  SetOptionInteger(OpalVideoFormat::MinRxFrameHeightOption(), XM_QCIF_HEIGHT);
  SetOptionInteger(OpalVideoFormat::MaxRxFrameWidthOption(), XM_CIF_WIDTH);
  SetOptionInteger(OpalVideoFormat::MaxRxFrameHeightOption(), XM_CIF_HEIGHT);
}

PObject* XMMediaFormat_H261::Clone() const
{
  return new XMMediaFormat_H261(*this);
}

bool XMMediaFormat_H261::ToNormalisedOptions()
{
  unsigned cifMPI = GetOptionInteger(CIFOption(), 1);
  unsigned qcifMPI = GetOptionInteger(QCIFOption(), 1);
  
  unsigned width = 0;
  unsigned height = 0;
  unsigned mpi = 0;
  
  if (cifMPI > 0) {
    mpi = cifMPI;
    width = XM_CIF_WIDTH;
    height = XM_CIF_HEIGHT;
  } else if (qcifMPI > 0) {
    mpi = qcifMPI;
    width = XM_QCIF_WIDTH;
    height = XM_QCIF_HEIGHT;
  }
  
  SetOptionInteger(OpalMediaFormat::FrameTimeOption(), OpalMediaFormat::VideoClockRate*100*mpi/2997);
  SetOptionInteger(OpalVideoFormat::FrameWidthOption(), width);
  SetOptionInteger(OpalVideoFormat::FrameHeightOption(), height);
  
  return OpalVideoFormatInternal::ToNormalisedOptions();
}

bool XMMediaFormat_H261::ToCustomisedOptions()
{
  unsigned frameTime = GetOptionInteger(OpalMediaFormat::FrameTimeOption(), 0);
  unsigned mpi = (unsigned)round((double)frameTime*2997/((double)100*OpalMediaFormat::VideoClockRate));
  unsigned width = GetOptionInteger(OpalVideoFormat::FrameWidthOption(), 0);
  unsigned height = GetOptionInteger(OpalVideoFormat::FrameHeightOption(), 0);
  
  unsigned cifMPI = 0;
  unsigned qcifMPI = 0;
  
  if (width >= XM_QCIF_WIDTH && height >= XM_QCIF_HEIGHT) {
    qcifMPI = mpi;
  }
  if (width >= XM_CIF_WIDTH && height >= XM_CIF_HEIGHT) {
    cifMPI = mpi;
  }
  
  SetOptionInteger(QCIFOption(), qcifMPI);
  SetOptionInteger(CIFOption(), cifMPI);
  
  return OpalVideoFormatInternal::ToCustomisedOptions();
}

class XMMediaFormat_H263 : public OpalVideoFormatInternal
{
  PCLASSINFO(XMMediaFormat_H263, OpalVideoFormatInternal);
  
public:
  XMMediaFormat_H263(bool isH263Plus);
  virtual PObject* Clone() const;
  virtual bool ToNormalisedOptions();
  virtual bool ToCustomisedOptions();
  
  static const PString & SQCIFOption()      { static PString s = "SQCIF MPI";    return s; }
  static const PString & QCIFOption()       { static PString s = "QCIF MPI";     return s; }
  static const PString & CIFOption()        { static PString s = "CIF MPI";      return s; }
  static const PString & CIF4Option()       { static PString s = "CIF4 MPI";     return s; }
  static const PString & CIF16Option()      { static PString s = "CIF16 MPI";    return s; }
  static const PString & CanRFC2429Option() { static PString s = "Can RFC 2429"; return s; }
  static const PString & IsRFC2429Option()  { static PString s = "Is RFC 2429";  return s; }
};

XMMediaFormat_H263::XMMediaFormat_H263(bool isH263Plus)
: OpalVideoFormatInternal((isH263Plus ? _XMMediaFormat_H263Plus : _XMMediaFormat_H263),
                          (isH263Plus ? (RTP_DataFrame::PayloadTypes)98 : RTP_DataFrame::H263),
                          (isH263Plus ? _XMMediaFormatEncoding_H263Plus : _XMMediaFormatEncoding_H263),
                          XM_CIF_WIDTH,
                          XM_CIF_HEIGHT,
                          XM_MAX_FRAME_RATE,
                          XM_MAX_H263_BITRATE,
                          0)
{
  OpalMediaOption *sqcifOption = new OpalMediaOptionUnsigned(SQCIFOption(), false, OpalMediaOption::MaxMerge, 1, 0, 30);
  sqcifOption->SetFMTPName("SQCIF");
  sqcifOption->SetFMTPDefault("0");
  AddOption(sqcifOption);
  
  OpalMediaOption *qcifOption = new OpalMediaOptionUnsigned(QCIFOption(), false, OpalMediaOption::MaxMerge, 1, 0, 30);
  qcifOption->SetFMTPName("QCIF");
  qcifOption->SetFMTPDefault("0");
  AddOption(qcifOption);
  
  OpalMediaOption *cifOption = new OpalMediaOptionUnsigned(CIFOption(), false, OpalMediaOption::MaxMerge, 1, 0, 30);
  cifOption->SetFMTPName("CIF");
  cifOption->SetFMTPDefault("0");
  AddOption(cifOption);
  
  OpalMediaOption *cif4Option = new OpalMediaOptionUnsigned(CIF4Option(), false, OpalMediaOption::MaxMerge, 0, 0, 30);
  cif4Option->SetFMTPName("CIF4");
  cif4Option->SetFMTPDefault("0");
  AddOption(cif4Option);
  
  OpalMediaOption *cif16Option = new OpalMediaOptionUnsigned(CIF16Option(), false, OpalMediaOption::MaxMerge, 0, 0, 30);
  cif16Option->SetFMTPName("CIF16");
  cif16Option->SetFMTPDefault("0");
  AddOption(cif16Option);

  AddOption(new OpalMediaOptionBoolean(IsRFC2429Option(),  false, OpalMediaOption::MinMerge, false));
  AddOption(new OpalMediaOptionString(OpalVideoFormat::MediaPacketizationOption(), false, "RFC2190"));
  
  if (isH263Plus) {
    SetOptionBoolean(IsRFC2429Option(), true);
    SetOptionString(OpalVideoFormat::MediaPacketizationOption(), "RFC2429");
  }
}

PObject *XMMediaFormat_H263::Clone() const
{
  return new XMMediaFormat_H263(*this);
}

bool XMMediaFormat_H263::ToNormalisedOptions()
{
  unsigned sqcifMPI = GetOptionInteger(SQCIFOption(), 1);
  unsigned qcifMPI = GetOptionInteger(QCIFOption(), 1);
  unsigned cifMPI = GetOptionInteger(CIFOption(), 1);
  
  unsigned width = 0;
  unsigned height = 0;
  unsigned mpi = 0;
  
  if (cifMPI > 0) {
    mpi = cifMPI;
    width = XM_CIF_WIDTH;
    height = XM_CIF_HEIGHT;
  } else if (qcifMPI > 0) {
    mpi = qcifMPI;
    width = XM_QCIF_WIDTH;
    height = XM_QCIF_HEIGHT;
  } else if (sqcifMPI > 0) {
    mpi = sqcifMPI;
    width = XM_SQCIF_WIDTH;
    height = XM_SQCIF_HEIGHT;
  }
  
  SetOptionInteger(OpalMediaFormat::FrameTimeOption(), OpalMediaFormat::VideoClockRate*100*mpi/2997);
  SetOptionInteger(OpalVideoFormat::FrameWidthOption(), width);
  SetOptionInteger(OpalVideoFormat::FrameHeightOption(), height);
  
  return OpalVideoFormatInternal::ToNormalisedOptions();
}

bool XMMediaFormat_H263::ToCustomisedOptions()
{
  unsigned frameTime = GetOptionInteger(OpalMediaFormat::FrameTimeOption(), 0);
  unsigned mpi = (unsigned)round((double)frameTime*2997/((double)100*OpalMediaFormat::VideoClockRate));
  unsigned width = GetOptionInteger(OpalVideoFormat::FrameWidthOption(), 0);
  unsigned height = GetOptionInteger(OpalVideoFormat::FrameHeightOption(), 0);
  
  unsigned sqcifMPI = 0;
  unsigned qcifMPI = 0;
  unsigned cifMPI = 0;
  unsigned cif4MPI = 0;
  unsigned cif16MPI = 0;
  
  if (width >= XM_SQCIF_WIDTH && height >= XM_SQCIF_HEIGHT) {
    sqcifMPI = mpi;
  }
  if (width >= XM_QCIF_WIDTH && height >= XM_QCIF_HEIGHT) {
    qcifMPI = mpi;
  }
  if (width >= XM_CIF_WIDTH && height >= XM_CIF_HEIGHT) {
    cifMPI = mpi;
  }
  
  SetOptionInteger(SQCIFOption(), sqcifMPI);
  SetOptionInteger(QCIFOption(), qcifMPI);
  SetOptionInteger(CIFOption(), cifMPI);
  SetOptionInteger(CIF4Option(), cif4MPI);
  SetOptionInteger(CIF16Option(), cif16MPI);
  
  return OpalVideoFormatInternal::ToCustomisedOptions();
}

class XMMediaFormat_H264 : public OpalVideoFormatInternal
{
public:
  XMMediaFormat_H264();
  virtual PObject* Clone() const;
  virtual bool IsValidForProtocol(const PString & protocol) const;
  virtual bool ToNormalisedOptions();
  virtual bool ToCustomisedOptions();
  
  static const PString & ProfileOption()           { static PString s = "Profile";            return s; }
  static const PString & LevelOption()             { static PString s = "Level";              return s; }
};

XMMediaFormat_H264::XMMediaFormat_H264()
: OpalVideoFormatInternal(_XMMediaFormat_H264, 
                          (RTP_DataFrame::PayloadTypes)97,
                          _XMMediaFormatEncoding_H264,
                          XM_MAX_FRAME_WIDTH,
                          XM_MAX_FRAME_HEIGHT,
                          XM_MAX_FRAME_RATE,
                          XM_MAX_H264_BITRATE,
                          0)
{
  AddOption(new OpalMediaOptionUnsigned(ProfileOption(), false, OpalMediaOption::NoMerge, XM_H264_PROFILE_BASELINE, XM_H264_PROFILE_BASELINE, XM_H264_PROFILE_MAIN));
  AddOption(new OpalMediaOptionUnsigned(LevelOption(),   false, OpalMediaOption::NoMerge, XM_H264_LEVEL_2, XM_H264_LEVEL_1, XM_H264_LEVEL_2));
  AddOption(new OpalMediaOptionString(OpalVideoFormat::MediaPacketizationOption(), false, "0.0.8.241.0.0.0.0"));
}

PObject* XMMediaFormat_H264::Clone() const
{
  return new XMMediaFormat_H264(*this);
}

bool XMMediaFormat_H264::IsValidForProtocol(const PString & protocol) const
{
  cout << "Is valid for protocol " << protocol << endl;
  if (protocol == "h323") {
    return true;
  }
  return false;
}

bool XMMediaFormat_H264::ToNormalisedOptions()
{
  unsigned level = GetOptionInteger(LevelOption(), 0);
  unsigned maxBitRate = GetOptionInteger(OpalVideoFormat::MaxBitRateOption(), 0);
  unsigned width = 0;
  unsigned height = 0;
  unsigned mpi = 0;
  
  // See Table A-1 Level limits in the H.264 spec
  if (level < XM_H264_LEVEL_1_B) { // use level 1
    width = XM_QCIF_WIDTH;
    height = XM_QCIF_HEIGHT;
    if (maxBitRate > 64000) {
      maxBitRate = 64000;
    }
    mpi = 2; // 15 FPS
  } else if (level < XM_H264_LEVEL_1_1) { // use level 1.b
    width = XM_QCIF_WIDTH;
    height = XM_QCIF_HEIGHT;
    if (maxBitRate < 128000) {
      maxBitRate = 128000;
    }
    mpi = 2; // 15 FPS
  } else if (level < XM_H264_LEVEL_1_2) { // use level 1.1
    // Use QCIF instead of CIF, but transmit 30 FPS
    width = XM_QCIF_WIDTH;
    height = XM_QCIF_HEIGHT;
    if (maxBitRate > 192000) {
      maxBitRate = 192000;
    }
    mpi = 1;
  } else if (level < XM_H264_LEVEL_1_3) { // use level 1.2
    width = XM_CIF_WIDTH;
    height = XM_CIF_HEIGHT;
    if (maxBitRate > 384000) {
      maxBitRate = 384000;
    }
    mpi = 2;
  } else if (level < XM_H264_LEVEL_2) { // use level 1.3
    width = XM_CIF_WIDTH;
    height = XM_CIF_HEIGHT;
    if (maxBitRate > 768000) {
      maxBitRate = 768000;
    }
    mpi = 1;
  } else { // use level 2
    width = XM_CIF_WIDTH;
    height = XM_CIF_HEIGHT;
    if (maxBitRate > 2000000) {
      maxBitRate = 2000000;
    }
    mpi = 1;
  }
  
  SetOptionInteger(OpalMediaFormat::FrameTimeOption(), OpalMediaFormat::VideoClockRate*100*mpi/2997);
  SetOptionInteger(OpalVideoFormat::FrameWidthOption(), width);
  SetOptionInteger(OpalVideoFormat::FrameHeightOption(), height);
  SetOptionInteger(OpalMediaFormat::MaxBitRateOption(), maxBitRate);
  
  return OpalVideoFormatInternal::ToNormalisedOptions();
}

bool XMMediaFormat_H264::ToCustomisedOptions()
{
  unsigned bitrate = GetOptionInteger(OpalMediaFormat::MaxBitRateOption(), 0);
  unsigned level;
  
  // Determine the level. See Table A-1 in the H264 spec
  if (bitrate < 128000) {
    level = XM_H264_LEVEL_1;
  } else if (bitrate < 192000) {
    level = XM_H264_LEVEL_1_B;
  } else if (bitrate < 384000) {
    level = XM_H264_LEVEL_1_1;
  } else if (bitrate < 768000) {
    level = XM_H264_LEVEL_1_2;
  } else if (bitrate < 2000000) {
    level = XM_H264_LEVEL_1_3;
  } else {
    level = XM_H264_LEVEL_2;
  }

  SetOptionInteger(LevelOption(), level);
  return OpalVideoFormatInternal::ToCustomisedOptions();
}

const OpalMediaFormat & XMGetMediaFormat_H261()
{
  static const OpalMediaFormat format(new XMMediaFormat_H261());
  return format;
}

const OpalMediaFormat & XMGetMediaFormat_H263()
{
	static const OpalMediaFormat format(new XMMediaFormat_H263(false));
	return format;
}

const OpalMediaFormat & XMGetMediaFormat_H263Plus()
{
	static const OpalMediaFormat format(new XMMediaFormat_H263(true));
	return format;
}

const OpalMediaFormat & XMGetMediaFormat_H264()
{
  static const OpalMediaFormat format(new XMMediaFormat_H264());
  return format;
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
  
	unsigned maxBitRate = std::min((unsigned)mediaFormat.GetOptionInteger(OpalMediaFormat::MaxBitRateOption()), (h263.m_maxBitRate)*100);
  mediaFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption(), maxBitRate);
	
	return true;
}

#pragma mark -
#pragma mark XM_H323_H263PLUS_Capability Methods

XM_H323_H263PLUS_Capability::XM_H323_H263PLUS_Capability()
: XM_H323_H263_Capability(true)
{
}

#pragma mark -
#pragma mark XM_H323_H264_Capability Methods

unsigned GetProfileCode(unsigned profile) {
  switch (profile) {
    case XM_H264_PROFILE_BASELINE:
      return XM_H264_PROFILE_CODE_BASELINE;
    case XM_H264_PROFILE_MAIN:
      return XM_H264_PROFILE_CODE_MAIN;
    default:
      return 0;
  }
}

unsigned GetLevelCode(unsigned level) {
  switch (level) {
    case XM_H264_LEVEL_1:
      return XM_H264_LEVEL_CODE_1;
    case XM_H264_LEVEL_1_B:
      return XM_H264_LEVEL_CODE_1_B;
    case XM_H264_LEVEL_1_1:
      return XM_H264_LEVEL_CODE_1_1;
    case XM_H264_LEVEL_1_2:
      return XM_H264_LEVEL_CODE_1_2;
    case XM_H264_LEVEL_1_3:
      return XM_H264_LEVEL_CODE_1_3;
    case XM_H264_LEVEL_2:
      return XM_H264_LEVEL_CODE_2;
    default:
      return 0;
  }
}

unsigned GetProfile(unsigned profileCode)
{
  switch (profileCode) {
    case XM_H264_PROFILE_CODE_BASELINE:
      return XM_H264_PROFILE_BASELINE;
    case XM_H264_PROFILE_CODE_MAIN:
      return XM_H264_PROFILE_MAIN;
    default:
      return 0;
  }
}

unsigned GetLevel(unsigned levelCode) {
  switch (levelCode) {
    case XM_H264_LEVEL_CODE_1:
      return XM_H264_LEVEL_1;
    case XM_H264_LEVEL_CODE_1_B:
      return XM_H264_LEVEL_1_B;
    case XM_H264_LEVEL_CODE_1_1:
      return XM_H264_LEVEL_1_1;
    case XM_H264_LEVEL_CODE_1_2:
      return XM_H264_LEVEL_1_2;
    case XM_H264_LEVEL_CODE_1_3:
      return XM_H264_LEVEL_1_3;
    case XM_H264_LEVEL_CODE_2:
      return XM_H264_LEVEL_2;
    default:
      return 0;
  }
}

XM_H323_H264_Capability::XM_H323_H264_Capability()
{
  SetPayloadType(XM_MEDIA_FORMAT_H264.GetPayloadType());
}

PObject * XM_H323_H264_Capability::Clone() const
{
	return new XM_H323_H264_Capability(*this);
}

PObject::Comparison XM_H323_H264_Capability::Compare(const PObject & obj) const
{
  Comparison result = H323Capability::Compare(obj);
  if (result != EqualTo) {
    return result;
  }
  
	if (PIsDescendant(&obj, XM_H323_H264_Capability)) {
    return EqualTo;
	}
  
  return LessThan;
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
  const OpalMediaFormat & mediaFormat = GetMediaFormat();
  unsigned profile    = mediaFormat.GetOptionInteger(XMMediaFormat_H264::ProfileOption());
  unsigned level      = mediaFormat.GetOptionInteger(XMMediaFormat_H264::LevelOption());
  unsigned maxBitRate = mediaFormat.GetOptionInteger(OpalMediaFormat::MaxBitRateOption())/100;
  
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
  profileValueInteger.SetValue(GetProfileCode(profile));
	
  H245_GenericParameter & h264Level = h264Collapsing[1];
  H245_ParameterIdentifier & levelIdentifier = h264Level.m_parameterIdentifier;
  levelIdentifier.SetTag(H245_ParameterIdentifier::e_standard);
  PASN_Integer & levelIdentifierInteger = levelIdentifier;
  levelIdentifierInteger.SetValue(42);
  H245_ParameterValue & levelValue = h264Level.m_parameterValue;
  levelValue.SetTag(H245_ParameterValue::e_unsignedMin);
  PASN_Integer & levelValueInteger = levelValue;
  levelValueInteger.SetValue(GetLevelCode(level));
	
  return true;
}

bool XM_H323_H264_Capability::OnSendingPDU(H245_VideoMode & pdu) const
{
  return true;
}

bool XM_H323_H264_Capability::OnReceivedPDU(const H245_VideoCapability & cap)
{
  if (cap.GetTag() != H245_VideoCapability::e_genericVideoCapability) {
    return false;
  }
	
  const H245_GenericCapability & h264 = cap;
	
  const H245_CapabilityIdentifier & h264CapabilityIdentifier = h264.m_capabilityIdentifier;
  if (h264CapabilityIdentifier.GetTag() != H245_CapabilityIdentifier::e_standard) {
    return false;
  }
	
  const PASN_ObjectId & h264ObjectId = h264CapabilityIdentifier;
  if (h264ObjectId != "0.0.8.241.0.0.1") {
    return false;
  }
	
	OpalMediaFormat & mediaFormat = GetWritableMediaFormat();
  unsigned level = 0;
  unsigned profile = 0;
	
  if (!h264.HasOptionalField(H245_GenericCapability::e_maxBitRate)) {
    return false;
  }
	unsigned maxBitRate = std::min((unsigned)mediaFormat.GetOptionInteger(OpalMediaFormat::MaxBitRateOption()), (h264.m_maxBitRate)*100);
	
  if (!h264.HasOptionalField(H245_GenericCapability::e_collapsing)) {
    return false;
  }
	
  const H245_ArrayOf_GenericParameter & h264Collapsing = h264.m_collapsing;
  unsigned size = h264Collapsing.GetSize();
  for (unsigned i = 0; i < size; i++) {
    const H245_GenericParameter & parameter = h264Collapsing[i];
		
    const H245_ParameterIdentifier & parameterIdentifier = parameter.m_parameterIdentifier;
    if (parameterIdentifier.GetTag() != H245_ParameterIdentifier::e_standard) {
      break;
    }
		
    const PASN_Integer & parameterInteger = parameterIdentifier;
		
    const H245_ParameterValue & parameterValue = parameter.m_parameterValue;
		
    switch (parameterInteger) {
      case 41:
        if (parameterValue.GetTag() == H245_ParameterValue::e_booleanArray) {
          const PASN_Integer & profileValueInteger = parameterValue;
          profile = GetProfile(profileValueInteger);
        }
        break;
			case 42:
        if (parameterValue.GetTag() == H245_ParameterValue::e_unsignedMin) {
          const PASN_Integer & levelValueInteger = parameterValue;
          level = GetLevel(levelValueInteger);
        }
        break;
      default:
        break;
    }
  }
  
  if (profile == 0 || level == 0) {
    return false;
  }
	
  mediaFormat.SetOptionInteger(XMMediaFormat_H264::ProfileOption(), profile);
  mediaFormat.SetOptionInteger(XMMediaFormat_H264::LevelOption(), level);
  mediaFormat.SetOptionInteger(OpalMediaFormat::MaxBitRateOption(), maxBitRate*100);

  return true;
}

#pragma mark -
#pragma mark Packetization and Codec Option Functions

bool _XMGetIsRFC2429(const OpalMediaFormat & mediaFormat)
{
  if (mediaFormat.HasOption(XMMediaFormat_H263::IsRFC2429Option())) {
    return mediaFormat.GetOptionBoolean(XMMediaFormat_H263::IsRFC2429Option());
  }
  return false;
}

unsigned _XMGetH264Profile(const OpalMediaFormat & mediaFormat)
{
  if (mediaFormat.HasOption(XMMediaFormat_H264::ProfileOption())) {
    return mediaFormat.GetOptionInteger(XMMediaFormat_H264::ProfileOption());
  }
  return XM_H264_PROFILE_BASELINE;
}

void _XMSetH264Profile(OpalMediaFormat & mediaFormat, unsigned profile)
{
  if (mediaFormat.HasOption(XMMediaFormat_H264::ProfileOption())) {
    mediaFormat.SetOptionInteger(XMMediaFormat_H264::ProfileOption(), profile);
  }
}

unsigned _XMGetH264Level(const OpalMediaFormat & mediaFormat)
{
  if (mediaFormat.HasOption(XMMediaFormat_H264::LevelOption())) {
    return mediaFormat.GetOptionInteger(XMMediaFormat_H264::LevelOption());
  }
  return XM_H264_LEVEL_1;
}

void _XMSetH264Level(OpalMediaFormat & mediaFormat, unsigned level)
{
  if (mediaFormat.HasOption(XMMediaFormat_H264::LevelOption())) {
    mediaFormat.SetOptionInteger(XMMediaFormat_H264::LevelOption(), level);
  }
}

