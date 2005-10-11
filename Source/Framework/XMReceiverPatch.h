/*
 * $Id: XMReceiverPatch.h,v 1.1 2005/10/11 09:03:10 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_RECEIVER_PATCH__
#define __XM_RECEIVER_PATCH__

#include <ptlib.h>
#include <opal/patch.h>

class XMReceiverPatch : public OpalMediaPatch
{
	PCLASSINFO(XMReceiverPatch, OpalMediaPatch);
	
public:
	XMReceiverPatch(OpalMediaStream & source);
	~XMReceiverPatch();
	
	virtual void Main();
};

#endif // __XM_RECEIVER_PATCH__

