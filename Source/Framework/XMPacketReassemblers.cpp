/*
 * $Id: XMPacketReassemblers.cpp,v 1.12 2008/10/07 23:19:17 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#include "XMPacketReassemblers.h"
#include "XMCallbackBridge.h"

bool XMH261RTPPacketReassembler::IsFirstPacketOfFrame(XMRTPPacket *packet)
{
  BYTE *data = packet->GetPayloadPtr();
	
  // The first packet of a frame has GOBN 0 and MBAP 0
  BYTE gobn = (data[1] >> 4) & 0x0f;
  BYTE mbap = (data[1] & 0x0f) << 1;
  mbap |= (data[2] >> 7) & 0x01;
	
  if (gobn == 0 && mbap == 0) {
    return true;
  }
	
  return false;
}

bool XMH261RTPPacketReassembler::CopyPacketsIntoFrameBuffer(XMRTPPacket *packetListHead, BYTE *frameBuffer, PINDEX *outFrameLength)
{
  XMRTPPacket *packet = packetListHead;
  PINDEX frameLength = 0;
	
  BYTE ebit = 0;
	
  do {
		
    if (ebit != 0) {
      frameLength -= 1;
    }
		
    BYTE *data = packet->GetPayloadPtr();
    PINDEX dataIndex = 0;
    PINDEX dataLength = packet->GetPayloadSize();
		
    if (dataLength <= 4) {
      // prevent crashes if packet size too small.
      // 4 bytes is the length of the H.261 payload header
      return false;
    }
    BYTE sbit = (data[0] >> 5) & 0x07;
    ebit = (data[0] >> 2) & 0x07;
		
    // scanning past the H.261 header
    dataIndex += 4;
    dataLength -= 4;
		
    if (sbit != 0) {
      BYTE mask = (0xff >> sbit);
      frameBuffer[frameLength] |= (data[dataIndex] & mask);
      frameLength += 1;
      dataIndex += 1;
      dataLength -= 1;
    }
		
    BYTE *dest = &frameBuffer[frameLength];
    BYTE *src = &data[dataIndex];
    dataLength -= 1;
		
    memcpy(dest, src, dataLength);
    frameLength += dataLength;
		
    BYTE mask = (0xff << ebit);
    frameBuffer[frameLength] = (src[dataLength] & mask);
    frameLength += 1;
		
    packet = packet->next;
		
  } while (packet != NULL);
	
  // adding a PSC to the end of the stream so that the codec does render the frame
  frameBuffer[frameLength] = 0;
  frameBuffer[frameLength+1] = (1 << ebit);
  frameBuffer[frameLength+2] = 0;
  frameLength += 3;
	
  *outFrameLength = frameLength;
	
  return true;
}

bool XMH261RTPPacketReassembler::CopyIncompletePacketsIntoFrameBuffer(XMRTPPacket *packetListHead, BYTE *frameBuffer, PINDEX *frameLength)
{
  return false;
}

bool XMH263RTPPacketReassembler::IsFirstPacketOfFrame(XMRTPPacket *packet)
{
  // The first packet is always Mode A and starts with a picture start code
  BYTE *data = packet->GetPayloadPtr();
	
  BYTE f = data[0] & 0x80;
  if (f == 0) {
    // The picture start code is byte aligned
    if (data[4] == 0 && data[5] == 0 && (data[6] & 0xfc) == 0x80) {
      return true;
    }
  }
  return false;
}

bool XMH263RTPPacketReassembler::CopyPacketsIntoFrameBuffer(XMRTPPacket *packetListHead, BYTE *frameBuffer, PINDEX *outFrameLength)
{
  XMRTPPacket *packet = packetListHead;
  PINDEX frameLength = 0;
	
  BYTE ebit;
	
  do {
		
    BYTE *dest = &(frameBuffer[frameLength]);
    BYTE *data = packet->GetPayloadPtr();
    PINDEX dataLength = packet->GetPayloadSize();
		
    if (dataLength <= 4) {
      return false;
    }
		
    BYTE f = (data[0] >> 7) & 0x01;
    BYTE p = (data[0] >> 6) & 0x01;
    ebit = data[0] & 0x07;
		
    if (f == 0) {
      // Mode A
      data += 4;
      dataLength -= 4;
    } else if (p == 0) {
      if (dataLength <= 8) {
        return false;
      }
      // Mode B
      data += 8;
      dataLength -= 8;
    } else {
      if (dataLength <= 12) {
        return false;
      }
      // Mode C
      data += 12;
      dataLength -= 12;
    }
		
    memcpy(dest, data, dataLength);
		
    frameLength += dataLength;
		
    packet = packet->next;
		
    if (packet == NULL) {
      break;
    }
		
    if (ebit != 0) {
      frameLength -= 1;
    }
		
  } while (true);
	
  *outFrameLength = frameLength;
	
  return true;
}

bool XMH263RTPPacketReassembler::CopyIncompletePacketsIntoFrameBuffer(XMRTPPacket *packetListHead, BYTE *frameBuffer, PINDEX *frameLength)
{
  return false;
}

bool XMH263PlusRTPPacketReassembler::IsFirstPacketOfFrame(XMRTPPacket *packet)
{
  BYTE *data = packet->GetPayloadPtr();
	
  BYTE p = (data[0] >> 2) & 0x01;
  BYTE v = (data[0] >> 1) & 0x01;
  BYTE plen = (data[0] & 0x01) << 4;
  plen |= (data[1] >> 3) & 0x0f;
	
  // The first packet has p set to one and begins with
  // a picture start code
  if (p == 1 && (data[2+v+plen] & 0xfc) == 0x80) {
    return true;
  }

  return false;
}

bool XMH263PlusRTPPacketReassembler::CopyPacketsIntoFrameBuffer(XMRTPPacket *packetListHead, BYTE *frameBuffer, PINDEX *outFrameLength)
{
  XMRTPPacket *packet = packetListHead;
  PINDEX frameLength = 0;

  do {
		
    BYTE *data = packet->GetPayloadPtr();
    WORD dataLength = packet->GetPayloadSize();
		
    if (dataLength <= 2) {
      return false;
    }
		
    // extracting the P, V and PLEN fields
    BYTE p = (data[0] >> 2) & 0x01;
    BYTE v = (data[0] >> 1) & 0x01;
    BYTE plen = (data[0] & 0x01) << 5;
    plen |= (data[1] >> 3) & 0x1f;
		
    if (dataLength <= (2+v+plen)) {
      return false;
    }
    if (p == 1) {
      // inserting the two zero bytes of the start code
      frameBuffer[frameLength] = 0;
      frameBuffer[frameLength+1] = 0;
      frameLength += 2;
    }
		
    PINDEX offset = 2+v+plen;
		
    // If this is the first packet, we examine the H.323 picture header
    if (packet == packetListHead) {
      PINDEX sourceFormatOffset = 2;
      if (p == 0) {
        sourceFormatOffset = 4;
      }
			
      BYTE *src = &data[sourceFormatOffset];
      BYTE sourceFormat = (src[2] >> 2) & 0x07;
			
      // QuickTime H.263 cannot understand the extended PTYPE header
      // (PLUSPTYPE). With the very basic capability set declared so far,
      // it should be possible to transform the PLUSPTYPE header into a
      // normal PTYPE header. Fortunately, QuickTime fully understands 
      // bitstreams where PSC isn't byte-aligned.
			
      if (sourceFormat == 7) {
        BYTE tr = (src[0] & 0x03) << 6;
        tr |= (src[1] >> 2) & 0x3f;
			
        BYTE ufep = (src[2] & 0x03) << 1;
        ufep |= (src[3] >> 7) & 0x01;
				
        if (ufep == 0) {
          return false;
        }
				
        sourceFormat = (src[3] >> 4) & 0x07;
				
        if (((src[3] & 0x0f) != 0) ||
            (src[4] != 1) ||
            ((src[5] & 0xe3) != 0) ||
            ((src[6] & 0x70) != 0x10)) {
          return false;
        }
				
        BYTE pictureTypeCode = (src[5] >> 2) & 0x07;
        if (pictureTypeCode > 1) {
          return false;
        }
				
        BYTE cpm = (src[6] >> 3) & 0x01;
        if (cpm == 1) {
          //cout << "cannot transform frame since CPM is one" << endl;
          return false;
        }
				
        BYTE pquant = (src[6] & 0x07) << 2;
        pquant |= (src[7] >> 6) & 0x03;
			
        src[0] = 0;
        src[1] = 0;
        src[2] = 0;
        src[3] = 0x40;
        src[4] = (tr << 1);
        src[4] |= 0x01;
        src[5] = 0;
        src[5] |= (sourceFormat << 1);
        src[5] |= (pictureTypeCode & 0x01);
        src[6] = 0;
        src[6] |= (pquant >> 1);
        src[7] &= 0x3f;
        src[7] |= (pquant & 0x01) << 7;
				
        offset += 3;
      }
    }
		
    BYTE *dest = &(frameBuffer[frameLength]);
    BYTE *src = &(data[offset]);
    dataLength -= offset;
		
    memcpy(dest, src, dataLength);
    frameLength += dataLength;
		
    packet = packet->next;
		
  } while (packet != NULL);
	
  *outFrameLength = frameLength;
  return true;
}

bool XMH263PlusRTPPacketReassembler::CopyIncompletePacketsIntoFrameBuffer(XMRTPPacket *packetListHead, BYTE *frameBuffer, PINDEX *frameLength)
{
  return false;
}

bool XMH264RTPPacketReassembler::IsFirstPacketOfFrame(XMRTPPacket *packet)
{
  // We only know for sure if this is the first packet of a packet group
  // if the packet type yields and SPS packet.
  BYTE *data = packet->GetPayloadPtr();
  BYTE packetType = data[0] & 0x1f;
	
  if (packetType == 7) {
    return true;
  }
  return false;
}

bool XMH264RTPPacketReassembler::CopyPacketsIntoFrameBuffer(XMRTPPacket *packetListHead, BYTE *frameBuffer, PINDEX *outFrameLength)
{
  XMRTPPacket *packet = packetListHead;
  unsigned frameLength = 0;
	
  do {
		
    BYTE *data = packet->GetPayloadPtr();
    WORD dataLength = packet->GetPayloadSize();
    if (dataLength <= 1) {
      return false;
    }
    BYTE packetType = data[0] & 0x1f;
		
    if (packetType == 7) { // handling SPS Atoms
      _XMHandleH264SPSAtomData(data, dataLength);
    } else if (packetType == 8) { // handling PPS Atoms
      _XMHandleH264PPSAtomData(data, dataLength);
    } else if (packetType > 0 && packetType < 24) { // handling Single NAL Unit packets
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
    } else if (packetType == 24) { // handling STAP-A packets
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
				
      } while (index < dataLength);
    } else if (packetType == 28) { // handling FU-A packets
      if (dataLength <= 2) {
        return false;
      }
			
      // reading the NRI field
      BYTE nri = data[0] & 0x60;
      BYTE s = (data[1] >> 7) & 0x01;
      BYTE e = (data[1] >> 6) & 0x01;
      BYTE type = data[1] & 0x1f;
			
      // the first two data bytes are not added to the final frame
      dataLength -= 2;
			
      // If the S bit is set, we scan past the packets ahead
      // to determine the length of the complete NAL Unit
      if (s == 1) {
        WORD totalNALLength = dataLength+1;
        XMRTPPacket *thePacket = packet;
				
        while (e == 0) {
          thePacket = thePacket->next;
          BYTE *thePacketData = thePacket->GetPayloadPtr();
          PINDEX thePacketDataLength = thePacket->GetPayloadSize() - 2;
					
          totalNALLength += thePacketDataLength;
					
          e = (thePacketData[1] >> 6) & 0x01;
        }
				
        // adding the NAL length information
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
    } else {
      //cout << "UNKNOWN NAL TYPE" << endl;
    }
		
    packet = packet->next;
		
  } while (packet != NULL);
	
  *outFrameLength = frameLength;
	
  return true;
}

bool XMH264RTPPacketReassembler::CopyIncompletePacketsIntoFrameBuffer(XMRTPPacket *packetListHead, BYTE *frameBuffer, PINDEX *frameLength)
{
  return false;
}

int _XMDetermineH263PacketizationScheme(const BYTE *data, PINDEX length)
{
  if (length <= 10) {
    // won't determine short frames
    return 0;
  }
	
  if ((data[0] & 0xf8) != 0) {
    // RFC2429 has these bits reserved, set to zero
    // RFC2190 has these bits set to zero if it is the first frame of a packet group.
    // Thus, if this part isn't zero, it is RFC2190 but not a packet group start
    return 1;
  }
	
  // if the first two bits are zero AND bytes 5 and 6 are zero, we have RFC2190
  if ((data[0] & 0xc0) == 0 && data[4] == 0 && data[5] == 0) {
    return 1;
  }
	
  return 2;
}