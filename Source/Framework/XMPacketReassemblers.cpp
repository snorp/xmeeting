/*
 * $Id: XMPacketReassemblers.cpp,v 1.1 2006/01/10 15:13:21 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#include "XMPacketReassemblers.h"
#include "XMCallbackBridge.h"

BOOL XMH261RTPPacketReassembler::IsFirstPacketOfFrame(XMRTPPacket *packet)
{
	BYTE *data = packet->GetPayloadPtr();
	
	// The first packet of a frame has GOBN 0 and MBAP 0
	BYTE gobn = (data[1] >> 4) & 0x0f;
	BYTE mbap = (data[1] & 0x0f) << 1;
	mbap |= (data[2] >> 7) & 0x01;
	
	if(gobn == 0 && mbap == 0)
	{
		return TRUE;
	}
	
	return FALSE;
}

BOOL XMH261RTPPacketReassembler::CopyPacketsIntoFrameBuffer(XMRTPPacket *packetListHead, BYTE *frameBuffer, PINDEX *frameBufferSize)
{
	XMRTPPacket *packet = packetListHead;
	unsigned bufferSize = 0;
	
	unsigned ebit;
	
	do {
		
		BYTE *dest = &(frameBuffer[bufferSize]);
		BYTE *payload = packet->GetPayloadPtr();
		PINDEX size = packet->GetPayloadSize();
		ebit = (payload[0] >> 2) & 0x07;
		
		// dropping the H.261 header
		payload += 4;
		size -= 4;
		
		memcpy(dest, payload, size);
		
		bufferSize += size;
		
		packet = packet->next;
		
		if(packet == NULL)
		{
			break;
		}
		
		if(ebit != 0)
		{
			bufferSize -= 1;
		}
		
	} while(TRUE);
	
	// adding a PSC to the end of the stream so that the codec does render the frame
	frameBuffer[bufferSize] = 0;
	frameBuffer[bufferSize+1] = (1 << ebit);
	frameBuffer[bufferSize+2] = 0;
	
	bufferSize += 3;
	
	*frameBufferSize = bufferSize;
	
	return TRUE;
}

BOOL XMH263RTPPacketReassembler::IsFirstPacketOfFrame(XMRTPPacket *packet)
{
	// The first packet is always Mode A and starts with a picture start code
	BYTE *data = packet->GetPayloadPtr();
	
	BYTE f = data[0] & 0x80;
	if(f == 0)
	{
		// The picture start code is byte aligned
		if(data[4] == 0 && data[5] == 0 && (data[6] & 0xfc) == 0x80)
		{
			return TRUE;
		}
	}
	return FALSE;
}

BOOL XMH263RTPPacketReassembler::CopyPacketsIntoFrameBuffer(XMRTPPacket *packetListHead, BYTE *frameBuffer, PINDEX *frameBufferSize)
{
	XMRTPPacket *packet = packetListHead;
	unsigned bufferSize = 0;
	
	BYTE ebit;
	
	do {
		BYTE *dest = &(frameBuffer[bufferSize]);
		BYTE *payload = packet->GetPayloadPtr();
		PINDEX size = packet->GetPayloadSize();
		
		BYTE f = (payload[0] >> 7) & 0x01;
		BYTE p = (payload[0] >> 6) & 0x01;
		ebit = payload[0] & 0x07;
		
		if(f == 0)
		{
			// Mode A
			payload += 4;
			size -= 4;
		}
		else if(p == 0)
		{
			// Mode B
			payload += 8;
			size -= 8;
		}
		else
		{
			// Mode C
			payload += 12;
			size -= 12;
		}
		
		memcpy(dest, payload, size);
		
		bufferSize += size;
		
		packet = packet->next;
		
		if(packet == NULL)
		{
			break;
		}
		
		if(ebit != 0)
		{
			bufferSize -= 1;
		}
		
	} while(TRUE);
	
	*frameBufferSize = bufferSize;
	
	return TRUE;
}

BOOL XMH263PlusRTPPacketReassembler::IsFirstPacketOfFrame(XMRTPPacket *packet)
{
	return FALSE;
}

BOOL XMH263PlusRTPPacketReassembler::CopyPacketsIntoFrameBuffer(XMRTPPacket *packetListHead, BYTE *frameBuffer, PINDEX *frameBufferSize)
{
	return FALSE;
}

BOOL XMH264RTPPacketReassembler::IsFirstPacketOfFrame(XMRTPPacket *packet)
{
	return FALSE;
}

BOOL XMH264RTPPacketReassembler::CopyPacketsIntoFrameBuffer(XMRTPPacket *packetListHead, BYTE *frameBuffer, PINDEX *frameBufferSize)
{
	XMRTPPacket *packet = packetListHead;
	unsigned bufferSize = 0;
	
	do {
		
		BYTE *data = packet->GetPayloadPtr();
		WORD payloadSize = packet->GetPayloadSize();
		BYTE packetType = data[0] & 0x1f;
		
		if(packetType == 7)
		{
			_XMHandleH264SPSAtomData(data, payloadSize);
		}
		else if(packetType == 8)
		{
			_XMHandleH264PPSAtomData(data, payloadSize);
		}
		else if(packetType > 0 && packetType < 24)
		{
			// Adding two zero bytes to have 4 byte length fields
			frameBuffer[bufferSize] = 0;
			frameBuffer[bufferSize + 1] = 0;
			bufferSize += 2;
			
			// Adding the length of this NAL unit
			WORD *lengthField = (WORD *)&(frameBuffer[bufferSize]);
			lengthField[0] = payloadSize;
			bufferSize += 2;
			
			BYTE *dest = &(frameBuffer[bufferSize]);
			
			memcpy(dest, data, payloadSize);
			bufferSize += payloadSize;
		}
		else if(packetType == 24)
		{
			cout << "STAP A" << endl;
		}
		else if(packetType == 28)
		{
			cout << "FU A" << endl;
		}
		else
		{
			cout << "UNKNOWN" << endl;
		}
		
		packet = packet->next;
		
	} while(packet != NULL);
	
	*frameBufferSize = bufferSize;
	
	return TRUE;
}