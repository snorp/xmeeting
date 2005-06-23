/*
 * $Id: XMSubsystemSetupThread.cpp,v 1.1 2005/06/23 12:35:56 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#include "XMSubsystemSetupThread.h"
#include "XMCallbackBridge.h"

XMSubsystemSetupThread::XMSubsystemSetupThread(void *thePreferences)
: PThread(1000, AutoDeleteThread, NormalPriority, "XMSubsystemSetupThread")
{
	preferences = thePreferences;
	Resume();
}

XMSubsystemSetupThread::~XMSubsystemSetupThread()
{
	cout << "destructor" << endl;
}

void XMSubsystemSetupThread::Main()
{
	// all this method does is calling the Objective-C
	// with the preferences pointer so that the OPAL
	// subsystem can be setup correctly within the context
	// of a new thread
	doSubsystemSetup(preferences);
}