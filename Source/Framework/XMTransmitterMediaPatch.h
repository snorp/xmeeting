/*
 * $Id: XMTransmitterMediaPatch.h,v 1.2 2005/10/17 12:57:53 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_TRANSMITTER_MEDIA_PATCH__
#define __XM_TRANSMITTER_MEDIA_PATCH__

#include <ptlib.h>
#include <opal/patch.h>

// The purpose of this class is to have an OpalMediaPatch
// instance which doesn't spawn it's own thread.
// Rather, the MediaTransmitter is passed a message so that
// the MediaTransmitter thread, which does already run,
// does start transmitting the media
class XMTransmitterMediaPatch : public OpalMediaPatch
{
	PCLASSINFO(XMTransmitterMediaPatch, OpalMediaPatch);
	
public:
	XMTransmitterMediaPatch(OpalMediaStream & source);
	~XMTransmitterMediaPatch();
	
	virtual BOOL IsTerminated() const;
	virtual void Resume();
	void Close();
	
	static void SetTimeStamp(unsigned sessionID,
							 unsigned timeStamp);
	
	static void AppendData(unsigned sessionID,
						   void *data,
						   unsigned length);
	
	static void SendPacket(unsigned sessionID, BOOL setMarker);
	
	static void HandleDidStopTransmitting(unsigned sessionID);
	
private:

	BOOL doesRunOwnThread;
	BOOL isTerminated;
	RTP_DataFrame *dataFrame;
};

#endif // __XM_TRANSMITTER_MEDIA_PATCH__