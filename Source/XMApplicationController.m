/*
 * $Id: XMApplicationController.m,v 1.1 2005/01/20 17:28:12 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project (http://xmeeting.sf.net).
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMApplicationController.h"
#import "XMController.h"


@implementation XMApplicationController

- (void)awakeFromNib
{
	[XMController testEndpoint];
}

@end
