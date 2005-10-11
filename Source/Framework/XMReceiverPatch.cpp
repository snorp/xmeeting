/*
 * $Id: XMReceiverPatch.cpp,v 1.1 2005/10/11 09:03:10 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#include "XMReceiverPatch.h"

#include <opal/mediastrm.h>

#include "XMMediaStream.h"
#include "XMCallbackBridge.h"

XMReceiverPatch::XMReceiverPatch(OpalMediaStream & src)
: OpalMediaPatch(src)
{
	cout << "Patch created" << endl;
}

XMReceiverPatch::~XMReceivePatch()
{
	cout << "VideoReceivePatch destroyed" << endl;
}

void XMReceiverPatch::Main()
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
				BYTE *dataPtr = sourceFrame.GetPayloadPtr();
				PINDEX length = sourceFrame.GetPayloadSize();
				PINDEX headerSize = sourceFrame.GetHeaderSize();
				dataPtr -= headerSize;
				length += headerSize;
				
				XMProcessPacket((void *)dataPtr, (unsigned)length, source.GetSessionID());
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
	
	cout << "XMVideoReceivePatchTread ended" << endl;
}