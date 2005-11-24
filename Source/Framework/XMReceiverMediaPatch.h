/*
 * $Id: XMReceiverMediaPatch.h,v 1.3 2005/11/24 21:13:02 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_RECEIVER_MEDIA_PATCH__
#define __XM_RECEIVER_MEDIA_PATCH__

#include <ptlib.h>
#include <opal/patch.h>

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
	PNotifier notifier;
	BOOL notifierSet;
};

#endif // __XM_RECEIVER_MEDIA_PATCH__

