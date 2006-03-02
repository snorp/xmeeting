/*
 * $Id: XMSIPEndPoint.h,v 1.1 2006/03/02 22:35:54 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_SIP_END_POINT_H__
#define __XM_SIP_END_POINT_H__

#include <ptlib.h>
#include <sip/sipep.h>
#include <sip/sipcon.h>

class XMSIPEndPoint : public SIPEndPoint
{
	PCLASSINFO(XMSIPEndPoint, SIPEndPoint);
	
public:
	XMSIPEndPoint(OpalManager & manager);
	virtual ~XMSIPEndPoint();
	
	BOOL EnableListeners(BOOL enable);
	BOOL IsListening();
	
	virtual void OnEstablished(OpalConnection & connection);
	virtual void OnReleased(OpalConnection & connection);
	
private:
	BOOL isListening;
	
	PString connectionToken;
};

#endif // __XM_SIP_END_POINT_H__
