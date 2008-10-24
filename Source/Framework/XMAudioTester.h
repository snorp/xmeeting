/*
 * $Id: XMAudioTester.h,v 1.3 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Andreas Fenkart, Hannes Friederich. All rights reserved.
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

