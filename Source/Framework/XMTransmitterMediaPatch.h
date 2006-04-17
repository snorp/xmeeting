/*
 * $Id: XMTransmitterMediaPatch.h,v 1.9 2006/04/17 17:51:22 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_TRANSMITTER_MEDIA_PATCH__
#define __XM_TRANSMITTER_MEDIA_PATCH__

#include <ptlib.h>
#include <opal/patch.h>

#include "XMTypes.h"

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
	
	virtual BOOL ExecuteCommand(const OpalMediaCommand & command,
								BOOL fromSink);
	
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
	RTP_DataFrame::PayloadTypes payloadType;
	XMCodecIdentifier codecIdentifier;
};

#endif // __XM_TRANSMITTER_MEDIA_PATCH__