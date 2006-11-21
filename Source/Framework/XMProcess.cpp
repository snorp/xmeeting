/*
 * $Id: XMProcess.cpp,v 1.8 2006/11/21 13:09:54 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#include "XMProcess.h"

XMProcess::XMProcess() 
: PProcess("XMeeting", "XMeeting.app", 0, 3, BetaCode, 4) 
{
}

void XMProcess::Main() {}