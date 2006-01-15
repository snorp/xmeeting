/*
 * $Id: XMPacketReassemblers.cpp,v 1.3 2006/01/15 22:07:57 hfriederich Exp $
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

BOOL XMH261RTPPacketReassembler::CopyPacketsIntoFrameBuffer(XMRTPPacket *packetListHead, BYTE *frameBuffer, PINDEX *outFrameLength)
{
	XMRTPPacket *packet = packetListHead;
	PINDEX frameLength = 0;
	
	BYTE ebit;
	
	do {
		
		BYTE *dest = &(frameBuffer[frameLength]);
		BYTE *data = packet->GetPayloadPtr();
		PINDEX dataLength = packet->GetPayloadSize();
		ebit = (data[0] >> 2) & 0x07;
		
		// dropping the H.261 header
		data += 4;
		dataLength -= 4;
		
		memcpy(dest, data, dataLength);
		frameLength += dataLength;
		
		packet = packet->next;
		
		if(packet == NULL)
		{
			break;
		}
		
		if(ebit != 0)
		{
			frameLength -= 1;
		}
		
	} while(TRUE);
	
	// adding a PSC to the end of the stream so that the codec does render the frame
	frameBuffer[frameLength] = 0;
	frameBuffer[frameLength+1] = (1 << ebit);
	frameBuffer[frameLength+2] = 0;
	frameLength += 3;
	
	*outFrameLength = frameLength;
	
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

BOOL XMH263RTPPacketReassembler::CopyPacketsIntoFrameBuffer(XMRTPPacket *packetListHead, BYTE *frameBuffer, PINDEX *outFrameLength)
{
	XMRTPPacket *packet = packetListHead;
	PINDEX frameLength = 0;
	
	BYTE ebit;
	
	do {
		
		BYTE *dest = &(frameBuffer[frameLength]);
		BYTE *data = packet->GetPayloadPtr();
		PINDEX dataLength = packet->GetPayloadSize();
		
		BYTE f = (data[0] >> 7) & 0x01;
		BYTE p = (data[0] >> 6) & 0x01;
		ebit = data[0] & 0x07;
		
		if(f == 0)
		{
			// Mode A
			data += 4;
			dataLength -= 4;
		}
		else if(p == 0)
		{
			// Mode B
			data += 8;
			dataLength -= 8;
		}
		else
		{
			// Mode C
			data += 12;
			dataLength -= 12;
		}
		
		memcpy(dest, data, dataLength);
		
		frameLength += dataLength;
		
		packet = packet->next;
		
		if(packet == NULL)
		{
			break;
		}
		
		if(ebit != 0)
		{
			frameLength -= 1;
		}
		
	} while(TRUE);
	
	*outFrameLength = frameLength;
	
	return TRUE;
}

BOOL XMH263PlusRTPPacketReassembler::IsFirstPacketOfFrame(XMRTPPacket *packet)
{
	BYTE *data = packet->GetPayloadPtr();
	
	BYTE p = (data[0] >> 2) & 0x01;
	BYTE plen = (data[0] & 0x01) << 4;
	plen |= (data[1] >> 4) & 0x0f;
	
	if(p == 1 && (data[2] & 0xfc) == 0x80)
	{
		return TRUE;
	}

	return FALSE;
}

BOOL XMH263PlusRTPPacketReassembler::CopyPacketsIntoFrameBuffer(XMRTPPacket *packetListHead, BYTE *frameBuffer, PINDEX *outFrameLength)
{
	XMRTPPacket *packet = packetListHead;
	PINDEX frameLength = 0;
	
	do {
		
		BYTE *data = packet->GetPayloadPtr();
		WORD dataLength = packet->GetPayloadSize();
		
		// extracting the P, V and PLEN fields
		BYTE p = (data[0] >> 2) & 0x01;
		BYTE v = (data[0] >> 1) & 0x01;
		BYTE plen = (data[0] & 0x01) << 4;
		plen |= (data[1] >> 3) & 0x1f;
		//BYTE pebit = data[1] & 0x07;
		
		if(v == 1)
		{
			dataLength += 1;
		}
		if(p == 1)
		{
			// inserting the two zero bytes of the start code
			frameBuffer[frameLength] = 0;
			frameBuffer[frameLength+1] = 0;
			frameLength += 2;
		}
		
		BYTE *dest = &(frameBuffer[frameLength]);
		BYTE *src = &(data[2+v+plen]);
		dataLength -= (2 + v + plen);
		
		memcpy(dest, src, dataLength);
		frameLength += dataLength;
		
		packet = packet->next;
		
	} while(packet != NULL);
	
	*outFrameLength = frameLength;
	return TRUE;
}

BOOL XMH264RTPPacketReassembler::IsFirstPacketOfFrame(XMRTPPacket *packet)
{
	BYTE *data = packet->GetPayloadPtr();
	BYTE packetType = data[0] & 0x1f;
	
	if(packetType == 7 || packetType == 8)
	{
		return TRUE;
	}
	return FALSE;
}

BOOL XMH264RTPPacketReassembler::CopyPacketsIntoFrameBuffer(XMRTPPacket *packetListHead, BYTE *frameBuffer, PINDEX *outFrameLength)
{
	XMRTPPacket *packet = packetListHead;
	unsigned frameLength = 0;
	
	do {
		
		BYTE *data = packet->GetPayloadPtr();
		WORD dataLength = packet->GetPayloadSize();
		BYTE packetType = data[0] & 0x1f;
		
		// handling SPS Atoms
		if(packetType == 7)
		{
			_XMHandleH264SPSAtomData(data, dataLength);
		}
		// Handling PPS Atoms
		else if(packetType == 8)
		{
			_XMHandleH264PPSAtomData(data, dataLength);
		}
		// handling Single NAL Unit packets
		else if(packetType > 0 && packetType < 24)
		{
			// Adding two zero bytes to have 4 byte length fields
			frameBuffer[frameLength] = 0;
			frameBuffer[frameLength + 1] = 0;
			frameLength += 2;
			
			// Adding the length of this NAL unit
			PUInt16b *lengthField = (PUInt16b *)&frameBuffer[frameLength];
			lengthField[0] = dataLength;
			frameLength += 2;
			
			BYTE *dest = &(frameBuffer[frameLength]);
			
			memcpy(dest, data, dataLength);
			frameLength += dataLength;
		}
		// handling STAP-A packets
		else if(packetType == 24)
		{
			// The first byte is the STAP-A byte and is already read
			unsigned index = 1;
			
			do {
				
				PUInt16b *header = (PUInt16b *)&data[index];
				WORD unitLength = header[0];
				
				// Adding the length of the STAP-A NAL unit
				frameBuffer[frameLength] = 0;
				frameBuffer[frameLength+1] = 0;
				frameBuffer[frameLength+2] = data[index];
				frameBuffer[frameLength+3] = data[index+1];
				
				index += 2;
				frameLength += 4;
				
				BYTE *dest = &(frameBuffer[frameLength]);
				BYTE *src = &(data[index]);
				
				memcpy(dest, src, unitLength);
				
				frameLength += unitLength;
				index += unitLength;
				
			} while(index < dataLength);
		}
		// Handling FU-A packets
		else if(packetType == 28)
		{
			// reading the NRI field
			BYTE nri = data[0] & 0x60;
			BYTE s = (data[1] >> 7) & 0x01;
			BYTE e = (data[1] >> 6) & 0x01;
			BYTE type = data[1] & 0x1f;
			
			// the first two data bytes are not added to the final frame
			dataLength -= 2;
			
			// If the S bit is set, we scan past the packets ahead
			// to determine the length of the complete NAL Unit
			if(s == 1)
			{
				WORD totalNALLength = dataLength+1;
				XMRTPPacket *thePacket = packet;
				
				while(e == 0)
				{
					thePacket = thePacket->next;
					BYTE *thePacketData = thePacket->GetPayloadPtr();
					PINDEX thePacketDataLength = thePacket->GetPayloadSize() - 2;
					
					totalNALLength += thePacketDataLength;
					
					e = (thePacketData[1] >> 6) & 0x01;
				}
				
				// addint the NAL length information
				frameBuffer[frameLength] = 0;
				frameBuffer[frameLength+1] = 0;
				
				PUInt16b *header = (PUInt16b *)&frameBuffer[frameLength+2];
				header[0] = totalNALLength;
				
				// Adding the NAL header byte
				frameBuffer[frameLength+4] = 0;
				frameBuffer[frameLength+4] |= nri;
				frameBuffer[frameLength+4] |= type;
				
				frameLength += 5;
			}
			
			BYTE *dest = &(frameBuffer[frameLength]);
			BYTE *src = &(data[2]);
			memcpy(dest, src, dataLength);
			frameLength += dataLength;
		}
		else
		{
			cout << "UNKNOWN NAL TYPE" << endl;
		}
		
		packet = packet->next;
		
	} while(packet != NULL);
	
	*outFrameLength = frameLength;
	
	return TRUE;
}