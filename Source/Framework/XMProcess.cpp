/*
 * $Id: XMProcess.cpp,v 1.1 2005/02/11 12:58:44 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#include "XMProcess.h"

XMProcess::XMProcess() : PProcess("XMeeting", "XMeeting.app", 0, 0, AlphaCode, 1) {}

void XMProcess::Main() {}