/*
 * $Id: XMMediaStream.h,v 1.3 2005/10/20 11:55:55 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_MEDIA_STREAM_H__
#define __XM_MEDIA_STREAM_H__

#include <ptlib.h>
#include <opal/mediastrm.h>

class XMMediaStream : public OpalMediaStream
{
	PCLASSINFO(XMMediaStream, OpalMediaStream);
	
public:
	XMMediaStream(const OpalMediaFormat & mediaFormat,
						 unsigned sessionID,
						 BOOL isSource);
	~XMMediaStream();
	
	virtual BOOL ReadPacket(RTP_DataFrame & packet);
	virtual BOOL WritePacket(RTP_DataFrame & packet);
	virtual BOOL IsSynchronous() const;
	virtual BOOL Close();
};

#endif // __XM_MEDIA_STREAM_H__
