/*
 * $Id: XMReceiverMediaPatch.cpp,v 1.37 2008/10/14 21:35:10 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#include "XMReceiverMediaPatch.h"

#include <opal/mediastrm.h>
#include <opal/mediacmd.h>
#include <opal/connection.h>
#include <opal/call.h>

#include "XMMediaFormats.h"
#include "XMMediaStream.h"
#include "XMCallbackBridge.h"

#include "XMAudioTester.h"

#define XM_PACKET_POOL_GRANULARITY 8
#define XM_FRAME_BUFFER_SIZE 352*288*4

#define XM_RTP_DATA_SIZE 2000

XMReceiverMediaPatch::XMReceiverMediaPatch(OpalMediaStream & src)
: OpalMediaPatch(src),
  packetReassembler(NULL)
{
}

XMReceiverMediaPatch::~XMReceiverMediaPatch()
{
}

void XMReceiverMediaPatch::Start()
{
  // quit any running audio test if needed
  XMAudioTester::Stop();
	
  OpalMediaPatch::Start();
}

void XMReceiverMediaPatch::SetCommandNotifier(const PNotifier & notifier, bool fromSink)
{
  commandNotifier = notifier;
  OpalMediaPatch::SetCommandNotifier(notifier, fromSink);
}

void XMReceiverMediaPatch::Main()
{
  ///////////////////////////////////////////////////////////////////////////////////////////////
  // The receiving algorithm tries to achieve best-possible data integrity and builds upon
  // the following assumptions:
  //
  // 1) The chance for packets actually being lost/dropped is very small
  // 2) The chance of packets being delayed across timestamp boundaries is much smaller than
  //    the chance of packets being reordered within the same timestamp (the same video frame)
  //
  // First, the frames will be read and put into a sorted linked list with ascending sequence
  // numbers. If a packet group is complete, the packet payloads are put together and the
  // resulting frame is sent to the XMMediaReceiver class for decompression and display.
  // A packet group is considered to be complete IF
  //
  // a) The first packet has the next ascending sequence number to the sequence number of the
  //    last packet of the previous packet group or the packet contains the beginning of a
  //    coded frame (picture start codes in H.261 / H.263) AND
  // b) The sequence numbers of the packets in the list are ascending with no sequence number
  //    missing AND
  // c) The last packet has the marker bit set
  //
  // This algorithm makes it possible to process packets of a packet group even if they arrive
  // after the last packet of the packet group with the marker bit set. This works well if
  // assumptions 1) and 2) are true.
  //
  // If a packet group is incomplete and the first packet of the next packet group arrives
  // (indicated by a different timestamp), the incomplete packet group is either dropped
  // or processed, depending on the codec being used. If the incomplete packet group is
  // processed, the processing happens delayed since the first packet of the next packet
  // group arrived, leading to inconstant display intervals. As long as assumption 1)
  // is met, this is not a big drawback.
  //
  // If either packets are missing or the decompression of the frame fails, an
  // fast update request is being sent to the remote party.
  ///////////////////////////////////////////////////////////////////////////////////////////////
	
  // Allocating a pool of XMRTPPacket instances to reduce
  // buffer allocation overhead.
  // The pool size increases in steps of 8 packets with an initial size of 8 packets.
  // These 8 packets are allocated initially.
  // The packets 9-xx are allocated on demand
  unsigned allocatedPackets = XM_PACKET_POOL_GRANULARITY;
  XMRTPPacket **packets =  (XMRTPPacket **)malloc(allocatedPackets * sizeof(XMRTPPacket *));
  unsigned packetIndex = 0;
  for (unsigned i = 0; i < allocatedPackets; i++) {
    packets[i] = new XMRTPPacket(XM_RTP_DATA_SIZE);
  }
	
  // make sure the RTP session does NOT ignore out of order packets
  OpalRTPMediaStream & rtpStream = (OpalRTPMediaStream &)source;
  rtpStream.GetRtpSession().SetIgnoreOutOfOrderPackets(false);
	
  BYTE *frameBuffer = (BYTE *)malloc(sizeof(BYTE) * XM_FRAME_BUFFER_SIZE);
	
  // Read the first packet
  bool firstReadSuccesful = source.ReadPacket(*(packets[0]));
    
  // Access the media format
  const OpalMediaFormat & mediaFormat = source.GetMediaFormat();
	
  if (firstReadSuccesful == true) {
		// Tell the media receiver to prepare processing packets
    XMCodecIdentifier codecIdentifier = _XMGetMediaFormatCodec(mediaFormat);
    unsigned sessionID = 2;
        
    RTP_DataFrame::PayloadTypes payloadType = packets[0]->GetPayloadType();
		
    // initialize the packet processing variables
    DWORD currentTimestamp = packets[0]->GetTimestamp();
    WORD firstSeqNrOfPacketGroup = 0;
    XMRTPPacket *firstPacketOfPacketGroup = NULL;
    XMRTPPacket *lastPacketOfPacketGroup = NULL;
		
		switch (codecIdentifier) {
      case XMCodecIdentifier_H261:
        packetReassembler = new XMH261RTPPacketReassembler();
        break;
      case XMCodecIdentifier_H263:
        if (_XMGetIsRFC2429(mediaFormat) || mediaFormat == XM_MEDIA_FORMAT_H263PLUS) {
          cout << "Receiving RFC2429" << endl;
          packetReassembler = new XMH263PlusRTPPacketReassembler();
        } else {
          int result = _XMDetermineH263PacketizationScheme(packets[0]->GetPayloadPtr(), packets[0]->GetPayloadSize());
					
          if (result == 0) {
            // cannot determine. Last hope is to look at the payload code
            if (payloadType == RTP_DataFrame::H263) {
              cout << "Receiving RFC2190" << endl;
              packetReassembler = new XMH263RTPPacketReassembler();
            } else {
              cout << "Receiving RFC2429" << endl;
              packetReassembler = new XMH263PlusRTPPacketReassembler();
            }
          } else if (result == 1) {
            cout << "Receiving RFC2190" << endl;
            packetReassembler = new XMH263RTPPacketReassembler();
          } else {
            cout << "Receiving RFC2429" << endl;
            packetReassembler = new XMH263PlusRTPPacketReassembler();
          }
        }
        break;
      case XMCodecIdentifier_H264:
        packetReassembler = new XMH264RTPPacketReassembler();
        break;
      default:
        break;
    }
		
    _XMStartMediaReceiving(sessionID, codecIdentifier);
    
    unsigned decodingFailures = 0; // tracks the # of successive failed frames
		
		// loop to receive packets and process them
		do {
      inUse.StartRead();
			
      bool completePacketGroup = true;
      bool decodingSuccessful = true;
      unsigned numberOfPacketsToRelease = 0;
			
      XMRTPPacket *packet = packets[packetIndex];
			
      packet->next = NULL;
      packet->prev = NULL;
			
      // processing the packet
      DWORD timestamp = packet->GetTimestamp();
      WORD sequenceNumber = packet->GetSequenceNumber();
			
      // take into account that the timestamp might wrap around
      if (timestamp < currentTimestamp && (currentTimestamp - timestamp) > (0x01 << 31)) {
        // This packet group is already processed
        // By changing the sequenceNumber parameter,
        // the expected beginning of the current packet group
        // can be adjusted
        if (firstSeqNrOfPacketGroup <= sequenceNumber) {
          firstSeqNrOfPacketGroup = sequenceNumber + 1;
        }
      } else {
        // also take into account that the timestamp might wrap around
        if (timestamp > currentTimestamp || (timestamp < currentTimestamp && (currentTimestamp - timestamp) > (0x01 << 31))) {
          if (firstPacketOfPacketGroup != NULL) {
            // Try to process the old packet although not complete
            bool result = true;
            PINDEX frameBufferSize = 0;
						
            result = packetReassembler->CopyIncompletePacketsIntoFrameBuffer(firstPacketOfPacketGroup, frameBuffer, &frameBufferSize);
						
            if (result == true) {
              _XMProcessFrame(GetSource().GetConnection().GetCall().GetToken(), sessionID, frameBuffer, frameBufferSize);
            }
						
            firstSeqNrOfPacketGroup = lastPacketOfPacketGroup->GetSequenceNumber() + 1;
            firstPacketOfPacketGroup = NULL;
            lastPacketOfPacketGroup = NULL;
            completePacketGroup = false;
            PTRACE(1, "XMeetingReceiverMediaPatch\tIncomplete old packet group");
						
            // There are (packetIndex + 1) packets in the buffer, but only the last one
            // ist still needed
            numberOfPacketsToRelease = packetIndex;
          }
					
          currentTimestamp = timestamp;
        }
				
        if (lastPacketOfPacketGroup != NULL) {
          XMRTPPacket *previousPacket = lastPacketOfPacketGroup;
					
          do {
            WORD previousSequenceNumber = previousPacket->GetSequenceNumber();
						
            // take into account that the sequence number might wrap around
            if (sequenceNumber > previousSequenceNumber || 
                (sequenceNumber < previousSequenceNumber && (previousSequenceNumber - sequenceNumber) > (0x01 << 15))) {
              // ordering is correct, insert at this point
              packet->next = previousPacket->next;
              previousPacket->next = packet;
              packet->prev = previousPacket;
							
              if (previousPacket == lastPacketOfPacketGroup) {
                lastPacketOfPacketGroup = packet;
              }
							
              break;
            } else if (sequenceNumber == previousSequenceNumber) {
              break;
            }
						
            if (previousPacket == firstPacketOfPacketGroup) {
              // inserting this packet at the beginning of
              // the packet group
              packet->next = previousPacket;
              previousPacket->prev = packet;
              firstPacketOfPacketGroup = packet;
              break;
            }
						
            previousPacket = previousPacket->prev;
						
          } while (true);
        } else {
          firstPacketOfPacketGroup = packet;
          lastPacketOfPacketGroup = packet;
        }
      }
			
      /////////////////////////////////////////////////////////
      // checking whether the packet group is complete or not
      /////////////////////////////////////////////////////////
      bool packetGroupIsComplete = false;
			
      WORD expectedSequenceNumber = firstSeqNrOfPacketGroup;
      XMRTPPacket *thePacket = firstPacketOfPacketGroup;
			
      bool isFirstPacket = false;
			
      if (expectedSequenceNumber == thePacket->GetSequenceNumber()) {
        isFirstPacket = true;
      } else {
        // the sequence number is not the expected one. Try to analyze
        // the bitstream to determine whether this is the first packet
        // of a packet group or not
        isFirstPacket = packetReassembler->IsFirstPacketOfFrame(thePacket);
      }
      if (isFirstPacket == true) {
        expectedSequenceNumber = thePacket->GetSequenceNumber();
				
        do {
          if (expectedSequenceNumber != thePacket->GetSequenceNumber()) {
            break;
          }
					
          expectedSequenceNumber++;
					
          if (thePacket->next == NULL) {
            // no more packets in the packet group.
            // If the marker bit is set, the group is complete
            if (thePacket->GetMarker() == true) {
              packetGroupIsComplete = true;
            }
            break;
          }
					
          thePacket = thePacket->next;
					
        } while (true);
      }
			
      /////////////////////////////////////////////////////
      // If the packet group is complete, copy the packets
      // into a frame and send it to the XMMediaReceiver
      // system.
      /////////////////////////////////////////////////////
			
      if (packetGroupIsComplete == true) {
        bool result = true;
        PINDEX frameBufferSize = 0;
				
        result = packetReassembler->CopyPacketsIntoFrameBuffer(firstPacketOfPacketGroup, frameBuffer, &frameBufferSize);
				
        if (result == true) {
          result = _XMProcessFrame(GetSource().GetConnection().GetCall().GetToken(), sessionID, frameBuffer, frameBufferSize);
          if (result == false) {
            PTRACE(1, "XMeetingReceiverMediaPatch\tDecompression of the frame failed");
            decodingSuccessful = false;
            decodingFailures++;
          } else {
            decodingFailures = 0;
          }
        } else {
          PTRACE(1, "XMeetingReceiverMediaPatch\tCould not copy packets into frame buffer");
          decodingSuccessful = false;
        }
        firstSeqNrOfPacketGroup = lastPacketOfPacketGroup->GetSequenceNumber() + 1;
        firstPacketOfPacketGroup = NULL;
        lastPacketOfPacketGroup = NULL;
				
        // Release all packets in the pool
        numberOfPacketsToRelease = packetIndex + 1;
      }

      if (completePacketGroup == false) {
        IssueVideoUpdatePictureCommand();
      } else if (decodingSuccessful == false) {
        // avoid flooding the remote party with update commands
        if (decodingFailures < 3 || (decodingFailures % 30) == 0) {
          IssueVideoUpdatePictureCommand();
        }
      }
			
      // If not all packets can be released, the remaining packets are
      // put at the beginning of the packet pool.
      if (numberOfPacketsToRelease != 0) {
        for (unsigned i = 0; i < (packetIndex + 1 - numberOfPacketsToRelease); i++) {
          // swapping the remaining frames
          XMRTPPacket *packet = packets[i];
          packets[i] = packets[i + numberOfPacketsToRelease];
          packets[i + numberOfPacketsToRelease] = packet;
        }
        packetIndex = packetIndex + 1 - numberOfPacketsToRelease;
      } else {
        // increment the packetIndex, allocate a new XMRTPPacket if needed.
        // Also increase the size of the packet pool if required
        packetIndex++;
        if (packetIndex == allocatedPackets) {
          if (allocatedPackets % XM_PACKET_POOL_GRANULARITY == 0) {
            packets = (XMRTPPacket **)realloc(packets, (allocatedPackets + XM_PACKET_POOL_GRANULARITY) * sizeof(XMRTPPacket *));
          }
					
          packets[packetIndex] = new XMRTPPacket(XM_RTP_DATA_SIZE);
          allocatedPackets++;
        }
      }
			
      // check for loop termination conditions
			PINDEX len = sinks.GetSize();
			
      inUse.EndRead();
			
      if (len == 0) {
        break;
      }
			
    } while (source.ReadPacket(*(packets[packetIndex])) == true);
    
		
		// End the media processing
		_XMStopMediaReceiving(sessionID);
	}
	
  // release the used RTP_DataFrames
  for (unsigned i = 0; i < allocatedPackets; i++) {
    XMRTPPacket *dataFrame = packets[i];
    delete dataFrame;
  }
  free(packets);
  free(frameBuffer);
  if (packetReassembler != NULL) {
    free(packetReassembler);
  }
}

void XMReceiverMediaPatch::IssueVideoUpdatePictureCommand()
{
  OpalVideoUpdatePicture command = OpalVideoUpdatePicture(-1, -1, -1);
    
  if (!commandNotifier.IsNULL()) {
    commandNotifier(command, 0);
  }
}
