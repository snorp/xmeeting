/*
 * $Id: XMeeting.m,v 1.1 2005/06/23 12:35:56 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMeeting.h"

void InitXMeetingFramework()
{
	[XMUtils sharedInstance];
	[XMCallManager sharedInstance];
	[XMCodecManager sharedInstance];
	[XMAudioManager sharedInstance];
	[XMVideoManager sharedInstance];
}
