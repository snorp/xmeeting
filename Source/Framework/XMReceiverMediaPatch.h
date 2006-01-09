/*
 * $Id: XMReceiverMediaPatch.h,v 1.4 2006/01/09 22:22:57 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_RECEIVER_MEDIA_PATCH__
#define __XM_RECEIVER_MEDIA_PATCH__

#include <ptlib.h>
#include <opal/patch.h>

#include "XMRTPPacket.h"

class XMReceiverMediaPatch : public OpalMediaPatch
{
	PCLASSINFO(XMReceiverMediaPatch, OpalMediaPatch);
	
public:
	XMReceiverMediaPatch(OpalMediaStream & source);
	~XMReceiverMediaPatch();
	
	virtual void Main();
	virtual void SetCommandNotifier(const PNotifier & notifier,
									BOOL fromSink);
	
private:
		
	void IssueVideoUpdatePictureCommand();
	
	BOOL IsFirstPacketOfH261Frame(XMRTPPacket *packet);
	BOOL CopyH261PacketsIntoFrameBuffer(XMRTPPacket *packetListHead, BYTE *frameBuffer, PINDEX *frameBufferSize);
	
	PNotifier notifier;
	BOOL notifierSet;
};

#endif // __XM_RECEIVER_MEDIA_PATCH__

