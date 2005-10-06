/*
 * $Id: XMeeting.m,v 1.2 2005/10/06 15:04:42 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMeeting.h"
#import "XMPrivate.h"

void InitXMeetingFramework()
{
	[XMUtils sharedInstance];
	[XMCallManager sharedInstance];
	[XMCodecManager sharedInstance];
	[XMAudioManager sharedInstance];
	[[XMVideoManager sharedInstance] _startup];
}
