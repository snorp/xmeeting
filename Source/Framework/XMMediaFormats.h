/*
 * $Id: XMMediaFormats.h,v 1.23 2008/10/07 23:19:17 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_MEDIA_FORMATS_H__
#define __XM_MEDIA_FORMATS_H__

#include <ptlib.h>
#include <opal/mediafmt.h>
#include <codec/vidcodec.h>
#include <h323/h323caps.h>
#include <sip/sdpcaps.h>

#include "XMTypes.h"

class H245_H2250Capability;

#pragma mark Media Format Strings

// Audio Format Identifiers
// These identifiers shall be used to enable/disable/reorder media formats
extern const char *_XMMediaFormatIdentifier_G711_uLaw;
extern const char *_XMMediaFormatIdentifier_G711_ALaw;

// Video Format Identifiers
// These identifiers shall be used to enable/disable/reorder media formats
extern const char *_XMMediaFormatIdentifier_H261;
extern const char *_XMMediaFormatIdentifier_H263;
extern const char *_XMMediaFormatIdentifier_H264;

extern const char *_XMMediaFormat_H261;
extern const char *_XMMediaFormat_H263;
extern const char *_XMMediaFormat_H263Plus;
extern const char *_XMMediaFormat_H264;

// Format Encodings
extern const char *_XMMediaFormatEncoding_H261;
extern const char *_XMMediaFormatEncoding_H263;
extern const char *_XMMediaFormatEncoding_H263Plus;
extern const char *_XMMediaFormatEncoding_H264;

#pragma mark XMeeting Video Formats

extern const OpalVideoFormat & XMGetMediaFormat_H261();
extern const OpalVideoFormat & XMGetMediaFormat_H263();
extern const OpalVideoFormat & XMGetMediaFormat_H263Plus();
extern const OpalVideoFormat & XMGetMediaFormat_H264();

#define XM_MEDIA_FORMAT_H261 XMGetMediaFormat_H261()
#define XM_MEDIA_FORMAT_H263 XMGetMediaFormat_H263()
#define XM_MEDIA_FORMAT_H263PLUS XMGetMediaFormat_H263Plus()
#define XM_MEDIA_FORMAT_H264 XMGetMediaFormat_H264()

#pragma mark Constants

#define XM_H264_PROFILE_BASELINE 1
#define XM_H264_PROFILE_MAIN 2

#define XM_H264_LEVEL_1		1
#define XM_H264_LEVEL_1_B	2
#define XM_H264_LEVEL_1_1	3
#define XM_H264_LEVEL_1_2	4
#define XM_H264_LEVEL_1_3	5
#define XM_H264_LEVEL_2		6

#define XM_H264_PACKETIZATION_MODE_SINGLE_NAL 1
#define XM_H264_PACKETIZATION_MODE_NON_INTERLEAVED 2

#pragma mark -
#pragma mark Media Format Options

extern const char * const CanRFC2429Option;
extern const char * const IsRFC2429Option;
extern const char * const ProfileOption;
extern const char * const LevelOption;
extern const char * const PacketizationOption;
extern const char * const H264LimitedModeOption;

#pragma mark -
#pragma mark Managing Media Formats

XMCodecIdentifier _XMGetMediaFormatCodec(const OpalMediaFormat & mediaFormat);
XMVideoSize _XMGetMediaFormatSize(const OpalMediaFormat & mediaFormat);
const char *_XMGetMediaFormatName(const OpalMediaFormat & mediaFormat);

unsigned _XMGetMaxH261Bitrate();
unsigned _XMGetMaxH263Bitrate();
unsigned _XMGetMaxH264Bitrate();

#pragma mark -
#pragma mark H.323 Capabilities

/**
 * This class adds some common functionality to the video capabilities
 * used within XMeeting.
 *
 * The IsValidCapabilityForSending() returns if the XMeeting system can
 * actually send the format that is advertised by the capability.
 * This is to handle some shortcomings in the QuickTime library.
 *
 * CompareTo() implements a different compare algorithm than the one
 * found in Compare(). The default Compare() must return EqualTo if
 * both capabilities define the same format and are compatible, or the
 * capability merge system of Opal will fail. However, CompareTo() is
 * used to rank similar capabilities in order to choose the best one.
 **/
class XMH323VideoCapability : public H323VideoCapability
{
  PCLASSINFO(XMH323VideoCapability, H323VideoCapability);
	
public:
	
  virtual bool IsValidCapabilityForSending() const = 0;
  virtual Comparison CompareTo(const XMH323VideoCapability & obj) const = 0;
};

class XM_H323_H261_Capability : public XMH323VideoCapability
{
  PCLASSINFO(XM_H323_H261_Capability, XMH323VideoCapability);
	
public:
  XM_H323_H261_Capability();
  virtual PObject * Clone() const;
  virtual Comparison Compare(const PObject & obj) const;
  virtual unsigned GetSubType() const;
  virtual PString GetFormatName() const;
  virtual bool OnSendingPDU(H245_VideoCapability & pdu) const;
  virtual bool OnSendingPDU(H245_VideoMode & pdu) const;
  virtual bool OnReceivedPDU(const H245_VideoCapability & pdu);
	
  virtual bool IsValidCapabilityForSending() const;
  virtual Comparison CompareTo(const XMH323VideoCapability & obj) const;
    
  //virtual void UpdateFormat(const OpalMediaFormat & mediaFormat);
	
private:
  unsigned cifMPI;
  unsigned qcifMPI;
  unsigned maxBitRate;
};

class XM_H323_H263_Capability : public XMH323VideoCapability
{
  PCLASSINFO(XM_H323_H263_Capability, XMH323VideoCapability);
	
public:
  XM_H323_H263_Capability();
  XM_H323_H263_Capability(bool isH263PlusCapability);
  virtual PObject * Clone() const;
  virtual Comparison Compare(const PObject & obj) const;
  virtual unsigned GetSubType() const;
  virtual PString GetFormatName() const;
  virtual bool OnSendingPDU(H245_VideoCapability & pdu) const;
  virtual bool OnSendingPDU(H245_VideoMode & pdu) const;
  virtual bool OnReceivedPDU(const H245_VideoCapability & pdu);
    //virtual void OnSendingPDU(H245_MediaPacketizationCapability & mediaPacketizationCapability) const;
    //virtual void OnReceivedPDU(const H245_MediaPacketizationCapability & mediaPacketizationCapability);
    //virtual bool HasMediaPacketizationParameters() const { return IsH263PlusCapability(); }
	//virtual void OnSendingPDU(H245_H2250LogicalChannelParameters_mediaPacketization & mediaPacketization) const;
	//virtual void OnReceivedPDU(const H245_H2250LogicalChannelParameters_mediaPacketization & mediaPacketization);
	
  virtual bool IsValidCapabilityForSending() const;
  virtual Comparison CompareTo(const XMH323VideoCapability & obj) const;
    
  virtual void UpdateFormat(const OpalMediaFormat & mediaFormat);
	
  bool IsH263PlusCapability() const { return isH263PlusCapability; }
  bool CanRFC2429() const { return canRFC2429; }
  bool IsRFC2429() const { return isRFC2429; }
	
private :
        
  void SetCanRFC2429(bool canRFC2429);
  void SetIsRFC2429(bool isRFC2429);
    
  unsigned sqcifMPI;
  unsigned qcifMPI;
  unsigned cifMPI;
  unsigned cif4MPI;
  unsigned cif16MPI;
	
  unsigned maxBitRate;
	
  unsigned slowSqcifMPI;
  unsigned slowQcifMPI;
  unsigned slowCifMPI;
  unsigned slowCif4MPI;
  unsigned slowCif16MPI;
	
  bool isH263PlusCapability;
  bool canRFC2429;
  bool isRFC2429;
};

class XM_H323_H263PLUS_Capability : public XM_H323_H263_Capability
{
  PCLASSINFO(XM_H323_H263PLUS_Capability, XM_H323_H263_Capability);
	
public:
	
  XM_H323_H263PLUS_Capability();
};

class XM_H323_H264_Capability : public XMH323VideoCapability
{
  PCLASSINFO(XM_H323_H264_Capability, XMH323VideoCapability);
	
public:
  XM_H323_H264_Capability();
  virtual PObject * Clone() const;
  virtual Comparison Compare(const PObject & obj) const;
  virtual unsigned GetSubType() const;
  virtual PString GetFormatName() const;
  virtual bool OnSendingPDU(H245_VideoCapability & pdu) const;
  virtual bool OnSendingPDU(H245_VideoMode & pdu) const;
  virtual bool OnReceivedPDU(const H245_VideoCapability & pdu);
	
  //virtual void OnSendingPDU(H245_MediaPacketizationCapability & mediaPacketizationCapability) const;
  //virtual void OnReceivedPDU(const H245_MediaPacketizationCapability & mediaPacketizationCapability);
	
  virtual bool IsValidCapabilityForSending() const;
  virtual Comparison CompareTo(const XMH323VideoCapability & obj) const;
    
  virtual void UpdateFormat(const OpalMediaFormat & mediaFormat);
	
  unsigned GetProfile() const;
  unsigned GetLevel() const;
	
private:
        
  void SetProfile(WORD profile);
  void SetLevel(unsigned level);
  void SetPacketizationMode(unsigned packetizationMode);
	
  unsigned maxBitRate;
  WORD profile;
  unsigned level;
  unsigned packetizationMode;
  bool h264LimitedMode;
};

#pragma mark -
#pragma mark SDP Capabilities

/*class XM_SDP_H261_Capability : public SDPCapability
{
    PCLASSINFO(XM_SDP_H261_Capability, SDPCapability);
    
public:
    
    virtual bool OnSendingSDP(SDPMediaFormat & sdpMediaFormat) const;
    virtual bool OnReceivedSDP(const SDPMediaFormat & sdpMediaFormat,
                               const SDPMediaDescription & mediaDescription,
                               const SDPSessionDescription & sessionDescription);
};

class XM_SDP_H263_Capability : public SDPCapability
{
    PCLASSINFO(XM_SDP_H263_Capability, SDPCapability);
    
public:
    
    virtual bool OnSendingSDP(SDPMediaFormat & sdpMediaFormat) const;
    virtual bool OnReceivedSDP(const SDPMediaFormat & sdpMediaFormat,
                               const SDPMediaDescription & mediaDescription,
                               const SDPSessionDescription & sessionDescription);
};

class XM_SDP_H263PLUS_Capability : public XM_SDP_H263_Capability
{
    PCLASSINFO(XM_SDP_H263PLUS_Capability, XM_SDP_H263_Capability);
};*/

#pragma mark -
#pragma mark Packetization and Codec Option Functions

bool _XMGetCanRFC2429(const OpalMediaFormat & mediaFormat);
void _XMSetCanRFC2429(OpalMediaFormat & mediaFormat, bool canRFC2429);
bool _XMGetIsRFC2429(const OpalMediaFormat & mediaFormat);
void _XMSetIsRFC2429(OpalMediaFormat & mediaFormat, bool isRFC2429);

unsigned _XMGetH264Profile(const OpalMediaFormat & mediaFormat);
void _XMSetH264Profile(OpalMediaFormat & mediaFormat, unsigned profile);
unsigned _XMGetH264Level(const OpalMediaFormat & mediaFormat);
void _XMSetH264Level(OpalMediaFormat & mediaFormat, unsigned level);
unsigned _XMGetH264PacketizationMode(const OpalMediaFormat & mediaFormat);
void _XMSetH264PacketizationMode(OpalMediaFormat & mediaFormat, unsigned packetizationMode);
bool _XMGetEnableH264LimitedMode(const OpalMediaFormat & mediaFormat);
void _XMSetEnableH264LimitedMode(OpalMediaFormat & mediaFormat, bool enableH264LimitedMode);

#pragma mark -
#pragma mark Macros

#define XM_REGISTER_FORMATS() \
  H323_REGISTER_CAPABILITY(XM_H323_H261_Capability, XMGetMediaFormat_H261().GetName()); \
  //static H323CapabilityFactory::Worker<XM_H323_H263_Capability> h263Factory(XM_MEDIA_FORMAT_H263, true); \
  //static H323CapabilityFactory::Worker<XM_H323_H263PLUS_Capability> h263PlusFactory(XM_MEDIA_FORMAT_H263PLUS, true); \
  //static H323CapabilityFactory::Worker<XM_H323_H264_Capability> h264Factory(XM_MEDIA_FORMAT_H264, true); \
  //SDP_REGISTER_CAPABILITY(XM_SDP_H261_Capability, XM_MEDIA_FORMAT_H261); \
  //SDP_REGISTER_CAPABILITY(XM_SDP_H263_Capability, XM_MEDIA_FORMAT_H263); \
  //SDP_REGISTER_CAPABILITY(XM_SDP_H263PLUS_Capability, XM_MEDIA_FORMAT_H263PLUS); \

#endif // __XM_MEDIA_FORMATS_H__