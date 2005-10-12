/*
 * $Id: XMReceiverMediaPatch.cpp,v 1.1 2005/10/12 21:07:40 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#include "XMReceiverMediaPatch.h"

#include <opal/mediastrm.h>

#include "XMMediaFormats.h"
#include "XMMediaStream.h"
#include "XMCallbackBridge.h"

XMReceiverMediaPatch::XMReceiverMediaPatch(OpalMediaStream & src)
: OpalMediaPatch(src)
{
	//cout << "Patch created" << endl;
	didStartMediaReceiver = FALSE;
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
				
				if(didStartMediaReceiver == FALSE)
				{
					unsigned codecType;
					XMVideoSize mediaSize;
					
					OpalMediaFormat mediaFormat = source.GetMediaFormat();
					
					if(mediaFormat == XM_MEDIA_FORMAT_H261_QCIF)
					{
						codecType = _XMVideoCodec_H261;
						mediaSize = XMVideoSize_QCIF;
					}
					else if(mediaFormat == XM_MEDIA_FORMAT_H261_CIF)
					{
						codecType = _XMVideoCodec_H261;
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
				
				_XMProcessPacket((void *)dataPtr, (unsigned)length, sessionID);
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