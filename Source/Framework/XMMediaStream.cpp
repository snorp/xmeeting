/*
 * $Id: XMMediaStream.cpp,v 1.1 2005/10/11 09:03:10 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#include "XMMediaStream.h"

XMMediaStream::XMMediaStream(const OpalMediaFormat & mediaFormat,
										   unsigned sessionID,
										   BOOL isSource)
: OpalMediaStream(mediaFormat, sessionID, isSource)
{
}

XMMediaStream::~XMMediaStream()
{
}

BOOL XMMediaStream::ReadPacket(RTP_DataFrame & packet)
{	
	if(IsSink())
	{
		return FALSE;
	}
	
	// do nothing here, should never be called
	return TRUE;
}

BOOL XMMediaStream::WritePacket(RTP_DataFrame & packet)
{
	if(IsSource())
	{
		return FALSE;
	}
	
	// do nothing here, should never be called
	return TRUE;
}

BOOL XMMediaStream::IsSynchronous() const
{
	return FALSE;
}