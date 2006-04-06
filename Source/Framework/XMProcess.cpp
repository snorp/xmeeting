/*
 * $Id: XMProcess.cpp,v 1.4 2006/04/06 23:15:32 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#include "XMProcess.h"

XMProcess::XMProcess() 
: PProcess("XMeeting", "XMeeting.app", 0, 2, AlphaCode, 2) 
{
}

void XMProcess::Main() {}