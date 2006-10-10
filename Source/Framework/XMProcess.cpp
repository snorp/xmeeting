/*
 * $Id: XMProcess.cpp,v 1.7 2006/10/10 16:48:25 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#include "XMProcess.h"

XMProcess::XMProcess() 
: PProcess("XMeeting", "XMeeting.app", 0, 3, BetaCode, 3) 
{
}

void XMProcess::Main() {}