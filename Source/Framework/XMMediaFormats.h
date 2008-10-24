/*
 * $Id: XMMediaFormats.h,v 1.33 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_MEDIA_FORMATS_H__
#define __XM_MEDIA_FORMATS_H__

#include <ptlib.h>
#include <opal/mediafmt.h>
#include <codec/vidcodec.h>
#include <h323/h323caps.h>
#include <sip/sdpcaps.h>
#include <h224/h323h224.h>

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

extern const OpalMediaFormat & XMGetMediaFormat_H261();
extern const OpalMediaFormat & XMGetMediaFormat_H263();
extern const OpalMediaFormat & XMGetMediaFormat_H263Plus();
extern const OpalMediaFormat & XMGetMediaFormat_H264();

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
#pragma mark Managing Media Formats

XMCodecIdentifier _XMGetMediaFormatCodec(const OpalMediaFormat & mediaFormat);
XMVideoSize _XMGetMediaFormatSize(const OpalMediaFormat & mediaFormat);
const char *_XMGetMediaFormatName(const OpalMediaFormat & mediaFormat);

unsigned _XMGetMaxH261Bitrate();
unsigned _XMGetMaxH263Bitrate();
unsigned _XMGetMaxH264Bitrate();

#pragma mark -
#pragma mark H.323 Capabilities

class XM_H323_H261_Capability : public H323VideoCapability
{
  PCLASSINFO(XM_H323_H261_Capability, H323VideoCapability);
	
public:
  XM_H323_H261_Capability();
  virtual PObject * Clone() const;
  virtual Comparison Compare(const PObject & obj) const;
  virtual unsigned GetSubType() const;
  virtual PString GetFormatName() const;
  virtual bool OnSendingPDU(H245_VideoCapability & pdu) const;
  virtual bool OnSendingPDU(H245_VideoMode & pdu) const;
  virtual bool OnReceivedPDU(const H245_VideoCapability & pdu);
};

class XM_H323_H263_Capability : public H323VideoCapability
{
  PCLASSINFO(XM_H323_H263_Capability, H323VideoCapability);
	
public:
  XM_H323_H263_Capability();
  XM_H323_H263_Capability(bool isH263Plus);
  virtual PObject * Clone() const;
  virtual Comparison Compare(const PObject & obj) const;
  virtual unsigned GetSubType() const;
  virtual PString GetFormatName() const;
  virtual bool OnSendingPDU(H245_VideoCapability & pdu) const;
  virtual bool OnSendingPDU(H245_VideoMode & pdu) const;
  virtual bool OnReceivedPDU(const H245_VideoCapability & pdu);
  
private:
  bool isH263PlusCapability;
};

class XM_H323_H263PLUS_Capability : public XM_H323_H263_Capability
{
  PCLASSINFO(XM_H323_H263PLUS_Capability, XM_H323_H263_Capability);
	
public:
	
  XM_H323_H263PLUS_Capability();
};

class XM_H323_H264_Capability : public H323VideoCapability
{
  PCLASSINFO(XM_H323_H264_Capability, H323VideoCapability);
	
public:
  XM_H323_H264_Capability();
  virtual PObject * Clone() const;
  virtual Comparison Compare(const PObject & obj) const;
  virtual unsigned GetSubType() const;
  virtual PString GetFormatName() const;
  virtual bool OnSendingPDU(H245_VideoCapability & pdu) const;
  virtual bool OnSendingPDU(H245_VideoMode & pdu) const;
  virtual bool OnReceivedPDU(const H245_VideoCapability & pdu);
private:
  void OnSendingPDU(H245_GenericCapability & capability) const;
};

#pragma mark -
#pragma mark Packetization and Codec Option Functions

bool _XMGetIsRFC2429(const OpalMediaFormat & mediaFormat);

unsigned _XMGetH264Profile(const OpalMediaFormat & mediaFormat);
void _XMSetH264Profile(OpalMediaFormat & mediaFormat, unsigned profile);
unsigned _XMGetH264Level(const OpalMediaFormat & mediaFormat);
void _XMSetH264Level(OpalMediaFormat & mediaFormat, unsigned level);
unsigned _XMGetH264PacketizationMode(const OpalMediaFormat & mediaFormat);

#pragma mark -
#pragma mark Macros

#define XM_REGISTER_FORMATS() \
  H323_REGISTER_CAPABILITY(XM_H323_H261_Capability, XMGetMediaFormat_H261().GetName()); \
  H323_REGISTER_CAPABILITY(XM_H323_H263_Capability, XMGetMediaFormat_H263().GetName()); \
  H323_REGISTER_CAPABILITY(XM_H323_H263PLUS_Capability, XMGetMediaFormat_H263Plus().GetName()); \
  H323_REGISTER_CAPABILITY(XM_H323_H264_Capability, XMGetMediaFormat_H264().GetName()); \
  H323_REGISTER_CAPABILITY(H323_H224_AnnexQCapability, GetOpalH224_H323AnnexQ().GetName()); \
  H323_REGISTER_CAPABILITY(H323_H224_HDLCTunnelingCapability, GetOpalH224_HDLCTunneling().GetName()); \


#endif // __XM_MEDIA_FORMATS_H__