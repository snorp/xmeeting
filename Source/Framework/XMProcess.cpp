/*
 * $Id: XMProcess.cpp,v 1.10 2008/09/22 22:26:09 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#include "XMProcess.h"

// keep PTLib-linking happy
namespace PWLibStupidOSXHacks {
  int loadFakeVideoStuff;
  int loadCoreAudioStuff;
}

XMProcess::XMProcess() 
: PProcess("XMeeting Project", "XMeeting", 0, 4, AlphaCode, 1) 
{
}

void XMProcess::Main() {}