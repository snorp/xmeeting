/*
 * $Id: XMProcess.cpp,v 1.3 2006/03/14 23:05:57 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#include "XMProcess.h"

XMProcess::XMProcess() 
: PProcess("XMeeting", "XMeeting.app", 0, 0, AlphaCode, 1) 
{
}

void XMProcess::Main() {}