/*
 * $Id: XMReceiverMediaPatch.cpp,v 1.5 2005/11/23 19:28:44 hfriederich Exp $
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

XMReceiverMediaPatch::XMReceiverMediaPatch(OpalMediaStream & src)
: OpalMediaPatch(src)
{
	//cout << "Patch created" << endl;
	didStartMediaReceiver = FALSE;
	notifierSet = FALSE;
}

XMReceiverMediaPatch::~XMReceiverMediaPatch()
{
	//cout << "VideoReceivePatch destroyed" << endl;
}

void XMReceiverMediaPatch::Main()
{
	PINDEX i;
	
	inUse.Wait();
	if (!source.IsSynchronous()) 
	{
		for(i = 0; i < sinks.GetSize(); i++) 
		{
			if (sinks[i].stream->IsSynchronous()) 
			{
				source.EnableJitterBuffer();
				break;
			}
		}
	}
	inUse.Signal();
	
	WORD lastSequenceNumber = 0;
	DWORD lastTimestamp;
	BOOL needsPictureUpdate = FALSE;
	
	RTP_DataFrame sourceFrame(source.GetDataSize());
	while(source.ReadPacket(sourceFrame))
	{
		inUse.Wait();
		
		FilterFrame(sourceFrame, source.GetMediaFormat());
		
		PINDEX size = sinks.GetSize();
		for(i = 0; i < size; i++)
		{
			if(PIsDescendant(sinks[i].stream, XMMediaStream))
			{
				unsigned sessionID = source.GetSessionID();
				
				WORD sequenceNumber = sourceFrame.GetSequenceNumber();
				DWORD timestamp = sourceFrame.GetTimestamp();
				
				if(sequenceNumber != (lastSequenceNumber + 1))
				{
					if(timestamp == 0)
					{
						// this is normally the first packet received
						// and should not be treated as a lost packet
						lastSequenceNumber = sequenceNumber;
						//break;
					}
					
					needsPictureUpdate = TRUE;
				}
				
				if(didStartMediaReceiver == FALSE)
				{
					int codecType;
					XMVideoSize mediaSize;
					
					OpalMediaFormat mediaFormat = source.GetMediaFormat();
					
					if(mediaFormat == XM_MEDIA_FORMAT_H261_QCIF)
					{
						codecType = XMCodecIdentifier_H261;
						mediaSize = XMVideoSize_QCIF;
					}
					else if(mediaFormat == XM_MEDIA_FORMAT_H261_CIF)
					{
						codecType = XMCodecIdentifier_H261;
						mediaSize = XMVideoSize_CIF;
					}
					
					RTP_DataFrame::PayloadTypes payloadType = sourceFrame.GetPayloadType();
					_XMStartMediaReceiving(codecType, (unsigned)payloadType, mediaSize, sessionID);
					
					didStartMediaReceiver = TRUE;
				}
				
				BYTE *dataPtr = sourceFrame.GetPayloadPtr();
				PINDEX length = sourceFrame.GetPayloadSize();
				PINDEX headerSize = sourceFrame.GetHeaderSize();
				dataPtr -= headerSize;
				length += headerSize;
				
				BOOL succ = _XMProcessPacket((void *)dataPtr, (unsigned)length, sessionID);
				if(succ == FALSE)
				{
					needsPictureUpdate = TRUE;
				}
				
				if((needsPictureUpdate == TRUE) && 
				   (timestamp != lastTimestamp))
				{
					// only issue video update picture command when the
					// timestamp changes
					IssueVideoUpdatePictureCommand();
					needsPictureUpdate = FALSE;
				}
				
				lastSequenceNumber = sequenceNumber;
				lastTimestamp = timestamp;
			}
			else
			{
				sinks[i].WriteFrame(sourceFrame);
			}
		}
		
		PINDEX len = sinks.GetSize();
		
		inUse.Signal();
		
		if(len == 0)
		{
			break;
		}
	}
	
	if(didStartMediaReceiver == TRUE)
	{
		_XMStopMediaReceiving(source.GetSessionID());
	}
	
	//cout << "XMVideoReceivePatchTread ended" << endl;
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
	cout << "issuing videoUpdateCommand" << endl;
	OpalVideoUpdatePicture command = OpalVideoUpdatePicture(-1, -1, -1);
	
	if(notifierSet == TRUE)
	{
		notifier(command, 0);
	}
}

