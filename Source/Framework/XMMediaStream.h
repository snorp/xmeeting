/*
 * $Id: XMMediaStream.h,v 1.7 2007/02/15 11:06:28 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_MEDIA_STREAM_H__
#define __XM_MEDIA_STREAM_H__

#include <ptlib.h>
#include <opal/mediastrm.h>
#include <rtp/rtp.h>

class XMMediaStream : public OpalMediaStream
{
	PCLASSINFO(XMMediaStream, OpalMediaStream);
	
public:
	XMMediaStream(const OpalMediaFormat & mediaFormat,
                  BOOL isSource);
	~XMMediaStream();
	
    virtual void OnPatchStart();
    virtual BOOL Close();
	virtual BOOL ReadPacket(RTP_DataFrame & packet);
	virtual BOOL WritePacket(RTP_DataFrame & packet);
	virtual BOOL IsSynchronous() const { return FALSE; }
    virtual BOOL RequiresPatchThread() const { return FALSE; }
    
    static void SetTimeStamp(unsigned mediaID, unsigned timeStamp);
    static void AppendData(unsigned mediaID, void *data, unsigned lenght);
    static void SendPacket(unsigned mediaID, BOOL setMarker);
    static void HandleDidStopTransmitting(unsigned mediaID);
    
    virtual BOOL ExecuteCommand(const OpalMediaCommand & command, BOOL isEndOfChain = FALSE);
    
private:
    RTP_DataFrame dataFrame;
    BOOL hasStarted;
    BOOL isTerminated;
};

#endif // __XM_MEDIA_STREAM_H__
