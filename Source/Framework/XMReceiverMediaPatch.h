/*
 * $Id: XMReceiverMediaPatch.h,v 1.7 2006/04/06 23:15:32 hfriederich Exp $
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
#include "XMPacketReassemblers.h"

class XMReceiverMediaPatch : public OpalMediaPatch
{
	PCLASSINFO(XMReceiverMediaPatch, OpalMediaPatch);
	
public:
	XMReceiverMediaPatch(OpalMediaStream & source);
	~XMReceiverMediaPatch();
	
	virtual void Main();
	virtual void SetCommandNotifier(const PNotifier & notifier,
									BOOL fromSink);
	
	static void SetIsRFC2429(BOOL flag);
	static BOOL IsRFC2429(RTP_DataFrame::PayloadTypes payloadType, const BYTE *data, unsigned dataLength);
	
private:
		
	void IssueVideoUpdatePictureCommand();
	
	XMRTPPacketReassembler *packetReassembler;
	
	PNotifier notifier;
	BOOL notifierSet;
};

#endif // __XM_RECEIVER_MEDIA_PATCH__

