/*
 * $Id: XMProcess.h,v 1.2 2005/06/23 12:35:56 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
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

