/*
 * $Id: XMProcess.cpp,v 1.9 2007/08/07 17:09:58 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#include "XMProcess.h"

XMProcess::XMProcess() 
: PProcess("XMeeting Project", "XMeeting", 0, 4, AlphaCode, 1) 
{
}

void XMProcess::Main() {}