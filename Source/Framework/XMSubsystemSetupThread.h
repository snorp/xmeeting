/*
 * $Id: XMSubsystemSetupThread.h,v 1.1 2005/06/23 12:35:56 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_SUBSYSTEM_SETUP_THREAD_H__
#define __XM_SUBSYSTEM_SETUP_THREAD_H__

#include <ptlib.h>

/**
 * This class is required to create a correct PThread
 * instance so that calls to the OPAL subsystem work
 * from the Objective-C world. When directly using the
 * NSThread API, some calls to OPAL object fail with
 * Signal 10 (SIGBUS)
 **/
class XMSubsystemSetupThread : public PThread
{
	PCLASSINFO(XMSubsystemSetupThread, PThread);
	
public:
	// preferences is a (void*) wrapped pointer to an
	// XMPreferences Obj-C object which will be passed
	// back to the Objective-C world
	XMSubsystemSetupThread(void *preferences);
	~XMSubsystemSetupThread();
	
	void Main();
private:
	void *preferences;
};

#endif // __XM_SUBSYSTEM_SETUP_THREAD_H__
