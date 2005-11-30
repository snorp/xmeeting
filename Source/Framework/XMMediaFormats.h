/*
 * $Id: XMMediaFormats.h,v 1.7 2005/11/30 23:49:46 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_MEDIA_FORMATS_H__
#define __XM_MEDIA_FORMATS_H__

#include <ptlib.h>
#include <opal/mediafmt.h>
#include <codec/vidcodec.h>
#include <h323/h323caps.h>

#include "XMTypes.h"

#pragma mark Audio Media Formats

extern const char *_XMMediaFormatIdentifier_G711_uLaw;
extern const char *_XMMediaFormatIdentifier_G711_ALaw;

#pragma mark Video Media Formats

extern const char *_XMMediaFormatIdentifier_H261;
extern const char *_XMMediaFormatIdentifier_H263;
extern const char *_XMMediaFormatIdentifier_H264;

extern const char *_XMMediaFormat_Video;

extern const char *_XMMediaFormat_H261_QCIF;
extern const char *_XMMediaFormat_H261_CIF;

extern const char *_XMMediaFormat_H263_SQCIF;
extern const char *_XMMediaFormat_H263_QCIF;
extern const char *_XMMediaFormat_H263_CIF;
extern const char *_XMMediaFormat_H263_4CIF;
extern const char *_XMMediaFormat_H263_16CIF;

extern const char *_XMMediaFormat_H264_QCIF;
extern const char *_XMMediaFormat_H264_CIF;

// definition of the "XMeeting" video formats

extern const OpalVideoFormat & XMGetMediaFormat_Video();
extern const OpalVideoFormat & XMGetMediaFormat_H261_QCIF();
extern const OpalVideoFormat & XMGetMediaFormat_H261_CIF();
extern const OpalVideoFormat & XMGetMediaFormat_H263_SQCIF();
extern const OpalVideoFormat & XMGetMediaFormat_H263_QCIF();
extern const OpalVideoFormat & XMGetMediaFormat_H263_CIF();
extern const OpalVideoFormat & XMGetMediaFormat_H263_4CIF();
extern const OpalVideoFormat & XMGetMediaFormat_H263_16CIF();
extern const OpalVideoFormat & XMGetMediaFormat_H264_QCIF();
extern const OpalVideoFormat & XMGetMediaFormat_H264_CIF();

#define XM_MEDIA_FORMAT_VIDEO XMGetMediaFormat_Video()
#define XM_MEDIA_FORMAT_H261_QCIF XMGetMediaFormat_H261_QCIF()
#define XM_MEDIA_FORMAT_H261_CIF XMGetMediaFormat_H261_CIF()
#define XM_MEDIA_FORMAT_H263_SQCIF XMGetMediaFormat_H263_SQCIF()
#define XM_MEDIA_FORMAT_H263_QCIF XMGetMediaFormat_H263_QCIF()
#define XM_MEDIA_FORMAT_H263_CIF XMGetMediaFormat_H263_CIF()
#define XM_MEDIA_FORMAT_H263_4CIF XMGetMediaFormat_H263_4CIF()
#define XM_MEDIA_FORMAT_H263_16CIF XMGetMediaFormat_H263_16CIF()
#define XM_MEDIA_FORMAT_H264_QCIF XMGetMediaFormat_H264_QCIF()
#define XM_MEDIA_FORMAT_H264_CIF XMGetMediaFormat_H264_CIF()

// limiting the video bitrate
void _XMSetMaxVideoBitrate(unsigned maxVideoBitrate);
unsigned _XMGetMaxVideoBitrate();

// identifying MediaFormats
BOOL _XMIsVideoMediaFormat(const OpalMediaFormat & mediaFormat);

// definition of the transcoders

class XM_H261_VIDEO_QCIF : public OpalVideoTranscoder
{
	PCLASSINFO(XM_H261_VIDEO_QCIF, OpalVideoTranscoder);
	
public:
	XM_H261_VIDEO_QCIF();
	~XM_H261_VIDEO_QCIF();
	virtual PINDEX GetOptimalDataFrameSize(BOOL input) const;
	virtual BOOL ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst);
};

class XM_H261_VIDEO_CIF : public OpalVideoTranscoder
{
	PCLASSINFO(XM_H261_VIDEO_CIF, OpalVideoTranscoder);
	
public:
	XM_H261_VIDEO_CIF();
	~XM_H261_VIDEO_CIF();
	virtual PINDEX GetOptimalDataFrameSize(BOOL input) const;
	virtual BOOL ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst);
};

class XM_H263_VIDEO_SQCIF : public OpalVideoTranscoder
{
	PCLASSINFO(XM_H263_VIDEO_SQCIF, OpalVideoTranscoder);
public:
	XM_H263_VIDEO_SQCIF();
	~XM_H263_VIDEO_SQCIF();
	virtual PINDEX GetOptimalDataFrameSize(BOOL input) const;
	virtual BOOL ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst);
};

class XM_H263_VIDEO_QCIF : public OpalVideoTranscoder
{
	PCLASSINFO(XM_H263_VIDEO_QCIF, OpalVideoTranscoder);
public:
	XM_H263_VIDEO_QCIF();
	~XM_H263_VIDEO_QCIF();
	virtual PINDEX GetOptimalDataFrameSize(BOOL input) const;
	virtual BOOL ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst);
};

class XM_H263_VIDEO_CIF : public OpalVideoTranscoder
{
	PCLASSINFO(XM_H263_VIDEO_CIF, OpalVideoTranscoder);
public:
	XM_H263_VIDEO_CIF();
	~XM_H263_VIDEO_CIF();
	virtual PINDEX GetOptimalDataFrameSize(BOOL input) const;
	virtual BOOL ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst);
};

class XM_H263_VIDEO_4CIF : public OpalVideoTranscoder
{
	PCLASSINFO(XM_H263_VIDEO_4CIF, OpalVideoTranscoder);
public:
	XM_H263_VIDEO_4CIF();
	~XM_H263_VIDEO_4CIF();
	virtual PINDEX GetOptimalDataFrameSize(BOOL input) const;
	virtual BOOL ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst);
};

class XM_H263_VIDEO_16CIF : public OpalVideoTranscoder
{
	PCLASSINFO(XM_H263_VIDEO_16CIF, OpalVideoTranscoder);
public:
	XM_H263_VIDEO_16CIF();
	~XM_H263_VIDEO_16CIF();
	virtual PINDEX GetOptimalDataFrameSize(BOOL input) const;
	virtual BOOL ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst);
};

class XM_VIDEO_H261_QCIF : public OpalVideoTranscoder
{
	PCLASSINFO(XM_VIDEO_H261_QCIF, OpalVideoTranscoder);
	
public:
	XM_VIDEO_H261_QCIF();
	~XM_VIDEO_H261_QCIF();
	virtual PINDEX GetOptimalDataFrameSize(BOOL input) const;
	virtual BOOL ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst);
};

class XM_VIDEO_H261_CIF : public OpalVideoTranscoder
{
	PCLASSINFO(XM_VIDEO_H261_CIF, OpalVideoTranscoder);
	
public:
	XM_VIDEO_H261_CIF();
	~XM_VIDEO_H261_CIF();
	virtual PINDEX GetOptimalDataFrameSize(BOOL input) const;
	virtual BOOL ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst);
};

class XM_VIDEO_H263_SQCIF : public OpalVideoTranscoder
{
	PCLASSINFO(XM_VIDEO_H263_SQCIF, OpalVideoTranscoder);
	
public:
	XM_VIDEO_H263_SQCIF();
	~XM_VIDEO_H263_SQCIF();
	virtual PINDEX GetOptimalDataFrameSize(BOOL input) const;
	virtual BOOL ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst);
};

class XM_VIDEO_H263_QCIF : public OpalVideoTranscoder
{
	PCLASSINFO(XM_VIDEO_H263_QCIF, OpalVideoTranscoder);
	
public:
	XM_VIDEO_H263_QCIF();
	~XM_VIDEO_H263_QCIF();
	virtual PINDEX GetOptimalDataFrameSize(BOOL input) const;
	virtual BOOL ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst);
};

class XM_VIDEO_H263_CIF : public OpalVideoTranscoder
{
	PCLASSINFO(XM_VIDEO_H263_CIF, OpalVideoTranscoder);
	
public:
	XM_VIDEO_H263_CIF();
	~XM_VIDEO_H263_CIF();
	virtual PINDEX GetOptimalDataFrameSize(BOOL input) const;
	virtual BOOL ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst);
};

class XM_VIDEO_H263_4CIF : public OpalVideoTranscoder
{
	PCLASSINFO(XM_VIDEO_H263_4CIF, OpalVideoTranscoder);
	
public:
	XM_VIDEO_H263_4CIF();
	~XM_VIDEO_H263_4CIF();
	virtual PINDEX GetOptimalDataFrameSize(BOOL input) const;
	virtual BOOL ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst);
};

class XM_VIDEO_H263_16CIF : public OpalVideoTranscoder
{
	PCLASSINFO(XM_VIDEO_H263_16CIF, OpalVideoTranscoder);
	
public:
	XM_VIDEO_H263_16CIF();
	~XM_VIDEO_H263_16CIF();
	virtual PINDEX GetOptimalDataFrameSize(BOOL input) const;
	virtual BOOL ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst);
};

// H.323 Capability definitions

class XM_H323_H261_Capability : public H323VideoCapability
{
	PCLASSINFO(XM_H323_H261_Capability, H323VideoCapability);
	
public:
	XM_H323_H261_Capability(XMVideoSize videoSize);
	virtual PObject * Clone() const;
	Comparison Compare(const PObject & obj) const;
	virtual unsigned GetSubType() const;
	virtual PString GetFormatName() const;
	virtual BOOL OnSendingPDU(H245_VideoCapability & pdu) const;
	virtual BOOL OnSendingPDU(H245_VideoMode & pdu) const;
	virtual BOOL OnReceivedPDU(const H245_VideoCapability & pdu);
	
private:
	unsigned cifMPI;
	unsigned qcifMPI;
	BOOL temporalSpatialTradeOffCapability;
	unsigned maxBitRate;
	BOOL stillImageTransmission;
};

class XM_H323_H263_Capability : public H323VideoCapability
{
	PCLASSINFO(XM_H323_H263_Capability, H323VideoCapability);
	
public:
	XM_H323_H263_Capability(XMVideoSize videoSize);
	virtual PObject * Clone() const;
	Comparison Compare(const PObject & obj) const;
	virtual unsigned GetSubType() const;
	virtual PString GetFormatName() const;
	virtual BOOL OnSendingPDU(H245_VideoCapability & pdu) const;
	virtual BOOL OnSendingPDU(H245_VideoMode & pdu) const;
	virtual BOOL OnReceivedPDU(const H245_VideoCapability & pdu);
	
private :
	unsigned sqcifMPI;
	unsigned qcifMPI;
	unsigned cifMPI;
	unsigned cif4MPI;
	unsigned cif16MPI;
	
	unsigned maxBitRate;
	BOOL unrestrictedVector;
	BOOL arithmeticCoding;
	BOOL advancedPrediction;
	BOOL pbFrames;
	BOOL temporalSpatialTradeOffCapability;
	
	long unsigned hrd_B;
	unsigned bppMaxKb;
	
	unsigned slowSqcifMPI;
	unsigned slowQcifMPI;
	unsigned slowCifMPI;
	unsigned slowCif4MPI;
	unsigned slowCif16MPI;
	
	BOOL errorCompensation;
};

#define XM_REGISTER_H323_CAPABILITIES \
	H323_REGISTER_CAPABILITY_FUNCTION(XM_H323_H261_QCIF, _XMMediaFormat_H261_QCIF, H323_NO_EP_VAR) \
		{ return new XM_H323_H261_Capability(XMVideoSize_QCIF); } \
	H323_REGISTER_CAPABILITY_FUNCTION(XM_H323_H261_CIF, _XMMediaFormat_H261_CIF, H323_NO_EP_VAR) \
		{ return new XM_H323_H261_Capability(XMVideoSize_CIF); } \
    H323_REGISTER_CAPABILITY_FUNCTION(XM_H323_H263_SQCIF, _XMMediaFormat_H263_SQCIF, H323_NO_EP_VAR) \
		{ return new XM_H323_H263_Capability(XMVideoSize_SQCIF); } \
	H323_REGISTER_CAPABILITY_FUNCTION(XM_H323_H263_QCIF, _XMMediaFormat_H263_QCIF, H323_NO_EP_VAR) \
		{ return new XM_H323_H263_Capability(XMVideoSize_QCIF); } \
	H323_REGISTER_CAPABILITY_FUNCTION(XM_H323_H263_CIF, _XMMediaFormat_H263_CIF, H323_NO_EP_VAR) \
		{ return new XM_H323_H263_Capability(XMVideoSize_CIF); }

// macro for registering the media formats

#define XM_REGISTER_FORMATS() \
	XM_REGISTER_H323_CAPABILITIES \
	OPAL_REGISTER_TRANSCODER(XM_H261_VIDEO_CIF, XM_MEDIA_FORMAT_H261_CIF, XM_MEDIA_FORMAT_VIDEO); \
	OPAL_REGISTER_TRANSCODER(XM_H261_VIDEO_QCIF, XM_MEDIA_FORMAT_H261_QCIF, XM_MEDIA_FORMAT_VIDEO); \
	OPAL_REGISTER_TRANSCODER(XM_H263_VIDEO_SQCIF, XM_MEDIA_FORMAT_H263_SQCIF, XM_MEDIA_FORMAT_VIDEO); \
	OPAL_REGISTER_TRANSCODER(XM_H263_VIDEO_QCIF, XM_MEDIA_FORMAT_H263_QCIF, XM_MEDIA_FORMAT_VIDEO); \
	OPAL_REGISTER_TRANSCODER(XM_H263_VIDEO_CIF, XM_MEDIA_FORMAT_H263_CIF, XM_MEDIA_FORMAT_VIDEO); \
	OPAL_REGISTER_TRANSCODER(XM_H263_VIDEO_4CIF, XM_MEDIA_FORMAT_H263_4CIF, XM_MEDIA_FORMAT_VIDEO); \
	OPAL_REGISTER_TRANSCODER(XM_H263_VIDEO_16CIF, XM_MEDIA_FORMAT_H263_16CIF, XM_MEDIA_FORMAT_VIDEO); \
	OPAL_REGISTER_TRANSCODER(XM_VIDEO_H261_CIF, XM_MEDIA_FORMAT_VIDEO, XM_MEDIA_FORMAT_H261_CIF); \
	OPAL_REGISTER_TRANSCODER(XM_VIDEO_H261_QCIF, XM_MEDIA_FORMAT_VIDEO, XM_MEDIA_FORMAT_H261_QCIF); \
	OPAL_REGISTER_TRANSCODER(XM_VIDEO_H263_SQCIF, XM_MEDIA_FORMAT_VIDEO, XM_MEDIA_FORMAT_H263_SQCIF); \
	OPAL_REGISTER_TRANSCODER(XM_VIDEO_H263_QCIF, XM_MEDIA_FORMAT_VIDEO, XM_MEDIA_FORMAT_H263_QCIF); \
	OPAL_REGISTER_TRANSCODER(XM_VIDEO_H263_CIF, XM_MEDIA_FORMAT_VIDEO, XM_MEDIA_FORMAT_H263_CIF); \
	OPAL_REGISTER_TRANSCODER(XM_VIDEO_H263_4CIF, XM_MEDIA_FORMAT_VIDEO, XM_MEDIA_FORMAT_H263_4CIF); \
	OPAL_REGISTER_TRANSCODER(XM_VIDEO_H263_16CIF, XM_MEDIA_FORMAT_VIDEO, XM_MEDIA_FORMAT_H263_16CIF)

#endif // __XM_MEDIA_FORMATS_H__