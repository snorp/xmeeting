/*
 * $Id: XMMediaStream.h,v 1.9 2008/08/14 19:57:05 hfriederich Exp $
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

class XMConnection;

class XMMediaStream : public OpalMediaStream
{
	PCLASSINFO(XMMediaStream, OpalMediaStream);
	
public:
	XMMediaStream(XMConnection & conn,
                const OpalMediaFormat & mediaFormat,
                unsigned sessionID,
                bool isSource);
	~XMMediaStream();
	
    virtual void OnPatchStart();
    virtual bool Close();
	virtual bool ReadPacket(RTP_DataFrame & packet);
	virtual bool WritePacket(RTP_DataFrame & packet);
	virtual bool IsSynchronous() const { return false; }
    virtual bool RequiresPatchThread() const { return false; }
    
    static void SetTimeStamp(unsigned mediaID, unsigned timeStamp);
    static void AppendData(unsigned mediaID, void *data, unsigned lenght);
    static void SendPacket(unsigned mediaID, bool setMarker);
    static void HandleDidStopTransmitting(unsigned mediaID);
    
    virtual bool ExecuteCommand(const OpalMediaCommand & command, bool isEndOfChain = false);
    
private:
    RTP_DataFrame dataFrame;
    bool hasStarted;
    bool isTerminated;
};

#endif // __XM_MEDIA_STREAM_H__
