/*
 * $Id: XMMediaFormats.cpp,v 1.1 2005/10/11 09:03:10 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#include "XMMediaFormats.h"

#define FRAME_WIDTH PVideoDevice::CIFWidth
#define FRAME_HEIGHT PVideoDevice::CIFHeight
#define FRAME_RATE 25 // PAL

#define new PNEW

const OpalVideoFormat & GetXMVideoFormat_H261()
{
	static const OpalVideoFormat XMVideoFormat_H261(XM_VIDEO_H261,
													RTP_DataFrame::MaxPayloadType,
													XM_VIDEO_H261,
													FRAME_WIDTH,
													FRAME_HEIGHT,
													FRAME_RATE,
													32*FRAME_WIDTH*FRAME_HEIGHT*FRAME_RATE);
	return XMVideoFormat_H261;
}

#pragma mark XM_H261_VIDEO_CIF methods

XM_H261_VIDEO_CIF::XM_H261_VIDEO_CIF()
: OpalVideoTranscoder(OpalH261_CIF, XM_VIDEO_FORMAT_H261)
{
	cout << "XM_H261_VIDEO_CIF transcoder created" << endl;
}

XM_H261_VIDEO_CIF::~XM_H261_VIDEO_CIF()
{
	cout << "XM_H261_VIDEO_CIF transcoder destroyed" << endl;
}

PINDEX XM_H261_VIDEO_CIF::GetOptimalDataFrameSize(BOOL input) const
{
	return RTP_DataFrame::MaxEthernetPayloadSize;
}

BOOL XM_H261_VIDEO_CIF::ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst)
{
	cout << "XM_H261_VIDEO_CIF ConvertFrames called" << endl;
	
	return TRUE;
}

#pragma mark XM_H261_VIDEO_QCIF methods

XM_H261_VIDEO_QCIF::XM_H261_VIDEO_QCIF()
: OpalVideoTranscoder(OpalH261_QCIF, XM_VIDEO_FORMAT_H261)
{
	cout << "XM_H261_VIDEO_QCIF transcoder created" << endl;
}

XM_H261_VIDEO_QCIF::~XM_H261_VIDEO_QCIF()
{
	cout << "XM_H261_VIDEO_QCIF transcoder destroyed" << endl;
}

PINDEX XM_H261_VIDEO_QCIF::GetOptimalDataFrameSize(BOOL input) const
{
	return RTP_DataFrame::MaxEthernetPayloadSize;
}

BOOL XM_H261_VIDEO_QCIF::ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst)
{
	cout << "XM_H261_VIDEO_QCIF ConvertFrames called" << endl;
	
	return TRUE;
}