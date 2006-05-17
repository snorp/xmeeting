/*
 * $Id: XMProcess.cpp,v 1.5 2006/05/17 23:54:05 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#include "XMProcess.h"

XMProcess::XMProcess() 
: PProcess("XMeeting", "XMeeting.app", 0, 2, BetaCode, 1) 
{
}

void XMProcess::Main() {}