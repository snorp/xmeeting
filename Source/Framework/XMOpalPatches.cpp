/*
 * $Id: XMOpalPatches.cpp,v 1.2 2006/04/17 17:51:22 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

/**
 * Workaround to remove the need for compiling codec/h261codec.cxx
 * This is used to prevent that the OPAL H.261 media formats get registered with the system
 **/

#include <ptlib.h>
#include <codec/h261codec.h>

const OpalVideoFormat & XMGetMediaFormat_Dummy()
{
	static const OpalVideoFormat XMMediaFormat_Dummy("DUMMY", RTP_DataFrame::IllegalPayloadType,
													 "DUMMY", 176, 144, 10, 300);
	return XMMediaFormat_Dummy;
}

const OpalVideoFormat & GetOpalH261_QCIF()
{
	return XMGetMediaFormat_Dummy();
}

const OpalVideoFormat & GetOpalH261_CIF()
{
	return XMGetMediaFormat_Dummy();
}

H323_H261Capability::H323_H261Capability(unsigned _qcifMPI,
                                         unsigned _cifMPI,
                                         BOOL _temporalSpatialTradeOffCapability,
                                         BOOL _stillImageTransmission,
                                         unsigned _maxBitRate)
{
}


PObject * H323_H261Capability::Clone() const
{
	return NULL;
}


PObject::Comparison H323_H261Capability::Compare(const PObject & obj) const
{
	return GreaterThan;
}


unsigned H323_H261Capability::GetSubType() const
{
	return 0;
}


PString H323_H261Capability::GetFormatName() const
{
	return "DUMMY";
}


BOOL H323_H261Capability::OnSendingPDU(H245_VideoCapability & cap) const
{
	return FALSE;
}


BOOL H323_H261Capability::OnSendingPDU(H245_VideoMode & pdu) const
{
	return FALSE;
}


BOOL H323_H261Capability::OnReceivedPDU(const H245_VideoCapability & cap)
{
	return FALSE;
}

Opal_H261_YUV420P::Opal_H261_YUV420P()
: OpalVideoTranscoder(OpalH261_QCIF, OpalYUV420P)
{
	//cout << "YYY" << endl;
}


Opal_H261_YUV420P::~Opal_H261_YUV420P()
{
}


PINDEX Opal_H261_YUV420P::GetOptimalDataFrameSize(BOOL input) const
{
	return 0;
}


BOOL Opal_H261_YUV420P::ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst)
{
	return FALSE;
}


//////////////////////////////////////////////////////////////////////////////

Opal_YUV420P_H261::Opal_YUV420P_H261()
: OpalVideoTranscoder(OpalYUV420P, OpalH261_QCIF)
{
	//cout << "ZZZ" << endl;
}


Opal_YUV420P_H261::~Opal_YUV420P_H261()
{
}


PINDEX Opal_YUV420P_H261::GetOptimalDataFrameSize(BOOL input) const
{
	return 0;
}


BOOL Opal_YUV420P_H261::ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst)
{
	return FALSE;
}
