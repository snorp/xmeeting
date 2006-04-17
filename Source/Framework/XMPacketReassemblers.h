/*
 * $Id: XMPacketReassemblers.h,v 1.3 2006/04/17 17:51:22 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_PACKET_REASSEMBLERS_H__
#define __XM_PACKET_REASSEMBLERS_H__

#include <ptlib.h>

#include "XMRTPPacket.h"

/**
 * Abstract base class
 **/
class XMRTPPacketReassembler : public PObject
{
	PCLASSINFO(XMRTPPacketReassembler, PObject);
	
	virtual BOOL IsFirstPacketOfFrame(XMRTPPacket *packet) = 0;
	virtual BOOL CopyPacketsIntoFrameBuffer(XMRTPPacket *packetListHead, BYTE *frameBuffer, PINDEX *frameLength) = 0;
};

/**
 * Implementation of RFC 2032 for H.261 streams
 **/
class XMH261RTPPacketReassembler : public XMRTPPacketReassembler
{
	PCLASSINFO(XMH261RTPPacketReassembler, XMRTPPacketReassembler);
	
	virtual BOOL IsFirstPacketOfFrame(XMRTPPacket *packet);
	virtual BOOL CopyPacketsIntoFrameBuffer(XMRTPPacket *packetListHead, BYTE *frameBuffer, PINDEX *frameLength);
};

/**
 * Implementation of RFC 2190 for H.263 streams
 **/
class XMH263RTPPacketReassembler : public XMRTPPacketReassembler
{
	PCLASSINFO(XMH263RTPPacketReassembler, XMRTPPacketReassembler);
	
	virtual BOOL IsFirstPacketOfFrame(XMRTPPacket *packet);
	virtual BOOL CopyPacketsIntoFrameBuffer(XMRTPPacket *packetListHead, BYTE *frameBuffer, PINDEX *frameLength);
};

/**
 * Implementation of RFC 2429 for H.263 streams
 **/
class XMH263PlusRTPPacketReassembler : public XMRTPPacketReassembler
{
	PCLASSINFO(XMH263PlusRTPPacketReassembler, XMRTPPacketReassembler);
	
	virtual BOOL IsFirstPacketOfFrame(XMRTPPacket *packet);
	virtual BOOL CopyPacketsIntoFrameBuffer(XMRTPPacket *packetListHead, BYTE *frameBuffer, PINDEX *frameLength);
};

/**
 * Implementation of RFC 3984 for H.264 streams
 **/
class XMH264RTPPacketReassembler : public XMRTPPacketReassembler
{
	PCLASSINFO(XMH264RTPPacketReassembler, XMRTPPacketReassembler);
	
	virtual BOOL IsFirstPacketOfFrame(XMRTPPacket *packet);
	virtual BOOL CopyPacketsIntoFrameBuffer(XMRTPPacket *packetListHead, BYTE *frameBuffer, PINDEX *frameLength);
};

// 0: cannot determine
// 1: RFC2190
// 2: RFC2429
int _XMDetermineH263PacketizationScheme(const BYTE *data, PINDEX length);

#endif // __XM_PACKET_REASSEMBLERS_H__

