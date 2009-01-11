/*
 * $Id: XMProcess.cpp,v 1.14 2009/01/11 18:57:54 hfriederich Exp $
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
: PProcess("XMeeting Project", "XMeeting", 0, 4, BetaCode, 1) 
{
}

XMProcess::~XMProcess()
{
}

void XMProcess::Main() {}