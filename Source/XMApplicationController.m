/*
 * $Id: XMApplicationController.m,v 1.2 2005/02/11 12:58:37 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMApplicationController.h"
#import "XMAudioManager.h"
#import "XMCallManager.h"


@implementation XMApplicationController

- (void)awakeFromNib
{
	[[XMCallManager sharedInstance] startH323Listening];
}

@end
