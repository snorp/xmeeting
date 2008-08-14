/*
 * $Id: XMAudioTester.h,v 1.2 2008/08/14 19:57:05 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Andreas Fenkart, Hannes Friederich. All rights reserved.
 */

#ifndef __XM_AUDIO_TESTER_H__
#define __XM_AUDIO_TESTER_H__

#include <ptlib.h>
#include "XMSoundChannel.h"
#include "XMCircularBuffer.h"

class XMAudioTester : public PThread
{
	PCLASSINFO(XMAudioTester, PThread);
	
public:
	XMAudioTester(unsigned delay);
	virtual void Main();
	
	static void Start(unsigned delay);
	static void Stop();
	
private:
	unsigned delay;
	XMCircularBuffer circularBuffer;
	bool stop;
};

#endif // __XM_AUDIO_TESTER_H__

