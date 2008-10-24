/*
 * $Id: XMProcess.cpp,v 1.13 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#include "XMProcess.h"

// keep PTLib-linking happy
namespace PWLibStupidLinkerHacks {
  int loadFakeVideoStuff;
  int loadCoreAudioStuff;
}

XMProcess::XMProcess() 
: PProcess("XMeeting Project", "XMeeting", 0, 4, AlphaCode, 1) 
{
}

XMProcess::~XMProcess()
{
}

void XMProcess::Main() {}