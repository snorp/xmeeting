/*
 * $Id: XMReceiverMediaPatch.cpp,v 1.7 2005/11/24 21:13:02 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#include "XMReceiverMediaPatch.h"

#include <opal/mediastrm.h>
#include <opal/mediacmd.h>

#include "XMMediaFormats.h"
#include "XMMediaStream.h"
#include "XMCallbackBridge.h"

#define XM_FRAME_POOL_GRANULARITY 8

XMReceiverMediaPatch::XMReceiverMediaPatch(OpalMediaStream & src)
: OpalMediaPatch(src)
{
	notifierSet = FALSE;
}

XMReceiverMediaPatch::~XMReceiverMediaPatch()
{
}

void XMReceiverMediaPatch::Main()
{
	// Currently, audio is processed using the default OPAL facilities.
	// Only video is processed using QuickTime
	const OpalMediaFormat & mediaFormat = source.GetMediaFormat();
	if(_XMIsVideoMediaFormat(mediaFormat) == FALSE)
	{
		OpalMediaPatch::Main();
		return;
	}
	
	// Allocating a pool of RTP_DataFrame instances to reduce
	// copy overhead
	// sizeof(RTP_DataFrame *) = 4
	// malloc has 16 byte granularity. Approximately 7-12 frames are used
	// for H.261 CIF. Therefore, the pointer array size is incremented by 8
	unsigned allocatedFrames = XM_FRAME_POOL_GRANULARITY;
	RTP_DataFrame **dataFrames =  (RTP_DataFrame **)malloc(100 * sizeof(RTP_DataFrame *));
	unsigned frameIndex = 0;
	for(unsigned i = 0; i < XM_FRAME_POOL_GRANULARITY; i++)
	{
		dataFrames[i] = new RTP_DataFrame(source.GetDataSize());
	}
	
	// Read the first packet
	BOOL firstRead = source.ReadPacket(*(dataFrames[frameIndex]));

	if(firstRead == TRUE)
	{
		// Tell the media receiver to start processing packets
		XMCodecIdentifier codecIdentifier;
		XMVideoSize mediaSize;
		unsigned sessionID = source.GetSessionID();
		RTP_DataFrame::PayloadTypes payloadType = dataFrames[frameIndex]->GetPayloadType();
		
		if(mediaFormat == XM_MEDIA_FORMAT_H261_QCIF)
		{
			codecIdentifier = XMCodecIdentifier_H261;
			mediaSize = XMVideoSize_QCIF;
		}
		else if(mediaFormat == XM_MEDIA_FORMAT_H261_CIF)
		{
			codecIdentifier = XMCodecIdentifier_H261;
			mediaSize = XMVideoSize_CIF;
		}

		_XMStartMediaReceiving(codecIdentifier, (unsigned)payloadType, mediaSize, sessionID);
		
		//looping & processing the packets
		WORD lastSequenceNumber = 0;
		DWORD lastTimestamp = 0;
		BOOL needsPictureUpdate = FALSE;
		
		do {
	
			inUse.Wait();
		
			RTP_DataFrame *sourceFrame = dataFrames[frameIndex];
		
			FilterFrame(*sourceFrame, source.GetMediaFormat());
		
			WORD sequenceNumber = sourceFrame->GetSequenceNumber();
			DWORD timestamp = sourceFrame->GetTimestamp();
				
			if(sequenceNumber != (lastSequenceNumber + 1) && (timestamp != 0))
			{
				// do not issue when being the first packet
				needsPictureUpdate = TRUE;
			}
			
			// processing the packet
			BYTE *dataPtr = sourceFrame->GetPayloadPtr();
			PINDEX length = sourceFrame->GetPayloadSize();
			PINDEX headerSize = sourceFrame->GetHeaderSize();
			dataPtr -= headerSize;
			length += headerSize;
				
			unsigned canReleasePackets = 0;
			BOOL succ = _XMProcessPacket((void *)dataPtr, (unsigned)length, sessionID, &canReleasePackets);
			
			if(succ == FALSE && (timestamp != 0))
			{
				needsPictureUpdate = TRUE;
			}
				
			if((needsPictureUpdate == TRUE) && (timestamp != lastTimestamp))
			{
				// only issue video update picture command when the
				// timestamp changes
				IssueVideoUpdatePictureCommand();
				needsPictureUpdate = FALSE;
			}
				
			if(canReleasePackets == 1)
			{
				// simply reset the frameIndex
				frameIndex = 0;
			}
			else
			{
				// increment the frameIndex, allocate a new RTP_DataFrame if needed.
				// Also increase the size of the RTP_DataFrame pool if required
				frameIndex++;
				if(frameIndex == allocatedFrames)
				{
					if(allocatedFrames % XM_FRAME_POOL_GRANULARITY == 0)
					{
						dataFrames = (RTP_DataFrame **)realloc(dataFrames, (allocatedFrames + XM_FRAME_POOL_GRANULARITY) * sizeof(RTP_DataFrame *));
					}
					
					dataFrames[frameIndex] = new RTP_DataFrame(source.GetDataSize());
					allocatedFrames++;
				}
			}
		
			// updating the variables
			lastSequenceNumber = sequenceNumber;
			lastTimestamp = timestamp;
			
			// check for loop termination conditions
			PINDEX len = sinks.GetSize();
		
			inUse.Signal();

			if(len == 0)
			{
				break;
			}
		} while(source.ReadPacket(*(dataFrames[frameIndex])));
		
		// End the media processing
		_XMStopMediaReceiving(sessionID);
	}
	
	// release the used RTP_DataFrames
	for(unsigned i = 0; i < allocatedFrames; i++)
	{
		RTP_DataFrame *dataFrame = dataFrames[i];
		delete dataFrame;
	}
	free(dataFrames);
}

void XMReceiverMediaPatch::SetCommandNotifier(const PNotifier & theNotifier,
											  BOOL fromSink)
{
	if(fromSink == FALSE)
	{
		notifier = theNotifier;
		notifierSet = TRUE;
	}
	OpalMediaPatch::SetCommandNotifier(theNotifier, fromSink);
}

void XMReceiverMediaPatch::IssueVideoUpdatePictureCommand()
{
	OpalVideoUpdatePicture command = OpalVideoUpdatePicture(-1, -1, -1);
	
	if(notifierSet == TRUE)
	{
		notifier(command, 0);
	}
}

