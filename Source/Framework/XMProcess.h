/*
 * $Id: XMProcess.h,v 1.3 2006/03/14 23:05:57 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

/*
 * PWLib requires a subclass of PProcess to be present
 * in order to work correctly.
 * This implementation does nothing besides correct initialization
 */

#ifndef __XM_PROCESS_H__
#define __XM_PROCESS_H__

#include <ptlib.h>

class XMProcess : public PProcess
{
public:
	// Constructor
	XMProcess();
	
	// never used!
	virtual void Main();
};

#endif // __XM_PROCESS_H__

