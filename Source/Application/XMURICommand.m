/*
 * $Id: XMURICommand.m,v 1.1 2006/08/17 21:47:28 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#import "XMURICommand.h"

@implementation XMURICommand

- (id)performDefaultImplementation
{
    NSString *command = [[self commandDescription] commandName];
    NSString *urlString = [self directParameter]; 
	
    if ([command isEqualToString:@"GetURL"] ||
        [command isEqualToString:@"OpenURL"])
	{
        NSLog(@"Received script command: %@ (%@)", command, urlString);
    }
    return nil;
}

@end
