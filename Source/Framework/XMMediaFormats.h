/*
 * $Id: XMMediaFormats.h,v 1.1 2005/10/11 09:03:10 hfriederich Exp $
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
#include <codec/h261codec.h>
#include <h323/h323caps.h>

// definition of the "XMeeting" video formats

#define XM_VIDEO_H261 "XMVideo_H.261"

extern const OpalVideoFormat & GetXMVideoFormat_H261();

#define XM_VIDEO_FORMAT_H261 GetXMVideoFormat_H261()

// definition of the transcoders

class XM_H261_VIDEO_CIF : public OpalVideoTranscoder
{
public:
	XM_H261_VIDEO_CIF();
	~XM_H261_VIDEO_CIF();
	virtual PINDEX GetOptimalDataFrameSize(BOOL input) const;
	virtual BOOL ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst);
};

class XM_H261_VIDEO_QCIF : public OpalVideoTranscoder
{
public:
	XM_H261_VIDEO_QCIF();
	~XM_H261_VIDEO_QCIF();
	virtual PINDEX GetOptimalDataFrameSize(BOOL input) const;
	virtual BOOL ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst);
};

#define XM_REGISTER_FORMATS() \
	OPAL_REGISTER_TRANSCODER(XM_H261_VIDEO_CIF, OpalH261_CIF, XM_VIDEO_FORMAT_H261); \
	OPAL_REGISTER_TRANSCODER(XM_H261_VIDEO_QCIF, OpalH261_QCIF, XM_VIDEO_FORMAT_H261)

#endif // __XM_MEDIA_FORMATS_H__